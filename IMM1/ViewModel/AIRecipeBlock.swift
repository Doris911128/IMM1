//
//  AIRecipeBlock.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/9/2.
//


import SwiftUI
import Foundation

struct AIRecipeBlock: View, AIRecipeP
{
    let U_ID: String // 用於添加收藏
    let record: ChatRecord // 傳遞進來的單個 ChatRecord
    
    @State var chatRecords: [ChatRecord] = []
    @State private var isLoading: Bool = true // 載入狀態
    @State private var loadingError: String? = nil // 加載錯誤訊息
    
    @State private var currentUserID: String? = nil // 用於保存當前用戶 ID
    
    var data: [ChatRecord]
    {
        [record] // 使用傳遞的單個 record
    }
    
    // MARK: - AIRecipeP 協議要求的實作方法
    func itemName() -> String
    {
        return record.input ?? "Unknown AI Recipe"
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
    func AICookbookView(safeArea: EdgeInsets) -> AnyView
    {
        return AnyView(
            VStack(spacing: 18) 
            {
                if let foodSteps = extractFoodSteps(from: record.output),
                   let cookingSteps = extractCookingSteps(from: record.output)
                {
                    // 顯示食材
                    VStack(alignment: .leading)
                    {
                        Text("所需食材")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(foodSteps, id: \.self)
                        { food in
                            HStack(spacing:25)
                            {
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
                    
                    // 顯示料理方法
                    VStack(alignment: .leading)
                    {
                        Text("料理方法")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(Array(cookingSteps.enumerated()), id: \.offset)
                        { index, step in
                            HStack(alignment: .top)
                            {
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
                            .padding(.horizontal, 35) //内容左右的留白
                            .padding(.vertical, 3) //上下行距
                        }
                    }
                    
                    // 顯示小技巧（如果有）
                    if let tips = extractTips(from: record.output)
                    {
                        VStack(alignment: .leading)
                        {
                            Text("小技巧")
                                .foregroundStyle(.orange)
                                .font(.title2)
                                .bold()
                                .padding(.leading, 20)
                            
                            ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                                HStack(alignment: .top) 
                                {
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
                } else
                {
                    // 如果無法拆分食材或料理方法，顯示完整的 output 並顯示“智慧食譜”
                    VStack(alignment: .leading)
                    {
                        Text("智慧食譜")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ScrollView
                        {
                            Text(record.output)
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
    
    // MARK: 拆分[食材]
    func extractFoodSteps(from output: String) -> [String]?
    {
        guard let foodStartRange = output.range(of: "食材：") ?? output.range(of: "材料：") 
        else
        {
            print("找不到 '食材' 或 '材料' 的標題")
            return nil
        }
        
        // 找到 '作法：', '步驟：', '做法：' 或文末結束的位置
        let end = output.range(of: "作法：")?.lowerBound ??
        output.range(of: "步驟：")?.lowerBound ??
        output.range(of: "做法：")?.lowerBound ??
        output.endIndex
        
        let foodContent = String(output[foodStartRange.upperBound..<end])
        
        // 分割並清理每一行的內容
        let steps = foodContent.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        // 調試打印
        if steps.isEmpty 
        {
            print("食材步驟拆分失敗，找不到任何有效的食材")
        }
        
        return steps.isEmpty ? nil : steps
    }
    
    // MARK: 拆分[料理方法]
    func extractCookingSteps(from output: String) -> [String]? 
    {
        guard let methodStartRange = output.range(of: "作法：") ??
                output.range(of: "步驟：") ??
                output.range(of: "做法：") 
        else
        {
            print("找不到 '作法'、'步驟' 或 '做法' 的標題")
            return nil
        }
        
        // 找到 '小技巧：', '小貼士：', 'isAICol' 或文末的結束位置
        let end = output.range(of: "小技巧：")?.lowerBound ??
        output.range(of: "小貼士：")?.lowerBound ??
        output.range(of: "isAICol")?.lowerBound ??
        output.endIndex
        
        let methodContent = String(output[methodStartRange.upperBound..<end])
        
        let steps = methodContent.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        // 調試打印
        if steps.isEmpty 
        {
            print("料理步驟拆分失敗，找不到任何有效的步驟")
        }
        
        return steps.isEmpty ? nil : steps
    }
    
    
    // MARK: 拆分[小技巧＆小貼士]
    // 提取 "小技巧：" 或 "小貼士：" 後的內容
    func extractTips(from output: String) -> [String]? {
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
    
    // MARK: body
    var body: some View
    {
        GeometryReader
        { geometry in
            let safeArea = geometry.safeAreaInsets
            let size = geometry.size
            
            if let record = chatRecords.first
            {
                ScrollView(.vertical, showsIndicators: false)
                {
                    VStack
                    {
                        // 封面CoverView
                        self.CoverView(safeArea: safeArea, size: size)
                        
                        // 烹飪書CookbookView
                        self.AICookbookView(safeArea: safeArea).padding(.top)
                        
                        // 標題HeaderView
                        //self.HeaderView(size: size)
                    }
                }
                .coordinateSpace(name: "SCROLL")
            } else
            {
                Text("No Recipe Data Available")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .toolbarBackground(Color("menusheetbackgroundcolor"), for: .navigationBar)
        .toolbar 
        {
            ToolbarItem(placement: .navigationBarTrailing)
            {
                Button(action: {
                    withAnimation(.easeInOut.speed(3)) 
                    {
                        toggleAIColmark(U_ID: record.U_ID, Recipe_ID: record.Recipe_ID, isAICol: !record.isAICol) 
                        { result in
                            switch result 
                            {
                            case .success(let message):
                                print("isAICol Action successful: \(message)")
                            case .failure(let error):
                                print("Error toggling AICol: \(error.localizedDescription)")
                            }
                        }
                    }
                }) {
                    Image(systemName: record.isAICol ? "bookmark.fill" : "bookmark")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
                .animation(.none)
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
                loadAICData(for: userID, chatRecords: $chatRecords, isLoading: $isLoading, loadingError: $loadingError)
            }
        }
    }
}
