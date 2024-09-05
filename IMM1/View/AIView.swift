// AIView.swift

import SwiftUI

// 用於編碼和解碼 JSON 資料的結構
struct DataModel: Codable
{
    var text: String
}

// 處理伺服器回應的 JSON 資料
struct RecipeResponse: Codable
{
    var output: String
}

// ForEach 循環中使用
struct IdentifiableOption: Identifiable
{
    var id = UUID()
    var title: String
}

struct ResponseWrapper: Codable
{
    var chatRecords: [ChatRecord] // 根據實際的 JSON 結構定義
}

//MARK: 此畫面主結構＿歷史聊天紀錄
struct ChatRecord: Identifiable, Codable
{
    var id: Int { Recipe_ID }
    let Recipe_ID: Int
    let U_ID: String
    let input: String
    let output: String
    var isAICol: Bool
    
    // 自定义解码方法，将 Int 转换为 Bool
    enum CodingKeys: String, CodingKey
    {
        case Recipe_ID, U_ID, input, output, isAICol = "isAICol"
    }
    
    init(from decoder: Decoder) throws 
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        Recipe_ID = try container.decode(Int.self, forKey: .Recipe_ID)
        U_ID = try container.decode(String.self, forKey: .U_ID)
        input = try container.decode(String.self, forKey: .input)
        output = try container.decode(String.self, forKey: .output)
        let isAIColInt = try container.decode(Int.self, forKey: .isAICol)
        isAICol = isAIColInt == 1
    }
}


