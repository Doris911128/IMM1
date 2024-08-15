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
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes? = nil
    @State private var isLoading: Bool = true // 加载状态
    @State private var loadingError: String? = nil // 加載错误信息
    
    //func
    func loadAIRData()
    {
        
    }
    
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
                } else if dishesData.isEmpty
                {
                    ZStack
                    {
                        GeometryReader
                        { geometry in
                            VStack
                            {
                                Image("空AI食譜")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 180)
                                    .position(x: geometry.size.width / 2, y: geometry.size.height / 3) // 向上移动图片
                            }
                            VStack
                            {
                                Spacer().frame(height: geometry.size.height / 2) // 向下移动文字
                                VStack
                                {
                                    Text("暫未新增任何AI食譜")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                    NavigationLink(destination: PastRecipesView())
                                    {
                                        Text("前往“過往食譜”添加更多＋＋")
                                            .font(.system(size: 18))
                                            .foregroundColor(.blue).underline()
                                    }
                                    Spacer().frame(height: 300)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else
                {
                    ScrollView(showsIndicators: false)
                    {
                        LazyVStack
                        {
                            ForEach(dishesData, id: \.Dis_ID)
                            { dish in
                                NavigationLink(destination: Recipe_IP_View(U_ID: "", Dis_ID: dish.Dis_ID))
                                {
                                    RecipeBlock(imageName: dish.D_image, title: dish.Dis_Name, U_ID: "", Dis_ID: dish.Dis_ID)
                                }
                                .padding(.bottom, -70)
                            }
                        }
                    }
                }
            }
            .onAppear
            {
                loadAIRData()
            }
        }
    }
}

#Preview {
    AIRecipeView(U_ID:"ofmyRwDdZy")
}
