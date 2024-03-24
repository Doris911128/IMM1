// EditPlanView.swift

import SwiftUI
import Foundation

// Define the structure for food data obtained from the server
struct FoodData: Codable {
    let Dis_ID: String
    let Dis_Name: String
    let D_image: String
    
    // Additional properties can be added if needed
    
    init(Dis_ID: String, Dis_Name: String, D_image: String, category: String) {
        self.Dis_ID = Dis_ID
        self.Dis_Name = Dis_Name
        self.D_image = D_image
    }
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

// Define a function to save a plan to the server
func savePlanToServer(P_ID: String, U_ID: String,Dis_ID: String, P_DT: String,P_Bought:String,completion: @escaping (Bool, String?) -> Void) {
    // Implement the logic to save the plan to the server here
    // If the save is successful, call completion(true, nil)
    // If the save fails, call completion(false, "Error message")
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
    
    @Environment(\.presentationMode) var presentationMode
    
    // Function to fetch food options from the server
    func fetchFoodOptions() {
        if let url = URL(string: "http://163.17.9.107/food/Dishes.php") {
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

    // Function to save plan to server
    func savePlanToServer(P_ID: String, U_ID: String, Dis_ID: String, P_DT: String, P_Bought: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/Plan.php") else {
            completion(false, "無效的 URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Construct POST data
        let postData = "P_ID=\(P_ID)&U_ID=\(U_ID)&Dis_ID=\(Dis_ID)&P_DT=\(P_DT)&P_Bought=\(P_Bought)"
        request.httpBody = postData.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "錯誤: \(error.localizedDescription)")
                return
            }

            // 解析响应
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
                        
                        savePlanToServer(P_ID: "", U_ID: "", Dis_ID: selectedFoodData.Dis_ID, P_DT: dateString, P_Bought: "") { success, errorMessage in
                            if success {
                                print("計畫成功保存到伺服器")
                            } else {
                                print("保存計畫的結果：\(errorMessage ?? "出問題")")
                                
                        
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
