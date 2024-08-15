// EditPlanView

import SwiftUI
import Foundation

// 定義從服務器獲取的計劃數據結構
struct PlanData: Codable
{
    let P_ID: String
}

// 定義一個從指定 URL 獲取計劃數據的函數
func fetchPlanData(from url: URL, completion: @escaping (PlanData?, Error?) -> Void)
{
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let data = data else {
            completion(nil, NSError(domain: "com.example", code: 0, userInfo: [NSLocalizedDescriptionKey: "未收到數據"]))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let planData = try decoder.decode(PlanData.self, from: data)
            completion(planData, nil)
        } catch {
            completion(nil, error)
        }
    }.resume()
}

func fetchFoodData(from url: URL, completion: @escaping ([Dishes]?, Error?) -> Void)
{
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let data = data else {
            completion(nil, NSError(domain: "com.example", code: 0, userInfo: [NSLocalizedDescriptionKey: "未收到數據"]))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let dishesData = try decoder.decode([Dishes].self, from: data)
            completion(dishesData, nil)
        } catch {
            completion(nil, error)
        }
    }.resume()
}

struct EditPlanView: View
{
    var day: String
    var planIndex: Int
    
    @State private var dishesData: [Dishes] = []
    @State private var show1: [Bool] = [false, false, false, false, false, false, false, false, false, false]
    @State private var searchText: String = ""
    @State private var editedPlan = ""
    @State private var isShowingDetail = false
    @State private var foodDataFromServer: [Dishes] = []
    @State private var foodOptions: [Dishes] = []
    @Binding var plans: [String: [Plan]]
    @State private var isNewPlan = true
    @State private var planID: String = ""
    @State private var showAlert = false
    @State private var selectedFoodData: Dishes?
    @State private var currentCategoryIndex: Int? = nil
    @State private var isSaveAlertShowing = false
    @State private var isSearchingByIngredient = false
    
    @State private var isLoading: Bool = false
    @State private var isEmpty: Bool = false
    
    @State private var searchResults: [FoodOption] = []
    @Environment(\.presentationMode) var presentationMode
    
    // 選擇食物的函數
    func selectFood(food: Dishes) {
        selectedFoodData = food
        showAlert = true
        if let categoryIndex = currentCategoryIndex {
            show1[categoryIndex] = false // 隱藏分類介面
        }
    }
    
    // Function to fetch food options from the server
    func fetchFoodOptions() {
        if let url = URL(string: "http://163.17.9.107/food/php/Dishes.php") {
            fetchFoodData(from: url) { foodData, error in
                if let error = error {
                    print("Error occurred: \(error)")
                } else if let dishes = foodData {
                    print("Fetched food data: \(dishes)")
                    self.foodDataFromServer = dishes
                    self.foodOptions = dishes
                    self.foodOptions1 = dishes.filter { ["1", "2", "3", "5", "8", "9", "10", "11", "12", "13", "15", "21", "22", "24", "27", "28"].contains(String($0.Dis_ID)) }
                    self.foodOptions2 = dishes.filter { ["2","3", "12","13", "22", "24", "28"].contains(String($0.Dis_ID)) }
                    self.foodOptions3 = dishes.filter { ["1", "2", "3", "9", "10", "11", "13", "15", "17", "22", "23", "24", "26", "28"].contains(String($0.Dis_ID)) }
                    self.foodOptions4 = dishes.filter { ["4", "6", "7" ,"14", "16", "18", "19", "20", "23", "25"].contains(String($0.Dis_ID)) }
                    self.foodOptions5 = dishes.filter { ["1", "2", "3", "17", "19", "22", "26","28"].contains(String($0.Dis_ID)) }
                    self.foodOptions6 = dishes
                    self.foodOptions7 = dishes
                    self.foodOptions8 = dishes
                    self.foodOptions9 = dishes
                    self.foodOptions10 = dishes
                    // 单独获取用户收藏
                    fetchUserFavorites()
                }
            }
        } else {
            print("Invalid URL")
        }
    }
    
