//  Custom_recipesView.swift 用戶自訂食譜
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/22.
//

import SwiftUI

struct Recipe: Identifiable
{
    let id = UUID()
    let recipe_id : Int
    var name: String //菜名
    var ingredients: String //食材
    var method: String //煮法
}

struct Custom_recipesView: View
{
    let U_ID: String // 用於添加收藏
    
    @State private var recipes: [Recipe] = []
    @State private var showingAddRecipeView = false
    @State private var selectedRecipe: Recipe? = nil
    
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
                        ForEach(recipes)
                        { recipe in
                            NavigationLink(
                                destination: CRecipeDetailBlock(
                                    recipe: $recipes[recipes.firstIndex(where: { $0.recipe_id == recipe.recipe_id })!], data: recipes,
                                    U_ID: U_ID // 傳遞用戶ID
                                )
                            ) {
                                CR_Block(recipeName: recipe.name) // 使用 CR_Block 顯示食譜名稱
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
                }
            }
            .sheet(isPresented: $showingAddRecipeView)
            {
                AddRecipeView(recipes: $recipes)
            }
        }
    }
}



//MARK: 新增用戶自訂食譜視圖
struct AddRecipeView: View
{
    @Environment(\.dismiss) var dismiss
    @Binding var recipes: [Recipe] //讓新增的食譜可以同步到主視圖中
    
    @State private var name = ""
    @State private var ingredients = ""
    @State private var method = ""
    
    @State private var ingredientsList: [String] = [""] // 用於儲存動態新增的食材
    @State private var stepsList: [String] = [""] // 用於儲存動態新增的步驟
    
    private func saveRecipe() {
        // 獲取當前最大 recipe_id，然後加 1，確保唯一性
        let newRecipeID = (recipes.map { $0.recipe_id }.max() ?? 0) + 1
        
        // 將動態新增的食材和步驟組合成字串
        let ingredients = ingredientsList.joined(separator: "\n")
        let method = stepsList.joined(separator: "\n")
        
        // 創建新的 Recipe 並加入 recipes 陣列
        let newRecipe = Recipe(recipe_id: newRecipeID, name: name, ingredients: ingredients, method: method)
        recipes.append(newRecipe)
        dismiss() // 關閉視圖
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                ) {
                    TextField("輸入食譜名稱", text: $name)
                }
                
                Section(header:
                            Text("所需食材")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                )
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
// MARK: 外部公模板 CR_Block
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


//MARK: 自建食譜的單篇詳細視圖
//struct RecipeDetailView: View
//{
//    let recipe: Recipe
//
//    var body: some View
//    {
//        VStack(alignment: .leading)
//        {
//            Text(recipe.name)
//                .font(.largeTitle)
//                .bold()
//                .padding(.bottom, 10)
//
//            Text("所需食材")
//                .font(.headline)
//            Text(recipe.ingredients)
//                .padding(.bottom, 10)
//
//            Text("製作方法")
//                .font(.headline)
//            Text(recipe.method)
//                .padding(.bottom, 10)
//
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("食譜內容")
//    }
//}



#Preview
{
    Custom_recipesView(U_ID: "ofmyRwDdZy")
}
