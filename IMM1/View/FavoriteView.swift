//
//  Favorite.swift
//
//  Created on 2023/8/18.
//

// MARK: 最愛View
import SwiftUI

struct FavoriteView: View 
{
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes? = nil  // 用於存儲用戶選擇的菜品資訊
    
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                Text("我的最愛")
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
//    var body: some View
//    {
//        ScrollView 
//        {
//            VStack(spacing: 20) 
//            {
//                ForEach(0..<10) 
//                { _ in
//                    VStack(alignment: .leading)
//                    {
//                        HStack {
//                            Circle() //頭像
//                                .fill(Color(.systemGray3))
//                                .frame(width: 50)
//                            Text("收藏料理") //收藏料理
//                                .font(.title3)
//                                .foregroundColor(.black)
//                        }
//                        Text("料理作法") //料理作法
//                            .font(.title2)
//                            .foregroundColor(.black)
//                            .padding(10)
//                            .frame(maxWidth: .infinity)
//                            .background(Color(.systemGray3))
//                            .cornerRadius(30)
//                    }
//                }
//            }
//            .padding()
//        }
//        .scrollIndicators(.hidden)
//    }
    
    
}

struct FavoriteView_Previews: PreviewProvider 
{
    static var previews: some View 
    {
        ContentView()
    }
}