    // MARK: 導入最愛食譜
    func fetchUserFavorites()
    {
        isLoading = true
        isEmpty = false
        if let url = URL(string: "http://163.17.9.107/food/php/UserFavorites.php")
        {
            fetchFoodData(from: url) { foodData, error in
                isLoading = false
                if let error = error
                {
                    print("Error fetching favorites: \(error)")
                    self.isEmpty = true // 出错时也应该显示空状态
                } else if let favorites = foodData
                {
                    if favorites.isEmpty
                    {
                        print("No favorite dishes found for the user.")
                        self.foodOptions7 = favorites
                        self.isEmpty = favorites.isEmpty // 如果数据为空，设置 isEmpty = true
                    }
                    print("Fetched favorite dishes: \(favorites)")
                    self.foodOptions7 = favorites
                }
            }
        } else
        {
            print("Invalid URL for favorites")
            isLoading = false
            isEmpty = true
        }
    }
    
    // MARK: 「未作」導入公開食譜
    func fetchPublicRecipes() {
        isLoading = true
        isEmpty = false
        
        if let url = URL(string: "http://163.17.9.107/food/php/PublicRecipes.php") {
            fetchFoodData(from: url) { foodData, error in
                isLoading = false
                if let error = error {
                    print("Error fetching public recipes: \(error)")
                    self.foodOptions9 = []
                    isEmpty = true
                } else if let publicRecipes = foodData {
                    self.foodOptions9 = publicRecipes
                    isEmpty = publicRecipes.isEmpty
                }
            }
        } else {
            print("Invalid URL for public recipes")
            isLoading = false
            isEmpty = true
        }
    }
    
    // MARK: 懶人選項
    @State private var foodOptions1: [Dishes] = []
    
    // MARK: 減肥選項
    @State private var foodOptions2: [Dishes] = []
    
    // MARK: 省錢選項
    @State private var foodOptions3: [Dishes] = []
    
    // MARK: 放縱選項
    @State private var foodOptions4: [Dishes] = []
    
    // MARK: 養生選項
    @State private var foodOptions5: [Dishes] = []
    
    // MARK: 清庫存選項
    @State private var foodOptions6: [Dishes] = []
    
    // MARK: 我的最愛選項
    @State private var foodOptions7: [Dishes] = []
    
    // MARK: 適合我選項
    @State private var foodOptions8: [Dishes] = []
    
    // MARK: 公開食譜選項
    @State private var foodOptions9: [Dishes] = []
    
    // MARK: AI食譜選項
    @State private var foodOptions10: [Dishes] = []
    
    //@State private var isShowingDetail7 = false
    
    func findSelectedFoodData(for name: String) -> Dishes? {
        // 根據食物名稱在從服務器獲取的數據中找到對應的食物資料
        for food in foodDataFromServer {
            if food.Dis_Name == name {
                return food
            }
        }
        return nil
    }
    
    // MARK: 聽天由命選項的View
    //    private var fateButton: some View {
    //        CustomButton(imageName: "聽天由命", buttonText: "聽天由命") {
    //            isShowingDetail7.toggle()
    //        }
    //        .sheet(isPresented: $isShowingDetail7) {
    //            VStack {
    //                Spacer()
    //                SpinnerView()
    //                    .background(Color.white)
    //                    .cornerRadius(10)
    //            }
    //            .edgesIgnoringSafeArea(.all)
    //        }
    //    }
    
