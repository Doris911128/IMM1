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
    
    var data: [ChatRecord]
    {
        [aiRecipe] // 使用傳遞的單個 record
    }
    
    // MARK: 拆分[食材]
    func extractFoodSteps(from output: String) -> [String]? {
        // 所有可能的「食材」標題
        let foodTitles = ["所需材料", "原料", "材料", "食材"]
        
        // 查找開始的食材範圍
        guard let foodStartRange = foodTitles.compactMap({ output.range(of: $0) }).first 
        else {
            print("找不到食材的標題")
            return nil
        }
        
        // 所有可能的「料理方法」標題
        let methodTitles = ["作法", "指示", "做法", "製作方法", "製作步驟"]
        
        // 查找料理方法的結束範圍
        let end = methodTitles.compactMap { output.range(of: $0)?.lowerBound }.first ?? output.endIndex
        
        // 確保範圍有效
        guard foodStartRange.upperBound <= end 
        else {
            print("Error: 範圍無效，請確認標題")
            return nil
        }
        
        // 抽取並清理內容
        let foodContent = String(output[foodStartRange.upperBound..<end])
        let steps = foodContent.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if steps.isEmpty {
            print("找不到有效的食材")
        }
        
        return steps.isEmpty ? nil : steps
    }
    
    
    // MARK: 拆分[料理方法]
    func extractCookingSteps(from output: String) -> [String]? {
        // 查找料理方法的標題，新增“製作方法”的條件
        guard let methodStartRange = output.range(of: "作法") ??
                output.range(of: "指示") ??
                output.range(of: "做法") ??
                output.range(of: "製作步驟") ??
                output.range(of: "製作方法") else {
            print("找不到 '作法'、'指示'、'做法'、'製作步驟' 或 '製作方法' 的標題")
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
        // 嘗試從 output 中提取名稱
        if let extractedName = aiRecipe.output.extractRecipeName() {
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
            }
            
            .toolbarBackground(Color("menusheetbackgroundcolor"), for: .navigationBar)
            .toolbar
            {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
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
