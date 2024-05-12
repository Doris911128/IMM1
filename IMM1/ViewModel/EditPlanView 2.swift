// EditPlanView.swift

    import SwiftUI
    import Foundation

    // Define the structure for food data obtained from the server
    struct FoodData: Codable {
        let Dis_ID: String
        let Dis_Name: String
        let D_image: String
        // Additional properties can be added if needed
        
        init(Dis_ID: String, Dis_Name: String, D_image: String,P_ID:String, category: String) {
            self.Dis_ID = Dis_ID
            self.Dis_Name = Dis_Name
            self.D_image = D_image
        }
    }
    // 定義從服務器獲取的計劃數據結構
    struct PlanData: Codable {
        let P_ID: String
        // 根據需要添加其他屬性
    }

    // 定義一個結構來表示帶有份量的食物
    struct FoodWithPortion {
        let foodData: FoodData
        var portionSize: Int
    }

    // Define a function to fetch food data from a specified URL
    func fetchFoodData(from url: URL, completion: @escaping ([FoodData]?, Error?) -> Void) {
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
                let foodData = try decoder.decode([FoodData].self, from: data)
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
        
        @State private var show1: [Bool] = [false, false, false, false, false, false, false]
        @State private var searchText: String = ""
        @State private var editedPlan = ""
        @State private var isShowingDetail = false
        @State private var foodDataFromServer: [FoodData] = []
        @State private var foodOptions: [FoodData] = []
        @Binding var plans: [String: [String]]
        @State private var isNewPlan = true
        @State private var planID: String = ""
        @State private var foodWithPortions: [FoodWithPortion] = []
        // 將 foodWithPortions 初始化為包含默認份量的 FoodWithPortion 對象
        func initializeFoodWithPortions() {
            foodWithPortions = foodDataFromServer.map { foodData in
                FoodWithPortion(foodData: foodData, portionSize: 1) // 假設默認份量為 1
            }
        }
        private func foodItemRow(foodWithPortion: Binding<FoodWithPortion>) -> some View {
            let bindingPortionSize = Binding<Int>(
                get: { foodWithPortion.wrappedValue.portionSize },
                set: { newValue in
                    var newFoodWithPortion = foodWithPortion.wrappedValue
                    newFoodWithPortion.portionSize = newValue
                    foodWithPortion.wrappedValue = newFoodWithPortion
                }
            )
            
            return HStack {
                Text(foodWithPortion.wrappedValue.foodData.Dis_Name)
                Spacer()
                HStack {
                    TextField("份量", value: bindingPortionSize, formatter: NumberFormatter()) { isEditing in
                        // Handle editing status if needed
                    } onCommit: {
                        // Handle on commit action if needed
                    }
                    .padding(5)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .keyboardType(.numberPad)
                    
                    Stepper(value: bindingPortionSize, in: 1...10) {
                        Text("份")
                    }
                }
            }
        }



        @Environment(\.presentationMode) var presentationMode
        
        // Function to fetch food options from the server
        func fetchFoodOptions() {
            if let url = URL(string: "http://163.17.9.107/food/TestDishes2.php") {
                fetchFoodData(from: url) { foodData, error in
                    if let error = error {
                        print("Error occurred: \(error)")
                    } else if let foodData = foodData {
                        print("Fetched food data: \(foodData)")
                        self.foodDataFromServer = foodData
                        self.foodOptions = foodData
                        self.foodOptions1 = Array(foodData[0...4])
                        self.foodOptions2 = [foodData[2]]
                        self.foodOptions3 = foodData.filter { ["7", "9", "11"].contains($0.Dis_ID) }
                        self.foodOptions4 = foodData
                        self.foodOptions5 = foodData
                        self.foodOptions6 = foodData
                    }
                }
            } else {
                print("Invalid URL")
            }
        }

      

        
         // MARK: 懶人選項
         @State private var foodOptions1: [FoodData] = []

         // MARK: 減肥選項
         @State private var foodOptions2: [FoodData] = []
         
         // MARK: 省錢選項
         @State private var foodOptions3: [FoodData] = []
         
         // MARK: 放縱選項
         @State private var foodOptions4: [FoodData] = []
         
         // MARK: 養生選項
         @State private var foodOptions5: [FoodData] = []
         
         // MARK: 今日推薦選項
         @State private var foodOptions6: [FoodData] = []
         
         @State private var isShowingDetail7 = false
         func findSelectedFoodData(for name: String) -> FoodData? {
             
             // 根據食物名稱在從服務器獲取的數據中找到對應的食物資料
             // 注意：您需要根據自己的數據結構和邏輯來實現這個函式
             // 以下僅為示例
             for food in foodDataFromServer {
                 if food.Dis_Name == name {
                     return food
                 }
             }
             return nil
         }

         // MARK: 聽天由命選項的View
         private var fateButton: some View {
             CustomButton(imageName: "聽天由命", buttonText: "聽天由命")
             {
                 isShowingDetail7.toggle()
             }
             .sheet(isPresented: $isShowingDetail7)
             {
                 VStack {
                     Spacer()
                     SpinnerView()
                         .background(Color.white) // 可以設定 SpinnerView 的背景色
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

        // 在你的 EditPlanView 中，修改函數以獲取計劃數據
        func fetchPlanData() {
            if let url = URL(string: "http://163.17.9.107/food/Plan.php") {
                fetchPlanData(from: url) { planData, error in
                    if let error = error {
                        print("在獲取計劃數據時發生錯誤：\(error)")
                    } else if let planData = planData {
                        // 在這裡處理獲取的計劃數據
                        print("獲取的計劃數據：\(planData)")
                        // 根據需要將 P_ID 存儲在變量中，或者根據需要將其傳遞給其他函數
                    }
                }
            } else {
                print("無效的 URL")
            }
        }

        
         @ViewBuilder
         private func TempView(imageName: String, buttonText: String, isShowingDetail: Binding<Bool>, foodOptions: [FoodData]) -> some View {
             CustomButton(imageName: imageName, buttonText: buttonText) {
                 isShowingDetail.wrappedValue.toggle()
             }
             .sheet(isPresented: isShowingDetail) {
                 FoodSelectionView(isShowingDetail: $isShowingDetail, editedPlan: $editedPlan, foodOptions: foodOptions.map { foodData in
                     FoodOption(name: foodData.Dis_Name, backgroundImage: URL(string: foodData.D_image)!)
                 })
             }
         }
        // 在 updatePlanOnServer 函數中將 pID 參數改為可選型
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
                // 如果 pID 為 nil，直接返回，不執行後續操作
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
                    // 在此處處理服務器的響應

                    // 確保更新成功後才保存計劃到伺服器
                    if responseString.contains("成功") { // 假設服務器返回成功的訊息
                        self.isNewPlan = false

                    }
                }
            }.resume()
        }




        // 函數來將計劃保存到伺服器
        func savePlanToServer(P_ID: String, U_ID: String, Dis_ID: String, P_DT: String, P_Bought: String, completion: @escaping (Bool, String?) -> Void) {
            guard let url = URL(string: "http://163.17.9.107/food/Plan.php") else {
                completion(false, "無效的 URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            // 構造 POST 數據
            let postData = "P_ID=\(P_ID)&U_ID=\(U_ID)&Dis_ID=\(Dis_ID)&P_DT=\(P_DT)&P_Bought=\(P_Bought)"
            request.httpBody = postData.data(using: .utf8)

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(false, "錯誤: \(error.localizedDescription)")
                    return
                }

                // 解析響應
                if let data = data,
                   let responseString = String(data: data, encoding: .utf8) {
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



         var body: some View {
             VStack {
                 VStack {
                     ForEach(foodWithPortions.indices, id: \.self) { index in
                         foodItemRow(foodWithPortion: $foodWithPortions[index])
                     }
                   
                                 
                     Text("選擇的食物: \(editedPlan)")
                         .font(.title)
                         .padding(.top,30)
                         .opacity(editedPlan.isEmpty ? 0 : 1)
                         .offset(y: -18)
                     
                     HStack {}
                 }
             }
             .navigationBarItems(trailing: Button("保存") {
                 if var dayPlans = plans[day] {
                        dayPlans[planIndex] = editedPlan
                        plans[day] = dayPlans
                        
                        if let selectedFoodData = findSelectedFoodData(for: editedPlan) {
                            print("取得的食物資料: \(selectedFoodData)")
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            let dateString = dateFormatter.string(from: Date())
                            
                            
                          
                            
                            savePlanToServer(P_ID: "", U_ID: "", Dis_ID: selectedFoodData.Dis_ID, P_DT: day, P_Bought: "") { success, errorMessage in
                                               if success {
                                                   print("計劃成功保存到伺服器")
                                               } else {
                                                   print("保存計劃的結果：\(errorMessage ?? "出問題")")
                                               }
                                           }
                        } else {
                            print("Selected food data not found")
                        }
                        
                        self.presentationMode.wrappedValue.dismiss()
                    }
                })
                
               
             NavigationView {
                 ScrollView {
                     VStack(spacing:5) {
                         HStack(spacing:-20) {
                             TextField("搜尋食譜.....", text: $searchText)
                                 .padding()
                                 .textFieldStyle(RoundedBorderTextFieldStyle())
                             Button(action: {
                                 // 執行搜尋操作
                             }) {
                                 Image(systemName: "magnifyingglass") // 放大鏡圖標
                                     .padding()
                             }
                         }
                         .padding(.top, 10)
                         
                         .onAppear {
                                  fetchFoodOptions()
                              }
                         let name=["懶人","減肥","省錢","放縱","養生","今日推薦","聽天由命"]
                         let show2=[foodOptions1,foodOptions2,foodOptions3,foodOptions4,foodOptions5,foodOptions6]
                         VStack(spacing: 30) {
                             ForEach(name.indices, id: \.self) { index in
                                 if index == 6 {
                                     fateButton // 顯示第七個選項的專用按鈕
                                 } else {
                                     self.TempView(
                                         imageName: name[index],
                                         buttonText: name[index],
                                         isShowingDetail: $show1[index],
                                         foodOptions: show2[index]
                                     )
                                 }
                             }
                         }
                         .padding()
                     }
                 }
             }
         }
     }
