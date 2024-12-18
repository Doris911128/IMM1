import SwiftUI

struct SignupView: View {
    @Binding var textselect: Int
    @Environment(\.dismiss) private var dismiss
    @State private var show: Bool = false
    @State private var selectedTab: Int = 0
    @State private var description: String = ""
    @State private var method: String = "GET"
    @State private var date: Date = Date()
    @State private var result: (Bool, String) = (false, "")
    @State private var information: (String, String, String, String, String, String, String, String) = ("", "", "", "", "", "", "", "")
    private let title: [String] = ["請輸入您的帳號 密碼", "請輸入您的名稱", "請選擇您的性別", "請輸入您的生日", "請輸入您的身高(CM)體重(KG)", "個人資訊"]
    
    init(textselect: Binding<Int>) {
        self._textselect = textselect
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.orange
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray
        _information = State(initialValue: ("", "", "", "", "", SignupView.formatDate(Date()), "", ""))
    }
    
    private func sendRequest() {
        // 檢查所有必填欄位是否為空
        if information.0.isEmpty || information.1.isEmpty || information.2.isEmpty || information.3.isEmpty || information.4.isEmpty || information.6.isEmpty || information.7.isEmpty {
            // 顯示錯誤訊息
            self.result = (true, "註冊失敗：所有欄位均為必填，請檢查輸入")
            return
        }
        
        // 檢查密碼是否一致
        if !passcheck() {
            self.result = (true, "註冊失敗：兩次密碼輸入不一致")
            return
        }
        
        guard let url = URL(string: "http://163.17.9.107/food/php/Signin.php") else {
            print("錯誤: 無效的URL")
            self.result = (true, "註冊失敗：無效的註冊URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let gender: Int
        switch information.4 {
        case "男性":
            gender = 0
        case "女性":
            gender = 1
        case "隱私":
            gender = 2
        default:
            gender = 2
        }
        
        let parameters: [String: Any] = [
            "U_Acc": information.0,
            "U_Pas": information.1,
            "U_Name": information.3,
            "U_Gen": gender,
            "U_Bir": information.5,
            "H": Float(information.6) ?? 0.0,
            "W": Float(information.7) ?? 0.0,
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
            print("發送的JSON數據: \(String(data: jsonData, encoding: .utf8) ?? "無法將數據轉化為字符串")")
        } catch {
            print("錯誤: 無法從參數創建JSON")
            self.result = (true, "註冊失敗：無法生成註冊JSON數據")
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("网络请求错误: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.result = (true, "註冊失敗：\(error.localizedDescription)")
                }
            } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("网络请求响应: \(responseString)")
                DispatchQueue.main.async {
                    if responseString.contains("success") {
                        self.result = (true, "註冊成功！")
                    } else {
                        self.result = (true, "註冊成功：\(responseString)")
                    }
                }
            }
        }.resume()
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private let label: [InformationLabel] = [
        InformationLabel(image: "person.text.rectangle", label: "帳號"),
        InformationLabel(image: "", label: ""),
        InformationLabel(image: "", label: ""),
        InformationLabel(image: "person.fill", label: "名稱"),
        InformationLabel(image: "figure.arms.open", label: "性別"),
        InformationLabel(image: "birthday.cake", label: "生日"),
        InformationLabel(image: "ruler", label: "身高"),
        InformationLabel(image: "dumbbell", label: "體重"),
    ]
    
    private func setInformation(index: Int) -> String {
        switch(index) {
        case 0: return self.information.0
        case 1: return self.information.1
        case 2: return self.information.2
        case 3: return self.information.3
        case 4: return self.information.4
        case 5: return self.information.5
        case 6: return String(self.information.6)
        case 7: return String(self.information.7)
        default: return ""
        }
    }
    
    private func passcheck() -> Bool {
        return !self.information.1.isEmpty && self.information.1 == self.information.2
    }
    
    private func CurrenPageAcc() -> Bool {
        if self.information.0.isEmpty || self.information.1.isEmpty || self.information.2.isEmpty {
            return false
        } else if !self.passcheck() {
            return false
        } else {
            return true
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Text(self.title[self.selectedTab])
                .bold()
                .font(.title)
                .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
                .contentTransition(.numericText())
                .offset(y: 50)
            
            TabView(selection: self.$selectedTab) {
                VStack(spacing: 60) {
                    VStack(spacing: 20) {
                        TextField("輸入您的帳號", text: self.$information.0)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                            .autocapitalization(.none)
                        SecureField("輸入您的密碼", text: self.$information.1)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                            .autocapitalization(.none)
                        SecureField("再次輸入密碼", text: self.$information.2)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                            .autocapitalization(.none)
                    }
                }
                .tag(0)
                VStack(spacing: 60) {
                    VStack {
                        TextField("您的名稱", text: self.$information.3)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                            .autocapitalization(.none)
                    }
                }
                .tag(1)
                VStack(spacing: 20) {
                    VStack {
                        Picker("", selection: $information.4) {
                            Text("").tag("")
                            Text("男性").tag("男性")
                            Text("女性").tag("女性")
                            Text("隱私").tag("隱私")
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 330, height: 100)
                    }
                    .padding(20)
                }
                .tag(2)
                VStack(spacing: 60) {
                    if(self.show) {
                        Text(self.description)
                            .bold()
                            .font(.largeTitle)
                            .onAppear {
                                withAnimation(.easeInOut.delay(1)) {
                                    self.show = false
                                }
                            }
                    } else {
                        VStack(spacing: 50) {
                            DatePicker(selection: self.$date, displayedComponents: .date) {
                                Text("選擇日期")
                            }
                            .onChange(of: self.date) { newDate in
                                self.information.5 = SignupView.formatDate(newDate)
                            }
                        }
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .padding(20)
                    }
                }
                .tag(3)
                VStack(spacing: 60) {
                    VStack {
                        TextField("輸入您的身高", text: self.$information.6)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                    }
                    VStack {
                        TextField("輸入您的體重", text: self.$information.7)
                            .padding()
                            .background(Color.gray.opacity(0.5))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                    }
                    .padding()
                }
                .tag(4)
                VStack {
                    List {
                        ForEach(0..<Mirror(reflecting: self.information).children.count, id: \.self) { index in
                            if(!(index == 1 || index == 2)) {
                                HStack {
                                    if(index < self.label.count) {
                                        self.label[index]
                                    }
                                    Text(self.setInformation(index: index))
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(.clear)
                    .listRowSeparator(.hidden)
                }
                .tag(5) // 這裡的tag會改成5，請依需要調整
                .offset(y: 100)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth, value: self.selectedTab)
            .onTapGesture {
                self.dismissKeyboard()
            }
            HStack(spacing: 100) {
                if self.selectedTab > 0 {
                    Button(action: {
                        withAnimation(.easeInOut) {
                            self.selectedTab -= 1
                        }
                    }) {
                        Image(systemName: "arrow.left").foregroundColor(.gray)
                    }
                }
                
                Button("", systemImage: self.selectedTab < self.title.count - 1 ? "arrow.right" : "checkmark") {
                    withAnimation(.easeInOut) {
                        if(self.selectedTab == self.title.count - 1) {
                            self.dismiss()
                            self.sendRequest()
                        }
                        self.selectedTab = self.selectedTab < self.title.count - 1 ? self.selectedTab + 1 : self.selectedTab
                    }
                }
                .contentTransition(.symbolEffect(.replace))
            }
            .font(.largeTitle)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .alert(self.result.1, isPresented: self.$result.0) {
                Button("確認") {
                    if(self.result.1.contains("註冊成功！！")) {
                        self.dismissKeyboard()
                    }
                }
            }
            
        }
    }
}


struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignupView(textselect: .constant(0))
        }
    }
}
