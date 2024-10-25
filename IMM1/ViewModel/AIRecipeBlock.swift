//  AIRecipeBlock.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/9/2.
//


import SwiftUI
import Foundation

struct AIRecipeBlock: View, AIRecipeP
{
    @Binding var aiRecipes: [ChatRecord] // 使用傳遞的 aiRecipes
    let aiRecipe: ChatRecord // 傳遞進來的單個 ChatRecord
    
    let U_ID: String // 用於添加收藏
    
    @State var caRecipes: CA_Recipes = CA_Recipes(customRecipes: [], aiRecipes: [])
    
    @State private var isLoading: Bool = true // 載入狀態
    @State private var loadingError: String? = nil // 加載錯誤訊息
    
    @State private var currentUserID: String? = nil // 用於保存當前用戶 ID
    
    @State private var isEditing: Bool = false // 控制編輯彈出框顯示
    
    @State private var isImagePickerPresented: Bool = false // 控制圖片選擇器顯示
    @State private var editedImages: [String] = [] // 用來存儲圖片 URL
    @State private var selectedImage: UIImage? = nil // 本地選擇的圖片
    
    @State private var editedRecipeName: String = "" // 新增編輯後的食譜名稱
    @State private var editedFoodSteps: [String] = [] // 編輯後的食材
    @State private var editedCookingSteps: [String] = [] // 編輯後的步驟
    @State private var editedTips: [String] = [] // 編輯後的小技巧＆小貼士
    @State private var editedOtherCook: [String] = [] // 編輯後的例外狀況給智慧食譜編輯做改動
    
    // 宣告 focusedXXXXIndex 為 Int? 以追蹤當前的索引
    @State private var focusedNameIndex: Bool = false
    @State private var focusedFoodIndex: Int? = nil// 食材
    @State private var focusedCookingIndex: Int? = nil// 步驟
    @State private var focusedOtherIndex: Int? = nil// 智慧食譜
    @State private var focusedFieldIndex: Int? = nil// 小技巧
    
    @State private var uploadProgress: Double = 0.0 //追蹤圖片上傳進度
    
    var data: [ChatRecord]
    {
        [aiRecipe] // 使用傳遞的單個 record
    }
    
