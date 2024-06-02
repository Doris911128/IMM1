import SwiftUI
import Foundation

// 定義從服務器獲取的計劃數據結構
struct PlanData: Codable {
    let P_ID: String
    // 根據需要添加其他屬性
}

// Define a function to fetch food data from a specified URL
func fetchFoodData(from url: URL, completion: @escaping ([Dishes]?, Error?) -> Void) {
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
            let foodData = try decoder.decode([Dishes].self, from: data)
            completion(foodData, nil)
        } catch {
            completion(nil, error)
        }
    }.resume()
}

// Define the EditPlanView SwiftUI view
struct EditPlanView: View {
    
    var day: String
    var planIndex: Int
    
    @State private var dishesData: [Dishes] = []
    @State private var show1: [Bool] = [false, false, false, false, false, false, false]
    @State private var searchText: String = ""
    @State private var editedPlan = ""
    @State private var isShowingDetail = false
    @State private var foodDataFromServer: [Dishes] = []
    @State private var foodOptions: [Dishes] = []
    @Binding var plans: [String: [String]]
    @State private var isNewPlan = true
    @State private var planID: String = ""
    @State private var showAlert = false
    @State private var selectedFoodData: Dishes?
    @State private var currentCategoryIndex: Int? = nil
    @State private var isSaveAlertShowing = false
    @State private var isSearchingByIngredient = false
    
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
        if let url = URL(string: "http://163.17.9.107/food/Dishes.php") {
            fetchFoodData(from: url) { foodData, error in
                if let error = error {
                    print("Error occurred: \(error)")
                } else if let dishes = foodData {
                    print("Fetched food data: \(dishes)")
                    self.foodDataFromServer = dishes
                    self.foodOptions = dishes
                    self.foodOptions1 = Array(dishes[0...4])
                    self.foodOptions2 = [dishes[2]]
                    self.foodOptions3 = dishes.filter { ["7", "9", "11"].contains(String($0.Dis_ID)) }
                    self.foodOptions4 = dishes
                    self.foodOptions5 = dishes
                    self.foodOptions6 = dishes
                }
            }
        } else {
            print("Invalid URL")
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
     
    // MARK: 今日推薦選項
    @State private var foodOptions6: [Dishes] = []
     
    @State private var isShowingDetail7 = false
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
    private var fateButton: some View {
        CustomButton(imageName: "聽天由命", buttonText: "聽天由命") {
            isShowingDetail7.toggle()
        }
        .sheet(isPresented: $isShowingDetail7) {
            VStack {
                Spacer()
                SpinnerView()
                    .background(Color.white)
                    .cornerRadius(10)
            }
            .edgesIgnoringSafeArea(.all)
        }
    }

    // 定義一個從指定 URL 獲取計劃數據的函數
    func fetchPlanData(from url: URL, completion: @escaping (PlanData?, Error?) -> Void) {
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

    func fetchPlanData() {
        if let url = URL(string: "http://163.17.9.107/food/Plan.php") {
            fetchPlanData(from: url) { planData, error in
                if let error = error {
                    print("在獲取計劃數據時發生錯誤：\(error)")
                } else if let planData = planData {
                    print("獲取的計劃數據：\(planData)")
                }
            }
        } else {
            print("無效的 URL")
        }
    }

    @ViewBuilder
    private func TempView(imageName: String, buttonText: String, isShowingDetail: Binding<Bool>, foodOptions: [Dishes], categoryIndex: Int) -> some View {
        
        CustomButton(imageName: imageName, buttonText: buttonText) {
            currentCategoryIndex = categoryIndex
            isShowingDetail.wrappedValue.toggle()
            
        }
        .sheet(isPresented: isShowingDetail) {
                    FoodSelectionView(isShowingDetail: isShowingDetail, editedPlan: $editedPlan, foodOptions: .constant(foodOptions.map { foodData in
                        
                        FoodOption(name: foodData.Dis_Name, backgroundImage: URL(string: foodData.D_image)!)
                    }))
            .onDisappear {
                if let selectedFood = findSelectedFoodData(for: editedPlan) {
                    self.selectedFoodData = selectedFood
                    self.showAlert = true
                }
            }
        }
    }
//幫我寫一下搜尋功能，在EditPlanView中進行搜尋食物，並利用FoodSelectionView顯示搜尋結果
    func updatePlanOnServer(pID: String?, disID: String) {
        guard let url = URL(string: "http://163.17.9.107/food/Planupdate.php") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // 構造 POST 數據
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

            // 解析響應
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
                if responseString.contains("成功") {
                    self.isNewPlan = false
                }
            }
        }.resume()
    }

