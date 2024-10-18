//  ContentView.swift
//
//
//
//

// MARK: TabView
import SwiftUI

struct ContentView: View
{
    @AppStorage("signin") private var signin: Bool=false //存取登入狀態
    @State var isDarkMode: Bool = false //切換深淺模式
    @State private var showSide: Bool = false //TabView選擇的頁面
    @State private var select: Int = 0 //跟蹤標籤頁
    
    var body: some View
    {
        NavigationStack
        {
            //            //已登入
            //            if(self.logIn) {
            //                HomeView().transition(.opacity)//原ForumView_231020
            //            //未登入
            //            } else {
            //                SigninView(textselect: .constant(0)).transition(.opacity)
            //            }
            //        }
            //        .ignoresSafeArea(.all)
            ZStack
            {
                TabView(selection: self.$select)
                {
                    //                  HomeView(select: self.$select)
                    
                    PlanView()
                        .tag(0)
                        .tabItem
                    {
                        Label("計畫", systemImage: "calendar")
                    }
                    // MARK: ForumView
                    ShopView()
                        .tag(1)
                        .tabItem
                    {
                        Label("採購", systemImage: "cart")
                    }
                    
                    //                CameraContentView(cameraManagerViewModel: self.cameraManagerViewModel)
                    CookView(U_ID:"ofmyRwDdZy")
                        .tag(2)
                        .tabItem
                    {
                        Label("烹飪", systemImage: "fork.knife")
                    }
                    
                    AIView()
                        .tag(3)
                        .tabItem
                    {
                        Label("AI", systemImage: "brain")
                    }
                    
                    MyView(select: self.$select)
                        .tag(4)
                        .tabItem
                    {
                        Label("設置", systemImage: "gearshape.fill")
                    }
                }
                .tint(Color("BottonColor")) // 點選後的顏色
                
            }
        }
        .ignoresSafeArea(.all)
    }
}
struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        NavigationStack
        {
            ContentView()
        }
    }
}
