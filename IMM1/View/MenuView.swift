//  MenuView.swift
//  食譜份數暫時未新增因要更動版面
//  立即主食譜顯示+烹飪模式AI

//
//

import SwiftUI
import Foundation

struct MenuView: View, RecipeProtocol
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
            .overlay(
                //MARK: 前往烹飪模式AI按鈕
                VStack
                {
                    Spacer()
                    HStack
                    {
                        Spacer()
                        NavigationLink(destination: CookingAiView())
                        {
                            HStack
                            {
                                ZStack
                                {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 40, height: 40)
                                    
                                    Image("chef-hat-one-2")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                }
                                
                                Text("AI Cooking")
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 10) // 控制按鈕上下內邊距
                            .padding(.horizontal,10) // 控制按鈕左右內邊距
                            .background(Color.orange)
                            .clipShape(CustomCorners(cornerRadius: 30, corners: [.topLeft, .bottomLeft]))
                            .shadow(radius: 10)
                        }
                        .padding(.bottom, 50) // 調整按鈕的垂直位置
                    }
                }
            )
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
                            toggleFavorite(U_ID: U_ID, Dis_ID: Dis_ID, isFavorited: self.isFavorited!) { result in
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
        .onAppear {
            print("顯示的 Dis_ID: \(Dis_ID)")
            loadMenuData()
        }
    }
}

//MARK: 自定義“烹飪模式AI按鈕”圓角方向
struct CustomCorners: Shape
{
    var cornerRadius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path
    {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        return Path(path.cgPath)
    }
}

#Preview
{
    MenuView(U_ID:"ofmyRwDdZy",Dis_ID: 1)
}
