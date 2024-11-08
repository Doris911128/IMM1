//
//  CRecipeDetailBlock.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/9/10.
//

import SwiftUI

// CRecipeDetailBlock 符合 CRecipeP 協議
struct CRecipeDetailBlock: View, CRecipeP
{
    let U_ID: String // 假設需要用戶ID?
    @Binding var Crecipe: CRecipe // 綁定 Recipe 物件 允許修改 Crecipe
    
    @State var caRecipes: CA_Recipes = CA_Recipes(customRecipes: [], aiRecipes: [])
    
    @State private var isLoading: Bool = true // 載入狀態
    @State private var loadingError: String? = nil // 加載錯誤訊息
    
    @State private var currentUserID: String? = nil // 用於保存當前用戶 ID
    @State private var isEditing: Bool = false // 控制編輯彈出框顯示
    
    @State private var editedRecipeName: String = ""
    @State private var editedUFoodSteps: [String] = [] // 編輯後的食材
    @State private var editedUCookingSteps: [String] = [] // 編輯後的步驟
    @State private var editedUTips: [String] = [] // 編輯後的小技巧＆小貼士
    
    // 圖片相關狀態
    @State private var isImagePickerPresented = false
    @State private var selectedImage: UIImage? = nil
    @State private var imageURL: String? = nil
    