//MARK: 用於顯示歷史對話紀錄的視圖
struct ChatHistoryView: View
{
    @State private var chatRecords: [ChatRecord] = []
    @State private var currentUserID: String? = nil

    
    //MARK: 根據用戶的 ID 從伺服器獲取該用戶的聊天記錄
    func fetchChatRecords(for userID: String)
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/GetRecipe1.php?U_ID=\(userID)")
        else
        {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data
            else
            {
                print("No data received")
                return
            }
            
            // Print raw JSON
            if let jsonString = String(data: data, encoding: .utf8)
            {
                print("Raw JSON: \(jsonString)")
            }
            
            // Decode the JSON response
            do {
                let decoder = JSONDecoder()
                let records = try decoder.decode([ChatRecord].self, from: data)
                
                // Filter the records for the current user
                DispatchQueue.main.async
                {
                    self.chatRecords = records.filter { $0.U_ID == userID }
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    var body: some View
    {
        VStack
        {
            Text("歷史對話紀錄")
                .font(.system(size: 22))
                .bold()
                .padding()
                .offset(y:5)
            
            ScrollView
            {
                if chatRecords.isEmpty
                {
                    // 顯示暫時無歷史紀錄的視圖
                    VStack
                    {
                        Image("空ai紀錄")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                        Text("暫時無歷史紀錄")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    .offset(y:180)
                } else {
                    VStack(spacing: 20) {  // 设置卡片之间的垂直间距
                        ForEach(chatRecords) { record in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .shadow(radius: 4)
                                
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("問：\(record.input)")
                                            .fontWeight(.bold)
                                        Spacer()
                                        
                                        Button(action: {
                                            toggleAIColmark(U_ID: record.U_ID, Recipe_ID: record.Recipe_ID, isAICol: !record.isAICol) { result in
                                                switch result {
                                                case .success(let message):
                                                    DispatchQueue.main.async {
                                                        if let index = chatRecords.firstIndex(where: { $0.Recipe_ID == record.Recipe_ID }) {
                                                            chatRecords[index].isAICol.toggle() // 更新收藏狀態
                                                        }
                                                        print("isAICol Action successful: \(message)") // 打印成功消息
                                                    }
                                                case .failure(let error):
                                                    DispatchQueue.main.async {
                                                        print("Error toggling AICol: \(error.localizedDescription)")
                                                    }
                                                }
                                            }
                                        }) {
                                            Image(systemName: record.isAICol ? "bookmark.fill" : "bookmark")
                                                .font(.title)
                                                .foregroundColor(.red)
                                        }
                                        .offset(y: -22)
                                        
                                    }
                                    Text("答：\(record.output)")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical) // 添加顶端和底端的间距
                }
            }
        }
        .onAppear {
            fetchUserID { userID in
                guard let userID = userID else {
                    print("Failed to get user ID")
                    return
                }
                self.currentUserID = userID
                fetchChatRecords(for: userID)
            }
        }
    }
}

//MARK: 主要的互動界面
struct AIView: View
{
    @State private var messageText: String = ""
    @State private var messages: [String] = []
    @State private var isLoading: Bool = false
    @State private var searchingMessageIndex: Int? = nil
    @State private var showingImagePicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedOption: IdentifiableOption? = nil
    @State private var selectedItems: Set<String> = []
    @State private var showHistory: Bool = false
    @State private var isLoading1 = false
    
    var body: some View {
        VStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer().frame(width: 20)
                    Button(action: {
                        showHistory.toggle()
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                            .frame(width: 40, height: 40)
                    }
                    .sheet(isPresented: $showHistory) {
                        ChatHistoryView() // 用於顯示歷史對話紀錄的視圖
                    }
                    
                    Spacer()
                    Text("AI助手")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .offset(x: -10, y: 0)
                    Spacer()
                    NavigationLink(destination: AIphotoView()) {
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
                
                ForEach(messages.indices, id: \.self) { index in
                    HStack {
                        if messages[index].starts(with: "答：") {
                            ServerMessageView(message: messages[index])
                        } else {
                            UserMessageView(message: messages[index])
                        }
                    }
                    .padding()
                }
                if isLoading1 {
                    LoadingAnimationView()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .padding()
                }
                if isLoading {
                    LoadingView()
                        .frame(width: 300,height: 300)
                        .padding()
                    
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    OptionButton(title: "減脂增肌", action: { self.selectedOption = IdentifiableOption(title: "減脂增肌") })
                    OptionButton(title: "穩定血脂", action: { self.selectedOption = IdentifiableOption(title: "穩定血脂") })
                    OptionButton(title: "穩定血壓", action: { self.selectedOption = IdentifiableOption(title: "穩定血壓") })
                    OptionButton(title: "穩定血糖", action: { self.selectedOption = IdentifiableOption(title: "穩定血糖") })
                }
                .padding(.horizontal)
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
        .sheet(item: $selectedOption) { option in
            OptionSheet(option: option.title, selectedItems: $selectedItems) {
                // Update the messageText with selected items
                let selectedItemsString = selectedItems.joined(separator: ", ")
                messageText = selectedItemsString
                // Dismiss the sheet
                self.selectedOption = nil
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType:.photoLibrary)
            
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                // Handle the selected image here
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            }
        }
    }
    
    //MARK: 點擊發送按鈕時被調用
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        let dataModel = DataModel(text: messageText)
        messages.append("問：\(messageText)") // Add user message
        isLoading = true // Show loading animation after user sends message
        messageText = ""
        
        sendToDatabase(dataModel: dataModel)
    }
    
    //MARK: 獲取最新的 AI 回應
    func sendToDatabase(dataModel: DataModel) {
        guard let url = URL(string: "http://163.17.9.107/food/php/AI_Recipe.php") else { return }
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
    
    //MARK: 獲取最新的 AI 回應 更新到 messages 中
    func fetchData() {
        guard let url = URL(string: "http://163.17.9.107/food/php/GetRecipe.php") else { return }
        
        // 開始加載動畫
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading1 = false // 停止加載動畫
                    if self.searchingMessageIndex == nil {
                        self.messages.append("答：Error occurred. Retrying...")
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
                    self.isLoading1 = false // 停止加載動畫
                    if self.searchingMessageIndex == nil {
                        self.messages.append("答：No data received. Retrying...")
                        self.searchingMessageIndex = self.messages.count - 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.fetchData()
                    }
                }
                return
            }
            
            // 解碼 JSON 回應
            do {
                let decoder = JSONDecoder()
                let recipeResponse = try decoder.decode(RecipeResponse.self, from: data)
                
                DispatchQueue.main.async {
                    if recipeResponse.output == "Loading..." {
                        if self.searchingMessageIndex == nil {
                            self.messages.append("答：生成中....")
                            self.searchingMessageIndex = self.messages.count - 1
                        }
                        
                        // 繼續顯示加載動畫並再次調用 fetchData()
                        self.isLoading1 = true
                        self.fetchData()
                    } else {
                        if let index = self.searchingMessageIndex {
                            self.messages[index] = "答：\(recipeResponse.output)"
                        } else {
                            self.messages.append("答：\(recipeResponse.output)")
                        }
                        self.isLoading = false // 停止加載動畫
                        self.searchingMessageIndex = nil // 重設標誌
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading1 = false // 停止加載動畫
                    if self.searchingMessageIndex == nil {
                        self.messages.append("答：生成中....")
                        self.searchingMessageIndex = self.messages.count - 1
                    }
                    self.fetchData()
                }
            }
        }.resume()
    }
    
}


struct OptionButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 20) // Adjust horizontal padding for a capsule effect
                .padding(.vertical, 10) // Adjust vertical padding for a capsule effect
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue) // Set text color to match the background
                .clipShape(Capsule()) // Create a capsule shape
                .frame(minWidth: 100) // Set a minimum width
        }
    }
}

