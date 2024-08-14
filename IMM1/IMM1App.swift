//
//  IMM1App.swift
//  IMM1
//
//  Created by Mac on 2024/2/22.
//

import SwiftUI
import Foundation

@main
struct IMM1App: App {
    // 控制深浅模式
    @AppStorage("colorScheme") private var colorScheme: Bool = true
    
    // 提供所有 View 使用的 User 物件
    @StateObject private var user = User()
    
    @State private var showSplash = true // 控制是否顯示 Splash Screen
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView(showSplash: $showSplash)
                    .preferredColorScheme(self.colorScheme ? .light : .dark)
            } else {
                SigninView()
                    .preferredColorScheme(self.colorScheme ? .light : .dark)
                    .environmentObject(user) // 傳遞 User 物件給 SigninView
                    .onAppear {
                        executeAutoPlandeleteRequest()
                    }
            }
        }
    }
    
    // 自動刪除請求
    private func executeAutoPlandeleteRequest() {
        guard let url = URL(string: "http://163.17.9.107/food/php/Auto.php") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response code: \(httpResponse.statusCode)")
            }
            
            if let data = data {
                // 處理回應數據
                print("Response data: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }
        task.resume()
    }
}

// SplashScreenView 放在外部
struct SplashScreenView: View {
    @Binding var showSplash: Bool
    @State private var scale: CGFloat = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        VStack {
            Image("登入Logo") // 使用名稱為“登入Logo”的圖片
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.5)) {
                        self.scale = 1.0
                        self.opacity = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        showSplash = false // 2.5秒後隱藏啟動畫面
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // 你想要的背景顏色
    }
}
