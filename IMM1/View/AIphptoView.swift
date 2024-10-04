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
                // 顯示圖片或提示信息
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

                // 上傳圖片按鈕
                if image != nil {
                    Button("上傳圖片") {
                        if let image = image {
                            uploadImage(image)
                        }
                    }
                    .padding()
                }
            }

            // 加載動畫
            if isLoading {
                VStack {
                    LoadingView() // 自定義加載視圖
                        .frame(width: 300, height: 400)
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding()
                    Text("正在辨識中，請稍候")
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
            AImagePicker(selectedImage: $image, sourceType: sourceType)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
        }
        .alert(item: $identifyResult) { result in
            Alert(title: Text(result.result), message: Text(alertMessage), dismissButton: .default(Text("確定")))
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

                // 停止加載，並獲取最新圖片
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    isLoading = false // 停止加載
                    fetchLatestImage() // 獲取最新圖片
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

                // 打印原始 JSON 數據以進行調試
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("原始 JSON 回應: \(jsonString)")
                }

                do {
                    // 解碼 JSON 回應
                    let imageFile = try JSONDecoder().decode(ImageFile.self, from: data)
                    fetchImage(named: imageFile.filename) // 獲取圖片
                } catch {
                    print("解碼 JSON 失敗: \(error.localizedDescription)")
                    alertMessage = "解析圖片列表失敗，未知錯誤。"
                    showAlert = true
                    isLoading = false // 停止加載
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
                } else {
                    alertMessage = "讀取圖片失敗，未知錯誤。"
                    showAlert = true
                }

                isLoading = false // 停止加載
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

// 用於解析圖片的結構
struct ImageFile: Codable {
    let filename: String
    let modified: Int
}

// 用於辨識結果的結構
struct IdentifyEchoResponse: Codable {
    let identifyID: String
    let identifyResult: String
}

// 用於顯示辨識結果的結構
struct IdentifyResult: Identifiable {
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

