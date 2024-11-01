//  AIRecipeView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/14.
//

import SwiftUI

struct AIRecipeView: View, AIRecipeP {
    @Binding var aiRecipes: [ChatRecord] // 使用傳遞的 aiRecipes
    let U_ID: String // 用於添加收藏
    
    @State var caRecipes: CA_Recipes = CA_Recipes(customRecipes: [], aiRecipes: [])
    @State private var isLoading: Bool = true // 載入狀態
    @State private var loadingError: String? = nil // 載入錯誤訊息
    @State private var currentUserID: String? = nil // 用於保存當前用戶 ID

    var data: [ChatRecord] {
        aiRecipes
    }

    // MARK: - AIRecipeP 協議要求的實作方法
    func itemName() -> String {
        guard let output = aiRecipes.first?.output else {
            return "Unknown AI Recipe"
        }
        return output
    }

    func itemImageURL() -> URL? {
        return nil // AI 食譜通常沒有封面圖片
    }

    func HeaderView(size: CGSize, recordInput: String? = nil) -> AnyView {
        return AnyView(
            Text(itemName())
                .font(.largeTitle)
                .bold()
                .padding()
        )
    }

    func AICookbookView(safeArea: EdgeInsets) -> AnyView {
        return self.AICookbookView(safeArea: safeArea)
    }

    // MARK: AIRecipeView body
    var body: some View {
        NavigationStack {
            VStack {
                Text("AI 食譜庫")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("載入中...").progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = loadingError {
                    VStack {
                        Text("載入失敗: \(error)")
                            .font(.body)
                            .foregroundColor(.red)
                        Spacer().frame(height: 120)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if aiRecipes.isEmpty {
                    AIEmptyStateView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack {
                            ForEach(aiRecipes.indices, id: \.self) { index in
                                NavigationLink(destination: AIRecipeBlock(aiRecipes: $aiRecipes, aiRecipe: aiRecipes[index], U_ID: U_ID)) {
                                    AIR_Block(aiRecipes: $aiRecipes, index: index) // 傳入 aiRecipes 和 index
                                }
                                .padding(10)
                            }
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
                    loadAICData(for: userID, chatRecords: $aiRecipes, isLoading: $isLoading, loadingError: $loadingError)
                }
            }
        }
    }
}

//MARK: 外部公模板 AIR_Block
struct AIR_Block: View {
    @Binding var aiRecipes: [ChatRecord] // 使用 Binding 傳遞 chatRecords
    var index: Int // 對應於 aiRecipes 中的索引

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
            .shadow(radius: 2)
            

            VStack(alignment: .leading) {
                HStack {
                    // 使用 extractRecipeName 方法提取並顯示名稱
                    Text(aiRecipes[index].output.extractRecipeName() ?? "Unknown Recipe Name") // 若提取失敗顯示默認名稱
                        .font(.system(size: 22))
                        .bold()
                    Spacer()
                    Button(action: {
                        toggleAIColmark(U_ID: aiRecipes[index].U_ID, Recipe_ID: aiRecipes[index].Recipe_ID, isAICol: !aiRecipes[index].isAICol) { result in
                            switch result {
                            case .success(let message):
                                DispatchQueue.main.async {
                                    aiRecipes[index].isAICol.toggle() // 更新收藏狀態
                                    print("isAICol Action successful: \(message)")
                                }
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    print("Error toggling AICol: \(error.localizedDescription)")
                                }
                            }
                        }
                    }) {
                        Image(systemName: aiRecipes[index].isAICol ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 25))
                            .foregroundColor(.orange)
                    }
                    .offset(y: -30)
                }
            }
            .frame(height: 50)
            .padding()
        }
        .padding(.horizontal)
    }
}


// MARK: 當AI食譜為空 AIEmptyStateView
struct AIEmptyStateView: View {
    var body: some View {
        VStack {
            Image("空AI食譜")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
            Text("暫無新增任何AI食譜")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            NavigationLink(destination: AIView()) {
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
