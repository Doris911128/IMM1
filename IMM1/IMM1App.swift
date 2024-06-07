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
    // 提供所有 View 使用的 User 结构
    @EnvironmentObject var user: User

    // 控制深浅模式
    @AppStorage("colorScheme") private var colorScheme: Bool = true

    var body: some Scene {
        WindowGroup {
            SigninView()
                .preferredColorScheme(self.colorScheme ? .light:.dark)
                .environmentObject(User())
                .onAppear {
                    // 在 SigninView 出現后執行自動刪除請求
                    executeAutoPlandeleteRequest()
                }
        }
    }
    private func executeAutoPlandeleteRequest() {
        guard let url = URL(string: "http://163.17.9.107/food/Auto.php") else {
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
                // Handle the response data here
                print("Response data: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }

        task.resume()
    }

}

