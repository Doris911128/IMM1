
// MARK: 註冊View
import SwiftUI

struct SignupView: View
{
    
    @Binding var textselect: Int
    
    @State private var information: (String, String, String, String, String, String, String, String,Double , Double ,Double ,Double)=("", "", "", "", "", "", "" , "" ,0.0,0.0,0.0,0.0)
    @State private var result : (Bool,String)=(false,"") //執行結果Alert
    @State private var show: Bool=false //生日顯示
    @State private var description: String=""
    @State private var date: Date=Date()
    @State private var selectedTab = 0
    
    @Environment(\.dismiss) private var dismiss
    
    init(textselect: Binding<Int>)
    {
        self._textselect=textselect
        UIPageControl.appearance().currentPageIndicatorTintColor = .orange
        UIPageControl.appearance().pageIndicatorTintColor = .gray
    }
    
    // MARK: 註冊使用者
    private func signup() async
    {
        if(self.information.0.isEmpty || self.information.1.isEmpty || self.information.1 != self.information.2) //輸入框有空 || 密碼不相同
        {
            self.result.1="1.請確保沒有空白字段。\n2. 請確保您的密碼相同。"
            self.result.0.toggle()
        }
        else
        {
            //Authentication
            Authentication().signup(account: self.information.0, password: self.information.1)
            {(_, error) in
                if let error=error //註冊失敗
                {
                    self.result.1=error.localizedDescription
                    self.result.0.toggle()
                    
                } else //註冊成功
                {
                    //Realtime Database
                    RealTime().signup(account: self.information.0, password: self.information.1, name: self.information.3,gender: self.information.4,birthday:self.information.5, height: String(self.information.6),weight: String(self.information.7), like1: String(self.information.8),like2: String(self.information.9),like3: String(self.information.10),like4: String(self.information.11))
                    self.result.1="註冊成功!"
                    self.result.0.toggle()
                    self.dismiss()
                }
            }
        }
    }
    
