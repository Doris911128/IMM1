// MARK: 計畫View
import SwiftUI
import Foundation

struct Dish: Codable
{
    let Dis_Name: String
    let D_image: String
    let Dis_serving: String
}

func fetchDishesFromServer(completion: @escaping ([Dish]?, Error?) -> Void) {
    guard let url = URL(string: "http://163.17.9.107/food/php/Dishes.php") else {
        print("Invalid URL")
        completion(nil, NSError(domain: "InvalidURL", code: 0, userInfo: nil))
        return
    }
    
    URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Error: Invalid HTTP response")
            completion(nil, NSError(domain: "HTTPError", code: 0, userInfo: nil))
            return
        }
        
        guard let jsonData = data else {
            print("Error: No data received")
            completion(nil, NSError(domain: "NoDataError", code: 0, userInfo: nil))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let dishes = try decoder.decode([Dish].self, from: jsonData)
            completion(dishes, nil)
        } catch {
            print("Error decoding JSON: \(error)")
            completion(nil, error)
        }
    }.resume()
}


struct PlanDeleteError: Error
{
    let message: String
}

struct Plan: Codable {
    let P_ID: String
    let U_ID: String
    let Dis_ID: Int
    let P_DT: String
    let P_Bought: String
    let Dis_name: String
    var D_image: String? // 新增屬性
}

