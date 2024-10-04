//  Custom_recipesView.swift 用戶自訂食譜
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/22.
//

import SwiftUI

struct CRecipe: Identifiable
{
    let id = UUID()
    let CR_ID : Int
    var f_name: String //菜名
    var ingredients: String //食材
    var method: String //煮法
    var UTips: String //小技巧
    var c_image_url: String? // 新增圖片 URL 欄位
}

struct Custom_recipesView: View
{
    let U_ID: String // 用於添加收藏
    
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
                AddRecipeView(Crecipes: $Crecipes)
            }
        }
    }
}

//MARK: 新增用戶自訂食譜視圖
struct AddRecipeView: View
{
    @Environment(\.dismiss) var dismiss
    @Binding var Crecipes: [CRecipe] //讓新增的食譜可以同步到主視圖中
    
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
    
    private func saveRecipe() {
        // 確保唯一的食譜 ID
        let newRecipeID = (Crecipes.map { $0.CR_ID }.max() ?? 0) + 1
        
        // 將食材、步驟、小技巧組合成字串
        let ingredients = ingredientsList.joined(separator: "\n")
        let method = stepsList.joined(separator: "\n")
        let UTips = UTipsList.joined(separator: "\n")
        
        // 創建新的食譜並將圖片 URL 加入
        let newRecipe = CRecipe(CR_ID: newRecipeID, f_name: f_name, ingredients: ingredients, method: method, UTips: UTips, c_image_url: c_image_url)
        Crecipes.append(newRecipe)
        dismiss()
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
                Section {
                    VStack {
                        Button(action: {
                            isImagePickerPresented = true // 顯示圖片選擇器
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                
                                Text("更新圖片")
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                        }
                        .sheet(isPresented: $isImagePickerPresented) {
                            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                        }
                        
                        // 如果有選擇圖片，顯示圖片預覽和上傳按鈕
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                            
                            // 上傳圖片按鈕
                            Button(action: {
                                uploadImage(selectedImage) { result in
                                    switch result {
                                    case .success(let imageUrl):
                                        imageURL = imageUrl // 保存上傳成功的圖片 URL
                                    case .failure(let error):
                                        print("圖片上傳失敗: \(error.localizedDescription)")
                                    }
                                }
                            }) {
                                Text("上傳圖片")
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
                
                Section(header:
                            Text("所需食材")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading))
                {
                    ForEach(ingredientsList.indices, id: \.self)
                    { index in
                        TextField("輸入所需食材", text: $ingredientsList[index])
                            .frame(height: 40)
                    }
                    
                    HStack
                    {
                        Spacer()
                        Button(action: {
                            ingredientsList.append("") // 新增食材
                        })
                        {
                            HStack
                            {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                Text("新增食材")
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                        }
                        Spacer()
                    }
                }
                
                Section(header:
                            Text("製作方法")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading))
                {
                    ForEach(stepsList.indices, id: \.self)
                    { index in
                        TextField("輸入製作步驟", text: $stepsList[index])
                            .frame(height: 40)
                    }
                    
                    HStack
                    {
                        Spacer()
                        Button(action: {
                            stepsList.append("") // 新增步驟
                        })
                        {
                            HStack
                            {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                Text("新增步驟")
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                        }
                        Spacer()
                    }
                }
                
                Section(header:
                            Text("小技巧")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading))
                {
                    ForEach(UTipsList.indices, id: \.self)
                    { index in
                        TextField("輸入製作小技巧", text: $UTipsList[index])
                            .frame(height: 40)
                    }
                    
                    HStack
                    {
                        Spacer()
                        Button(action: {
                            UTipsList.append("") // 新增步驟
                        })
                        {
                            HStack
                            {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                Text("新增小技巧")
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                        }
                        Spacer()
                    }
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
                    }
                }
                .listRowBackground(Color.clear) // 只對儲存按鈕的區塊移除背景
            }
            .navigationTitle("新增食譜")
        }
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
