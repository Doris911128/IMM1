// EditPlanView.swift

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

  

    @Environment(\.presentationMode) var presentationMode
    
    // Function to fetch food options from the server
    func fetchFoodOptions() {
            if let url = URL(string: "http://163.17.9.107/food/Dishes.php") {
                fetchFoodData(from: url) { foodData, error in
                    if let error = error {
                        print("Error occurred: (error)")
                    } else if let dishes = foodData {
                        print("Fetched food data: (dishes)")
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
     private func TempView(imageName: String, buttonText: String, isShowingDetail: Binding<Bool>, foodOptions: [Dishes]) -> some View {
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
                    savePlanToServer(P_ID: "", U_ID: "", Dis_ID: disID, P_DT: day, P_Bought: "") { success, errorMessage in
                        if success {
                            print("計劃成功保存到伺服器")
                        } else {
                            print("保存計劃的結果：\(errorMessage ?? "出問題")")
                        }
                    }
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
             Text("選擇的食物: \(editedPlan)")
                 .font(.title)
                 .padding(.top,30)
                 .opacity(editedPlan.isEmpty ? 0 : 1)
                 .offset(y: -18)
             HStack {}
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
                        
                        
                        updatePlanOnServer(pID:"nJqERSSPjn", disID: String(selectedFoodData.Dis_ID))
                        
                        savePlanToServer(P_ID: "", U_ID: "", Dis_ID: String(selectedFoodData.Dis_ID), P_DT: day, P_Bought: "") { success, errorMessage in
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