// 刪除計劃的方法
func deletePlan(withID pID: String, day: String, at indices: IndexSet, completion: @escaping (Result<Void, Error>) -> Void)
{
    guard let url = URL(string: "http://163.17.9.107/food/php/Plandelete.php")
    else {
        completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    // 將 P_ID 進行 URL 編碼並添加到請求參數中
    guard let encodedPID = pID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        completion(.failure(NSError(domain: "URLEncodingError", code: 1, userInfo: nil)))
        return
    }
    let parameters = "delete=true&P_ID=\(encodedPID)"
    request.httpBody = parameters.data(using: .utf8)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = "Invalid HTTP response: \(String(describing: response))"
            completion(.failure(NSError(domain: "HTTPError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            return
        }
        
        guard let data = data else {
            let errorMessage = "No data received"
            completion(.failure(NSError(domain: "NoDataError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            return
        }
        
        guard let responseData = String(data: data, encoding: .utf8) else {
            let errorMessage = "Failed to decode response data"
            completion(.failure(NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            return
        }
        
        let responseString = responseData
        
        if responseString.contains("{\"status\":\"success\"}") {
            completion(.success(()))
            
            // 在成功的 case 中打印 responseString
            print("Server response:", responseString)
        } else {
            let errorMessage = "Failed to delete plan. Server response: \(responseString)"
            completion(.failure(PlanDeleteError(message: errorMessage)))
        }
    }.resume()
}
func Plan_PRdelete(withID pID: String, day: String, at indices: IndexSet, completion: @escaping (Result<Void, Error>) -> Void)
{
    guard let url = URL(string: "http://163.17.9.107/food/php/Plan_PRdelete.php")
    else {
        completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    // 將 P_ID 進行 URL 編碼並添加到請求參數中
    guard let encodedPID = pID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        completion(.failure(NSError(domain: "URLEncodingError", code: 1, userInfo: nil)))
        return
    }
    let parameters = "delete=true&P_ID=\(encodedPID)"
    request.httpBody = parameters.data(using: .utf8)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = "Invalid HTTP response: \(String(describing: response))"
            completion(.failure(NSError(domain: "HTTPError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            return
        }
        
        guard let data = data else {
            let errorMessage = "No data received"
            completion(.failure(NSError(domain: "NoDataError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            return
        }
        
        guard let responseData = String(data: data, encoding: .utf8) else {
            let errorMessage = "Failed to decode response data"
            completion(.failure(NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            return
        }
        
        let responseString = responseData
        
        if responseString.contains("{\"status\":\"success\"}") {
            completion(.success(()))
            
            // 在成功的 case 中打印 responseString
            print("Server ssssssresponse:", responseString)
        } else {
            let errorMessage = "Failed to delete plan. Server response: \(responseString)"
            completion(.failure(PlanDeleteError(message: errorMessage)))
        }
    }.resume()
}
struct PlanView: View {
    // DateFormatter for formatting dates
    private let dateFormatter: DateFormatter
    @State private var deletionResult: Result<Void, Error>? = nil
    @State private var plans: [String: [Plan]] = [:] // 修改這裡的類型
    @State private var nameToIDMap: [String: String] = [:]
    @State private var selectedDate: String?
    @State private var showSingleDayView: Bool = false // 新增狀態變數
    @State private var dishes: [String: String] = [:] // 新增變數來儲存 Dis_Name 和 D_image 的映射
    @State private var dishServings: [String: String] = [:] // 新增變數來儲存 Dis_Name 和 Dis_serving 的映射
    @State private var hasCreatedNewPlan: Bool = false
    @State private var shakeAnimation: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    // DateFormatter for displaying dates in MM/DD format 用於顯示日期的 DateFormatter
    private var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }()
    private var displayDateFormatters: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    private var fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }()
    private var dayOfWeekFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    private var dayOfWeekFormatters: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_tw") // 設置為中文
        return formatter
    }()
    func convertPlansToDictionary(plans: [Plan]) -> [String: [Plan]] {
        var plansDict = [String: [Plan]]()
        var idToNameMap = [String: String]()
        var nameToIDMap = [String: String]() // 添加一个映射 Dis_name 到 P_ID 的字典
        let currentDate = Calendar.current.startOfDay(for: Date())
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: currentDate)!
        for plan in plans {
            idToNameMap[plan.P_ID] = plan.Dis_name
            nameToIDMap[plan.Dis_name] = plan.P_ID // 將 Dis_name 映射到 P_ID
        }
        
        // 遍歷七天內的日期，初始化字典中的鍵
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: currentDate) {
                let dateString = dateFormatter.string(from: date)
                plansDict[dateString] = []
            }
        }
        
        // 將計畫數據添加到字典中
        for plan in plans {
            guard let planDate = dateFormatter.date(from: plan.P_DT) else {
                continue
            }
            // 檢查計畫日期是否在接下來的七天內，並添加到相應的日期中
            if planDate >= currentDate && planDate <= endDate {
                let date = dateFormatter.string(from: planDate)
                if plansDict[date] == nil {
                    plansDict[date] = []
                }
                let disName = plan.Dis_name
                plansDict[date]?.append(plan) // 將 Plan 添加到相應的日期中
            }
        }
        return plansDict
    }
    
    func isNewPlan(_ plan: Plan) -> Bool {
        return plan.Dis_name == "新計畫"
    }
    
    func updatePlans() {
        fetchPlansFromServer { fetchedPlans, error in
            if let fetchedPlans = fetchedPlans {
                DispatchQueue.main.async {
                    self.plans = convertPlansToDictionary(plans: fetchedPlans)
                    self.updateNameToIDMap(plans: fetchedPlans) // 更新 nameToIDMap
                }
            } else if let error = error {
                print("Failed to fetch plans: \(error)")
            }
        }
    }
    
    func updateNameToIDMap(plans: [Plan]) {
        var newMap = [String: String]()
        for plan in plans {
            newMap[plan.Dis_name] = plan.P_ID
        }
        self.nameToIDMap = newMap
    }
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    var body: some View
    {
        NavigationStack
        {
            VStack(alignment: .leading)
            {
                Text("今天是 \(Date(), formatter: fullDateFormatter)")
                    .font(.headline)
                    .padding(.top, 20)
                    .padding(.leading, 20)
                ScrollView(.horizontal)
                {
                    HStack
                    {
                        ForEach(0..<7, id: \.self) { offset in
                            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                            let dateString = dateFormatter.string(from: date)
                            let dayOfWeek = dayOfWeekFormatter.string(from: date)
                            Button(action: {
                                if selectedDate == dateString {
                                    showSingleDayView.toggle()
                                    if (!showSingleDayView) {
                                        selectedDate = nil
                                    }
                                } else {
                                    selectedDate = dateString
                                    showSingleDayView = true
                                }
                            }) {
                                VStack {
                                    Text(displayDateFormatter.string(from: date))
                                        .font(.headline)
                                        .foregroundColor(selectedDate == dateString && showSingleDayView ? .white : .primary) // 在选中状态下为白色，否则为主色调
                                    Text(dayOfWeek)
                                        .font(.subheadline)
                                        .foregroundColor(selectedDate == dateString && showSingleDayView ? .white : .secondary) // 在选中状态下为白色，否则为次要色调
                                }
                                .frame(width: 35, height: 50)
                                .padding()
                                .background(selectedDate == dateString && showSingleDayView ? Color.orange : Color(UIColor.systemGray5))
                                .clipShape(Capsule())
                            }
                        }

                        .padding(3)
                    }
                    .padding(.horizontal)
                }.scrollIndicators(.hidden)
                
                List {
                    ForEach(Array(plans.keys.sorted(by: <)), id: \.self) { day in
                        if !showSingleDayView || selectedDate == day {
                            Section(header: HStack {
                                Text(self.displayDateFormatters.string(from: dateFormatter.date(from: day)!)).font(.title)
                                Text(getDayLabelText(for: day))
                                Spacer()
                                
                                // 按鈕仍然存在，但根據hasCreatedNewPlan狀態來禁用
                                Button(action: {
                                    plans[day]?.append(Plan(P_ID: UUID().uuidString, U_ID: "", Dis_ID: 0, P_DT: day, P_Bought: "", Dis_name: "新計畫"))
                                    hasCreatedNewPlan = true // 設置為true，防止再次添加
                                    shakeAnimation.toggle() // 啟動抖動動畫
                                }) {
                                    Image(systemName: "plus.circle")
                                        .imageScale(.large)
                                        .foregroundColor(hasCreatedNewPlan ? Color.gray : Color("BottonColor")) // 改變顏色
                                }
                                .disabled(hasCreatedNewPlan) // 禁用按鈕
                            }) {
                                if let dayPlans = plans[day]
                                {
                                    // 修改 body 中 NavigationLink 的 .disabled 條件
                                    ForEach(dayPlans.indices, id: \.self) { index in
                                        let plan = dayPlans[index]
                                        let isEditable = isNewPlan(plan) // 檢查是否是新計畫
                                        let dishImageURL = URL(string: dishes[plan.Dis_name] ?? "")// 添加這行
                                        
                                        HStack
                                        {
                                            if let imageURL = dishImageURL { // 添加這部分
                                                AsyncImage(url: imageURL) { image in
                                                    image.resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 50, height: 50)
                                                        .clipShape(Circle())
                                                } placeholder:
                                                {
                                                    ProgressView()
                                                }
                                            }
                                            
                                            NavigationLink(destination: isEditable ? EditPlanView(day: day, planIndex: index, plans: $plans) : nil)
                                            {
                                                VStack(alignment: .leading) { // 將文字設定為向下
                                                    Text(plan.Dis_name)
                                                        .font(.headline)
                                                    if let serving = dishServings[plan.Dis_name] {
                                                        Text(serving)
                                                            .font(.subheadline)
                                                    }
                                                }
                                            }
                                            .disabled(!isEditable) // 禁用點擊進入功能
                                            
                                        }
                                    }
                                    .onDelete
                                    { indices in
                                        guard let deletedPlan = plans[day]?[indices.first ?? 0]
                                        else
                                        {
                                            print("Error: Deleted plan not found")
                                            return
                                        }
                                        
                                        deletePlan(withID: deletedPlan.P_ID, day: day, at: indices)
                                        { result in
                                            switch result
                                            {
                                            case .success:
                                                print("成功刪除計畫:", deletedPlan.P_ID)
                                                DispatchQueue.main.async
                                                {
                                                    if var dayPlans = self.plans[day]
                                                    {
                                                        dayPlans.remove(atOffsets: indices)
                                                        self.plans[day] = dayPlans
                                                    }
                                                }
                                                
                                            case .failure(let error):
                                                print("Failed with error:", error)
                                                if let planDeleteError = error as? PlanDeleteError
                                                {
                                                    print("計劃刪除錯誤訊息:", planDeleteError.message)
                                                }
                                            }
                                        }
                                        Plan_PRdelete(withID: deletedPlan.P_ID, day: day, at: indices)
                                        { result in
                                            switch result
                                            {
                                            case .success:
                                                print("成功刪除計畫:", deletedPlan.P_ID)
                                                DispatchQueue.main.async
                                                {
                                                    if var dayPlans = self.plans[day]
                                                    {
                                                        dayPlans.remove(atOffsets: indices)
                                                        self.plans[day] = dayPlans
                                                    }
                                                }
                                                
                                            case .failure(let error):
                                                print("Failed with error:", error)
                                                if let planDeleteError = error as? PlanDeleteError
                                                {
                                                    print("計劃刪除錯誤訊息:", planDeleteError.message)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .onDisappear {
                    // 當用戶完成計畫時，重置狀態變數
                    hasCreatedNewPlan = false // 這可以根據實際情況進行調整
                }
            }
        }
        .onAppear {
            updatePlans()
            fetchDishesFromServer { fetchedDishes, error in
                if let fetchedDishes = fetchedDishes {
                    DispatchQueue.main.async {
                        var newDishes = [String: String]()
                        var newDishServings = [String: String]() // 添加這行
                        for dish in fetchedDishes {
                            newDishes[dish.Dis_Name] = dish.D_image
                            newDishServings[dish.Dis_Name] = dish.Dis_serving // 添加這行
                        }
                        self.dishes = newDishes
                        self.dishServings = newDishServings // 添加這行
                    }
                } else if let error = error {
                    print("Failed to fetch dishes: \(error)")
                }
            }
        }
    }
    
    private func getDayLabelText(for date: String) -> String {
        guard let dateObject = dateFormatter.date(from: date) else {
            return ""
        }
        
        let dayOfWeek = dayOfWeekFormatters.string(from: dateObject)
        return dayOfWeek
    }
}

struct PlanView_Previews: PreviewProvider
{
    static var previews: some View
    {
        PlanView()
    }
}

func fetchPlansFromServer(completion: @escaping ([Plan]?, Error?) -> Void)
{
    guard let url = URL(string: "http://163.17.9.107/food/php/Plan.php")
    else
    {
        print("Invalid URL")
        completion(nil, NSError(domain: "InvalidURL", code: 0, userInfo: nil))
        return
    }
    
    URLSession.shared.dataTask(with: url)
    { (data, response, error) in
        if let error = error
        {
            completion(nil, error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
        else
        {
            print("Error: Invalid HTTP response")
            completion(nil, NSError(domain: "HTTPError", code: 0, userInfo: nil))
            return
        }
        
        guard let jsonData = data
        else
        {
            print("Error: No data received")
            completion(nil, NSError(domain: "NoDataError", code: 0, userInfo: nil))
            return
        }
        
        do
        {
            let decoder = JSONDecoder()
            let plans = try decoder.decode([Plan].self, from: jsonData)
            completion(plans, nil)
        } catch
        {
            print("Error decoding JSON: \(error)")
            completion(nil, error)
        }
    }.resume()
}
