import SwiftUI

struct DataModel: Codable {
    var text: String
    var userId: String // Add userId field
}

struct RecipeResponse: Codable {
    var output: String
}

struct Message: Codable, Identifiable {
    let id = UUID()
    var message: String
}

struct AIView: View {
    @State private var messageText: String = ""
    @State private var messages: [Message] = []
    @State private var isLoading: Bool = false
    @State private var searchingMessageIndex: Int? = nil
    @State private var showingImagePicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var userId: String = "" // Ensure this is dynamically set

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("AI助手")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .offset(x: 21, y: 0)
                    Spacer()
                    Button(action: {
                        showingImagePicker.toggle()
                    }) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                            .frame(width: 40, height: 40)
                            .offset(x: -20, y: 0)
                    }
                }
                Divider()
                    .background(Color.gray)
                    .frame(height: 4)
            }
            .frame(maxWidth: .infinity)

            ScrollView {
                VStack {
                    ForEach(messages) { message in
                        HStack {
                            if message.message.starts(with: "答：") {
                                ServerMessageView(message: message.message, deleteAction: {
                                    deleteMessage(message: message)
                                })
                            } else {
                                UserMessageView(message: message.message, deleteAction: {
                                    deleteMessage(message: message)
                                })
                            }
                        }
                        .padding()
                    }
                    if isLoading {
                        LoadingAnimationView()
                            .frame(maxWidth: .infinity, maxHeight: 100)
                            .padding()
                    }
                }
            }

            HStack {
                TextField("請輸入食材，將幫您生成食譜", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: CGFloat(30))

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                }
                .padding()
            }
            .padding()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                // Handle the selected image here
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
        .onAppear {
            // Fetch userId from your login flow or app settings
            self.userId = "your_dynamic_user_id" // Set this dynamically
            fetchData()
        }
    }

    func sendMessage() {
        guard !messageText.isEmpty else { return }
        guard !userId.isEmpty else {
            print("User ID is not set")
            return
        }
        let dataModel = DataModel(text: messageText, userId: userId)
        messages.append(Message(message: "問：\(messageText)"))
        isLoading = true
        messageText = ""

        sendToDatabase(dataModel: dataModel)
    }

    func sendToDatabase(dataModel: DataModel) {
        guard let url = URL(string: "http://163.17.9.107/food/php/AI_Recipe.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "text=\(dataModel.text)&userId=\(dataModel.userId)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        request.httpBody = body?.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            let responseString = String(data: data, encoding: .utf8)
            print("Response: \(responseString ?? "No response")")

            // Fetch data after sending the message
            self.fetchData()
        }.resume()
    }

    func fetchData() {
        guard let url = URL(string: "http://163.17.9.107/food/php/GetRecipe.php?userId=\(userId)") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    if self.searchingMessageIndex == nil {
                        self.messages.append(Message(message: "答：Error occurred. Retrying..."))
                        self.searchingMessageIndex = self.messages.count - 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.fetchData()
                    }
                }
                return
            }

            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self.isLoading = false
                    if self.searchingMessageIndex == nil {
                        self.messages.append(Message(message: "答：No data received. Retrying..."))
                        self.searchingMessageIndex = self.messages.count - 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.fetchData()
                    }
                }
                return
            }

            // Decode the JSON response
            do {
                let decoder = JSONDecoder()
                let recipeResponse = try decoder.decode(RecipeResponse.self, from: data)

                DispatchQueue.main.async {
                    if recipeResponse.output == "LOADING" {
                        if self.searchingMessageIndex == nil {
                            self.messages.append(Message(message: "答：生成中...."))
                            self.searchingMessageIndex = self.messages.count - 1
                        }
                        self.fetchData()
                    } else {
                        if let index = self.searchingMessageIndex {
                            self.messages[index] = Message(message: "答：\(recipeResponse.output)")
                        } else {
                            self.messages.append(Message(message: "答：\(recipeResponse.output)"))
                        }
                        self.isLoading = false
                        self.searchingMessageIndex = nil
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if self.searchingMessageIndex == nil {
                        self.messages.append(Message(message: "答：生成中...."))
                        self.searchingMessageIndex = self.messages.count - 1
                    }
                    self.fetchData()
                }
            }
        }.resume()
    }

    func deleteMessage(message: Message) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages.remove(at: index)
        }
    }
}

struct ServerMessageView: View {
    var message: String
    var deleteAction: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.2))
                .clipShape(Circle())

            Text(message)
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contextMenu {
                    Button(action: deleteAction) {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }
}

struct UserMessageView: View {
    var message: String
    var deleteAction: () -> Void

    var body: some View {
        Text(message)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contextMenu {
                Button(action: deleteAction) {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}

struct LoadingAnimationView: View {
    @State private var rotation: Double = 0

    var body: some View {
        VStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(rotation))
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: rotation)
                .onAppear {
                    self.rotation = 360
                }
        }
    }
}

struct AIView_Previews: PreviewProvider {
    static var previews: some View {
        AIView()
    }
}
