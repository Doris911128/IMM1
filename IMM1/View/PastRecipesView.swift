//  過往食譜
//  PastRecipesView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/5/12.
//
import SwiftUI

struct PastRecipesView: View 
{
    @AppStorage("U_ID") private var U_ID: String = "" // 从 AppStorage 中读取 U_ID
    
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes? = nil  // 用於存儲用戶選擇的菜品資訊

    //let U_ID: Int //用於添加我的最愛
    //let Dis_ID: Int //用於添加我的最愛
    
    var body: some View
    {
        NavigationStack
        {
            VStack 
            {
                Text("過往食譜")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)

                //MARK: 料理顯示區
                ScrollView(showsIndicators: false) 
                {
                    LazyVStack 
                    {
                        ForEach(dishesData, id: \.Dis_ID)
                        { dish in
                            // 為每道菜點擊後導航至 Recipe_IP_View
                            NavigationLink(destination: Recipe_IP_View(Dis_ID: dish.Dis_ID))
                            {
                                RecipeBlock(
                                    imageName: dish.D_image,
                                    title: dish.Dis_Name,
                                    U_ID: U_ID,
                                    Dis_ID: "\(dish.Dis_ID)" // 确保 Dis_ID 是字符串
                                )
                            }
                            .padding(.bottom, 10)
                        }
                    }
                }
            }
            .onAppear 
            {
                DishService.loadDishes
                { dishes in
                    self.dishesData = dishes
                }
            }
        }
    }
}

#Preview
{
    PastRecipesView()
}