    // MARK: 彈出編輯視圖
    var editView: some View
    {
        VStack(spacing: 20)
        {
            // 標題
            Text("食譜編輯區")
                .font(.title2)
                .bold()
                .padding()
            
            ScrollView
            {
                VStack(spacing: 15)
                {
                    
                    // MARK: 更新圖片按鈕
                    VStack
                    {
                        Button(action: {
                            isImagePickerPresented = true // 顯示圖片選擇器
                        })
                        {
                            HStack
                            {
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                
                                Text("更新圖片")
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(
                                Color.white
                                    .frame(width: 320, height: 50)
                                    .cornerRadius(10)
                                    .shadow(radius: 4)
                            )
                        }
                        .sheet(isPresented: $isImagePickerPresented)
                        {
                            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                        }
                        
                        // 如果有選擇圖片，顯示圖片預覽和上傳按鈕
                        if let selectedImage = selectedImage
                        {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                            
                            // 上傳圖片按鈕
                            Button(action: {
                                uploadImage(selectedImage) { result in
                                    switch result
                                    {
                                    case .success(let imageUrl):
                                        print("圖片已上傳，URL為: \(imageUrl)")
                                    case .failure(let error):
                                        print("圖片上傳失敗: \(error.localizedDescription)")
                                    }
                                }
                            })
                            {
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
                    
                    // MARK: 食譜名稱編輯區塊
                    VStack(alignment: .leading)
                    {
                        Text("食譜名稱")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 5)
                            .padding(.leading, 15)
                        
                        if focusedNameIndex {
                            Text("Before: \(aiRecipe.input)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .padding(.leading, 15)
                        }
                        
                        HStack(alignment: .top) {
                            TextField("更新食譜名稱", text: $editedRecipeName)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .onTapGesture {
                                    focusedNameIndex = true
                                }
                                .onSubmit {
                                    focusedNameIndex = false
                                }
                        }
                        .padding(.horizontal, 15)
                    }
                    .padding(.vertical, 10)
                    
                    // MARK: 動態顯示區塊
                    if let foodSteps = extractFoodSteps(from: aiRecipe.output),
                       let cookingSteps = extractCookingSteps(from: aiRecipe.output)
                    {
                        // 顯示食材和烹飪步驟
                        displayFoodAndCookingSteps(foodSteps: foodSteps, cookingSteps: cookingSteps)
                        
                    } else
                    {
                        // 顯示智慧食譜編輯區
                        displaySmartRecipeSection()
                    }
                    
                    // MARK: 小技巧編輯區塊
                    displayTipsSection()
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
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    applyEdits()
                    isEditing = false // 確認後關閉編輯
                }) {
                    Text("確認")
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding()
        .onAppear {
            if editedTips.isEmpty, let tips = extractTips(from: aiRecipe.output) {
                editedTips = tips
            }
            editedOtherCook = aiRecipe.output.split(separator: "\n").map(String.init) ?? []
        }
    }
    
    // MARK: 動態顯示食材和烹飪步驟區塊
    @ViewBuilder
    private func displayFoodAndCookingSteps(foodSteps: [String], cookingSteps: [String]) -> some View {
        // 食材編輯區
        VStack(alignment: .leading) {
            Text("所需食材")
                .foregroundStyle(.orange)
                .font(.title2)
                .bold()
                .padding(.bottom, 5)
            
            ForEach(editedFoodSteps.indices, id: \.self) { index in
                VStack {
                    HStack(alignment: .top) {
                        Text("食材 \(index + 1)")
                            .font(.system(size: 12))
                            .bold()
                            .foregroundColor(.gray)
                        Spacer()
                        
                        if focusedFoodIndex == index, index < foodSteps.count {
                            Text("Before：\(foodSteps[index])")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    TextField("更新食材", text: $editedFoodSteps[index])
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .onTapGesture { focusedFoodIndex = index }
                        .onSubmit { focusedFoodIndex = nil }
                }
                .padding(.horizontal, 15)
            }
            
            addNewButton(label: "新增食材", action: { editedFoodSteps.append("") })
        }
        .padding(.horizontal, 15)
        
        // 料理方法編輯區
        VStack(alignment: .leading) {
            Text("料理方法")
                .foregroundStyle(.orange)
                .font(.title2)
                .bold()
                .padding(.bottom, 5)
            
            ForEach(editedCookingSteps.indices, id: \.self) { index in
                VStack {
                    HStack(alignment: .top) {
                        Text("步驟 \(index + 1)")
                            .font(.system(size: 12))
                            .bold()
                            .foregroundColor(.gray)
                        Spacer()
                        
                        if focusedCookingIndex == index, index < cookingSteps.count {
                            Text("Before：\(cookingSteps[index])")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    TextField("更新烹飪步驟", text: $editedCookingSteps[index])
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .onTapGesture { focusedCookingIndex = index }
                        .onSubmit { focusedCookingIndex = nil }
                }
                .padding(.horizontal, 20)
            }
            
            addNewButton(label: "新增步驟", action: { editedCookingSteps.append("") })
        }
        .padding(.horizontal, 15)
    }
    
    // MARK: 顯示智慧食譜區塊
    @ViewBuilder
    private func displaySmartRecipeSection() -> some View {
        VStack(alignment: .leading) {
            Text("智慧食譜")
                .foregroundStyle(.orange)
                .font(.title2)
                .bold()
            
            TextEditor(text: Binding(
                get: { editedOtherCook.joined(separator: "\n") },
                set: { newValue in
                    editedOtherCook = newValue.split(separator: "\n").map(String.init)
                }
            ))
            .font(.body)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .frame(minHeight: 400)
            .onTapGesture { focusedOtherIndex = 999 }
            
            if focusedOtherIndex == 999 {
                Text("先前智慧食譜：")
                    .font(.body)
                    .bold()
                    .padding(.top, 10)
                
                Text(aiRecipe.output)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .padding()
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 15)
    }
    
    // MARK: 顯示小技巧編輯區
    @ViewBuilder
    private func displayTipsSection() -> some View {
        VStack(alignment: .leading) {
            Text("小技巧")
                .foregroundStyle(.orange)
                .font(.title2)
                .bold()
                .padding(.bottom, 5)
            
            ForEach(editedTips.indices, id: \.self) { index in
                VStack {
                    HStack(alignment: .top) {
                        Text("技巧 \(index + 1)")
                            .font(.system(size: 12))
                            .bold()
                            .foregroundColor(.gray)
                        Spacer()
                        
                        if focusedFieldIndex == index {
                            Text("Before：\(editedTips[index])")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    TextField("更新小技巧", text: $editedTips[index])
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .onTapGesture { focusedFieldIndex = index }
                        .onSubmit { focusedFieldIndex = nil }
                }
                .padding(.horizontal, 20)
            }
            
            addNewButton(label: "新增小技巧", action: { editedTips.append("") })
        }
        .padding(.horizontal, 15)
    }
    
    // MARK: 添加新食材或步驟按鈕
    @ViewBuilder
    private func addNewButton(label: String, action: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            Button(action: action) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text(label)
                        .font(.body)
                        .bold()
                        .foregroundColor(.orange)
                }
                .padding()
                .background(
                    Color.white
                        .frame(width: 320, height: 50)
                        .cornerRadius(10)
                        .shadow(radius: 4)
                )
            }
            Spacer()
        }
    }
    
    
    var imagePickerSection: some View {
        VStack {
            Button(action: {
                isImagePickerPresented = true // 按下按鈕後顯示圖片選擇器
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
                .padding()
                .background(
                    Color.white
                        .frame(width: 320, height: 50)
                        .cornerRadius(10)
                        .shadow(radius: 4)
                )
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            
            // 顯示圖片預覽
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
                            print("圖片已上傳，URL為: \(imageUrl)")
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
    
    
    // MARK: - 更新數據模型
    private func applyEdits()
    {
        // 將編輯後的內容應用到數據模型中
        print("Edited recipe name: \(editedRecipeName)")
        print("Edited food steps: \(editedFoodSteps)")
        print("Edited cooking steps: \(editedCookingSteps)")
        print("Edited tips: \(editedTips)")
    }
    
    func saveImageURLToDatabase(imageUrl: String, recipeID: Int, completion: @escaping (Bool) -> Void) {
        // 更新食譜數據
        let updatedRecipe = CRecipe(
            CR_ID: recipeID,
            f_name: editedRecipeName.isEmpty ? aiRecipe.input : editedRecipeName,
            ingredients: editedFoodSteps.joined(separator: ", "),
            method: editedCookingSteps.joined(separator: "\n"),
            UTips: editedTips.joined(separator: "\n"),
            c_image_url: imageUrl
        )
        
        // 調用 editRecipe，只傳入正確的參數
        editRecipe(recipe: updatedRecipe, U_ID: U_ID, isAIRecipe: false) { success in
            if success {
                print("Recipe updated successfully")
                completion(true)
            } else {
                print("Failed to update recipe")
                completion(false)
            }
        }
    }
    
    // MARK: 拆分[食材]
    func extractFoodSteps(from output: String) -> [String]? {
        // 使用多個標題來查找食材的開始位置
        guard let foodStartRange = output.range(of: "所需材料") ??
                output.range(of: "原料") ??
                output.range(of: "材料") else {
            print("找不到 '所需材料' 或 '材料' 的標題")
            return nil
        }
        
        // 查找料理方法開始的標題
        let end = output.range(of: "作法")?.lowerBound ??
        output.range(of: "指示")?.lowerBound ??
        output.range(of: "做法")?.lowerBound ??
        output.endIndex
        
        let foodContent = String(output[foodStartRange.upperBound..<end])
        
        // 將食材內容按行拆分並清理多餘空格
        let steps = foodContent.split(separator: "\n")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if steps.isEmpty {
            print("食材拆分失敗，找不到有效的食材")
        }
        
        return steps.isEmpty ? nil : steps
    }
    
    // MARK: 拆分[料理方法]
    func extractCookingSteps(from output: String) -> [String]? {
        // 查找料理方法的標題，新增“製作步驟”的條件
        guard let methodStartRange = output.range(of: "作法") ??
                output.range(of: "指示") ??
                output.range(of: "做法") ??
                output.range(of: "製作步驟") else {
            print("找不到 '作法'、'指示'、'做法' 或 '製作步驟' 的標題")
            return nil
        }
        
        // 找到結束標題，這裡增加了可以結束的方法標題
        let end = output.range(of: "小技巧")?.lowerBound ??
        output.range(of: "小貼士")?.lowerBound ??
        output.range(of: "isAICol")?.lowerBound ??
        output.endIndex
        
        // 獲取料理方法的內容
        let methodContent = String(output[methodStartRange.upperBound..<end])
        
        // 將料理方法按行拆分，去除多餘的空格和空行
        let steps = methodContent.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if steps.isEmpty {
            print("料理方法拆分失敗，找不到有效的步驟")
        }
        
        return steps.isEmpty ? nil : steps
    }
    
    // MARK: 拆分[小技巧＆小貼士]
    func extractTips(from output: String) -> [String]?
    {
        guard let tipStartRange = output.range(of: "小技巧：") ?? output.range(of: "小貼士：")
        else
        {
            print("找不到 '小技巧' 或 '小貼士' 的標題")
            return nil
        }
        
        // 找到 'isAICol' 或文末的結束位置
        let end = output.range(of: "isAICol")?.lowerBound ?? output.endIndex
        let tipsContent = String(output[tipStartRange.upperBound..<end])
        
        let tips = tipsContent.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        // 調試打印
        if tips.isEmpty
        {
            print("小技巧拆分失敗，找不到任何有效的小技巧")
        }
        
        return tips.isEmpty ? nil : tips
    }
    // MARK: - AIRecipeP 協議要求的實作方法
    func itemName() -> String {
        // 如果名稱已編輯，返回編輯後的名稱
        if !editedRecipeName.isEmpty {
            print("名稱來自編輯後的名稱: \(editedRecipeName)")
            return editedRecipeName
        }
        // 否則嘗試從 output 中提取名稱
        else if let extractedName = aiRecipe.output.extractRecipeName() {
            print("名稱成功從 output 提取: \(extractedName)")
            return extractedName
        }
        // 如果無法提取名稱，返回默認的 record.input 或 "Unknown AI Recipe"
        else {
            let fallbackName = aiRecipe.input ?? "Unknown AI Recipe"
            print("提取失敗，使用默認名稱: \(fallbackName)")
            return fallbackName
        }
    }
    
    func itemImageURL() -> URL?
    {
        return nil // AI 食譜通常沒有封面圖片
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
    
    // MARK: AI 烹飪書 AICookbookView
    // 包括所需食材、AI 生成的烹飪方法和小技巧
    func AICookbookView(safeArea: EdgeInsets) -> AnyView {
        return AnyView(
            VStack(spacing: 18) {
                // 食譜顯示內容，直接使用 record.output
                let foodSteps = extractFoodSteps(from: aiRecipe.output)
                let cookingSteps = extractCookingSteps(from: aiRecipe.output)
                
                // MARK: 顯示食材
                if let foodSteps = foodSteps {
                    VStack(alignment: .leading) {
                        Text("所需食材")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(foodSteps, id: \.self) { food in
                            HStack(spacing: 25) {
                                Text("•")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                Text(food)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 32)
                            .padding(.vertical, -2)
                        }
                    }
                }
                
                // MARK: 料理方法
                if let cookingSteps = cookingSteps {
                    VStack(alignment: .leading) {
                        Text("料理方法")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(Array(cookingSteps.enumerated()), id: \.offset) { index, step in
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
                            .padding(.horizontal, 35) // 内容左右的留白
                            .padding(.vertical, 3) // 上下行距
                        }
                    }
                }
                
                // MARK: 小技巧（如果有）
                if let tips = extractTips(from: aiRecipe.output) {
                    VStack(alignment: .leading) {
                        Text("小技巧")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
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
                                    .padding(.leading, 5)
                                    .lineSpacing(2)
                            }
                            .padding(.horizontal, 35)
                            .padding(.vertical, 3)
                        }
                    }
                }
                
                // MARK: 例外處理 - 智慧食譜
                if foodSteps == nil && cookingSteps == nil {
                    VStack(alignment: .leading) {
                        Text("智慧食譜")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ScrollView {
                            Text(aiRecipe.output)
                                .font(.body)
                                .padding(.horizontal, 25)
                                .padding(.vertical, 10)
                                .lineSpacing(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        )
    }
    
    
    // MARK: body
    var body: some View
    {
        GeometryReader
        { geometry in
            let safeArea = geometry.safeAreaInsets
            let size = geometry.size
            
            // ScrollView 內容
            ZStack(alignment: .topTrailing) {
                if !aiRecipes.isEmpty {
                    ScrollView(.vertical, showsIndicators: false) {
                        // 封面CoverView
                        self.CoverView(safeArea: safeArea, size: size)
                        
                        // 烹飪書CookbookView
                        self.AICookbookView(safeArea: safeArea)
                            .padding(.top)
                    }
                    .coordinateSpace(name: "SCROLL")
                } else {
                    Text("No Recipe Data Available")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                if isEditing {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    editView
                }
            }

            .toolbarBackground(Color("menusheetbackgroundcolor"), for: .navigationBar)
            .toolbar
            {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        VStack {
                            // 固定的編輯按鈕
                            Button(action: {
                                // 直接使用 record.output
                                self.editedFoodSteps = extractFoodSteps(from: aiRecipe.output) ?? []
                                self.editedCookingSteps = extractCookingSteps(from: aiRecipe.output) ?? []
                                isEditing = true
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 25))
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        VStack {
                            Button(action: {
                                toggleAIColmark(U_ID: aiRecipe.U_ID, Recipe_ID: aiRecipe.Recipe_ID, isAICol: !aiRecipe.isAICol) { result in
                                    switch result {
                                    case .success(let message):
                                        DispatchQueue.main.async {
                                            if let index = aiRecipes.firstIndex(where: { $0.Recipe_ID == aiRecipe.Recipe_ID }) {
                                                aiRecipes[index].isAICol.toggle() // 更新收藏狀態
                                            }
                                            print("isAICol Action successful: \(message)")
                                        }
                                    case .failure(let error):
                                        DispatchQueue.main.async {
                                            print("Error toggling AICol: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }) {
                                Image(systemName: aiRecipe.isAICol ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 25))
                                    .foregroundColor(.orange)
                            }
                            .animation(.none)
                        }
                    }
                }
            }
            .onAppear
            {
                fetchUserID
                { userID in
                    guard let userID = userID
                    else
                    {
                        print("Failed to get user ID")
                        return
                    }
                    self.currentUserID = userID
                    loadAICData(for: userID, chatRecords: $aiRecipes, isLoading: $isLoading, loadingError: $loadingError)
                }
            }
        }
    }
    
}
