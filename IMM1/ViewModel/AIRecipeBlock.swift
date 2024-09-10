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
    
    @State private var isEditing: Bool = false // 控制編輯彈出框顯示
    @State private var editedFoodSteps: [String] = [] // 編輯後的食材
    @State private var editedCookingSteps: [String] = [] // 編輯後的步驟
    @State private var editedTips: [String] = [] // 編輯後的小技巧＆小貼士
    @State private var editedOtherCook: [String] = [] // 編輯後的例外狀況給智慧食譜編輯做改動
    
    // 宣告 focusedXXXXIndex 為 Int? 以追蹤當前的索引
    @State private var focusedFoodIndex: Int? = nil// 新增變量來追蹤哪一個TextField被聚焦_食材
    @State private var focusedCookingIndex: Int? = nil// 步驟
    @State private var focusedOtherIndex: Int? = nil// 智慧食譜
    @State private var focusedFieldIndex: Int? = nil// 小技巧
    
    var data: [ChatRecord]
    {
        [record] // 使用傳遞的單個 record
    }
    
    // MARK: 彈出編輯視圖
    var editView: some View
    {
        VStack(spacing: 20)
        {
            Text("食譜編輯區")
                .font(.title2)
                .bold()
                .padding()
            
            ScrollView
            {
                VStack(spacing: 15)
                {
                    
                    if let foodSteps = extractFoodSteps(from: record.output),
                       let cookingSteps = extractCookingSteps(from: record.output)
                    {
                        // MARK: 食材編輯區塊
                        VStack(alignment: .leading)
                        {
                            Text("所需食材")
                                .foregroundStyle(.orange)
                                .font(.title2)
                                .bold()
                                .padding(.bottom, 5)
                            
                            ForEach(editedFoodSteps.indices, id: \.self)
                            { index in
                                VStack
                                {
                                    HStack(alignment: .top)
                                    {
                                        Text("食材 \(index + 1)")
                                            .font(.system(size: 12))
                                            .bold()
                                            .foregroundColor(.gray)
                                        Spacer()
                                        
                                        // 右上：先前食材 (僅當 TextField 被選中時顯示)
                                        if focusedFoodIndex == index
                                        {
                                            if index < foodSteps.count
                                            {
                                                Text("Before：\(foodSteps[index])")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                            } else
                                            {
                                                Text("無法提取先前食材")
                                                    .font(.system(size: 12))
                                            }
                                        }
                                    }
                                    
                                    // 顯示可編輯的 TextField，並綁定焦點
                                    TextField("更新食材", text: $editedFoodSteps[index])
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                        .onTapGesture
                                    {
                                        focusedFoodIndex = index
                                    }
                                    .onSubmit
                                    {
                                        focusedFoodIndex = nil
                                    }
                                }
                                .padding(.horizontal, 15)
                            }
                            
                            // 新增食材按鈕
                            HStack
                            {
                                Spacer()
                                Button(action: {
                                    editedFoodSteps.append("")
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
                        .padding(.horizontal, 15)
                        
                        
                        // MARK: 料理方法編輯區塊
                        VStack(alignment: .leading)
                        {
                            Text("料理方法")
                                .foregroundStyle(.orange)
                                .font(.title2)
                                .bold()
                                .padding(.bottom, 5)
                            
                            ForEach(editedCookingSteps.indices, id: \.self)
                            { index in
                                VStack
                                {
                                    HStack(alignment: .top)
                                    {
                                        Text("步驟 \(index + 1)")
                                            .font(.system(size: 12))
                                            .bold()
                                            .foregroundColor(.gray)
                                        Spacer()
                                        
                                        if focusedCookingIndex == index
                                        {
                                            if index < cookingSteps.count
                                            {
                                                Text("Before：\(cookingSteps[index])")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                            } else {
                                                Text("無法提取先前步驟")
                                                    .font(.system(size: 12))
                                            }
                                        }
                                    }
                                    TextField("更新烹飪步驟", text: $editedCookingSteps[index])
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                        .onTapGesture
                                    {
                                        focusedCookingIndex = index
                                    }
                                    .onSubmit
                                    {
                                        focusedCookingIndex = nil
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // 新增步驟按鈕
                            HStack
                            {
                                Spacer()
                                Button(action: {
                                    editedCookingSteps.append("")
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
                        .padding(.horizontal, 15)
                    }
                    
                    // MARK: 小技巧編輯區塊
                    if let tips = extractTips(from: record.output)
                    {
                        VStack(alignment: .leading)
                        {
                            Text("小技巧")
                                .foregroundStyle(.orange)
                                .font(.title2)
                                .bold()
                                //.padding(.leading, 20)
                                .padding(.bottom, 5)
                            
                            ForEach(editedTips.indices, id: \.self)
                            { index in
                                VStack
                                {
                                    HStack(alignment: .top)
                                    {
                                        Text("技巧 \(index + 1)")
                                            .font(.system(size: 12))
                                            .bold()
                                            .foregroundColor(.gray)
                                        Spacer()
                                        
                                        if focusedFieldIndex == index
                                        {
                                            Text("Before：\(tips[index])")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    TextField("更新小技巧", text: $editedTips[index])
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                        .onTapGesture
                                    {
                                        focusedFieldIndex = index
                                    }
                                    .onSubmit
                                    {
                                        focusedFieldIndex = nil
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // 新增小技巧按鈕
                            HStack
                            {
                                Spacer()
                                Button(action: {
                                    editedTips.append("")
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
                        .padding(.horizontal, 15)
                    }
                    
                    // MARK: 智慧食譜編輯區塊
                    else
                    {
                        // 如果無法拆分食材或料理方法，顯示完整的 output 並顯示“智慧食譜”
                        VStack(alignment: .leading) 
                        {
                            Text("智慧食譜")
                                .foregroundStyle(.orange)
                                .font(.title2)
                                .bold()
                            
                            // 使用 TextEditor 來編輯智慧食譜區塊
                            TextEditor(text: Binding(
                                get: 
                                {
                                    // 將 Array 轉換為單一的 String 來顯示
                                    editedOtherCook.joined(separator: "\n")
                                },
                                set: 
                                { newValue in
                                    // 當編輯後的文本改變時，重新分割回 Array
                                    editedOtherCook = newValue.split(separator: "\n").map(String.init)
                                }
                            ))
                            .font(.body)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2)) // 灰底效果
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity, minHeight: 400, alignment: .leading)
                            .scrollContentBackground(.hidden)  // 背景
                            // 當 TextEditor 點擊時，更新 focusedOtherIndex
                            .onTapGesture
                            {
                                focusedOtherIndex = 999 // 假設 999 代表 TextEditor 的特定聚焦狀態
                            }

                            // 如果 TextEditor 被選中，顯示先前的智慧食譜內容
                            if focusedOtherIndex == 999
                            {
                                Text("先前智慧食譜：")
                                    .font(.body)
                                    .bold()
                                    .padding(.top, 10)
                                    .padding(.bottom,10)
                                
                                // 顯示 record.output 的內容
                                Text(record.output)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                    .lineSpacing(5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 15)
                    }
                }
            }
            
            
            // MARK: 確認和取消按鈕
            HStack
            {
                Button(action: {
                    isEditing = false // 關閉編輯
                })
                {
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
                })
                {
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
        .padding()//左右
        
        .onAppear
        {
            if editedTips.isEmpty, let tips = extractTips(from: record.output)
            {
                editedTips = tips
            }
            editedOtherCook = record.output.split(separator: "\n").map(String.init) ?? []
        }
        
    }
    
    // MARK: - 更新數據模型
    private func applyEdits()
    {
        // 將編輯後的內容應用到數據模型中
        print("Edited food steps: \(editedFoodSteps)")
        print("Edited cooking steps: \(editedCookingSteps)")
        print("Edited tips: \(editedTips)")
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
                // 食譜顯示內容
                if let foodSteps = extractFoodSteps(from: record.output),
                   let cookingSteps = extractCookingSteps(from: record.output)
                {
                    // MARK: 顯示食材
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
                    
                    // MARK: 料理方法
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
                    
                    // MARK: 小技巧（如果有）
                    if let tips = extractTips(from: record.output)
                    {
                        VStack(alignment: .leading)
                        {
                            Text("小技巧")
                                .foregroundStyle(.orange)
                                .font(.title2)
                                .bold()
                                .padding(.leading, 20)
                            
                            ForEach(Array(tips.enumerated()), id: \.offset)
                            { index, tip in
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
                } else// MARK: 例外處理 - 智慧食譜
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
    
    // MARK: body
    var body: some View
    {
        GeometryReader
        { geometry in
            let safeArea = geometry.safeAreaInsets
            let size = geometry.size
            
            // ScrollView 內容
            ZStack(alignment: .topTrailing)
            {
                if let record = chatRecords.first
                {
                    ScrollView(.vertical, showsIndicators: false)
                    {
                        // 封面CoverView
                        self.CoverView(safeArea: safeArea, size: size)
                        
                        // 烹飪書CookbookView
                        self.AICookbookView(safeArea: safeArea)
                            .padding(.top)
                    }
                    .coordinateSpace(name: "SCROLL")
                } else
                {
                    Text("No Recipe Data Available")
                        .foregroundColor(.gray)
                        .padding()
                }
                
                // 固定的編輯按鈕
                Button(action: {
                    // 打開編輯彈出框
                    self.editedFoodSteps = extractFoodSteps(from: record.output) ?? []
                    self.editedCookingSteps = extractCookingSteps(from: record.output) ?? []
                    isEditing = true
                    
                })
                {
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .padding()
                        .background(Color.white.opacity(0.9))  // 背景色和圓形
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .offset(y: 600) // 這裡可以調整按鈕距離頂部的高度，根據你的需求調整
                
                if isEditing
                {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    editView
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
    
}


