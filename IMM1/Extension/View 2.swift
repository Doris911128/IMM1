//
//  View.swift
//  Graduation_Project
//
//  Created by Mac on 2023/8/21.
//

// MARK: 須額外新增名為“Extension”的資料夾 存放自建方法
//.limitInput(text: $account, max: 12,min: 4) -> 限制最小字數為 4 最大字數為 12
//.limitInput(text: $account, max: 20) -> 只限制最大值 不限制最小值
//.lineLimit(10) -> 限制字串行數

import SwiftUI

extension View
{
    func sendBMIData(height: Double, weight: Double, php: String) {
        // 构建URL，包含查询参数
        let urlString = "http://163.17.9.107/food/BMI.php?height=\(height)&weight=\(weight)"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // 修改为GET请求

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status code: \(httpResponse.statusCode)")
            }
            if let error = error {
                print("Error sending data: \(error)")
            } else {
                // 如果需要处理返回的数据，可以在这里添加代码
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
                print("Data received successfully")
            }
        }.resume()
    }

    func limitInput(text: Binding<String>, max: Int) -> some View
    {
        self.modifier(TextLimit(text: text, max: max))
    }

}
struct TextLimit: ViewModifier
{
    @Binding var text: String

    var max: Int
    //舉例：Text("").font(.largeTitle)
    func body(content: Content) -> some View
    {
        content.onReceive(self.text.publisher.collect())
        {
            text=String($0.prefix(max))
        }
    }
}
