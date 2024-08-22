// 按下愛心食譜匯入資料庫暫時未成功！
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
    func sendBMIData(height: Double, weight: Double, php: String)
    {
        // 构建URL，包含查询参数
        let urlString = "http://163.17.9.107/food/php/BMI.php?height=\(height)&weight=\(weight)"
        guard let url = URL(string: urlString)
        else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // 修改为GET请求
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse
            {
                print("HTTP Status code: \(httpResponse.statusCode)")
            }
            if let error = error
            {
                print("Error sending data: \(error)")
            } else
            {
                // 如果需要处理返回的数据，可以在这里添加代码
                if let data = data, let responseString = String(data: data, encoding: .utf8)
                {
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
    
    // MARK: 愛心toggle
    func toggleFavorite(U_ID: String, Dis_ID: Int, isFavorited: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/php/Favorite.php") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyData = "Dis_ID=\(Dis_ID)&isFavorited=\(isFavorited ? 1 : 0)&U_ID=\(U_ID)"
        request.httpBody = bodyData.data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let statusError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                completion(.failure(statusError))
                return
            }
            
            if httpResponse.statusCode == 200 {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    completion(.success(responseString))
                } else {
                    let dataError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    completion(.failure(dataError))
                }
            } else {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Server error response: \(responseString)")
                }
                let serverError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
                completion(.failure(serverError))
            }
        }.resume()
    }
    
    // MARK: 檢查菜品是否已被收藏的方法
    func checkIfFavorited(U_ID: String, Dis_ID: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/php/Favorite.php?U_ID=\(U_ID)&Dis_ID=\(Dis_ID)") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                let dataError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(dataError))
                return
            }
            
            if responseString.contains("\"favorited\":true") {
                completion(.success(true))
            } else {
                completion(.success(false))
            }
        }.resume()
    }
    
    
    //MARK: 從伺服器獲取用戶的唯一 ID (U_ID)給ai歷史用
    func fetchUserID(completion: @escaping (String?) -> Void)
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/getUserID.php")
        else
        {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error
            {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data
            else
            {
                print("No data received")
                completion(nil)
                return
            }
            
            do
            {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
                let uID = json?["U_ID"]
                completion(uID)
            } catch
            {
                print("Decoding error: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
    
    // MARK: 切換根據收藏狀態切換按鈕顯示
    func toggleAIColmark(U_ID: String, Recipe_ID: Int, isAICol: Bool, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/php/UpdateAICol.php") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyData = "U_ID=\(U_ID)&Recipe_ID=\(Recipe_ID)&isAICol=\(isAICol ? 1 : 0)"
        request.httpBody = bodyData.data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let statusError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                completion(.failure(statusError))
                return
            }
            
            if httpResponse.statusCode == 200 {
                if let data = data {
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let message = jsonResponse["message"] as? String {
                            completion(.success(message))
                        } else {
                            let parseError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])
                            completion(.failure(parseError))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                } else {
                    let dataError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    completion(.failure(dataError))
                }
            } else {
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Server error response: \(responseString)")
                }
                let serverError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
                completion(.failure(serverError))
            }
        }.resume()
    }

    // MARK: 檢查收藏狀態
    func checkAIColed(U_ID: String, Recipe_ID: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/php/GetRecipe1.php?U_ID=\(U_ID)&Recipe_ID=\(Recipe_ID)") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                let dataError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(dataError))
                return
            }
            
            print("Raw response string: \(responseString)") // 添加這行來調試
            
            if responseString.contains("\"isAICol\":true") {
                completion(.success(true))
            } else {
                completion(.success(false))
            }
        }.resume()
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
