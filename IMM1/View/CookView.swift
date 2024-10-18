// CookView

import SwiftUI

// MARK: [class] CookViewModel
class CookViewModel: ObservableObject
{
    @Published var plans: [CookPlan] = []
    
    func fetchCookPlans()
    {
        fetchCookPlansFromServer { [weak self] fetchedPlans, error in
            if let fetchedPlans = fetchedPlans
            {
                DispatchQueue.main.async
                {
                    self?.plans = fetchedPlans
                }
            } else if let error = error
            {
                print("Failed to fetch plans: \(error)")
            }
        }
    }
}

// MARK: [func] fetchCookPlansFromServer
func fetchCookPlansFromServer(completion: @escaping ([CookPlan]?, Error?) -> Void)
{
    guard let url = URL(string: "http://163.17.9.107/food/php/Cook.php")
    else
    {
        completion(nil, NSError(domain: "InvalidURL", code: 0, userInfo: nil))
        return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error
        {
            completion(nil, error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
        else
        {
            completion(nil, NSError(domain: "HTTPError", code: 0, userInfo: nil))
            return
        }
        
        guard let data = data
        else
        {
            completion(nil, NSError(domain: "NoDataError", code: 0, userInfo: nil))
            return
        }
        
        do
        {
            if let jsonString = String(data: data, encoding: .utf8)
            {
                print("Fetched JSON: \(jsonString)")
            }
            
            let plans = try JSONDecoder().decode([CookPlan].self, from: data)
            completion(plans, nil)
        } catch
        {
            completion(nil, error)
        }
    }.resume()
}

// MARK: [struct] Cook
struct Cook: Codable, Identifiable
{
    let id = UUID()
    let P_ID: String
    let U_ID: String
    let Dis_ID: Int
    let P_DT: String
    let P_Bought: String
    let Dis_name: String
    
    enum CodingKeys: String, CodingKey
    {
        case P_ID
        case U_ID
        case Dis_ID
        case P_DT
        case P_Bought
        case Dis_name
    }
}

// MARK: [struct] CookPlanook
struct CookPlan: Codable, Identifiable
{
    let id = UUID()
    let P_ID: String
    let U_ID: String
    let Dis_ID: Int
    let P_DT: String
    let P_Bought: String
    let Dis_name: String
    let D_image: String
    var favorites: [Favorite]? // 添加收藏状态
    
    enum CodingKeys: String, CodingKey
    {
        case P_ID
        case U_ID
        case Dis_ID
        case P_DT
        case P_Bought
        case Dis_name
        case D_image
        case favorites // 添加CodingKey
    }
}

// MARK: CookView
struct CookView: View
{
    @StateObject private var viewModel = CookViewModel()
    
    @State private var plans: [CookPlan] = []
    @State private var favorites: [Favorite] = []
    @State private var isEditing = false
    let U_ID: String // 用於添加我的最愛
    
    // MARK: CookView body
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                // 添加標題1和標題2
                VStack
                {
                    Text("烹飪")
                        .font(.title)
                    Text("今日您計劃烹飪的食譜")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                //                // 根據計劃是否存在來決定是否顯示日期
                //                if !viewModel.plans.isEmpty
                //                {
                //                    HStack
                //                    {
                //                        ForEach(computeDays(), id: \.self) { day in
                //                            Text(day.dateString)
                //                                .font(.system(size: 20, weight: .bold))
                //                                .frame(maxWidth: .infinity, alignment: .center)
                //                        }
                //                    }
                //                    .frame(height: 50) // 固定日期部分高度
                //                }
                
                // 其他內容
                ScrollViewReader
                { scrollView in
                    if viewModel.plans.isEmpty
                    {
                        // 沒有計劃時顯示的靜態視圖
                        VStack {
                            Spacer().frame(height: 200) // 調整此高度以控制頂部間距
                            
                            VStack {
                                Image("烹飪")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 180) // 調整圖片大小
                            }
                            VStack {
                                Text("尚無烹飪計畫")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                            Spacer() // 自動將內容推到中心位置
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 確保內容在頂部對齊
                    } else
                    {
                        // 有計劃時顯示的滾動視圖
                        ScrollView(.horizontal)
                        {
                            LazyHStack(spacing: 20)
                            {
                                ForEach(computeDays(), id: \.self)
                                { day in
                                    let dateString = day.dateString
                                    
                                    VStack(alignment: .leading, spacing: 10)
                                    {
                                        let dayPlans = viewModel.plans.filter { $0.P_DT == dateString }
                                        //                                        if dayPlans.isEmpty {
                                        //                                            VStack {
                                        //                                                Spacer().frame(height: 200) // 調整此高度以控制頂部間距
                                        //
                                        //                                                VStack {
                                        //                                                    Image("烹飪")
                                        //                                                        .resizable()
                                        //                                                        .scaledToFit()
                                        //                                                        .frame(width: 180, height: 175) // 調整圖片大小
                                        //                                                }
                                        //                                                VStack {
                                        //                                                    Text("尚無計劃")
                                        //                                                        .font(.body)
                                        //                                                        .foregroundColor(.gray)
                                        //                                                }
                                        //                                                Spacer() // 自動將內容推到中心位置
                                        //                                            }
                                        //                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 確保內容在頂部對齊
                                        // } else {
                                        
                                        LazyHStack(spacing: 10)
                                        {
                                            ForEach(dayPlans, id: \.P_ID) { plan in
                                                HStack
                                                {
                                                    NavigationLink(destination: MRecipeView(U_ID: plan.U_ID, Dis_ID: plan.Dis_ID))
                                                    {
                                                        C_RecipeBlock(imageName: plan.D_image, title: plan.Dis_name, U_ID: plan.U_ID, Dis_ID: plan.Dis_ID, isFavorited: plan.favorites?.contains(where: { $0.U_ID == U_ID }) ?? false)
                                                            .padding(.top, 50)
                                                    }
                                                    
                                                    if isEditing
                                                    {
                                                        Button(action: {
                                                            if let index = viewModel.plans.firstIndex(where: { $0.P_ID == plan.P_ID })
                                                            {
                                                                viewModel.plans.remove(at: index)
                                                            }
                                                        })
                                                        {
                                                            Image(systemName: "minus.circle")
                                                                .foregroundColor(.red)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        // }//
                                    }
                                    .id(dateString)
                                    //.frame(minHeight: 500) // 設定最小高度，確保日期部分在沒有計畫時也在正確位置
                                }
                            }
                            .padding(.horizontal)
                        }
                        .scrollIndicators(.hidden)
                        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
                    }
                }
                .onAppear
                {
                    viewModel.fetchCookPlans()
                }
            }
        }
    }
    func computeDays() -> [Day]
    {
        var days: [Day] = []
        if let targetDate = Calendar.current.date(byAdding: .day, value: 0, to: Date())
        {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: targetDate)
            
            let day = Day(dateString: dateString, dayIndex: 0)
            days.append(day)
        }
        return days
    }
    
    struct Day: Hashable
    {
        let dateString: String
        let dayIndex: Int
    }
}


// MARK: C_RecipeBlock
struct C_RecipeBlock: View
{
    let D_image: String
    let Dis_Name: String
    let U_ID: String // 用於添加我的最愛
    let Dis_ID: Int // 用於添加我的最愛
    @State private var isFavorited: Bool
    
    init(imageName: String, title: String, U_ID: String, Dis_ID: Int = 0, isFavorited: Bool = false)
    {
        self.D_image = imageName
        self.Dis_Name = title
        self.U_ID = U_ID
        self.Dis_ID = Dis_ID
        self._isFavorited = State(initialValue: isFavorited)
    }
    
    // MARK: C_RecipeBlock body
    var body: some View
    {
        VStack
        {
            ZStack(alignment: .topTrailing)
            {
                AsyncImage(url: URL(string: D_image))
                { phase in
                    switch phase
                    {
                    case .empty:
                        Color.gray
                            .frame(width: 330, height: 450)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 330, height: 450)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure:
                        Color.red
                            .frame(width: 330, height: 450)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    @unknown default:
                        Color.blue
                            .frame(width: 330, height: 450)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                
                Button(action:{
                    withAnimation(.easeInOut.speed(3))
                    {
                        self.isFavorited.toggle()
                        toggleFavorite(U_ID: U_ID, Dis_ID: Dis_ID, isFavorited: isFavorited)
                        { result in
                            switch result
                            {
                            case .success(let responseString):
                                print("Success: \(responseString)")
                            case .failure(let error):
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    }
                }) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: self.isFavorited ? "heart.fill" : "heart")
                                .font(.title)
                                .foregroundColor(.red)
                        )
                }
                .offset(x: -15, y: 15) // 調整按鈕位置
                .symbolEffect(.bounce, value: self.isFavorited)
            }
            
            HStack(alignment: .bottom)
            {
                Text(Dis_Name)
                    .foregroundColor(.black)
                    .font(.system(size: 24))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 10)
                    .padding(.top,10)
            }
            .offset(y: -5)
        }
        .padding(.horizontal, 20)
        .offset(y: -40)
        .onAppear
        {
            checkIfFavorited(U_ID: U_ID, Dis_ID: "\(Dis_ID)")
            { result in
                switch result
                {
                case .success(let favorited):
                    self.isFavorited = favorited
                case .failure(let error):
                    print("Error checking favorite status: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct CookView_Previews: PreviewProvider
{
    static var previews: some View
    {
        CookView(U_ID:"ofmyRwDdZy")
    }
}
