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
    @State private var information: Information = Information(U_Name: "vc", U_Gen: "女性", U_Bir:Date(), H: "161", W: "50", BMI: 19.68, acid: 0.0, sweet: 0.0, bitter: 0.0, hot: 0.0)

//    @State private var information: Information = Information(U_Name: "vc", U_Gen: "女性", U_Bir:Date(), H: "161", W: "50", BMI: 19.68, like1: "0",sweet: "0",bitter: "0",like4: "0")
    

    //    @StateObject private var cameraManagerViewModel = CameraManagerViewModel()
        
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
                    CookView()
                        .tag(2)
                        .tabItem
                    {
                        Label("烹飪", systemImage: "fork.knife")
                    }
                    
                    DynamicView()
                        .tag(3)
                        .tabItem
                    {
                        Label("健康", systemImage: "chart.xyaxis.line")
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
