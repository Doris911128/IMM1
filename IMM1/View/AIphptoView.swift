import SwiftUI

struct AIphotoView: View {
    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var identifyResult: IdentifyResult? // 修改為 IdentifyResult 類型

    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("我是相框")
                    .padding()
            }

            Button("我有圖片") {
                sourceType = .photoLibrary
                showImagePicker = true
            }
            .padding()

            Button("我想拍照") {
                sourceType = .camera
                showImagePicker = true
            }
            .padding()

            Button("上傳啦～") {
                if let image = image {
                    uploadImage(image)
                }
            }
            .padding()

            // 按鈕：請求 Identify_echo.php 資料
            Button("Fetch Identify_echo Data") {
                fetchIdentifyEchoData() // 新增的請求函數
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $image, sourceType: sourceType)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("上傳成功"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
        }
        .alert(item: $identifyResult) { result in // 使用 IdentifyResult 類型
            Alert(title:Text(result.result) ,message: Text(alertMessage), dismissButton: .default(Text("確定")))
        }
    }

    func uploadImage(_ image: UIImage) {
        guard let url = URL(string: "http://163.17.9.107/food/php/Identify.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        let base64String = imageData.base64EncodedString()

        let body: [String: Any] = [
            "image": base64String,
            "filename": "yourImage.jpg"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    alertMessage = "上傳失敗: \(error.localizedDescription)"
                } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Upload successful, response: \(responseString)")
                    alertMessage = "資料已成功送出！"
                } else {
                    alertMessage = "上傳失敗，未知錯誤。"
                }
                showAlert = true
            }
        }.resume()
    }

    // 新增：從 Identify_echo.php 獲取資料的函數
    func fetchIdentifyEchoData() {
        guard let url = URL(string: "http://163.17.9.107/food/php/Identify_echo.php") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    // 解碼 JSON 數據
                    let decoder = JSONDecoder()
                    let responseData = try decoder.decode(IdentifyEchoResponse.self, from: data)
                    
                    // 印出解碼後的數據
                    print("Identify ID: \(responseData.identifyID)")
                    print("Identify Result: \(responseData.identifyResult)")
                    
                    // 更新 identifyResult 狀態以顯示提示框
                    DispatchQueue.main.async {
                        identifyResult = IdentifyResult(id: responseData.identifyID, result: responseData.identifyResult)
                    }
                } catch {
                    print("Failed to decode JSON: \(error.localizedDescription)")
                }
            } else {
                print("Failed to fetch data.")
            }
        }.resume() // 啟動網路請求
    }
}

// 定義數據結構以匹配 JSON 格式
struct IdentifyEchoResponse: Codable {
    let identifyID: String
    let identifyResult: String

    enum CodingKeys: String, CodingKey {
        case identifyID = "Identify_ID"
        case identifyResult = "Identify_Result"
    }
}

// 新增的 Identifiable 結構
struct IdentifyResult: Identifiable {
    let id: String // 使用 identifyID 作為 id
    let result: String
}