    // 宣告 focusedXXXXIndex 為 Int? 以追蹤當前的索引
    @State private var focusedUFoodIndex: Int? = nil// 新增變量來追蹤哪一個TextField被聚焦_食材
    @State private var focusedUCookingIndex: Int? = nil// 步驟
    @State private var focusedUFieldIndex: Int? = nil// 小技巧
    @State private var focusedUTipIndex: Int? = nil
   
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ?  Color.black: Color.white
    }
    
    private var foregroundColor: Color {
        colorScheme == .dark ?  Color.orange.opacity(0.8): Color.orange
    }
    
    private var textFieldBackgroundColor: Color {
        colorScheme == .dark ?  Color.white.opacity(0.2): Color.gray.opacity(0.15)
    }
    private var backgroundColor1: Color {
        colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color.white
    }
    private var Color1: Color {
        colorScheme == .dark ?  Color.white: Color.black
    }
    
    
    private func updateRecipe() {
        guard let url = URL(string: "http://163.17.9.107/food/php/EditCC_Recipes.php") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 显式指定类型为 [String: Any]
        let updatedRecipe: [String: Any] = [
            "U_ID": U_ID,
            "CR_ID": Crecipe.CR_ID, // 确保你有 CR_ID
            "f_name": editedRecipeName,
            "ingredients": editedUFoodSteps.joined(separator: "\n"),
            "method": editedUCookingSteps.joined(separator: "\n"),
            "UTips": editedUTips.joined(separator: "\n"),
            "c_image_url": imageURL ?? "" // 如果有图片URL的话
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updatedRecipe, options: [])
        } catch {
            print("Error serializing JSON: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating recipe: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
            }

            // 这里可以处理服务器的响应
            if let data = data {
                // 打印出完整的响应数据以便调试
                let responseString = String(data: data, encoding: .utf8)
                print("Response from server: \(responseString ?? "")")

                do {
                    // 尝试将响应解析为 JSON
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("Parsed JSON: \(json)")
                    }
                } catch {
                    print("Error parsing JSON: \(error)")
                }
            }
        }

        task.resume()
    }

    
    
    
    var data: [CRecipe]
    {
        [Crecipe]
    }// 全部的食譜數據
    
    // MARK: 彈出編輯視圖
    var UeditView: some View {
        VStack(spacing: 20) {
            Text("食譜編輯區")
                .font(.title2)
                .bold()
                .padding()
            
            ScrollView {
                VStack(spacing: 15) {
                    // MARK: 食譜名稱編輯區塊
                    VStack(alignment: .leading) {
                        Text("食譜名稱")
                            .font(.title2)
                            .bold()
                            .foregroundColor(foregroundColor)
                            .padding(.bottom, 5)
                        TextField("更新食譜名稱", text: $editedRecipeName)
                            .padding()
                            .background(textFieldBackgroundColor)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 15)
                    
                    
                    
                    // MARK: 食材編輯區塊
                    VStack(alignment: .leading) {
                        Text("所需食材")
                            .foregroundColor(foregroundColor)
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 5)
                        
                        ForEach(editedUFoodSteps.indices, id: \.self) { index in
                            TextField("更新食材", text: $editedUFoodSteps[index])
                                .padding()
                                .background(textFieldBackgroundColor)
                                .cornerRadius(8)
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                editedUFoodSteps.append("") // 新增食材
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                    Text("新增食材")
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(Color1)
                                }
                                .padding()
                                .background(
                                    foregroundColor
                                        .frame(width: 320, height: 50)
                                        .cornerRadius(10)
                                        .shadow(radius: 4)
                                )
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 15)
                    
                    // MARK: 料理方法編輯區塊
                    VStack(alignment: .leading) {
                        Text("料理方法")
                            .foregroundColor(foregroundColor)
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 5)
                        
                        ForEach(editedUCookingSteps.indices, id: \.self) { index in
                            TextField("更新烹飪步驟", text: $editedUCookingSteps[index])
                                .padding()
                                .background(textFieldBackgroundColor)
                                .cornerRadius(8)
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                editedUCookingSteps.append("") // 新增步驟
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                    Text("新增步驟")
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(Color1)
                                }
                                .padding()
                                .background(
                                    foregroundColor
                                        .frame(width: 320, height: 50)
                                        .cornerRadius(10)
                                        .shadow(radius: 4)
                                )
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 15)
                    
                    // MARK: 小技巧編輯區塊
                    VStack(alignment: .leading) {
                        Text("小技巧")
                            .foregroundColor(foregroundColor)
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 5)
                        
                        ForEach(editedUTips.indices, id: \.self) { index in
                            TextField("更新小技巧", text: $editedUTips[index])
                                .padding()
                                .background(textFieldBackgroundColor)
                                .cornerRadius(8)
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                editedUTips.append("") // 新增小技巧
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                    Text("新增小技巧")
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(Color1)
                                }
                                .padding()
                                .background(
                                    foregroundColor
                                        .frame(width: 320, height: 50)
                                        .cornerRadius(10)
                                        .shadow(radius: 4)
                                )
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 15)
                }
            }
            
            // MARK: 確認和取消按鈕
            HStack {
                Button(action: {

                    isEditing = false // 關閉編輯
                }) {
                    Text("取消")
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color1)
                        .background(textFieldBackgroundColor)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    applyUEdits()
                    updateRecipe() // 將更新資料發送到後端
                    isEditing = false // 確認後關閉編輯
                }) {
                    Text("確認")
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(foregroundColor)
                        .foregroundColor(Color1)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
        .background(backgroundColor1)
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding()
        .onAppear {
            // 初始化編輯內容
            editedRecipeName = Crecipe.f_name
            editedUFoodSteps = Crecipe.ingredients.split(separator: "\n").map { String($0) }
            editedUCookingSteps = Crecipe.method.split(separator: "\n").map { String($0) }
            editedUTips = Crecipe.UTips.split(separator: "\n").map { String($0) }
        }
    }
    
    
    // MARK: - 更新數據模型
    private func applyUEdits() {
        // 更新食譜的各個部分
        Crecipe.f_name = editedRecipeName
        Crecipe.ingredients = editedUFoodSteps.joined(separator: "\n")
        Crecipe.method = editedUCookingSteps.joined(separator: "\n")
        Crecipe.UTips = editedUTips.joined(separator: "\n")
        
        // 如果有圖片，則更新圖片 URL
        if let imageURL = imageURL {
            Crecipe.c_image_url = imageURL
        }
    }
    
    // MARK: - 須實現的 CRecipeP 協議方法
    func itemName() -> String
    {
        return Crecipe.f_name
    }
    
    func itemImageURL() -> URL?
    {
        return nil // 用戶自建食譜沒有圖片
    }
    
    // MARK: 標題畫面
    func HeaderView(size: CGSize, recordInput: String? = nil) -> AnyView
    {
        // 返回簡易名稱
        return AnyView(
            Text(itemName())
                .font(.largeTitle)
                .bold()
                .padding()
        )
    }
    
    // MARK: CCookbookView 烹飪書
    func CCookbookView(safeArea: EdgeInsets) -> AnyView {
        AnyView(
            VStack(spacing: 18) {
                // 食材顯示區塊
                if !Crecipe.ingredients.isEmpty {
                    VStack(alignment: .leading) {
                        Text("所需食材")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(Crecipe.ingredients.split(separator: "\n").map { String($0) }, id: \.self) { ingredient in
                            HStack(spacing: 25) {
                                Text("•")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                Text(ingredient)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 32)
                            .padding(.vertical, -2)
                        }
                    }
                }
                
                // 料理方法顯示區塊
                if !Crecipe.method.isEmpty {
                    VStack(alignment: .leading) {
                        Text("料理方法")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(Array(Crecipe.method.split(separator: "\n").enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top) {
                                let stepNumber = "\(index + 1)."
                                let stepDescription = step.trimmingCharacters(in: .whitespaces)
                                
                                Text(stepNumber)
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.orange)
                                    .frame(width: 30, alignment: .leading)
                                
                                Text(stepDescription)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 35)
                            .padding(.vertical, 3)
                        }
                    }
                }
                
                // 小技巧顯示區塊（僅當小技巧不為空時顯示）
                if !Crecipe.UTips.isEmpty
                {
                    VStack(alignment: .leading)
                    {
                        Text("小技巧")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(Array(Crecipe.UTips.split(separator: "\n").enumerated()), id: \.offset) { index, tip in
                            HStack(alignment: .top) {
                                let tipNumber = "\(index + 1)."
                                let tipDescription = tip.trimmingCharacters(in: .whitespaces)
                                
                                Text(tipNumber)
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.orange)
                                    .frame(width: 30, alignment: .leading)
                                
                                Text(tipDescription)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 35)
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        )
    }
    
    // MARK: CRecipeDetailBlock body
    var body: some View
    {
        GeometryReader
        { geometry in
            let safeArea = geometry.safeAreaInsets
            let size = geometry.size
            
            ZStack(alignment: .topTrailing)
            {
                ScrollView(.vertical, showsIndicators: false)
                {
                    VStack
                    {
                        // 顯示封面
                        CoverView(safeArea: safeArea, size: size)
                        
                        // 烹飪書視圖
                        CCookbookView(safeArea: safeArea)
                            .padding(.top)
                    }
                }
                .coordinateSpace(name: "SCROLL")
                
                
                
                // 顯示編輯視圖，當 isEditing 為 true 時
                if isEditing
                {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    UeditView // 顯示編輯視圖
                }
            }
            .toolbarBackground(Color("menusheetbackgroundcolor"), for: .navigationBar)  // 設置導航欄背景
            .toolbar
            {
                ToolbarItem(placement: .navigationBarTrailing)
                {
                    VStack
                    {
                        // 固定的編輯按鈕
                        Button(action: {
                            isEditing = true
                            // 初始化編輯資料
                            editedUFoodSteps = Crecipe.ingredients.split(separator: "\n").map { String($0) }
                            editedUCookingSteps = Crecipe.method.split(separator: "\n").map { String($0) }
                            editedUTips = Crecipe.UTips.split(separator: "\n").map { String($0) }
                        })
                        {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.orange)
                        }
                    }
                    
                }
            }
            
            .onAppear {
                           fetchUserID { userID in
                               guard let userID = userID else {
                                   print("Failed to get user ID")
                                   return
                               }
                               self.currentUserID = userID
                               loadCCRData(for: userID) { customRecipes in
                                   // 處理獲取到的自訂食譜資料
                                   self.isLoading = false
                               }
                           }
                       }
                   }
                   .navigationBarTitleDisplayMode(.inline)
               }
           }
