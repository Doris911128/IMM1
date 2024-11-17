//  MyView.swift
//  Graduation_Project
//
//  Created by Mac on 2023/9/15.
//

// MARK: 設置View
import SwiftUI
import PhotosUI

// MARK: MyView
struct MyView: View
{
    @AppStorage("userImage") private var userImage: Data?
    @AppStorage("colorScheme") private var colorScheme: Bool=true
    @AppStorage("signin") private var signin: Bool = false
    
    @Binding var select: Int
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var showPresetImages = false
    @State private var selectIndex = 0
    @State var disID: Int = 1  // 添加一個外部可綁定的 Dis_ID
    @State private var shouldRefreshView = false // 新增一個屬性來儲存是否需要刷新視圖
    @State private var pickImage: PhotosPickerItem?
    @State var isDarkMode: Bool = false
    @State private var isNameSheetPresented = false //更新名字完後會自動關掉ＳＨＥＥＴ
    @State private var isAnimatingColorChange = false // 新增的状态变量，用于动画
    @State private var showingImagePickerAlert = false  // 相簿選取的警示
    @State private var showingPresetImageAlert = false  // 預設圖片選取的警示
    @State private var selectedImageData: Data?         // 暫存選中的圖片數據
    
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var user: User // 從環境中獲取用戶資訊
    
    private let label: [InformationLabel]=[
        InformationLabel(image: "person.fill", label: "名稱"),
        InformationLabel(image: "figure.arms.open", label: "性別"),
        InformationLabel(image: "birthday.cake.fill", label: "生日"),
    ]
    // MARK: 從後端獲取用戶信息並更新 user 物件
    private func fetchUserInfo()
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/Login.php")
        else {
            print("Invalid URL")
            return
        }
        
        
        URLSession.shared.dataTask(with: url)
        { data, response, error in
            guard let data = data else
            {
                print("No data received: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                let decoder = JSONDecoder()
                // 設置日期解碼器的格式
                decoder.dateDecodingStrategy = .iso8601
                let userInfo = try decoder.decode(User.self, from: data)
                DispatchQueue.main.async
                {
                    // 將獲取的用戶信息設置到 user 物件中
                    self.user.update(with: userInfo)
                }
            } catch let error
            {
                print("Error decoding user info: \(error)")
            }
        }.resume()
    }
    
