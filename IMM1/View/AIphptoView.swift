import SwiftUI

struct AIphotoView: View {
    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var identifyResult: IdentifyResult?
    @State private var isLoading: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                } else {
                    Text("請上傳圖片以辨識食材")
                    Image("食材辨識圖片")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                }
                
                // 按鈕：上傳圖片
                if image != nil {
                    Button("上傳圖片") {
                        if let image = image {
                            uploadImage(image)
                        }
                    }
                    .padding()
                }
            }
            
            // 显示加载动画
            if isLoading {
                VStack {
                    LoadingView() // 你可以使用自己的加载视图
                        .frame(width: 300, height: 400) // 设置加载视图的大小
                        .background(Color.white) // 设置背景颜色
                        .cornerRadius(10) // 设置圆角
                        .padding() // 设定内边距
                    Text("正在辨識中，請稍候")
                }
            }
            
            // 相簿图标按钮，位于左下角
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    }) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(60)
                    }
                    .padding(.leading, 20)
                    Spacer()
                }
            }
            
            // 相机图标按钮，位于右下角
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            sourceType = .camera
                            showImagePicker = true
                        } else {
                            alertMessage = "此設備不支持相機。"
                            showAlert = true
                        }
                    }) {
                        Image(systemName: "camera")
                            .resizable()
                            .frame(width: 35, height: 34)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(60)
                    }
                    .padding(.trailing, 20)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $image, sourceType: sourceType)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
        }
        .alert(item: $identifyResult) { result in
            Alert(title: Text(result.result), message: Text(alertMessage), dismissButton: .default(Text("確定")))
        }
    }
    
    func uploadImage(_ image: UIImage) {
        isLoading = true // Start loading
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
                    showAlert = true
                } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Upload successful, response: \(responseString)")
                    alertMessage = "資料已成功送出！"
                    showAlert = true
                } else {
                    alertMessage = "上傳失敗，未知錯誤。"
                    showAlert = true
                }
                
                // 停止加載，延遲10秒後顯示警告
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    isLoading = false // Stop loading
                    // Trigger the Identify_echo data fetch after loading
                    fetchIdentifyEchoData()
                }
            }
        }.resume()
    }
    
    func fetchIdentifyEchoData() {
        guard let url = URL(string: "http://163.17.9.107/food/php/Identify_echo.php") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let responseData = try decoder.decode(IdentifyEchoResponse.self, from: data)
                    
                    print("Identify ID: \(responseData.identifyID)")
                    print("Identify Result: \(responseData.identifyResult)")
                    
                    DispatchQueue.main.async {
                        identifyResult = IdentifyResult(id: responseData.identifyID, result: responseData.identifyResult)
                    }
                } catch {
                    print("Failed to decode JSON: \(error.localizedDescription)")
                }
            } else {
                print("Failed to fetch data.")
            }
        }.resume()
    }
}

struct IdentifyEchoResponse: Codable {
    let identifyID: String
    let identifyResult: String
    
    enum CodingKeys: String, CodingKey {
        case identifyID = "Identify_ID"
        case identifyResult = "Identify_Result"
    }
}

struct IdentifyResult: Identifiable {
    let id: String
    let result: String
}
