//  過往食譜點進去後出現的單篇食譜畫面

//  食譜份數暫時未新增因要更動版面
//  食譜內頁顯示(食譜圖片、煮法、食材數量)
//  Recipe_IP.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/5/12.
//

import SwiftUI
import Foundation

struct Recipe_IP_View: View, RecipeProtocol
{
    let U_ID: String // 用於添加我的最愛
    let Dis_ID: Int // 用於添加我的最愛
    
    @State var isFavorited: Bool? = nil // 使用可选值
    
    @State var dishesData: [Dishes] = []
    @State var foodData: [Food] = []
    @State var amountData: [Amount] = []
    
    @State var cookingMethod: String? // 新增一個狀態來儲存從URL加載的烹飪方法
    @State var selectedDish: Dishes?
    
    // MARK: body
    var body: some View
    {
        GeometryReader
        {
            let safeArea: EdgeInsets=$0.safeAreaInsets //當前畫面的safeArea
            let size: CGSize=$0.size //GeometryReader的大小
            
            ScrollView(.vertical, showsIndicators: false)
            {
                VStack
                {
                    // MARK: CoverView
                    self.CoverView(safeArea: safeArea, size: size)
                    
                    // MARK: CookbookView
                    self.CookbookView(safeArea: safeArea).padding(.top)
                    
                    // MARK: HeaderView
                    self.HeaderView(size: size)
                }
            }
            .coordinateSpace(name: "SCROLL") //抓取ScrollView的各項數值
        }
        .toolbarBackground(Color("menusheetbackgroundcolor"), for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing)
            {
                Button(action: {
                    withAnimation(.easeInOut.speed(3)) 
                    {
                        if let isFavorited = isFavorited 
                        {
                            self.isFavorited = !isFavorited
                            toggleFavorite(U_ID: U_ID, Dis_ID: Dis_ID, isFavorited: self.isFavorited!) 
                            { result in
                                switch result 
                                {
                                case .success(let responseString):
                                    print("Success: \(responseString)")
                                case .failure(let error):
                                    print("Error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }) {
                    Image(systemName: (isFavorited ?? false) ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
                .animation(.none)
            }
        }
        .onAppear
        {
            print("顯示的 Dis_ID: \(Dis_ID)")
            loadMenuData()
        }
    }
}

#Preview
{
    Recipe_IP_View(U_ID:"ofmyRwDdZy",Dis_ID: 1)
}