    func savePlanToServer(P_ID: String, U_ID: String, Dis_ID: String, P_DT: String, P_Bought: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/Plan.php") else {
            completion(false, "無效的 URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let postData = "P_ID=\(P_ID)&U_ID=\(U_ID)&Dis_ID=\(Dis_ID)&P_DT=\(P_DT)&P_Bought=\(P_Bought)"
        request.httpBody = postData.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "錯誤: \(error.localizedDescription)")
                return
            }

            // 解析響應
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                if responseString.contains("計劃已成功保存到數據庫") {
                    completion(true, nil)
                } else {
                    completion(false, responseString)
                }
            } else {
                completion(false, "未從服務器收到數據")
            }
        }.resume()
    }

    struct CustomToggle: View {
           @Binding var isOn: Bool
           
           var body: some View {
               Button(action: {
                   self.isOn.toggle()
               }) {
                   VStack {
                       Image(systemName: isOn ? "checkmark.square.fill" : "square")
                           .resizable()
                           .frame(width: 20, height: 20)
                       Text(isOn ? "以食材搜索" : "以菜名搜索")
                           .font(.footnote)
                   }
                   .foregroundColor(isOn ? .orange : .gray)
               }
           }
       }

    func performSearch() {
            if isSearchingByIngredient {
                // 根據食材進行搜索
                let searchTextLowercased = searchText.lowercased()
                searchResults = foodDataFromServer
                    .filter { dish in
                        dish.foods?.contains { $0.F_Name.lowercased().contains(searchTextLowercased) } ?? false
                    }
                    .map { $0.toFoodOption() }
                isShowingDetail = true
            } else {
                // 根據食物名稱進行搜索
                let searchTextLowercased = searchText.lowercased()
                searchResults = foodDataFromServer
                    .filter { $0.Dis_Name.lowercased().contains(searchTextLowercased) }
                    .map { $0.toFoodOption() }
                isShowingDetail = true
            }
        }
    
    var body: some View {
        VStack {
        }

        NavigationView {
            ScrollView {
                VStack(spacing:5) {
                    HStack(spacing:-20) {
                        TextField("搜尋食譜.....", text: $searchText, onCommit: {
                                                    // 執行搜尋操作
                                                    performSearch()
                                                })
                                                .padding()
                                                .textFieldStyle(RoundedBorderTextFieldStyle())

                                                Button(action: {
                                                    // 執行搜尋操作
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
       
                  
                    // 在分類列表中使用 TempView 並傳遞分類索引
                    let name=["懶人","減肥","省錢","放縱","養生","今日推薦","聽天由命"]
                    let show2=[foodOptions1,foodOptions2,foodOptions3,foodOptions4,foodOptions5,foodOptions6]
                    VStack(spacing: 30) {
                        ForEach(name.indices, id: \.self) { index in
                            if index == 6 {
                                fateButton
                            } else {
                                self.TempView(
                                    imageName: name[index],
                                    buttonText: name[index],
                                    isShowingDetail: $show1[index],
                                    foodOptions: show2[index],
                                    categoryIndex: index
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("保存計劃"),
                message: Text("是否保存當前選擇的菜品？"),
                primaryButton: .default(Text("保存")) {
                    presentationMode.wrappedValue.dismiss()
                    if let selectedFood = selectedFoodData {
                        updatePlanOnServer(pID: "nJqERSSPjn", disID: String(selectedFood.Dis_ID))
                        savePlanToServer(P_ID: "", U_ID: "", Dis_ID: String(selectedFood.Dis_ID), P_DT: day, P_Bought: "") { success, errorMessage in
                            if success {
                                print("計劃成功保存到伺服器")
                            } else {
                                print("保存計劃的結果：\(errorMessage ?? "出問題")")
                            }
                        }
                    }
                },
                secondaryButton: .cancel(Text("取消")) {
  
                }
            )
        }
        .sheet(isPresented: $isShowingDetail) {
            FoodSelectionView(isShowingDetail: $isShowingDetail, editedPlan: $editedPlan, foodOptions: $searchResults)
                .onDisappear {
                    if let selectedFood = findSelectedFoodData(for: editedPlan) {
                        // 選擇了食物，準備顯示警示框
                        self.selectedFoodData = selectedFood
                        self.showAlert = true
                    } else {
                        // 沒有選擇食物，不顯示警示框
                        self.showAlert = false
                    }
                }
        }
    

               
    }
}
