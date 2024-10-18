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
        // 建構URL，包含查詢參數
        let urlString = "http://163.17.9.107/food/php/BMI.php?height=\(height)&weight=\(weight)"
        guard let url = URL(string: urlString)
        else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // 修改为GET請求
        
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
                // 處理返回數據
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
    func toggleFavorite(U_ID: String, Dis_ID: Int, isFavorited: Bool, completion: @escaping (Result<String, Error>) -> Void)
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/Favorite.php")
        else
        {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyData = "Dis_ID=\(Dis_ID)&isFavorited=\(isFavorited ? 1 : 0)&U_ID=\(U_ID)"
        request.httpBody = bodyData.data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error
            {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse
            else
            {
                let statusError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                completion(.failure(statusError))
                return
            }
            
            if httpResponse.statusCode == 200
            {
                if let data = data, let responseString = String(data: data, encoding: .utf8)
                {
                    completion(.success(responseString))
                } else
                {
                    let dataError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    completion(.failure(dataError))
                }
            } else
            {
                if let data = data, let responseString = String(data: data, encoding: .utf8)
                {
                    print("Server error response: \(responseString)")
                }
                let serverError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
                completion(.failure(serverError))
            }
        }.resume()
    }
    
    // MARK: 檢查菜品是否已被收藏的方法
    func checkIfFavorited(U_ID: String, Dis_ID: String, completion: @escaping (Result<Bool, Error>) -> Void)
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/Favorite.php?U_ID=\(U_ID)&Dis_ID=\(Dis_ID)")
        else
        {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error
            {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let responseString = String(data: data, encoding: .utf8)
            else
            {
                let dataError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(dataError))
                return
            }
            
            if responseString.contains("\"favorited\":true")
            {
                completion(.success(true))
            } else
            {
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
        
        URLSession.shared.dataTask(with: url)
        { data, response, error in
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
    
    // MARK: 根據收藏狀態切換ai按鈕顯示
    func toggleAIColmark(U_ID: String, Recipe_ID: Int, isAICol: Bool, completion: @escaping (Result<String, Error>) -> Void)
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/UpdateAICol.php")
        else
        {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyData = "U_ID=\(U_ID)&Recipe_ID=\(Recipe_ID)&isAICol=\(isAICol ? 1 : 0)"
        request.httpBody = bodyData.data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request)
        { data, response, error in
            if let error = error
            {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse
            else
            {
                let statusError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                completion(.failure(statusError))
                return
            }
            
            if httpResponse.statusCode == 200
            {
                if let data = data
                {
                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let message = jsonResponse["message"] as? String
                        {
                            completion(.success(message))
                        } else
                        {
                            let parseError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])
                            completion(.failure(parseError))
                        }
                    } catch
                    {
                        completion(.failure(error))
                    }
                } else
                {
                    let dataError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    completion(.failure(dataError))
                }
            } else
            {
                if let data = data, let responseString = String(data: data, encoding: .utf8)
                {
                    print("Server error response: \(responseString)")
                }
                let serverError = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
                completion(.failure(serverError))
            }
        }.resume()
    }
    
    // MARK: 檢查ai收藏狀態
    func checkAIColed(U_ID: String, Recipe_ID: Int, completion: @escaping (Result<Bool, Error>) -> Void)
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/GetRecipe1.php?U_ID=\(U_ID)&Recipe_ID=\(Recipe_ID)")
        else
        {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request)
        { data, response, error in
            if let error = error
            {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let responseString = String(data: data, encoding: .utf8)
            else
            {
                let dataError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(dataError))
                return
            }
            
            print("Raw response string: \(responseString)") // 添加這行來調試
            
            if responseString.contains("\"isAICol\":true")
            {
                completion(.success(true))
            } else
            {
                completion(.success(false))
            }
        }.resume()
    }
    
    // MARK: 加載收藏的 AI 生成的食譜數據
    func loadAICData(
        for userID: String,
        chatRecords: Binding<[ChatRecord]>,
        isLoading: Binding<Bool>,
        loadingError: Binding<String?>
    )
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/GetAIC.php?U_ID=\(userID)")
        else
        {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error
            {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async
                {
                    loadingError.wrappedValue = "Failed to load data: \(error.localizedDescription)"
                    isLoading.wrappedValue = false
                }
                return
            }
            
            guard let data = data
            else
            {
                print("No data received")
                DispatchQueue.main.async
                {
                    loadingError.wrappedValue = "No data received"
                    isLoading.wrappedValue = false
                }
                return
            }
            
            // 打印接收到的原始 JSON 数据
            if let jsonString = String(data: data, encoding: .utf8)
            {
                print("Raw JSON: \(jsonString)")
            }
            
            // 解码 JSON 响应
            do
            {
                let decoder = JSONDecoder()
                let records = try decoder.decode([ChatRecord].self, from: data)
                
                // 更新 UI 並打印記錄數量
                DispatchQueue.main.async
                {
                    print("Decoded \(records.count) records")
                    chatRecords.wrappedValue = records
                    isLoading.wrappedValue = false
                }
            } catch
            {
                DispatchQueue.main.async
                {
                    loadingError.wrappedValue = "Failed to decode JSON: \(error.localizedDescription)"
                    isLoading.wrappedValue = false
                    print("Decoding error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    // MARK: 更新ai和自訂食譜數據
    // 假設是用 URLSession 發送 API 請求來更新資料
    func updateRecipeData(parameters: [String: Any], completion: @escaping (Bool) -> Void) {
        // 在此編寫你與後端互動的邏輯，像是 API 請求的實現
        // 例如：
        guard let url = URL(string: "http://163.17.9.107/food/php/update") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
        } catch {
            print("Failed to encode JSON")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error)")
                completion(false)
                return
            }
            
            // 檢查回應的狀態碼，這裡假設成功的狀態碼是 200
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
    
    // MARK: - 上傳圖片功能
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/php/upload_recipe_image.php") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image data error"])))
            return
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let data = data, let response = try? JSONDecoder().decode([String: String].self, from: data), let imageUrl = response["imageUrl"] {
                completion(.success(imageUrl))
            } else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "無效的伺服器響應"])))
            }
        }.resume()
    }
    
    //MARK: loadCA_Recipes:從後端 API 獲取用戶的自訂和 AI 生成食譜
    //    func loadCA_Recipes(for userID: String) {
    //        guard let url = URL(string: "http://163.17.9.107/food/php/loadCA_Recipes.php") else { return }
    //
    //        var request = URLRequest(url: url)
    //        request.httpMethod = "POST"
    //        let postString = "U_ID=\(userID)" // 傳入的 userID
    //        request.httpBody = postString.data(using: .utf8)
    //
    //        URLSession.shared.dataTask(with: request) { data, response, error in
    //            if let error = error {
    //                print("載入失敗: \(error)")
    //                return
    //            }
    //
    //            if let data = data {
    //                do {
    //                    let decodedData = try JSONDecoder().decode(CA_Recipes_S.self, from: data)
    //                    DispatchQueue.main.async {
    //                        self.customRecipes = decodedData.customRecipes // 更新自訂食譜
    //                        self.aiRecipes = decodedData.aiRecipes        // 更新 AI 食譜
    //                    }
    //                } catch {
    //                    print("JSON 解析失敗: \(error)")
    //                }
    //            }
    //        }.resume()
    //    }
    
    
    //MARK: editRecipe: 編輯自訂或 AI 生成食譜
    func editRecipe(recipe: CRecipe, U_ID: String, isAIRecipe: Bool, completion: @escaping (Bool) -> Void) {
        let apiEndpoint = isAIRecipe ? "update_ARecipes.php" : "update_CRecipes.php"
        
        guard let url = URL(string: "http://163.17.9.107/food/php\(apiEndpoint)") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let recipeData: [String: Any] = [
            "U_ID": U_ID, // 從外部傳入 U_ID
            "f_name": recipe.f_name,
            "ingredients": recipe.ingredients,
            "method": recipe.method,
            "UTips": recipe.UTips,
            "c_image_url": recipe.c_image_url ?? "",
            "CR_ID": recipe.CR_ID // 自訂食譜ID或AI食譜ID
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: recipeData, options: [])
            request.httpBody = jsonData
        } catch {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("更新食譜失敗: \(error)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
    
}

// 追加Data的擴展
extension Data {
    mutating func append(_ string: String)
    {
        if let data = string.data(using: .utf8)
        {
            append(data)
        }
    }
}

struct UploadResponse: Codable
{
    let imageUrl: String
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
