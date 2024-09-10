//
//  CRecipeDetailBlock.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/9/10.
//

import SwiftUI

// CRecipeDetailBlock 符合 CRecipeP 協議
struct CRecipeDetailBlock: View, CRecipeP {
    @Binding var recipe: Recipe // 使用 @Binding 來允許修改 recipe
    var data: [Recipe] // 全部的食譜數據
    var U_ID: String // 假設需要用戶ID

    // MARK: - 必須實現的 CRecipeP 協議方法
    func itemName() -> String {
        return recipe.name
    }
    
    func itemImageURL() -> URL? {
        return nil // 用戶自建食譜沒有圖片
    }

    func CCookbookView(safeArea: EdgeInsets) -> AnyView {
        AnyView(
            VStack(spacing: 18) {
                VStack(alignment: .leading) {
                    Text("所需食材")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 20)

                    ForEach(recipe.ingredients.split(separator: "\n").map { String($0) }, id: \.self) { ingredient in
                        Text("• \(ingredient)")
                            .font(.body)
                            .padding(.horizontal, 20)
                    }
                }

                VStack(alignment: .leading) {
                    Text("製作方法")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 20)

                    ForEach(recipe.method.split(separator: "\n").map { String($0) }, id: \.self) { step in
                        HStack {
                            Text("•")
                                .font(.body)
                                .bold()
                                .foregroundColor(.orange)

                            Text(step)
                                .font(.body)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            let size = geometry.size

            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    // 顯示封面
                    CoverView(safeArea: safeArea, size: size)

                    // 烹飪書視圖
                    CCookbookView(safeArea: safeArea)
                        .padding(.top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(action: {
                    // 編輯模式邏輯
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

