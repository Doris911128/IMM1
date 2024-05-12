//  過往食譜
//  PastRecipesView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/5/12.
//
import SwiftUI

struct PastRecipesView: View 
{
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes? = nil  // 用於存儲用戶選擇的菜品資訊

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
                    LazyVStack {
                        ForEach(dishesData, id: \.Dis_ID) 
                        { dish in
                            NavigationLink(destination: MenuView(Dis_ID: dish.Dis_ID)) 
                            {
                                RecipeBlock(imageName: dish.D_image, title: dish.Dis_Name)
                            }
                            .padding(.bottom, 10)
                        }
                    }
                }
            }
            .onAppear {
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
