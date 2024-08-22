//
//  AIRecipeView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/14.
//

import SwiftUI

struct AIRecipeView: View
{
    let U_ID: String // 用於添加收藏
    
    @State private var chatRecords: [ChatRecord] = []
    @State private var isLoading: Bool = true // 加载状态
    @State private var loadingError: String? = nil // 加載错误信息
    
    @State private var currentUserID: String? = nil // 用於保存當前用戶 ID
    
    // 加载用户收藏的 AI 生成的食谱数据
    func loadAICData(for userID: String)
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/GetAIC.php?U_ID=\(userID)") else
        {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error
            {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data
            else
            {
                print("No data received")
                return
            }
            
            // 打印接收到的原始 JSON 数据
            if let jsonString = String(data: data, encoding: .utf8)
            {
                print("Raw JSON: \(jsonString)")
            }
            
            // 解码 JSON 响应
            do
            {
                let decoder = JSONDecoder()
                let records = try decoder.decode([ChatRecord].self, from: data)
                
                // 更新 UI 並打印記錄數量
                DispatchQueue.main.async
                {
                    print("Decoded \(records.count) records")
                    self.chatRecords = records
                    self.isLoading = false
                }
            } catch
            {
                DispatchQueue.main.async
                {
                    self.loadingError = "Failed to decode JSON: \(error.localizedDescription)"
                    self.isLoading = false
                    print("Decoding error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    // MARK: body
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                Text("AI食譜庫")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                
                // 以下部分的逻辑保持不变，以确保程序运行稳定
                if isLoading
                {
                    //MARK: 想要載入中轉圈圈動畫
                    VStack
                    {
                        Spacer()
                        ProgressView("載入中...").progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = loadingError
                {
                    VStack
                    {
                        Text("載入失敗: \(error)").font(.body).foregroundColor(.red)
                        Spacer().frame(height: 120)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else
                if chatRecords.isEmpty
                {
                    AIEmptyStateView()
                } else
                {
                    ScrollView(showsIndicators:false)
                    {
                        LazyVStack
                        {
                            ForEach(chatRecords)
                            { record in
                                NavigationLink(destination: DetailedRecipeView(record: record))
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
                fetchUserID { userID in
                    guard let userID = userID
                    else
                    {
                        print("Failed to get user ID")
                        return
                    }
                    self.currentUserID = userID
                    loadAICData(for: userID) // 加载数据
                }
            }
        }
    }
}

//MARK: 外部公模板
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
                Text("答：\(String(record.output.prefix(30)))...") // 将 Substring 转换为 String
                    .foregroundColor(.gray)
            }
            .frame(height: 50)
            .padding()
        }
        .padding(.horizontal)
    }
}

//MARK: 載入的詳細視圖
struct DetailedRecipeView: View
{
    let record: ChatRecord // 傳遞進來的單個 ChatRecord
    
    var body: some View
    {
        VStack(alignment: .leading)
        {
            HStack
            {
                Spacer()
                Button(action: {
                    toggleAIColmark(U_ID: record.U_ID, Recipe_ID: record.Recipe_ID, isAICol: !record.isAICol) { result in
                        switch result
                        {
                        case .success(let message):
                            print("isAICol Action successful: \(message)")
                        case .failure(let error):
                            print("Error toggling AICol: \(error.localizedDescription)")
                        }
                    }
                })
                {
                    Image(systemName: record.isAICol ? "bookmark.fill" : "bookmark")
                        .font(.title)
                        .foregroundColor(.red)
                }
                .offset(y: -22)
            }
            Text(record.output)
                .foregroundColor(.gray)
                .padding(.top, 10)
        }
        .padding()
        .navigationBarTitle(record.input, displayMode: .inline)
    }
}

// MARK: 當AI食譜為空
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview
{
    AIRecipeView(U_ID:"hhwWhJvWJk")
}
