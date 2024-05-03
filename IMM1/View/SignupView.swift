// MARK: 註冊View
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
    @State private var information: (String, String, String, String, String, String, String, String, Double, Double, Double, Double) = ("", "", "", "", "", "", "", "", 0.0, 0.0, 0.0, 0.0)
    private let title: [String] = ["請輸入您的帳號 密碼", "請輸入您的名稱", "請選擇您的性別", "請輸入您的生日", "請輸入您的身高(CM)體重(KG)", "請調整您的偏好  酸", "請調整您的偏好  甜", "請調整您的偏好  苦", "請調整您的偏好  辣", "個人資訊"]
    
    init(textselect: Binding<Int>) {
        self._textselect = textselect
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.orange
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray
    }

    private func sendRequest() {
        guard let url = URL(string: "http://163.17.9.107/food/Signin.php") else {
            print("錯誤: 無效的URL")
            return }
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
            gender = 2 // 或者其他默认值
        }
        
        let parameters: [String: Any] = [
            "U_Acc": information.0,
            "U_Pas": information.1,
            "U_Name": information.3,
            "U_Gen": gender ,
            "U_Bir":information.5,
            "H":Float(information.6),
            "W":Float(information.7),
            "acid": String(information.8),
            "sweet": String(information.9),
            "bitter": String(information.10),
            "hot": String(information.11)
        ]
        
        do {
               let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
               request.httpBody = jsonData
               print("發送的JSON數據: \(String(data: jsonData, encoding: .utf8) ?? "無法將數據轉化為字符串")")
           } catch {
               print("錯誤: 無法從參數創建JSON")
               return
           }

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("网络请求错误: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.result = (true, "错误: \(error.localizedDescription)")
                }
            } else if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("网络请求响应: \(responseString)")
                DispatchQueue.main.async {
                    if responseString.contains("success") {
                        self.result = (true, "注册成功！")
                    } else {
                        self.result = (true, responseString) // 或者一个更具体的错误消息
                    }
                }
            }
        }.resume()

       }

    // 辅助方法来格式化日期字符串
    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd" // 设定目标格式
        return formatter.string(from: date)
    }

    
    // MARK: InformationLabel記得要搬
    private let label: [InformationLabel]=[
        InformationLabel(image: "person.text.rectangle", label: "帳號"),
        InformationLabel(image: "", label: ""),
        InformationLabel(image: "", label: ""),
        InformationLabel(image: "person.fill", label: "名稱"),
        InformationLabel(image: "figure.arms.open", label: "性別"),
        InformationLabel(image: "birthday.cake", label: "生日"),
        InformationLabel(image: "ruler", label: "身高"),
        InformationLabel(image: "dumbbell", label: "體重"),
        InformationLabel(system: false, image: "acid", label: "酸"),
        InformationLabel(system: false, image: "sweet", label: "甜"),
        InformationLabel(system: false, image: "bitter", label: "苦"),
        InformationLabel(system: false, image: "spicy", label: "辣")
        
    ]
    // MARK: 設定顯示資訊
    private func setInformation(index: Int) -> String
    {
        switch(index)
        {
        case 0: return self.information.0 //帳號
        case 1: return self.information.1 //密碼
        case 2: return self.information.2 //密碼a
        case 3: return self.information.3 //名稱
        case 4: return self.information.4 //性別
        case 5: return  self.information.5//生日
        case 6: return String(self.information.6) //身高
        case 7: return String(self.information.7) //體重
        case 8: return String(self.information.8) //酸
        case 9: return String(self.information.9) //甜
        case 10: return String(self.information.10) //苦
        case 11: return String(self.information.11) //辣
        default: return ""
        }
    }
    
    // MARK: 驗證密碼
    private func passcheck() -> Bool
    {
        return !self.information.1.isEmpty && self.information.1==self.information.2
    }
    
    private func CurrenPageAcc() -> Bool
    {
        if self.information.0.isEmpty || self.information.1.isEmpty || self.information.2.isEmpty
        {
            return false
        }
        else if !self.passcheck()
        {
            return false
        }
        else
        {
            return true
        }
    }
    
    var body: some View
    {
        ZStack(alignment: .top)
        {
            Text(self.title[self.selectedTab])
                .bold()
                .font(.title)
                .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
                .contentTransition(.numericText())
                .offset(y:50)
            
            TabView(selection: self.$selectedTab)
            {
                // MARK: 輸入帳號密碼
                VStack(spacing: 60)
                {
                    VStack(spacing: 20)
                    {
                        TextField("輸入您的帳號", text: self.$information.0)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                            .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                        SecureField("輸入您的密碼", text: self.$information.1)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                            .lineLimit(10)
                            .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                        SecureField("再次輸入密碼", text: self.$information.2)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                            .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                    }
                    
                    //.ignoresSafeArea(.keyboard)
                }
                .tag(0)
                // MARK: 輸入名稱
                VStack(spacing: 60)
                {
                    VStack
                    {
                        // MARK: text: self.$account 改 連結
                        TextField("您的名稱", text: self.$information.3)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                            .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
                    }
                }
                //.ignoresSafeArea(.keyboard)
                .tag(1)
                // MARK: 選擇性別
                VStack(spacing: 20)
                {
                    VStack
                    {
                        Picker("", selection : $information.4)
                        {
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
                // MARK: 輸入生日
                VStack(spacing: 60)
                {
                    if(self.show)
                    {
                        Text(self.description)
                            .bold()
                            .font(.largeTitle)
                            .onAppear
                        {
                            withAnimation(.easeInOut.delay(1))
                            {
                                self.show=false
                            }
                        }
                    } else
                    {
                        VStack(spacing: 50)
                        {
                            DatePicker(selection: self.$date, displayedComponents: .date)
                            {
                                
                            }
                            .onChange(of: self.date) { newDate in
                                self.information.5 = formatDate(date: newDate)
                            }
                        }
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .padding(20)
                    }
                }
                .tag(3)
                // MARK: 輸入身高 體重
                VStack(spacing: 60)
                {
                    // MARK: 身高
                    VStack
                    {
                        TextField("輸入您的身高", text: self.$information.6)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                    }
                    
                    // MARK: 體重
                    VStack
                    {
                        TextField("輸入您的體重", text: self.$information.7)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                    }
                    .padding()
                }
                //                .ignoresSafeArea(.keyboard)
                .tag(4)
                //MARK: 喜好調查
                VStack(spacing: 60) //酸
                {
                    HStack
                    {
                        Text("0")
                            .padding()
                        Slider(value: $information.8, in: 0...5, step: 1)
                            .padding()
                            .accentColor(.blue)
                        Text("5")
                            .padding()
                    }
                    Text("酸: \(Int(information.8))")
                        .padding(.leading, 15)
                }
                .tag(5)
                VStack(spacing: 60) //甜
                {
                    HStack
                    {
                        Text("0")
                            .padding()
                        Slider(value: $information.9, in: 0...5, step: 1)
                            .padding()
                            .accentColor(.blue)
                        Text("5")
                            .padding()
                    }
                    Text("甜: \(Int(information.9))")
                        .padding(.leading, 15)
                }
                .tag(6)
                
                VStack(spacing: 60) //苦
                {
                    HStack
                    {
                        Text("0")
                            .padding()
                        Slider(value: $information.10, in: 0...5, step: 1)
                            .padding()
                            .accentColor(.blue)
                        Text("5")
                            .padding()
                    }
                    Text("苦: \(Int(information.10))")
                        .padding(.leading, 15)
                }
                .tag(7)
                
                VStack(spacing: 60) //辣
                {
                    HStack
                    {
                        Text("0")
                            .padding()
                        Slider(value: $information.11, in: 0...5, step: 1)
                            .padding()
                            .accentColor(.blue)
                        Text("5")
                            .padding()
                    }
                    Text("辣: \(Int(information.11))")
                        .padding(.leading, 15)
                }
                .tag(8)
                // MARK: 所有資料
                VStack
                {
                    List
                    {
                        ForEach(0..<Mirror(reflecting: self.information).children.count, id: \.self)
                        { index in
                            if(!(index==1 || index==2))
                            {
                                HStack
                                {
                                    if(index<self.label.count)
                                    {
                                        self.label[index]
                                    }
                                    Text(
                                        self.setInformation(index: index))
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(.clear)
                    .listRowSeparator(.hidden)
                    
                }
                .tag(9)
                .offset(y:100)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth, value: self.selectedTab)
            .onTapGesture
            {
                self.dismissKeyboard()
            }
            HStack(spacing: 100) {
                if self.selectedTab > 0
                {
                    Button(action:
                            {
                        withAnimation(.easeInOut)
                        {
                            self.selectedTab -= 1
                        }
                    })
                    {
                        Image(systemName: "arrow.left").foregroundColor(.gray)
                    }
                }
                
                Button("", systemImage: self.selectedTab<self.title.count-1 ? "arrow.right":"checkmark")
                {
                    withAnimation(.easeInOut)
                    {
                        if(self.selectedTab==self.title.count-1)
                        {
                            self.dismiss()
                            self.sendRequest()
                           // self.dismiss()
                        }
                        self.selectedTab=self.selectedTab<self.title.count-1 ? self.selectedTab+1:self.selectedTab
                    }
                }
                .contentTransition(.symbolEffect(.replace))
            }
            .font(.largeTitle)
            .frame(maxHeight: .infinity, alignment: .bottom)
            
            // MARK: 結果Alert
            .alert(self.result.1, isPresented: self.$result.0)
            {
                Button("確認")
                {
                    if(self.result.1.contains("success"))
                    {
                        self.dismissKeyboard()
                        }
                }
            }
            
        }
    }
}

struct SignupView_Previews: PreviewProvider
{
    static var previews: some View
    {
        NavigationStack
        {
            SignupView(textselect: .constant(0))
        }
    }
}
