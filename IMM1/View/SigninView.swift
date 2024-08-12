//SigninView

import SwiftUI

struct SigninView: View
{
    @AppStorage("signin") private var signin: Bool = false
    @AppStorage("rememberMe") private var rememberMe: Bool = false
    @AppStorage("U_ID") private var storedU_ID: String = "" // 用于存储
    @State private var scale: CGFloat = 1.0
    @State private var U_Acc: String = ""
    @State private var U_Pas: String = ""
    @State private var result: (Bool, String) = (false, "")
    @State private var information: (String, String) = ("", "")
    @State private var forget: Bool = false
    @EnvironmentObject private var user: User
    
    private func sendRequest()
    {
        let url = URL(string: "http://163.17.9.107/food/php/Login.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyParameters = "U_Acc=\(U_Acc)&U_Pas=\(U_Pas)"
        request.httpBody = bodyParameters.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request)
        { (data, response, error) in
            if let error = error
            {
                print("Error: \(error)")
            } else if let data = data
            {
                if let responseString = String(data: data, encoding: .utf8)
                {
                    print("Response: \(responseString)")
                    let responseData = try? JSONDecoder().decode(ResponseData.self, from: data)
                    if let responseData = responseData {
                        if responseData.status == "success" {
                            DispatchQueue.main.async {
                                // 登录成功
                                signin = true
                                if rememberMe {
                                    // 如果记住我已选中，则保存登录状态
                                    UserDefaults.standard.set(signin, forKey: "signin")
                                    UserDefaults.standard.set(U_Acc, forKey: "savedUsername")
                                    UserDefaults.standard.set(U_Pas, forKey: "savedPassword")
                                } else {
                                    // 如果记住我未选中，则清除保存的用户名和密码
                                    UserDefaults.standard.removeObject(forKey: "savedUsername")
                                    UserDefaults.standard.removeObject(forKey: "savedPassword")
                                }
                            }
                        } else {
                            // 登录失败，显示错误消息
                            result = (true, responseData.message)
                        }
                    } else {
                        print("Unable to decode response data.")
                    }
                }
            }
        }.resume()
    }
    
    var body: some View
    {
        NavigationView
        {
            if signin
            {
                ContentView().transition(.opacity)
            } else
            {
                VStack(spacing: 20)
                {
                    
                    Image("登入Logo")
                        .resizable()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .scaleEffect(scale) // Use the state variable for scaling
                        .background(Color.clear) // Set the background color to clear
                        .animation(.easeInOut(duration: 1.0), value: scale) // Apply animation
                        .onAppear {
                            scale = 1.8 // Change the scale value to trigger animation
                        }
                        .padding(.bottom, 50)
                    
                    VStack(spacing: 30)
                    {
                        TextField("帳號...",text: $U_Acc)
                            .scrollContentBackground(.hidden)
                            .padding()
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                            .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                        SecureField("密碼...",text: $U_Pas)
                            .scrollContentBackground(.hidden)
                            .padding()
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                            .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                    }
                    .font(.title3)
                    
                    
                    
                    Text("")
                        .font(.body)
                        .foregroundColor(Color(red: 0.574, green: 0.609, blue: 0.386))
                        .colorMultiply(.gray)
                    
                    
                    HStack
                    {
                        HStack
                        {
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
                                    withAnimation(.easeInOut)
                                    {
                                        rememberMe.toggle()
                                    }
                                }
                            
                            Text("記住我").font(.callout)
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: SignupView(textselect: .constant(0)))
                        {
                            Text("尚未註冊嗎？請點擊我")
                                .font(.body)
                                .foregroundColor(Color(red: 0.574, green: 0.609, blue: 0.386))
                                .colorMultiply(.gray)
                        }
                    }
                    
                    
                    Button {
                        // 验证用户是否输入了帐号和密码
                        if U_Acc.isEmpty || U_Pas.isEmpty {
                            // 如果帐号或密码为空，显示警告消息
                            result = (true, "帳號或密碼不能為空")
                        } else {
                            // 如果帐号和密码都不为空，发送请求
                            Task {
                                sendRequest()
                            }
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
                    .disabled(result.0) // 根据 result 中的状态禁用按钮
                }
                .onTapGesture
                {
                    dismissKeyboard()
                }
                .padding(.horizontal, 50)
                .transition(.opacity)
                .ignoresSafeArea(.keyboard)
            }
        }
        .alert(result.1, isPresented: $result.0)
        {
            Button("確認", role: .cancel)
            {
                if result.1.hasPrefix("歡迎")
                {
                    withAnimation(.easeInOut.speed(2))
                    {
                        signin = true
                    }
                }
            }
        }
        // 在视图初始化时加载保存的用户名和密码
        .onAppear
        {
            let savedUsername = UserDefaults.standard.string(forKey: "savedUsername") ?? ""
            let savedPassword = UserDefaults.standard.string(forKey: "savedPassword") ?? ""
            self.U_Acc = savedUsername
            self.U_Pas = savedPassword
        }
    }
}

// 响应数据模型，用于解析从服务器返回的 JSON 数据
struct ResponseData: Codable {
    let status: String
    let message: String
    let U_ID: String // 添加 U_ID 字段
}

struct SigninView_Previews: PreviewProvider
{
    static var previews: some View
    {
        SigninView()
    }
}
