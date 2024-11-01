import SwiftUI

struct AIphotoView: View {
    @Binding var messageText: String
    
    @State private var image: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var identifyResult: IdentifyResult?
    @State private var isLoading: Bool = false
    @State private var isUploading: Bool = false
    @State private var canFetchLatestImage: Bool = true // 控制是否允許獲取最新圖片
    
    // 定義一個計時器來定時檢查新圖片
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    // 顯示圖片或提示信息
                    if let image = image, !isUploading {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .padding(.top, 120)
                        
                        // 只在有辨識結果的情況下顯示辨識結果
                        if let result = identifyResult {
                            Text("食材辨識為：")
                                .font(.headline)
                                .padding(.top, 10)
                            
                            // 將辨識結果按行顯示
                            let ingredients = result.result.split(separator: " ")
                            ForEach(ingredients, id: \.self) { ingredient in
                                Text(String(ingredient))
                                    .padding(.top, 2)
                            }
                        }
                    } else if !isUploading {
                        Text("請上傳圖片以辨識食材")
                            .padding(.top, 100)
                        Image("食材辨識圖片")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300)
                            .padding(.top, 80)
                    }

                    // 上傳圖片按鈕
                    if image != nil && !isLoading && identifyResult == nil {
                        Button("上傳圖片") {
                            isLoading = true // 立即顯示加載動畫
                            if let image = image {
                                isUploading = true
                                canFetchLatestImage = false // 禁止獲取最新圖片
                                uploadImage(image) // 開始上傳圖片
                            }
                        }
                        .padding()
                    }
                }
                .padding()
            }
            
            // 加載動畫，隨機顯示 30 到 45 秒
            if isLoading {
                VStack {
                    LoadingView() // 自定義加載視圖
                        .frame(width: 300, height: 400)
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding()
                    Text("正在辨識中，請稍候")
                }
                .onAppear {
                    // 設置隨機加載時間 30 到 45 秒
                    let randomTime = Double.random(in: 30...40)
                    DispatchQueue.main.asyncAfter(deadline: .now() + randomTime) {
                        isLoading = false
                    }
                }
            }
            
            // 相簿按鈕
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
            
            // 相機按鈕
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            sourceType = .camera
                            showImagePicker = true // 開啟圖片選擇器
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
            AImagePicker(selectedImage: $image, sourceType: sourceType)
                .onDisappear {
                    // 當圖片選擇器消失時，檢查是否有選擇圖片
                    if image != nil {
                        canFetchLatestImage = false // 禁止獲取最新圖片
                        identifyResult = nil // 清除辨識結果
                    }
                }
        }

        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
        }
        .onChange(of: identifyResult) { _ in
            // 當辨識結果變更時，更新 messageText
            if let result = identifyResult {
                messageText = result.result
            }
        }
        .onReceive(timer) { _ in
            // 定時檢查是否有新的辨識結果
            // 只有在不加載的狀態下且可以獲取最新圖片時才執行
            // 並檢查 image 是否為 nil
            if !isLoading && canFetchLatestImage && image != nil {
                fetchLatestImage()
            }
        }
    }
    
    // 上傳圖片
    func uploadImage(_ image: UIImage) {
        isLoading = true // 開始加載
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
                isUploading = false
                
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    alertMessage = "上傳失敗: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false // 停止加載
                } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Upload successful, response: \(responseString)")
                    
                    // 在這裡添加15秒的延遲
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                        fetchLatestImage() // 獲取最新圖片
                    }
                    
                    // 在此處設置隨機加載時間
                    let randomTime = Double.random(in: 30...40)
                    DispatchQueue.main.asyncAfter(deadline: .now() + randomTime) {
                        isLoading = false // 停止加載
                    }
                } else {
                    alertMessage = "上傳失敗，未知錯誤。"
                    showAlert = true
                    isLoading = false // 停止加載
                }
            }
        }.resume()
    }



    // 獲取最新圖片
    func fetchLatestImage() {
        guard let listUrl = URL(string: "http://163.17.9.107/food/php/get_latest_image.php") else { return }
        
        isLoading = true // 開始加載
        
        URLSession.shared.dataTask(with: listUrl) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("獲取圖片列表時出錯: \(error.localizedDescription)")
                    alertMessage = "讀取圖片列表失敗: \(error.localizedDescription)"
                    showAlert = true
                    isLoading = false // 停止加載
                    return
                }
                
                guard let data = data else {
                    alertMessage = "讀取圖片列表失敗，未知錯誤。"
                    showAlert = true
                    isLoading = false // 停止加載
                    return
                }
                
                do {
                    let imageFile = try JSONDecoder().decode(ImageFile.self, from: data)
                    fetchImage(named: imageFile.filename)
                } catch {
                    print("解碼 JSON 失敗: \(error.localizedDescription)")
                    alertMessage = "解析圖片列表失敗，未知錯誤。"
                    showAlert = true
                    isLoading = false
                }
            }
        }.resume()
    }
    
    // 根據檔名獲取圖片
    func fetchImage(named filename: String) {
        guard let url = URL(string: "http://163.17.9.107/food/test/\(filename)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching image: \(error.localizedDescription)")
                    alertMessage = "讀取圖片失敗: \(error.localizedDescription)"
                    showAlert = true
                } else if let data = data, let loadedImage = UIImage(data: data) {
                    image = loadedImage
                    fetchIdentifyEchoData() // 在獲取圖片後獲取辨識結果
                } else {
                    alertMessage = "讀取圖片失敗，未知錯誤。"
                    showAlert = true
                }
                
                isLoading = false
            }
        }.resume()
    }
    
    // 獲取辨識結果
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
                    
                    DispatchQueue.main.async {
                        messageText = responseData.Identify_Result
                        identifyResult = IdentifyResult(id: responseData.Identify_ID, result: responseData.Identify_Result)
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

// 用於解析圖片的結構
struct ImageFile: Codable {
    let filename: String
    let modified: Int
}

// 用於辨識結果的結構
struct IdentifyEchoResponse: Codable {
    let Identify_ID: String
    let Identify_Result: String
}

// 用於顯示辨識結果的結構
struct IdentifyResult: Identifiable, Equatable {
    let id: String
    let result: String
}

// 用於選擇圖片的組件
struct AImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: AImagePicker
        
        init(_ parent: AImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
