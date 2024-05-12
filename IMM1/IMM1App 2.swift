//
//  IMM1App.swift
//  IMM1
//
//  Created by Mac on 2024/2/22.
//

import SwiftUI

@main
struct IMM1App: App
    {
        //提供所有View使用的User結構
        @EnvironmentObject var user: User

     

        //控制深淺模式
        @AppStorage("colorScheme") private var colorScheme: Bool = true
    //    @StateObject private var cameraManagerViewModel = CameraManagerViewModel()

    
        var body: some Scene
        {
            WindowGroup
            {
                SigninView()
    //            CameraContentView(cameraManagerViewModel: cameraManagerViewModel)
    //           ContentView()
                    .preferredColorScheme(self.colorScheme ? .light:.dark)
    //              //CoreData連結
    //                .environment(.managedObjectContext, persistenceController.container.viewContext)
                    //提供環境User初始化
                    .environmentObject(User())
            }
        }
    }