    @ViewBuilder
    private func TempView(imageName: String, buttonText: String, contentText: String , isShowingDetail: Binding<Bool>, foodOptions: [Dishes], categoryIndex: Int, categoryTitle: String) -> some View
    {
        CustomButton(imageName: imageName, buttonText: buttonText ,contentText: contentText)
        {
            currentCategoryIndex = categoryIndex
            isShowingDetail.wrappedValue.toggle()
        }
        .cornerRadius(10)
        .sheet(isPresented: isShowingDetail)
        //        {
        //            FoodSelectionView(isShowingDetail: isShowingDetail, editedPlan: $editedPlan, foodOptions: .constant(foodOptions.map { foodData in
        //                FoodOption(name: foodData.Dis_Name, backgroundImage: URL(string: foodData.D_image ?? "defaultImageURL") ?? URL(string: "defaultImageURL")!, serving: foodData.Dis_serving ?? "")
        //            }), categoryTitle: categoryTitle)
        //            .onDisappear {
        //                if let selectedFood = findSelectedFoodData(for: editedPlan) {
        //                    self.selectedFoodData = selectedFood
        //                    self.showAlert = true
        //                }
        //            }
        //        }
        {
            if categoryIndex == 0 && foodOptions7.isEmpty
            {
                EmptyStateView(imageName: "分類未新增最愛", message: "尚未收藏最愛食譜喔～快去添加吧！")
            } else if isLoading
            {
                LoadingView()
            } else
            {
                FoodSelectionView(
                    isShowingDetail: isShowingDetail,
                    editedPlan: $editedPlan,
                    foodOptions: .constant(foodOptions.map { foodData in
                        FoodOption(name: foodData.Dis_Name, backgroundImage: URL(string: foodData.D_image ?? "defaultImageURL") ?? URL(string: "defaultImageURL")!, serving: foodData.Dis_serving ?? "")
                    }),
                    categoryTitle: categoryTitle
                )
                .onDisappear {
                    if let selectedFood = findSelectedFoodData(for: editedPlan) {
                        self.selectedFoodData = selectedFood
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    
    func updatePlanOnServer(pID: String?, disID: Int) {
        guard let url = URL(string: "http://163.17.9.107/food/php/Planupdate.php") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var postData = "Dis_ID=\(disID)"
        if let pID = pID {
            postData += "&P_ID=\(pID)"
        } else {
            print("pID is nil, skipping update operation")
            return
        }
        
        request.httpBody = postData.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) 
            {
                print("Response: \(responseString)")
                if responseString.contains("成功") 
                {
                    self.isNewPlan = false
                }
            }
        }.resume()
    }
    
    func savePlanToServer(P_ID: String, U_ID: String, Dis_ID: Int, P_DT: String, P_Bought: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/php/Plan.php") 
        else
        {
            completion(false, "無效的 URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let postData = "P_ID=\(P_ID)&U_ID=\(U_ID)&Dis_ID=\(Dis_ID)&P_DT=\(P_DT)&P_Bought=\(P_Bought)"
        request.httpBody = postData.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request)
        { data, response, error in
            if let error = error
            {
                completion(false, "錯誤: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) 
            {
                if responseString.contains("計劃已成功保存到數據庫")
                {
                    completion(true, nil)
                } else 
                {
                    completion(false, responseString)
                }
            } else 
            {
                completion(false, "未從服務器收到數據")
            }
        }.resume()
    }
    
    func Plan_PR(P_ID: String, U_ID: String, Dis_ID: Int, P_DT: String, P_Bought: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/php/Plan_PR.php")
        else
        {
            completion(false, "無效的 URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let postData = "P_ID=\(P_ID)&U_ID=\(U_ID)&Dis_ID=\(Dis_ID)&P_DT=\(P_DT)&P_Bought=\(P_Bought)"
        request.httpBody = postData.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) 
        { data, response, error in
            if let error = error
            {
                completion(false, "錯誤: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) 
            {
                if responseString.contains("計劃已成功保存到數據庫")
                {
                    completion(true, nil)
                } else {
                    completion(false, responseString)
                }
            } else {
                completion(false, "未從服務器收到數據")
            }
        }.resume()
    }
    
    func performSearch()
    {
        if isSearchingByIngredient {
            let searchTextLowercased = searchText.lowercased()
            searchResults = foodDataFromServer
                .filter { dish in
                    dish.foods?.contains {
                        $0.F_Name.lowercased().contains(searchTextLowercased)
                    } ?? false
                }
                .map { $0.toFoodOption() }
            isShowingDetail = true
        } else {
            let searchTextLowercased = searchText.lowercased()
            searchResults = foodDataFromServer
                .filter { $0.Dis_Name.lowercased().contains(searchTextLowercased) }
                .map { $0.toFoodOption() }
            isShowingDetail = true
        }
    }
    
    var body: some View
    {
        NavigationView {
            ScrollView {
                VStack(spacing: 5) {
                    HStack(spacing: -20) {
                        TextField("搜尋食譜.....", text: $searchText, onCommit: {
                            performSearch()
                        })
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            performSearch()
                        }) {
                            Image(systemName: "magnifyingglass")
                                .padding()
                        }
                        CustomToggle(isOn: $isSearchingByIngredient)
                            .padding()
                    }
                    .padding(.top, 10)
                    .onAppear {
                        fetchFoodOptions()
                    }
                    let names = ["我的最愛","健康推薦" ,"懶人分類", "減肥分類", "省錢分類", "放縱分類", "素食分類", "庫存菜單", "公開食譜","AI食譜"]
                    
                    let contentText = ["美食珍藏庫，專屬小天地","數據分析師，量身訂製法","便捷又快速，食材易準備","低卡且低脂，健康拿滿分","用料超便宜，荷包省省省","高熱量美食，滿滿罪惡感","吃素不單調，色香味俱全","食材訂料理，菜色便整理","食譜大推薦，宜相互分享","創意無窮盡，樂趣多更多"]
                    
                    let showOptions = [foodOptions7,foodOptions8, foodOptions1, foodOptions2, foodOptions3, foodOptions4, foodOptions5, foodOptions6,foodOptions9,foodOptions10]
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20)
                    {
                        ForEach(names.indices, id: \.self) { index in
                            
                            self.TempView(
                                imageName: names[index],
                                buttonText: names[index],
                                contentText: contentText[index],
                                isShowingDetail: $show1[index],
                                foodOptions: showOptions[index],
                                categoryIndex: index,
                                categoryTitle: names[index]
                            )
                            
                        }
                    }
                    .padding()
                }
            }
        }
        .alert(isPresented: $showAlert) 
        {
            Alert(
                title: Text("保存計劃"),
                message: Text("是否保存當前選擇的菜品：\(selectedFoodData?.Dis_Name ?? "")"),
                primaryButton: .default(Text("保存")) 
                {
                    presentationMode.wrappedValue.dismiss()
                    if let selectedFood = selectedFoodData 
                    {
                        updatePlanOnServer(pID: plans[day]?[planIndex].P_ID, disID: selectedFood.Dis_ID)
                        savePlanToServer(P_ID: plans[day]?[planIndex].P_ID ?? "", U_ID: "", Dis_ID: selectedFood.Dis_ID, P_DT: day, P_Bought: "") 
                        { success, errorMessage in
                            if success 
                            {
                                print("計劃成功保存到伺服器")
                            } else 
                            {
                                print("保存計劃的結果：\(errorMessage ?? "出問題")")
                            }
                        }
                        Plan_PR(P_ID: plans[day]?[planIndex].P_ID ?? "", U_ID: "", Dis_ID: selectedFood.Dis_ID, P_DT: day, P_Bought: "") 
                        { success, errorMessage in
                            if success
                            {
                                print("計劃成功保存到伺服器")
                            } else {
                                print("保存計劃的結果：\(errorMessage ?? "出問題")")
                            }
                        }
                    }
                },
                secondaryButton: .cancel(Text("取消")) {}
            )
        }
        .sheet(isPresented: $isShowingDetail) 
        {
            FoodSelectionView(isShowingDetail: $isShowingDetail, editedPlan: $editedPlan, foodOptions: $searchResults, categoryTitle: "搜尋結果")
                .onDisappear 
            {
                    if let selectedFood = findSelectedFoodData(for: editedPlan)
                    {
                        self.selectedFoodData = selectedFood
                        self.showAlert = true
                    } else {
                        self.showAlert = false
                    }
                }
        }
    }
}

// 分類內加載狀態畫面
struct EmptyStateView: View
{
    var imageName: String
    var message: String
    
    var body: some View
    {
        VStack
        {
            Spacer().frame(height: 10)
            VStack
            {
                Image(imageName) // 使用自定义图片
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .onAppear {
                        print("Attempting to load image: \(imageName)")
                    }
            }
            VStack
            {
                Text(message)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CustomToggle: View 
{
    @Binding var isOn: Bool
    
    var body: some View 
    {
        Button(action: {
            self.isOn.toggle()
        }) 
        {
            VStack 
            {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(isOn ? "以食材搜尋" : "以菜名搜尋")
                    .font(.footnote)
            }
            .foregroundColor(isOn ? .orange : .gray)
        }
    }
}
