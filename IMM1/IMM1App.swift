//
//  IMM1App.swift
//  IMM1
//
//  Created by Mac on 2024/2/22.
//

import SwiftUI
import Foundation

@main
struct IMM1App: App
{
    // 控制深浅模式
    @AppStorage("colorScheme") private var colorScheme: Bool = true
    
    // 提供所有 View 使用的 User 物件
    @StateObject private var user = User()
    
    var body: some Scene
    {
        WindowGroup
        {
            SigninView()
                .preferredColorScheme(self.colorScheme ? .light : .dark)
                .environmentObject(user) // 傳遞 User 物件給 SigninView
                .onAppear
            {
                // 在 SigninView 出現后執行自動刪除請求
                executeAutoPlandeleteRequest()
            }
        }
    }
    
    private func executeAutoPlandeleteRequest() 
    {
        guard let url = URL(string: "http://163.17.9.107/food/Auto.php") 
        else
        {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) 
        { data, response, error in
            if let error = error
            {
                print("Error: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse 
            {
                print("Response code: \(httpResponse.statusCode)")
            }
            
            if let data = data 
            {
                // 處理回應數據
                print("Response data: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }
        task.resume()
    }
}