    // MARK: 登出操作 - logout
    func logout()
    {
        guard var urlComponents = URLComponents(string: "http://163.17.9.107/food/php/Login.php") else
        {
            print("Invalid URL")
            return
        }
        // 添加参数以指示登出操作
        urlComponents.queryItems =
        [
            URLQueryItem(name: "logout", value: "true")
        ]
        
        guard let url = urlComponents.url
        else
        {
            print("Failed to construct URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request)
        { data, response, error in
            guard let _ = data, error == nil
            else
            {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // 清除本地会话中的用户信息
                        DispatchQueue.main.async {
                            self.signin = false
                            // 清除存储的用户 ID
                            UserDefaults.standard.removeObject(forKey: "userID")
                        }
        }.resume()
    }
    
    //    private let tag: [String]=["高血壓", "尿酸", "高血脂", "美食尋寶家", "7日打卡"]
    
    // MARK: 設定顯示性別資訊
    private func setInformation(index: Int) -> String
    {
        switch(index)
        {
        case 0:
            return self.user.name
        case 1:
            if let genderInt = Int(self.user.gender)
            {
                switch genderInt
                {
                case 0:
                    return "男性"
                case 1:
                    return "女性"
                default:
                    return "隱私"
                }
            } else
            {
                return "" // 如果无法转换为整数，则返回隐私
            }
        case 2:
            return self.user.birthday
        default:
            return ""
        }
    }
    
    // MARK: MyView body
    var body: some View
    {
        NavigationStack
        {
            GeometryReader
            { geometry in
                ZStack
                {
                    VStack(spacing: 0)
                    {
                        Spacer().frame(height: 10)

                        Form
                        {
                            // MARK: 頭像
                            Section
                            {
                                VStack() 
                                {
                                    if let userImage = self.userImage,
                                       let image = UIImage(data: userImage) {
                                        Button(action: {
                                            self.showingActionSheet = true
                                        }) {
                                            Circle()
                                                .tint(Color.clear) // 背景變透明
                                                .scaledToFit()
                                                .frame(width: 160)
                                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                                .overlay {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .clipShape(Circle())
                                                }
                                        }
                                        .actionSheet(isPresented: $showingActionSheet) {
                                            ActionSheet(title: Text("選擇圖片"), buttons: [
                                                .default(Text("從相簿選取")) {
                                                    self.showingImagePicker = true
                                                },
                                                .default(Text("使用系統預設圖片")) {
                                                    self.showPresetImages = true
                                                },
                                                .cancel()
                                            ])
                                        }
                                    } else {
                                        Button(action: {
                                            self.showingActionSheet = true
                                        }) {
                                            Circle()
                                                .fill(Color.clear) // 背景變透明
                                                .scaledToFit()
                                                .frame(width: 160)
                                                .overlay {
                                                    Image("放縱分類")
                                                        .resizable()
                                                        .scaledToFill()
                                                        .clipShape(Circle())
                                                }
                                        }
                                        .actionSheet(isPresented: $showingActionSheet) {
                                            ActionSheet(title: Text("選擇圖片"), buttons: [
                                                .default(Text("從相簿選取")) {
                                                    self.showingImagePicker = true
                                                },
                                                .default(Text("使用系統預設圖片")) {
                                                    self.showPresetImages = true
                                                },
                                                .cancel()
                                            ])
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center) // 置中
                                .padding(.vertical, 10) // 給 Section 內部一些間距，避免裁切
                                
                                .alert("確認從相簿更換頭像", isPresented: $showingImagePickerAlert)
                                {
                                    Button("取消", role: .cancel) {}
                                    Button("確認") {
                                        if let data = selectedImageData {
                                            self.userImage = data
                                        }
                                    }
                                } message: {
                                    Text("您確定要使用相簿中的圖片嗎？")
                                }
                                .photosPicker(isPresented: $showingImagePicker, selection: $pickImage, matching: .any(of: [.images, .livePhotos]))
                                .onChange(of: pickImage)
                                { newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                            self.selectedImageData = data
                                            self.showingImagePickerAlert = true // 顯示相簿確認警示
                                        }
                                    }
                                }
                                .sheet(isPresented: $showPresetImages)
                                {
                                    PresetImageSelectionView(userImage: $userImage)
                                }
                            }
                            .background(Color.clear) // Section 背景透明
                            .listRowBackground(Color.clear) // 確保行背景也透明
                            
                            .listRowInsets(EdgeInsets(top: -10, leading: 16, bottom: -10, trailing: 16))
                            
                            // 個人資訊
                            Section(header: Text("個人資訊").foregroundColor(isDarkMode ? .white : .black))
                            {
                                
                                // 用戶名稱
                                HStack {
                                    Button(action: {
                                        isNameSheetPresented.toggle()
                                    }) {
                                        HStack {
                                            InformationLabel(image: "person.fill", label: "姓名")
                                            Text(user.name)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .sheet(isPresented: $isNameSheetPresented) {
                                    NameSheetView(name: $user.name, isPresented: $isNameSheetPresented)
                                }
                                
                                // 性別
                                HStack {
                                    self.label[1]
                                    Text(self.setInformation(index: 1))
                                        .foregroundColor(.gray)
                                }
                                
                                // 生日
                                HStack {
                                    self.label[2]
                                    Text(self.setInformation(index: 2))
                                        .foregroundColor(.gray)
                                }
                            }
                            .listRowBackground(isDarkMode ? Color.gray.opacity(0.2) : Color.white)
                            
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            
                            
                            // 更多功能
                            Section(header: Text("更多功能").foregroundColor(isDarkMode ? .white : .black))
                            {
                                
                                // 健康 連結
                                NavigationLink(destination: DynamicView()) {
                                    InformationLabel(image: "chart.xyaxis.line", label: "健康")
                                }
                                
                                // 過往食譜 連結
                                NavigationLink(destination: PastRecipesView()) {
                                    InformationLabel(image: "clock.arrow.circlepath", label: "過往食譜")
                                }
                                
                                // 食材紀錄 連結
                                NavigationLink(destination: StockView()) {
                                    InformationLabel(image: "doc.on.clipboard", label: "檢視庫存")
                                }
                                
                                // 我的最愛 連結
                                NavigationLink(destination: Rec_Col_View()) {
                                    InformationLabel(image: "tray.2.fill", label: "食譜收藏庫")
                                }
                                
                                // 深淺模式切換
                                HStack {
                                    Image(systemName: !self.colorScheme ? "moon.fill" : "sun.max.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .rotationEffect(.degrees(!self.colorScheme ? 360 : 0))
                                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: self.colorScheme)
                                    
                                    Text(!self.colorScheme ? "   深色模式" : "   淺色模式")
                                        .bold()
                                        .font(.body)
                                        .alignmentGuide(.leading) { d in d[.leading] }
                                        .opacity(1)
                                        .animation(.easeInOut(duration: 0.3), value: self.colorScheme)
                                    
                                    Toggle("", isOn: self.$colorScheme)
                                        .tint(Color("BottonColor"))
                                        .scaleEffect(0.75)
                                        .offset(x: 30)
                                        .onChange(of: self.colorScheme) { newValue in
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                fetchUserInfo()
                                            }
                                        }
                                }
                                
                                // 登出按鈕
                                Button(action: {
                                    logout()
                                    withAnimation(.easeInOut) {
                                        self.signin = false
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "power")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 25, height: 25)
                                            .offset(x: 2)
                                        
                                        Text("    登出")
                                            .bold()
                                            .font(.body)
                                            .alignmentGuide(.leading) { d in d[.leading] }
                                    }
                                }
                            }
                            .listRowBackground(isDarkMode ? Color.gray.opacity(0.2) : Color.white)
                            
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        }
                        
                        .listStyle(InsetGroupedListStyle())
                        .background(isDarkMode ? Color.black : Color(.systemGray6))
                        .onChange(of: self.colorScheme) { newValue in
                            self.isDarkMode = !self.colorScheme
                        }
                    }
                    
                }
                .preferredColorScheme(self.colorScheme ? .light : .dark) // 控制深浅模式切换
                .onAppear
                {
                    fetchUserInfo()
                }
            }
        }
    }
    
    
    // MARK: NameSheetView 更改用戶頭名稱
    struct NameSheetView: View
    {
        @Binding var name: String
        @Binding var isPresented: Bool
        
        @State private var newU_Name = ""
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("更改姓名")) {
                        TextField("新的姓名", text: $newU_Name)
                    }
                }
                .navigationBarItems(
                    leading: Button("取消") {
                        isPresented = false
                    },
                    trailing: Button("保存") {
                        guard let url = URL(string: "http://163.17.9.107/food/php/UpdateUsername.php") else {
                            print("Invalid URL")
                            return
                        }
                        
                        let parameters = "newU_Name=\(newU_Name)"
                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                        request.httpBody = parameters.data(using: .utf8)
                        
                        URLSession.shared.dataTask(with: request) { data, response, error in
                            guard let _ = data, error == nil else {
                                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                                return
                            }
                            
                            DispatchQueue.main.async {
                                self.name = self.newU_Name
                                self.isPresented = false
                            }
                        }.resume()
                    }
                )
            }
        }
    }
    
