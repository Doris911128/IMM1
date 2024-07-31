import SwiftUI

struct DataModel: Codable {
    var text: String
}

struct RecipeResponse: Codable {
    var output: String
}

struct AIView: View {
    @State private var messageText: String = ""
    @State private var messages: [String] = []
    @State private var isLoading: Bool = false
    @State private var searchingMessageIndex: Int? = nil
    @State private var showingImagePicker: Bool = false
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        VStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("AI助手")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.vertical, 10)
                    Spacer()
                    Button(action: {
                        showingImagePicker.toggle()
                    }) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                            .frame(width: 40, height: 40) // Adjust size here
                    }
                }
                Divider()
                    .background(Color.gray)
                    .frame(height: 4)
            }
            .frame(maxWidth: .infinity)

            ScrollView {
                VStack {
                    ForEach(messages.indices, id: \.self) { index in
                        HStack {
                            if messages[index].starts(with: "答:") {
                                ServerMessageView(message: messages[index])
                            } else {
                                UserMessageView(message: messages[index])
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
                TextField("輸入食材", text: $messageText)
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
                // For example, save it to the photo library or upload it
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }

    func sendMessage() {
        guard !messageText.isEmpty else { return }
        let dataModel = DataModel(text: messageText)
        messages.append("問: \(messageText)") // Add user message
        isLoading = true // Show loading animation after user sends message
        messageText = ""

        sendToDatabase(dataModel: dataModel)
    }

    func sendToDatabase(dataModel: DataModel) {
        guard let url = URL(string: "http://163.17.9.107/food/AI_Recipe.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "text=\(dataModel.text)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        request.httpBody = body?.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false // Stop loading animation
                }
                return
            }

            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    self.isLoading = false // Stop loading animation
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
        guard let url = URL(string: "http://163.17.9.107/food/GetRecipe.php") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false // Stop loading animation
                    if self.searchingMessageIndex == nil {
                        self.messages.append("答: Error occurred. Retrying...")
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
                    self.isLoading = false // Stop loading animation
                    if self.searchingMessageIndex == nil {
                        self.messages.append("答: No data received. Retrying...")
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
                
                // Print the decoded response to the terminal
                print("Fetched data: \(recipeResponse)")

                DispatchQueue.main.async {
                    if recipeResponse.output == "LOADING" {
                        if self.searchingMessageIndex == nil {
                            self.messages.append("答:生成中....")
                            self.searchingMessageIndex = self.messages.count - 1
                        }
                        self.fetchData()
                    } else {
                        if let index = self.searchingMessageIndex {
                            self.messages[index] = "答: \(recipeResponse.output)"
                        } else {
                            self.messages.append("答: \(recipeResponse.output)")
                        }
                        self.isLoading = false // Stop loading animation
                        self.searchingMessageIndex = nil // Reset flag
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false // Stop loading animation
                    if self.searchingMessageIndex == nil {
                        self.messages.append("答: 生成中....")
                        self.searchingMessageIndex = self.messages.count - 1
                    }
                    self.fetchData()
                }
            }
        }.resume()
    }
}
struct ServerMessageView: View {
    var message: String

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
        }
    }
}

struct UserMessageView: View {
    var message: String

    var body: some View {
        Text(message)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .frame(maxWidth: .infinity, alignment: .trailing)
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
