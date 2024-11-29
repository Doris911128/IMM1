//  Custom_recipesView.swift 用戶自訂食譜
   //  IMM1
   //
   //  Created by 朝陽資管 on 2024/8/22.
   //

   import SwiftUI



   struct Custom_recipesView: View
   {
       let U_ID: String // 用於添加收藏
       @State private var isEditing = false
       @State var caRecipes: CA_Recipes = CA_Recipes(customRecipes: [], aiRecipes: [])
       @State private var Crecipes: [CRecipe] = []
       @State private var showingAddRecipeView = false
       @State private var selectedRecipe: CRecipe? = nil
       @Environment(\.colorScheme) var colorScheme
       private func fetchCRecipes() {
              // 添加獲取食譜的邏輯
              guard let url = URL(string: "http://163.17.9.107/food/php/GetCC_Recipes.php") else { return }
              var request = URLRequest(url: url)
              request.httpMethod = "POST"
              request.setValue("application/json", forHTTPHeaderField: "Content-Type")
              let requestData = ["U_ID": U_ID]
              request.httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])

              URLSession.shared.dataTask(with: request) { data, response, error in
                  if let data = data {
                      do {
                          let decodedResponse = try JSONDecoder().decode([CRecipe].self, from: data)
                          DispatchQueue.main.async {
                              self.Crecipes = decodedResponse
                          }
                      } catch {
                          print("JSON 解碼錯誤：\(error)")
                      }
                  } else if let error = error {
                      print("請求錯誤：\(error)")
                  }
              }.resume()
          }
       private func deleteRecipe(at index: Int) {
              let recipeID = Crecipes[index].CR_ID
              guard let url = URL(string: "http://163.17.9.107/food/php/delete_CRecipe.php") else { return }

              var request = URLRequest(url: url)
              request.httpMethod = "POST"
              request.setValue("application/json", forHTTPHeaderField: "Content-Type")
              let requestData = ["CR_ID": recipeID]
              request.httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])

              URLSession.shared.dataTask(with: request) { data, response, error in
                  if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                      DispatchQueue.main.async {
                          Crecipes.remove(at: index)
                      }
                  } else {
                      print("刪除失敗，請稍後再試")
                  }
              }.resume()
          }
       private func deleteCRecipe(at offsets: IndexSet) {
           for index in offsets {
               let recipeToDelete = Crecipes[index]
               deleteCRecipeOnServer(recipeID: recipeToDelete.CR_ID) { success in
                   if success {
                       DispatchQueue.main.async {
                           self.Crecipes.remove(atOffsets: offsets)
                       }
                   } else {
                       print("刪除失敗")
                   }
               }
           }
       }
       var body: some View
       {
           NavigationStack
           {
               VStack
               {
                   Text("自訂食譜庫")
                       .font(.largeTitle)
                       .bold()
                       .frame(maxWidth: .infinity, alignment: .leading)
                       .padding(.leading, 20)
                   Spacer()
                   Button(action: {
                       isEditing.toggle() // 切換編輯狀態
                   }) {
                       Text(isEditing ? "完成" : "刪除")
                           .font(.headline)
                           .foregroundColor(colorScheme == .dark ? Color(red: 255/255, green: 212/255, blue: 161/255) : Color(red: 246/255, green: 143/255, blue: 28/255)) // 根据颜色模式调整文本颜色
                   }
                   .padding(.leading, 318)
                   .padding(.horizontal, 20)
                   .padding(.top, -40) // 使用 .top 調整向上移動的距離
                   .opacity(Crecipes.isEmpty ? 0 : 1) // 如果 Crecipes 為空，隱藏按鈕
                   .animation(.easeInOut, value: Crecipes.isEmpty) // 平滑動畫

                   if Crecipes.isEmpty
                                      {
                                          Spacer()
                                          VStack
                                          {
                                              Image("自訂食材預設圖片") // 替換為您的圖片名稱
                                                  .resizable()
                                                  .scaledToFit()
                                                  .frame(width: 200, height: 200)
                                                  .padding()

                                              Text("暫無新增任何自訂食譜")
                                                  .foregroundColor(.gray)
                                                  .font(.title2)
                                                  .padding(.bottom, 20)

                                          }

                                          Spacer()
                                      } else
                   {
                                          ScrollView {
                                              LazyVGrid(columns: [GridItem(.flexible())]) {
                                                  ForEach(Crecipes.indices, id: \.self) { index in
                                                      HStack(spacing: 10) {
                                                          NavigationLink(
                                                            destination: CRecipeDetailBlock(
                                                                U_ID: U_ID, Crecipe: $Crecipes[index]
                                                            )
                                                          ) {
                                                              CR_Block(recipeName: Crecipes[index].f_name)
                                                          }
                                                          if isEditing {
                                                              Button(action: {
                                                                  deleteRecipe(at: index)
                                                              }) {
                                                                  Image(systemName: "minus.circle.fill")
                                                                      .foregroundColor(.red)
                                                              }
                                                              .padding(.leading, 8)
                                                          }
                                                      }
                                                      .offset(x: isEditing ? -20 : 0)
                                                      .animation(.easeInOut, value: isEditing)
                                                  }
                                              }
                                              .padding()
                                          }
                                      }
                   
                   Button(action: {
                       showingAddRecipeView.toggle()
                   }) {
                       Text("新增自訂食譜")
                           .font(.headline)
                           .frame(maxWidth: .infinity, maxHeight: 50)
                           .background(Color.orange)
                           .foregroundColor(.white)
                           .cornerRadius(10)
                           .padding(.horizontal)
                           .padding(.bottom, 5)
                           .padding()
                           .shadow(radius: 4) // 新增陰影
                   }
               }
               
               .sheet(isPresented: $showingAddRecipeView) {
                   AddRecipeView(Crecipes: $Crecipes, isEditing: $isEditing, U_ID: U_ID)
               }

               .onAppear{
                   fetchCRecipes()
               }
               
           }
       }
   }
