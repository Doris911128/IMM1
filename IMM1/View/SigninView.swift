import SwiftUI

struct SigninView: View {
    @AppStorage("signin") private var signin: Bool = false
    @AppStorage("rememberMe") private var rememberMe: Bool = false
    @State private var U_Acc: String = ""
    @State private var U_Pas: String = ""
    @State private var result: (Bool, String) = (false, "")
    @State private var information: (String, String) = ("", "")
    @State private var forget: Bool = false
    @EnvironmentObject private var user: User

    private func sendRequest() {
        let url = URL(string: "http://163.17.9.107/food/Login.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyParameters = "U_Acc=\(U_Acc)&U_Pas=\(U_Pas)"
        request.httpBody = bodyParameters.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
            } else if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                    if responseString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "null" {
                        result = (true, "帳號或密碼錯誤")
                    } else {
                        DispatchQueue.main.async {
                            signin = true
                            if rememberMe {
                                // If remember me is checked, store the login state
                                UserDefaults.standard.set(signin, forKey: "signin")
                                UserDefaults.standard.set(U_Acc, forKey: "savedUsername")
                                UserDefaults.standard.set(U_Pas, forKey: "savedPassword")
                            } else {
                                // If remember me is not checked, clear saved username and password
                                UserDefaults.standard.removeObject(forKey: "savedUsername")
                                UserDefaults.standard.removeObject(forKey: "savedPassword")
                            }
                        }
                    }
                } else {
                    print("Unable to decode response data.")
                }
            }
        }.resume()
    }

    var body: some View {
        NavigationView {
            if signin {
                ContentView().transition(.opacity)
            } else {
                VStack(spacing: 20) {
                    Circle()
                        .fill(.gray)
                        .scaledToFit()
                        .frame(width: 150)
                        .padding(.bottom, 50)
                    
                    VStack(spacing: 30) {
                        TextField("帳號...",text: $U_Acc)
                            .scrollContentBackground(.hidden)
                            .padding()
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                        
                        SecureField("密碼...",text: $U_Pas)
                            .scrollContentBackground(.hidden)
                            .padding()
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }
                    .font(.title3)
                    
                    NavigationLink(destination: SignupView(textselect: .constant(0))) {
                        Text("尚未註冊嗎？請點擊我")
                            .font(.body)
                            .foregroundColor(Color(red: 0.574, green: 0.609, blue: 0.386))
                            .colorMultiply(.gray)
                    }
                    
                    HStack {
                        HStack {
                            Circle()
                                .fill(Color(.systemGray6))
                                .frame(width: 20)
                                .overlay {
                                    Circle()
                                        .fill(.blue)
                                        .padding(5)
                                        .opacity(rememberMe ? 1 : 0)
                                }
                                .onTapGesture {
                                    withAnimation(.easeInOut) {
                                        rememberMe.toggle()
                                    }
                                }
                            
                            Text("記住我").font(.callout)
                        }
                        
                        Spacer()
                        
                        Button("忘記密碼？") {
                            forget.toggle()
                        }
                        .font(.callout)
                    }
                    .sheet(isPresented: $forget) {
                        ForgetPasswordView()
                            .presentationDetents([.medium])
                            .presentationCornerRadius(30)
                    }
                    
                    Button {
                        Task {
                            sendRequest()
                        }
                    } label: {
                        Text("登入")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                            .clipShape(Capsule())
                    }
                    
                    HStack {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color(.systemGray3))
                                .scaledToFit()
                                .frame(height: 50)
                            
                            if index < 2 {
                                Spacer()
                            }
                        }
                    }
                }
                .onTapGesture {
                    dismissKeyboard()
                }
                .padding(.horizontal, 50)
                .transition(.opacity)
                .ignoresSafeArea(.keyboard)
            }
        }
        .alert(result.1, isPresented: $result.0) {
            Button("完成", role: .cancel) {
                if result.1.hasPrefix("歡迎") {
                    withAnimation(.easeInOut.speed(2)) {
                        signin = true
                    }
                }
            }
        }
        // 在视图初始化时加载保存的用户名和密码
        .onAppear {
            let savedUsername = UserDefaults.standard.string(forKey: "savedUsername") ?? ""
            let savedPassword = UserDefaults.standard.string(forKey: "savedPassword") ?? ""
            self.U_Acc = savedUsername
            self.U_Pas = savedPassword
        }
    }
}

struct SigninView_Previews: PreviewProvider {
    static var previews: some View {
        SigninView()
    }
}
