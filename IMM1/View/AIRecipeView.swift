//  AIRecipeView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/14.
//

import SwiftUI

struct AIRecipeView: View, AIRecipeP
{
    let U_ID: String // 用於添加收藏
    
    @State var chatRecords: [ChatRecord] = []
    @State private var isLoading: Bool = true // 載入狀態
    @State private var loadingError: String? = nil // 載入錯誤訊息
    
    @State private var currentUserID: String? = nil // 用於保存當前用戶 ID
    
    var data: [ChatRecord]
    {
        chatRecords
    }
    
    // MARK: - AIRecipeP 協議要求的實作方法
    func itemName() -> String
    {
        return chatRecords.first?.input ?? "Unknown AI Recipe"
    }
    
    func itemImageURL() -> URL?
    {
        return nil // AI 食譜通常沒有封面圖片
    }
    
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
    
    func AICookbookView(safeArea: EdgeInsets) -> AnyView
    {
        // 這裡直接呼叫協定擴充中的預設實現，保持程式碼簡潔
        return self.AICookbookView(safeArea: safeArea)
    }
    
    // MARK: AIRecipeView body
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                Text("AI 食譜庫")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                
                if isLoading
                {
                    // 載入中的轉圈動畫
                    VStack {
                        Spacer()
                        ProgressView("載入中...").progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = loadingError
                {
                    VStack
                    {
                        Text("載入失敗: \(error)")
                            .font(.body)
                            .foregroundColor(.red)
                        Spacer().frame(height: 120)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if chatRecords.isEmpty
                {
                    // 當沒有記錄時，顯示空狀態
                    AIEmptyStateView()
                } else
                {
                    ScrollView(showsIndicators: false)
                    {
                        LazyVStack
                        {
                            ForEach(chatRecords)
                            { record in
                                NavigationLink(destination: AIRecipeBlock(U_ID: U_ID, record: record))
                                {
                                    AIR_Block(record: record)
                                }
                                .padding(10)
                            }
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
                    loadAICData(for: userID, chatRecords: $chatRecords, isLoading: $isLoading, loadingError: $loadingError)
                }
            }
        }
    }
}

//MARK: 外部公模板 AIR_Block
struct AIR_Block: View
{
    let record: ChatRecord
    
    var body: some View
    {
        ZStack
        {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 4)
            
            VStack(alignment: .leading)
            {
                HStack
                {
                    Text(record.input)
                        .font(.system(size: 22))
                        .bold()
                    Spacer()
                    Button(action: {
                        toggleAIColmark(U_ID: record.U_ID, Recipe_ID: record.Recipe_ID, isAICol: !record.isAICol) { result in }
                    }) {
                        Image(systemName: record.isAICol ? "bookmark.fill" : "bookmark")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                    .offset(y: -18)
                }
                Text("答：\(String(record.output.prefix(30)))...") // 將 Substring 轉換為 String
                    .foregroundColor(.gray)
            }
            .frame(height: 50)
            .padding()
        }
        .padding(.horizontal)
    }
}

// MARK: 當AI食譜為空 AIEmptyStateView
struct AIEmptyStateView: View
{
    var body: some View
    {
        VStack
        {
            Image("空AI食譜")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
            Text("暫無新增任何AI食譜")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            NavigationLink(destination: AIView())
            {
                Text("前往“AI食譜”添加更多＋＋")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                    .underline()
            }
            Spacer().frame(height: 150)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
//
//#Preview
//{
//    AIRecipeView(U_ID:"hhwWhJvWJk")
//}
