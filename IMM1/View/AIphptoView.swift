//  AIphptoView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/9/4.
//

import SwiftUI

// 定義一個 TestView 結構，符合 View 協議
struct AIphotoView: View {
    @State private var image: UIImage? // 用於存儲選擇的圖片
    @State private var showImagePicker = false // 控制圖片選擇器的顯示狀態
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary // 預設來源為相簿
    
    var body: some View {
        VStack {
            // 如果有選擇的圖片，顯示圖片，否則顯示提示文字
            if let image = image {
                Image(uiImage: image) // 使用選擇的圖片
                    .resizable() // 使圖片可調整大小
                    .scaledToFit() // 按比例縮放
                    .frame(width: 300, height: 300) // 設定圖片框的大小
            } else {
                Text("我是相框") // 提示用戶選擇圖片
                    .padding() // 添加內邊距
            }
            
            // 按鈕：選擇圖片
            Button("我有圖片") {
                sourceType = .photoLibrary // 設定來源為相簿
                showImagePicker = true // 點擊後顯示圖片選擇器
            }
            .padding() // 添加內邊距
            
            // 按鈕：使用相機選擇圖片
            Button("我想拍照") {
                sourceType = .camera // 設定來源為相機
                showImagePicker = true // 點擊後顯示圖片選擇器
            }
            .padding() // 添加內邊距

            // 按鈕：上傳圖片
            Button("上傳啦～") {
                if let image = image {
                    uploadImage(image) // 如果有圖片，調用上傳函數
                }
            }
            .padding() // 添加內邊距
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $image, sourceType: sourceType)  // 顯示圖片選擇器，並將選擇的圖片綁定到 image
        }
    }
    
    // 上傳圖片的函數
    func uploadImage(_ image: UIImage) {
        // 設定上傳的 URL
        guard let url = URL(string: "http://163.17.9.107/food/php/Identify.php") else { return }
        var request = URLRequest(url: url) // 創建請求
        request.httpMethod = "POST" // 設定 HTTP 方法為 POST
        
        // 將圖片轉換為 JPEG 數據
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let base64String = imageData.base64EncodedString() // 將圖片數據轉換為 Base64 字符串
        
        // 構建請求的主體
        let body: [String: Any] = [
            "image": base64String, // 包含圖片數據
            "filename": "yourImage.jpg" // 設定文件名
        ]
        
        // 將主體轉換為 JSON 數據
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // 設定請求頭為 JSON
        
        // 發送請求
        URLSession.shared.dataTask(with: request) { data, response, error in
            // 處理上傳結果
            if let error = error {
                print("Upload error: \(error.localizedDescription)") // 打印錯誤信息
            } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Upload successful, response: \(responseString)") // 打印上傳成功的響應
            } else {
                print("Upload failed, unknown error.") // 打印未知錯誤
            }
        }.resume() // 開始請求
    }
}