    // MARK: InformationLabel記得要搬
    private let label: [InformationLabel]=[
        InformationLabel(image: "person.text.rectangle", label: "帳號"),
        InformationLabel(image: "", label: ""),
        InformationLabel(image: "", label: ""),
        InformationLabel(image: "person.fill", label: "名稱"),
        InformationLabel(image: "figure.arms.open", label: "性別"),
        InformationLabel(image: "birthday.cake.fill", label: "生日"),
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
        case 0:
            return self.information.0 //帳號
        case 1:
            return self.information.1 //密碼
        case 2:
            return self.information.2 //密碼a
        case 3:
            return self.information.3 //名稱
        case 4:
            return self.information.4 //性別
        case 5:
            return self.information.5//生日
        case 6:
            return "\(self.information.6)" //身高
        case 7:
            return "\(self.information.7)" //體重
        case 8:
            return "\(self.information.8)" //酸
        case 9:
            return "\(self.information.9)" //甜
        case 10:
            return "\(self.information.10)" //苦
        case 11:
            return "\(self.information.11)" //辣
        default:
            return ""
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
        TabView(selection: $selectedTab)
        {
            NavigationStack
            {
                // MARK: 輸入帳號密碼
                VStack(spacing: 60)
                {
                    VStack(spacing: 20)
                    {
                        Text("請輸入您的帳號 密碼")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
                        TextField("輸入您的帳號", text: self.$information.0)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                        
                        SecureField("輸入您的密碼", text: self.$information.1)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                            .lineLimit(10)
                        
                        SecureField("再次輸入密碼", text: self.$information.2)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .frame(width: 300, height: 50)
                            .cornerRadius(100)
                    }
                    VStack
                    {
                        Button
                        {
                            
                            selectedTab = 1
                        }
                        
                    label:
                        {
                            Text("下一步")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 300, height: 60)
                                .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                                .clipShape(Capsule())
                        }
                    }
                }
                .ignoresSafeArea(.keyboard)
            }
            .tag(0)
            
            // MARK: 輸入名稱
            VStack(spacing: 60)
            {
                VStack
                {
                    Text("請輸入您的名稱")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
                    // MARK: text: self.$account 改 連結
                    TextField("您的名稱", text: self.$information.3)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .frame(width: 300, height: 50)
                        .cornerRadius(100)
                }
                VStack
                {
                    Button
                    {
                        selectedTab = 2
                    }
                label:
                    {
                        Text("下一步")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                            .clipShape(Capsule())
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .tag(1)
            
            // MARK: 選擇性別
            VStack(spacing: 20)
            {
                Text("請選擇您的性別")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
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
                VStack
                {
                    Button
                    {
                        selectedTab = 3
                    }
                label:
                    {
                        Text("下一步")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                            .clipShape(Capsule())
                    }
                }
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
                    HStack{
                        Text("請輸入您的生日")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
                    }
                    VStack(spacing: 50)
                    {
                        DatePicker(selection: self.$date, displayedComponents: .date)
                        {
                            
                        }
                        .onChange(of: self.date) {(_, new) in
                            self.information.5=new.formatted(date: .numeric, time: .omitted)
                        }
                    }
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                    .padding(20)
                }
                VStack
                {
                    Button
                    {
                        selectedTab = 4
                    }
                label:
                    {
                        Text("下一步")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                            .clipShape(Capsule())
                        
                    }
                }
            }
            .tag(3)
            
            // MARK: 輸入身高 體重
            VStack(spacing: 60)
            {
                Text("請輸入您的身高(CM)和體重(KG)")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
                
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
                VStack
                {
                    Button
                    {
                        selectedTab = 5
                    }
                label:
                    {
                        Text("下一步")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                            .clipShape(Capsule())
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .tag(4)
            
            //MARK: 喜好調查
            VStack(spacing: 60) //酸
            {
                Text("請調整您的偏好")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
                HStack
                {
                    Text("1")
                        .padding()
                    Slider(value: $information.8, in: 1...5, step: 1)
                        .padding()
                        .accentColor(.blue)
                    Text("5")
                        .padding()
                }
                Text("酸: \(Int(information.8))")
                    .padding(.leading, 15)
                VStack
                {
                    Button
                    {
                        selectedTab = 6
                    }
                label:
                    {
                        Text("下一步")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                            .clipShape(Capsule())
                    }
                }
            }
            .tag(5)
            
            VStack(spacing: 60) //甜
            {
                Text("請調整您的偏好")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
                HStack
                {
                    Text("1")
                        .padding()
                    Slider(value: $information.9, in: 1...5, step: 1)
                        .padding()
                        .accentColor(.blue)
                    Text("5")
                        .padding()
                }
                Text("甜: \(Int(information.9))")
                    .padding(.leading, 15)
                VStack
                {
                    Button
                    {
                        selectedTab = 7
                    }
                label:
                    {
                        Text("下一步")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                            .clipShape(Capsule())
                    }
                }
            }
            .tag(6)
            
            VStack(spacing: 60) //苦
            {
                Text("請調整您的偏好")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
                HStack
                {
                    Text("1")
                        .padding()
                    Slider(value: $information.10, in: 1...5, step: 1)
                        .padding()
                        .accentColor(.blue)
                    Text("5")
                        .padding()
                }
                Text("苦: \(Int(information.10))")
                    .padding(.leading, 15)
                VStack
                {
                    Button
                    {
                        selectedTab = 8
                    }
                label:
                    {
                        Text("下一步")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                            .clipShape(Capsule())
                    }
                }
            }
            .tag(7)
           
            VStack(spacing: 60) //辣
            {
                Text("請調整您的偏好")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
                HStack
                {
                    Text("1")
                        .padding()
                    Slider(value: $information.11, in: 1...5, step: 1)
                        .padding()
                        .accentColor(.blue)
                    Text("5")
                        .padding()
                }
                Text("辣: \(Int(information.11))")
                    .padding(.leading, 15)
                VStack
                {
                    Button
                    {
                        selectedTab = 9
                    }
                label:
                    {
                        Text("下一步")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                            .clipShape(Capsule())
                    }
                }
            }
            .tag(8)
            // MARK: 所有資料
            VStack
            {
                Text("個人資訊")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.828, green: 0.249, blue: 0.115))
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
                VStack
                {
                    Button
                    {
                        Task
                        {
                            await self.signup() //註冊
                        }
                    }
                label:
                    {
                        Text("完成註冊～歡迎註冊")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 60)
                            .background(Color(red: 0.828, green: 0.249, blue: 0.115))
                            .clipShape(Capsule())
                    }
                }
            }
            .tag(9)
        }
        .tabViewStyle(.page(indexDisplayMode: self.selectedTab<9 ? .always:.never))
        .animation(.smooth, value: self.selectedTab)
        .onTapGesture 
        {
            self.dismissKeyboard()
        }
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
