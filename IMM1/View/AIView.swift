import SwiftUI

struct DataModel: Codable {
    var text: String
}

struct RecipeResponse: Codable {
    var Recipe_ID: Int
    var U_ID: String
    var input: String
    var output: String
}

struct AIView: View {
    @State private var messageText: String = ""
    @State private var messages: [String] = []
    @State private var isLoading: Bool = false

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    if isLoading {
                        // Show a custom loading animation when loading
                        LoadingAnimationView()
                            .frame(maxWidth: .infinity, maxHeight: 100)
                            .padding()
                    } else {
                        ForEach(messages, id: \.self) { message in
                            HStack {
                                if message.starts(with: "Server:") {
                                    Text(message)
                                        .padding()
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Text(message)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            .padding()
                        }
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
    }

    func sendMessage() {
        guard !messageText.isEmpty else { return }
        let dataModel = DataModel(text: messageText)
        sendToDatabase(dataModel: dataModel)
        messages.append("User: \(messageText)") // Add user message
        messageText = ""

        // Fetch data after sending the message
        fetchData()
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
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            let responseString = String(data: data, encoding: .utf8)
            print("Response: \(responseString ?? "No response")")
        }.resume()
    }

    func fetchData() {
        guard let url = URL(string: "http://163.17.9.107/food/GetRecipe.php") else { return }

        // Set loading status to true before starting the fetch
        DispatchQueue.main.async {
            self.isLoading = true
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    // Keep loading animation on and notify user of the error
                    self.messages = ["Server: Error occurred. Retrying..."]
                    self.isLoading = true
                    // Optionally retry after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.fetchData()
                    }
                }
                return
            }

            guard let data = data else {
                print("No data received")
                DispatchQueue.main.async {
                    // Keep loading animation on and notify user of the issue
                    self.messages = ["Server: No data received. Retrying..."]
                    self.isLoading = true
                    // Optionally retry after a delay
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
                        // Continue showing the loading animation
                        self.messages = ["Server: LOADING"]
                    } else {
                        // Update messages with the fetched data
                        self.messages = ["\(recipeResponse.output)"]
                        self.isLoading = false
                    }
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    // Keep loading animation on and notify user of the decoding error
                    self.messages = ["Server: Decoding error. Retrying..."]
                    self.isLoading = true
                    // Optionally retry after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.fetchData()
                    }
                }
            }
        }.resume()
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
