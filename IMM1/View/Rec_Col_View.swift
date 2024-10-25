//
//  Rec_Col_View.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/14.
//

import SwiftUI

struct Rec_Col_View: View
{
    @State private var aiRecipes: [ChatRecord] = [] // 在此聲明 aiRecipes 狀態變數
    var body: some View
    {
        TabView
        {
            FavoriteView(U_ID: " ")
                .tabItem {
                    Label("我的最愛", systemImage: "heart.fill")
                }
            AIRecipeView(aiRecipes: $aiRecipes, U_ID: " ")
                .tabItem {
                    Label("AI食譜庫", systemImage: "book.pages")
                }
            Custom_recipesView(U_ID: " ")
                .tabItem {
                    Label("自訂食譜庫", systemImage: "book.pages")
                }
        }
    }
}

#Preview
{
    Rec_Col_View()
}
