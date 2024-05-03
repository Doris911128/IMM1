// MARK: 計畫View
    import SwiftUI
    import Foundation

struct PlanDeleteError: Error {
    let message: String
}

    struct Plan: Codable {
        let P_ID: String
        let U_ID: String
        let Dis_ID: String
        let P_DT: String
        let P_Bought: String
        let Dis_name: String
    }

// 刪除計劃的方法
func deletePlan(withID pID: String, day: String, at indices: IndexSet, completion: @escaping (Result<Void, Error>) -> Void) {
    guard let url = URL(string: "http://163.17.9.107/food/Plandelete.php") else {
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





    struct PlanView: View {
        // DateFormatter for formatting dates
        private let dateFormatter: DateFormatter
        @State private var deletionResult: Result<Void, Error>? = nil
        @State private var plans: [String: [String]] = [:] // 修改此行，將型別改為 [String: [String]]
        @State private var nameToIDMap: [String: String] = [:]
        @State private var showingAlert = false
        @State private var alertMessage = ""

        // DateFormatter for displaying dates in MM/DD format
        private var displayDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter
        }()
        
        func convertPlansToDictionary(plans: [Plan]) -> [String: [String]] {
            var plansDict = [String: [String]]()
            var idToNameMap = [String: String]()
            var nameToIDMap = [String: String]() // 添加一个映射 Dis_name 到 P_ID 的字典
            let currentDate = Calendar.current.startOfDay(for: Date())
            let endDate = Calendar.current.date(byAdding: .day, value: 7, to: currentDate)!
                for plan in plans {
                    idToNameMap[plan.P_ID] = plan.Dis_name
                    nameToIDMap[plan.Dis_name] = plan.P_ID // 将 Dis_name 映射到 P_ID
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
                    plansDict[date]?.append(disName) // 只將 Dis_Name 添加到相應的日期中
                }
            }
            return plansDict
        }


        func isNewPlan(_ plan: String) -> Bool {
            return plan != "新計畫"
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
     
        var body: some View {
            NavigationStack {
                VStack {
                    Text("計畫")
                    List {
                        ForEach(Array(plans.keys.sorted(by: <)), id: \.self) { day in
                            Section(header:
                                HStack {
                                    Text(self.displayDateFormatter.string(from: dateFormatter.date(from: day)!)).font(.title)
                                    Text(getDayLabelText(for: day)) // 顯示 "第一天" 到 "第七天" 的文本
                                    Spacer()
                                    Button(action: {
                                        plans[day]?.append("新計畫")
                                    }) {
                                        Image(systemName: "plus.circle")
                                            .imageScale(.large)
                                            .foregroundColor(.blue)
                                    }
                                }
                            ) {
                                
                                if let dayPlans = plans[day] {
                                    ForEach(dayPlans.indices, id: \.self) { index in
                                        let plan = dayPlans[index]
                                        let isEditable = !isNewPlan(plan) // 檢查是否是新計畫

                                        NavigationLink(destination: isEditable ? EditPlanView(day: day, planIndex: index, plans: $plans) : nil) {
                                            Text(plan)
                                                .font(.headline)
                                        }
                                        .disabled(!isEditable) // 禁用點擊進入功能

                                    }
                                    
                                    .onDelete { indices in
                                        guard let deletedPlanName = plans[day]?[indices.first ?? 0] else {
                                            print("Error: Deleted plan name not found")
                                            return
                                        }
                                        guard let deletedPlanID = nameToIDMap[deletedPlanName] else {
                                            print("Error: Deleted plan ID not found for name \(deletedPlanName)")
                                            return
                                        }
                                        showingAlert = true
                                           // 設置警示框的內容
                                        alertMessage = "確定要刪除 \(plans[day]?[indices.first ?? 0] ?? "") 嗎？"
                                       
                                        // 直接執行刪除計畫
                                        deletePlan(withID: deletedPlanID, day: day, at: indices) { result in
                                            switch result {
                                            case .success:
                                                print("成功刪除計畫:", deletedPlanID)
                                                DispatchQueue.main.async {
                                                    if var dayPlans = self.plans[day] {
                                                        dayPlans.remove(atOffsets: indices)
                                                        self.plans[day] = dayPlans
                                                    }
                                                    
                                                  
                                                }
                                            case .failure(let error):
                                                print("Failed with error:", error)
                                                if let planDeleteError = error as? PlanDeleteError {
                                                    print("計劃刪除錯誤訊息:", planDeleteError.message)
                                                }
                                            }
                                        }
                                    }
                                    

                                }
                                  
                              
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .onAppear {
                updatePlans() // 在視圖顯示時獲取計畫
            }
            
        }
        
        func deleteSelectedPlan(day: String, indices: IndexSet) {
            guard let deletedPlanName = plans[day]?[indices.first ?? 0] else {
                print("Error: Deleted plan name not found")
                return
            }
            guard let deletedPlanID = nameToIDMap[deletedPlanName] else {
                print("Error: Deleted plan ID not found for name \(deletedPlanName)")
                return
            }
            
            deletePlan(withID: deletedPlanID, day: day, at: indices) { result in
                switch result {
                case .success:
                    print("成功刪除計畫:", deletedPlanID)
                    DispatchQueue.main.async {
                        if var dayPlans = self.plans[day] {
                            dayPlans.remove(atOffsets: indices)
                            self.plans[day] = dayPlans
                        }
                    }
                case .failure(let error):
                    print("Failed with error:", error)
                    if let planDeleteError = error as? PlanDeleteError {
                        print("計劃刪除錯誤訊息:", planDeleteError.message)
                    }
                }
            }
        }


        // MARK: 根據日期獲取 "第一天" 到 "第七天" 的文本
        private func getDayLabelText(for date: String) -> String {
            guard let index = Array(plans.keys.sorted(by: <)).firstIndex(of: date) else {
                return ""
            }
            let dayNumber = (index % 7) + 1
            return "第\(dayNumber)天"
        }
    }




    struct PlanView_Previews: PreviewProvider
    {
        static var previews: some View
        {
            PlanView()
        }
    }

func fetchPlansFromServer(completion: @escaping ([Plan]?, Error?) -> Void) {
     guard let url = URL(string: "http://163.17.9.107/food/Plan.php") else {
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
             let plans = try decoder.decode([Plan].self, from: jsonData)
             completion(plans, nil)
         } catch {
             print("Error decoding JSON: \(error)")
             completion(nil, error)
         }
     }.resume()
 }
