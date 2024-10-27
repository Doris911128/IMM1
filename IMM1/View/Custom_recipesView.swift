//  Custom_recipesView.swift 用戶自訂食譜
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/22.
//

import SwiftUI



struct Custom_recipesView: View
{
    let U_ID: String // 用於添加收藏
    
    @State var caRecipes: CA_Recipes = CA_Recipes(customRecipes: [], aiRecipes: [])
    @State private var Crecipes: [CRecipe] = []
    @State private var showingAddRecipeView = false
    @State private var selectedRecipe: CRecipe? = nil
    
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
                
                ScrollView
                {
                    LazyVGrid(columns: [GridItem(.flexible())]) // 使用 Flexible 來自動調整列寬
                    {
                        ForEach(Crecipes) { recipe in
                            NavigationLink(
                                destination: CRecipeDetailBlock(
                                    U_ID: U_ID, Crecipe: $Crecipes[Crecipes.firstIndex(where: { $0.CR_ID == recipe.CR_ID })!] // 傳遞用戶ID
                                )
                            ) {
                                CR_Block(recipeName: recipe.f_name) // 使用 CR_Block 顯示食譜名稱
                            }
                        }
                    }
                    .padding()
                }
                
                Button(action: {
                    showingAddRecipeView.toggle()
                }) {
                    Text("新增自訂食譜")
                        .font(.headline)
                        .frame(maxWidth: .infinity, maxHeight: 50)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        .padding()
                        .shadow(radius: 4) // 新增陰影
                }
            }
            .sheet(isPresented: $showingAddRecipeView)
            {
                AddRecipeView(Crecipes: $Crecipes, U_ID: U_ID)
            }
            
        }
    }
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

    private func saveRecipe()
    {
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
                
                // 新增圖片的功能
                Section
                {
                    VStack
                    {
                        Button(action:
                                {
                            isImagePickerPresented = true // 顯示圖片選擇器
                        }) {
                            HStack
                            {
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                
                                Text("上傳圖片")
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                        }
                        .sheet(isPresented: $isImagePickerPresented)
                        {
                            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                        }
                        
                        // 如果有選擇圖片，顯示圖片預覽和上傳按鈕
                        if let selectedImage = selectedImage
                        {
                            
                                    HStack {
                                        Spacer() // 左側留空白
                                        Image(uiImage: selectedImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit) // 讓圖片保持比例
                                            .frame(height: 200) // 固定高度
                                            .frame(maxWidth: .infinity) // 最大寬度填滿父容器
                                        Spacer() // 右側留空白
                                    }
                                
                            
                            // 上傳圖片按鈕
                            Button(action:
                                    {
                                uploadImage(selectedImage)
                                { result in
                                    switch result
                                    {
                                    case .success(let imageUrl):
                                        imageURL = imageUrl // 保存上傳成功的圖片 URL
                                    case .failure(let error):
                                        print("圖片上傳失敗: \(error.localizedDescription)")
                                    }
                                }
                            })
                            {
                                Text("確認上傳")
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(8)
                            }
                        }
                    }
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
                                .background(Color.blue) // 按鈕背景
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
struct CR_Block: View
{
    let recipeName: String // 接收食譜名稱
    
    var body: some View
    {
        ZStack
        {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 4)
            
            VStack
            {
                Text(recipeName)
                    .font(.system(size: 22))
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center) // 讓名稱居中
            }
            .frame(height: 50)
            .padding()
        }
        .frame(maxWidth: .infinity) // 讓 ZStack 佔滿父視圖的寬度
        .padding(.horizontal)
    }
}

#Preview
{
    Custom_recipesView(U_ID: "ofmyRwDdZy")
}