private func deleteCRecipeOnServer(recipeID: Int, completion: @escaping (Bool) -> Void) {
   guard let url = URL(string: "http://163.17.9.107/food/php/delete_CRecipe.php") else {
       completion(false)
       return
   }
   
   var request = URLRequest(url: url)
   request.httpMethod = "POST"
   request.setValue("application/json", forHTTPHeaderField: "Content-Type")
   
   let requestData = ["CR_ID": recipeID]
   request.httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])
   
   URLSession.shared.dataTask(with: request) { data, response, error in
       if let error = error {
           print("刪除失敗: \(error)")
           completion(false)
           return
       }
       
       if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
           completion(true)
       } else {
           completion(false)
       }
   }.resume()
}
   //MARK: addCRecipe: 新增自訂食譜
   func addCRecipe(recipe: CRecipe, U_ID: String, completion: @escaping (Bool) -> Void) {
       guard let url = URL(string: "http://163.17.9.107/food/php/add_CRecipes.php") else {
           completion(false)
           return
       }
       
       var request = URLRequest(url: url)
       request.httpMethod = "POST"
       request.setValue("application/json", forHTTPHeaderField: "Content-Type")
       
       let recipeData: [String: Any] = [
           "U_ID": U_ID,
           "f_name": recipe.f_name,
           "ingredients": recipe.ingredients,
           "method": recipe.method,
           "UTips": recipe.UTips,
           "c_image_url": recipe.c_image_url ?? ""
       ]

       
       do {
           let jsonData = try JSONSerialization.data(withJSONObject: recipeData, options: [])
           request.httpBody = jsonData
       } catch {
           completion(false)
           return
       }
       URLSession.shared.dataTask(with: request) { data, response, error in
           if let error = error {
               print("新增自訂食譜失敗: \(error)")
               completion(false)
               return
           }
           
           if let httpResponse = response as? HTTPURLResponse {
               print("HTTP Status Code: \(httpResponse.statusCode)")
               if let data = data, let responseString = String(data: data, encoding: .utf8) {
                   print("伺服器返回數據: \(responseString)") // 打印返回的数据
               }
               if httpResponse.statusCode == 200 {
                   completion(true)
               } else {
                   print("伺服器錯誤: \(httpResponse.statusCode)")
                   completion(false)
               }
           } else {
               print("無法獲取伺服器回應")
               completion(false)
           }
       }.resume()


   }


   //MARK: 新增用戶自訂食譜視圖
   struct AddRecipeView: View
   {
       @Environment(\.dismiss) var dismiss
       @Binding var Crecipes: [CRecipe] //讓新增的食譜可以同步到主視圖中
       @Binding var isEditing: Bool // 新增這行，綁定刪除狀態

       let U_ID: String // 添加這一行
       
       @State private var f_name = ""
       @State private var ingredients = ""
       @State private var method = ""
       @State private var UTips = ""
       @State private var c_image_url = ""
       
       @State private var ingredientsList: [String] = [""] // 用於儲存動態新增的食材
       @State private var stepsList: [String] = [""] // 用於儲存動態新增的步驟
       @State private var UTipsList: [String] = [""] // 用於儲存動態新增的小技巧
       
       // 圖片相關狀態
       @State private var isImagePickerPresented = false
       @State private var selectedImage: UIImage? = nil
       @State private var imageURL: String? = nil
       
       @State private var showAlert = false
       @State private var alertMessage = ""
       struct CustomRecipesResponse: Codable {
           let customRecipes: [CRecipe]
       }

       private func saveRecipe() {
           // 檢查空值
           if f_name.isEmpty || ingredientsList.contains(where: { $0.isEmpty }) || stepsList.contains(where: { $0.isEmpty }) {
               alertMessage = "請確保食譜名稱、所需食材和製作方法都已填寫！"
               showAlert = true
               return
           }

           let newRecipeID = (Crecipes.map { $0.CR_ID }.max() ?? 0) + 1
           let ingredients = ingredientsList.joined(separator: "\n")
           let method = stepsList.joined(separator: "\n")
           let UTips = UTipsList.joined(separator: "\n")

           let newRecipe = CRecipe(CR_ID: newRecipeID, f_name: f_name, ingredients: ingredients, method: method, UTips: UTips, c_image_url: c_image_url)

           // 呼叫 addCRecipe
           addCRecipe(recipe: newRecipe, U_ID: U_ID) { success in
               DispatchQueue.main.async {
                   if success {
                       fetchCRecipes() // 新增成功後從後端重新獲取資料
                       Crecipes.append(newRecipe)
                       isEditing = false // 確保刪除模式不會自動開啟
                       dismiss()
                   } else {
                       alertMessage = "儲存失敗，請稍後再試。"
                       showAlert = true
                   }
               }
           }
       }

       func fetchCRecipes() {
           guard let url = URL(string: "http://163.17.9.107/food/php/GetCC_Recipe.php") else { return }

           var request = URLRequest(url: url)
           request.httpMethod = "POST"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")

           // 構造包含 U_ID 的資料以過濾用戶自訂食譜
           let requestData = ["U_ID": U_ID]
           request.httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])

           URLSession.shared.dataTask(with: request) { data, response, error in
               if let data = data {
                   do {
                       let decodedResponse = try JSONDecoder().decode(CustomRecipesResponse.self, from: data)
                       DispatchQueue.main.async {
                           self.Crecipes = decodedResponse.customRecipes
                       }
                   } catch {
                       print("JSON 解码错误：\(error)")

                   }
               } else if let error = error {
                   print("請求錯誤：\(error)")
               }
           }.resume()
       }

       private func deleteCRecipe(at offsets: IndexSet) {
               offsets.forEach { index in
                   let recipe = Crecipes[index]
                   guard let url = URL(string: "http://163.17.9.107/food/php/DeleteCRecipe.php") else { return }
                   var request = URLRequest(url: url)
                   request.httpMethod = "POST"
                   request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                   let deleteData = ["U_ID": U_ID, "CR_ID": recipe.CR_ID]
                   request.httpBody = try? JSONSerialization.data(withJSONObject: deleteData, options: [])

                   URLSession.shared.dataTask(with: request) { data, response, error in
                       if let error = error {
                           print("刪除失敗: \(error)")
                       } else {
                           DispatchQueue.main.async {
                               Crecipes.remove(atOffsets: offsets)
                           }
                       }
                   }.resume()
               }
           }
           
       var body: some View
       {
           
           NavigationStack
           {
               Form
               {
                   Section(header:
                               Text("食譜名稱")
                       .font(.headline)
                       .frame(maxWidth: .infinity, alignment: .leading))
                   {
                       TextField("輸入食譜名稱", text: $f_name)
                   }
                   
                   
                   // 食材區塊
                   Section(header: Text("所需食材").font(.headline))
                   {
                       ForEach(ingredientsList.indices, id: \.self) { index in
                           HStack
                           {
                               // 確保索引安全地綁定
                               TextField("輸入所需食材", text: Binding(
                                   get:
                                       {
                                       if ingredientsList.indices.contains(index)
                                       {
                                           return ingredientsList[index]
                                       } else
                                       {
                                           return ""
                                       }
                                   },
                                   set:
                                       { newValue in
                                       if ingredientsList.indices.contains(index)
                                       {
                                           ingredientsList[index] = newValue
                                       }
                                   }
                               ))

                               .frame(height: 40)
                               
                               if ingredientsList.count > 1
                               {
                                   Button(action:
                                           {
                                       ingredientsList.remove(at: index)
                                   })
                                   {
                                       Image(systemName: "minus.circle.fill")
                                           .foregroundColor(.red)
                                   }
                               }
                           }
                       }
                       Button(action: { ingredientsList.append("") })
                       {
                           Label("新增食材", systemImage: "plus.circle.fill")
                               .foregroundColor(ingredientsList.last?.isEmpty == false ? .orange : .gray)
                       }
                       .disabled(ingredientsList.last?.isEmpty ?? true)
                   }
                   
                   // 製作步驟區塊
                   Section(header: Text("製作方法").font(.headline))
                   {
                       ForEach(stepsList.indices, id: \.self) { index in
                           HStack
                           {
                               TextField("輸入製作步驟", text: Binding(
                                   get:
                                       {
                                       if stepsList.indices.contains(index)
                                           {
                                           return stepsList[index]
                                       } else
                                           {
                                           return ""
                                       }
                                   },
                                   set:
                                       { newValue in
                                       if stepsList.indices.contains(index)
                                           {
                                           stepsList[index] = newValue
                                       }
                                   }
                               ))
                              
                               .frame(height: 40)
                               
                               if stepsList.count > 1
                               {
                                   Button(action:
                                           {
                                       stepsList.remove(at: index)
                                   })
                                   {
                                       Image(systemName: "minus.circle.fill")
                                           .foregroundColor(.red)
                                   }
                               }
                           }
                       }
                       Button(action: { stepsList.append("") })
                       {
                           Label("新增步驟", systemImage: "plus.circle.fill")
                               .foregroundColor(stepsList.last?.isEmpty == false ? .orange : .gray)
                       }
                       .disabled(stepsList.last?.isEmpty ?? true)
                   }
                   
                   // 小技巧區塊
                   Section(header: Text("小技巧").font(.headline))
                   {
                       ForEach(UTipsList.indices, id: \.self) { index in
                           HStack
                           {
                               TextField("輸入小技巧", text: Binding(
                                   get:
                                       {
                                       if UTipsList.indices.contains(index)
                                           {
                                           return UTipsList[index]
                                       } else
                                           {
                                           return ""
                                       }
                                   },
                                   set:
                                       { newValue in
                                       if UTipsList.indices.contains(index)
                                       {
                                           UTipsList[index] = newValue
                                       }
                                   }
                               ))
                               
                               .frame(height: 40)
                               
                               if UTipsList.count > 1
                               {
                                   Button(action:
                                           {
                                       UTipsList.remove(at: index)
                                   })
                                   {
                                       Image(systemName: "minus.circle.fill")
                                           .foregroundColor(.red)
                                   }
                               }
                           }
                       }
                       Button(action: { UTipsList.append("") })
                       {
                           Label("新增小技巧", systemImage: "plus.circle.fill")
                               .foregroundColor(UTipsList.last?.isEmpty == false ? .orange : .gray)
                       }
                       .disabled(UTipsList.last?.isEmpty ?? true)
                   }
                   
                   // 將儲存按鈕放回 Form 中，並移除它的背景
                   Section
                   {
                       HStack
                       {
                           Spacer()
                           Button(action: saveRecipe)
                           {
                               Text("儲存")
                                   .font(.headline)
                                   .padding()
                                   .frame(maxWidth: .infinity,maxHeight:50)
                                   .background(Color.orange) // 按鈕背景
                                   .foregroundColor(.white)
                                   .cornerRadius(10)
                           }
                           Spacer()
                               .alert(isPresented: $showAlert) {
                                   Alert(title: Text("警告"), message: Text(alertMessage), dismissButton: .default(Text("好")))
                               }

                       }
                   }
                   .listRowBackground(Color.clear) // 只對儲存按鈕的區塊移除背景
               }
               .navigationTitle("新增食譜")
           }
       }
       
   }
   // 安全訪問陣列的擴展
   extension Array {
       subscript(safe index: Index) -> Element? {
           return indices.contains(index) ? self[index] : nil
       }
   }
   //MARK: 外部公模板 CR_Block
struct CR_Block: View {
    let recipeName: String // 接收食譜名稱
    @Environment(\.colorScheme) var colorScheme // 获取当前颜色模式

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.5) : Color.white) // 使用柔和的灰色作为深色模式背景
                            .shadow(radius: 2)

            VStack(alignment: .leading) {
                    Text(recipeName)
                            .font(.system(size: 22))
                            .bold()
                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black) // 根据颜色模式调整文字颜色
                            .frame(maxWidth: .infinity, alignment: .center) // 讓名稱居中
                        }
            .frame(height: 50)
            .padding(.horizontal) // 左右內部間距
            .padding(.vertical, 8) // 上下內部間距
        }
        .frame(maxWidth: .infinity) // 讓 ZStack 佔滿父視圖的寬度
        .padding(.horizontal)
        .padding(.vertical, 10) // 外側上下間距
    }
}

   #Preview
   {
       Custom_recipesView(U_ID: "ofmyRwDdZy")
   }