    // MARK: PresetImageSelectionView 更改用戶頭像改小熊貓
    struct PresetImageSelectionView: View
    {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        @Environment(\.presentationMode) var presentationMode
        @State private var showingPresetImageAlert = false  // 預設圖片選取的警示
        @State private var selectedImageData: Data?         // 暫存選中的圖片數據
        @State private var selectedImageName: String?
        @Binding var userImage: Data?
        let presetImages = ["我的最愛", "已採購", "公開食譜", "分類未新增最愛", "自訂食材預設圖片", "空庫存", "空AI食譜", "省錢分類", "庫存菜單", "庫存頭腳", "素食分類", "健康推薦", "採購", "烹飪", "最愛", "減肥分類", "過往食譜", "懶人分類", "AI食譜"] // 替換為你的預設圖片名稱
        
        var body: some View
        {
            ScrollView
            {
                LazyVGrid(columns: columns, spacing: 20)
                {
                    ForEach(presetImages, id: \.self)
                    { imageName in
                        Button(action: {
                            self.selectedImageName = imageName
                            if let imageName = self.selectedImageName {
                                self.selectedImageData = UIImage(named: imageName)?.pngData()
                                self.showingPresetImageAlert = true // 顯示預設圖片確認警示
                            }
                        }) {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .padding()
                        }
                    }
                }
                .padding()
            }
            .alert("確認使用預設圖片", isPresented: $showingPresetImageAlert) {
                Button("取消", role: .cancel) {}
                Button("確認") {
                    if let data = selectedImageData {
                        self.userImage = data
                        self.presentationMode.wrappedValue.dismiss() // 返回到原本的畫面
                    }
                }
            } message: {
                Text("您確定要使用此預設圖片嗎？")
            }
        }
    }
}

struct MyView_Previews: PreviewProvider
{
    static var previews: some View
    {
        NavigationStack
        {
            MyView(select: .constant(0), disID: 1)  // 提供常數綁定
        }
    }
}