struct OptionSheet: View {
    var option: String
    @Binding var selectedItems: Set<String>
    var onDismiss: () -> Void
    var body: some View {
        NavigationView {
            List {
                switch option {
                case "減脂增肌":
                    Section(header: Text("蛋白質來源")) {
                        ForEach(proteinSources, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("碳水化合物來源")) {
                        ForEach(carbohydrateSources, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("健康脂肪來源")) {
                        ForEach(fatSources, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("蔬菜和水果")) {
                        ForEach(vegetablesAndFruits, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                case "穩定血脂":
                    Section(header: Text("纖維豐富的食材")) {
                        ForEach(fiberRichFoods, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("健康脂肪來源")) {
                        ForEach(fatSourcesForBloodFat, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("蔬菜和水果")) {
                        ForEach(vegetablesAndFruitsForBloodFat, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("碳水化合物來源")) {
                        ForEach(carbohydrateSourcesForBloodFat, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                case "穩定血壓":
                    Section(header: Text("鉀質豐富的食材")) {
                        ForEach(potassiumRichFoods, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("高纖維食材")) {
                        ForEach(highFiberFoodsForBloodPressure, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("健康脂肪來源")) {
                        ForEach(fatSourcesForBloodPressure, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                case "穩定血糖":
                    Section(header: Text("低升糖指數（GI）食材")) {
                        ForEach(lowGIFoods, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("高纖維食材")) {
                        ForEach(highFiberFoodsForBloodSugar, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("健康脂肪來源")) {
                        ForEach(fatSourcesForBloodSugar, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                    Section(header: Text("蛋白質來源")) {
                        ForEach(proteinSourcesForBloodSugar, id: \.self) { item in
                            OptionRow(item: item, isSelected: self.selectedItems.contains(item)) {
                                toggleSelection(for: item)
                            }
                        }
                    }
                default:
                    Text("No options available.")
                }
            }
            .navigationTitle(option)
            .navigationBarItems(trailing: Button("完成") {
                onDismiss()
                self.selectedItems.removeAll()
            })
        }
    }
    
    func toggleSelection(for item: String) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
    
    var proteinSources = [
        "雞胸肉", "鮭魚","鱈魚", "豆腐", "希臘酸奶（無糖）"
    ]
    
    var carbohydrateSources = [
        "地瓜", "蕎麥", "藜麥"
    ]
    
    var fatSources = [
        "鮭魚", "酪梨","亞麻籽"
    ]
    
    var vegetablesAndFruits = [
        "菠菜","羽衣甘藍", "番茄", "胡蘿蔔", "蘋果", "梨"
    ]
    
    var fiberRichFoods = [
        "燕麥", "全麥麵包", "糙米", "黑豆","鷹嘴豆", "杏仁","核桃"
    ]
    
    var fatSourcesForBloodFat = [
        "鮭魚", "酪梨", "橄欖油", "亞麻籽"
    ]
    
    var vegetablesAndFruitsForBloodFat = [
        "菠菜","羽衣甘藍", "番茄", "胡蘿蔔", "蘋果", "梨"
    ]
    
    var carbohydrateSourcesForBloodFat = [
        "地瓜", "蕎麥", "藜麥"
    ]
    
    var potassiumRichFoods = [
        "香蕉", "酪梨", "地瓜", "菠菜", "蘑菇", "番茄"
    ]
    
    var highFiberFoodsForBloodPressure = [
        "燕麥", "全麥麵包","蘋果", "梨"
    ]
    
    var fatSourcesForBloodPressure = [
        "鮭魚","杏仁","核桃"
    ]
    
    var lowGIFoods = [
        "燕麥","糙米","藜麥","全麥麵包","黑豆","藍豆","綠豆","豌豆"
    ]
    
    var highFiberFoodsForBloodSugar = [
        "菠菜","羽衣甘藍","西蘭花","胡蘿蔔","蘆筍","蘋果","梨","藍莓","草莓"
    ]
    
    var fatSourcesForBloodSugar = [
        "杏仁","核桃","開心果","酪梨"
    ]
    
    var proteinSourcesForBloodSugar = [
        "雞胸肉","鮭魚","鱈魚","豆腐","希臘酸奶（無糖）"
    ]
}


struct OptionRow: View {
    var item: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        HStack {
            Text(item)
                .padding()
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct ServerMessageView: View {
    var message: String
    
    var body: some View {
        HStack {
            Image("登入Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
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
