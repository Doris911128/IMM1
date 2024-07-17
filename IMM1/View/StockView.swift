// 時刻監控食材變動數量＿警示框ＯＫ
import SwiftUI

// MARK: - 数据模型定义
struct Stock: Codable {
    let F_ID: Int
    let F_Name: String?
    let U_ID: String?
    let SK_SUM: Int?
    let F_Unit: String?
    var Food_imge: String?
}

struct StockIngredient: Identifiable {
    var id = UUID()
    let U_ID: String
    let F_ID: Int
    var F_Name: String
    var SK_SUM: Int
    let F_Unit: String?
    var Food_imge: String?  // 新增食材圖片URL屬性
    var isSelectedForDeletion: Bool = false
    var isEditing: Bool = false // 表示是否处于编辑模式
}

struct IngredientInfo {
    let F_Name: String
    let F_ID: Int
    let F_Unit :String
    let Food_imge :String
    
}

// MARK: - 新增食材視圖
struct AddIngredients: View {
    @State private var selectedIngredientIndex = 0
    @State private var newIngredientQuantity: String = ""
    @State private var searchText = ""  // 搜索文本
    @State private var showAlert = false
    @State private var ingredientsInfo: [IngredientInfo] = []
    @State private var refreshTrigger = false
    
    var onAdd: (StockIngredient) -> Void
    
    @Binding var isSheetPresented: Bool
    @Binding var isEditing: Bool
    
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("新增食材")) {
              
                    TextField("搜索食材", text: $searchText)
                        .autocapitalization(.none)
                    
                    Picker("選擇食材", selection: $selectedIngredientIndex) {
                        ForEach(filteredIngredients.indices, id: \.self) { index in
                            Text("\(filteredIngredients[index].F_Name) (\(filteredIngredients[index].F_Unit))").tag(index)                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("請輸入食材數量", text: $newIngredientQuantity)
                        .keyboardType(.numberPad)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新增") {
                        if let SK_SUM = Int(newIngredientQuantity), SK_SUM > 0 {
                            if filteredIngredients.isEmpty {
                                showAlert = true // 如果过滤后的列表为空，显示警示
                            } else {
                                let selectedInfo = filteredIngredients[selectedIngredientIndex]
                                let newIngredient = StockIngredient(
                                    U_ID: UUID().uuidString,
                                    F_ID: selectedInfo.F_ID,
                                    F_Name: selectedInfo.F_Name,
                                    SK_SUM: SK_SUM,
                                    F_Unit: selectedInfo.F_Unit  // 正确引用F_Unit
                                )
                                onAdd(newIngredient)
                                let json = toJSONString(F_ID: newIngredient.F_ID, U_ID: newIngredient.U_ID, SK_SUM: newIngredient.SK_SUM)
                                sendDataToServer(json: json, F_ID: newIngredient.F_ID, U_ID: newIngredient.U_ID, SK_SUM: newIngredient.SK_SUM)
                                print("新增食材信息：F_ID=\(newIngredient.F_ID), U_ID=\(newIngredient.U_ID), SK_SUM=\(newIngredient.SK_SUM)")
                                
                                isSheetPresented = false
                                isEditing = false
                                refreshTrigger.toggle()  // Toggle the refresh trigger to update the view
                            }
                        } else {
                            showAlert = true
                        }
                    }
                    
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("警告"),
                    message: Text("請確認輸入的食材名稱或數量字元是否正確"),
                    dismissButton: .default(Text("好的")) {
                        searchText = ""  // 清空搜索文本框
                        newIngredientQuantity = ""  // 如果需要，也可以同時清空數量輸入框
                    }
                )
            }
            
        }
        .onAppear {
            fetchIngredientNames()
        }
    }
    
    // 根据搜索文本过滤食材
    var filteredIngredients: [IngredientInfo] {
        if searchText.isEmpty {
            return ingredientsInfo
        } else {
            return ingredientsInfo.filter { $0.F_Name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    // MARK: 抓取食材名稱的Function
    private func fetchIngredientNames() {
        let networkManager = NetworkManager()
        networkManager.fetchData(from: "http://163.17.9.107/food/Food.php") { result in
            switch result {
            case .success(let stocks):
                ingredientsInfo = stocks.compactMap { stock in
                    if let name = stock.F_Name, let unit = stock.F_Unit, let imge = stock.Food_imge {
                        return IngredientInfo(F_Name: name, F_ID: stock.F_ID, F_Unit: unit, Food_imge: imge)
                    } else {
                        return nil
                    }
                }
            case .failure(let error):
                print("Failed to fetch ingredient names: \(error)")
            }
        }
    }


    
    
    // MARK: 將資料改為Json字串的Function
    func toJSONString(F_ID: Int, U_ID: String, SK_SUM: Int) -> String? {
        let jsonDict: [String: Any] = [
            "F_ID": F_ID,
            "U_ID": U_ID,
            "SK_SUM": SK_SUM
        ]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error converting to JSON: \(error)")
            return nil
        }
    }
    
    
    private func sendDataToServer(json: String?, F_ID: Int, U_ID: String, SK_SUM: Int) {
        guard let jsonData = json, let url = URL(string: "http://163.17.9.107/food/Stock.php") else {
            print("Invalid URL or JSON data")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending data to server: \(error)")
                return
            }
            
            if let response = response as? HTTPURLResponse, let data = data {
                if response.statusCode == 200 {  // 判断响应状态码
                    if let responseJSON = String(data: data, encoding: .utf8) {
                        print("Response JSON: \(responseJSON)") // 打印服务器返回的JSON数据
                    } else {
                        print("Received data could not be converted to JSON")
                    }
                } else {
                    print("Server responded with status code: \(response.statusCode)")
                }
            }
        }.resume()
    }
}

// MARK: - 网络管理器
class NetworkManager {
    func fetchData(from urlString: String, completion: @escaping (Result<[Stock], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "無效的網址"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "未收到數據"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let stocks = try decoder.decode([Stock].self, from: data)
                completion(.success(stocks))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - 主庫存視圖
struct StockView: View {
    @State private var ingredients: [StockIngredient] = []
    @State private var isAddSheetPresented = false
    @State private var isEditing: Bool = false
    @State private var showAlert = false
    @State private var triggerRefresh: Bool = false // 用于触发视图刷新
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("庫存")
                    .font(.title)
                    .padding()
                
                if ingredients.isEmpty {
                    Spacer()
                    Text("目前無庫存項目")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(ingredients.indices, id: \.self) { index in
                                ZStack(alignment: .topLeading) {
                                    VStack {
                                        // 顯示圖片
                                        if let imageUrl = ingredients[index].Food_imge, let url = URL(string: imageUrl) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 150, height: 150)
                                                        .clipShape(Circle())
                                                case .failure:
                                                    Image(systemName: "photo")
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 150, height: 150)
                                                        .clipShape(Circle())
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            .padding(.bottom, 8) // 調整圖片與文字之間的距離
                                        } else {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 150, height: 150)
                                                .clipShape(Circle())
                                                .padding(.bottom, 8) // 調整圖片與文字之間的距離
                                        }
                                        
                                        HStack {
                                            Text(ingredients[index].F_Name)
                                                .lineLimit(1) // 限制為1行，超出部分顯示省略號
                                                .foregroundColor(ingredients[index].isSelectedForDeletion ? .gray : .primary)
                                            
                                            Spacer()
                                            
                                            if isEditing {
                                                TextField("食材數量", value: $ingredients[index].SK_SUM, formatter: NumberFormatter())
                                                    .keyboardType(.numberPad)
                                                    .frame(width: 50) // 限制 TextField 寬度
                                                    .multilineTextAlignment(.trailing)
                                                    .padding(.leading, -20) // 调整 TextField 左侧 padding
                                                    .onChange(of: ingredients[index].SK_SUM) { newValue in
                                                        sendEditedIngredientData(F_ID: ingredients[index].F_ID, U_ID: ingredients[index].U_ID, SK_SUM: newValue)
                                                    }
                                            } else {
                                                HStack {
                                                    Text("\(ingredients[index].SK_SUM)")
                                                    Text(ingredients[index].F_Unit ?? "")
                                                }
                                                .foregroundColor(ingredients[index].isSelectedForDeletion ? .gray : .primary)
                                                .multilineTextAlignment(.trailing)
                                            }
                                        }
                                        .padding()
                                        .background(Color(UIColor.systemBackground))
                                        .cornerRadius(8)
                                        .shadow(radius: 4)
                                    }
                                    
                                    if isEditing {
                                        Button(action: {
                                            toggleSelection(index)
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(ingredients[index].isSelectedForDeletion ? Color.gray : Color.orange)
                                                    .frame(width: 30, height: 30)
                                                
                                                Image(systemName: ingredients[index].isSelectedForDeletion ? "checkmark.square" : "square")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .offset(x: 5, y: 0) // 調整按鈕的位置
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                HStack {
                    if isEditing {
                        Button("新增食材") {
                            isAddSheetPresented.toggle()
                        }
                        .padding()
                    }
                }
                .padding()
                .sheet(isPresented: $isAddSheetPresented) {
                    AddIngredients(onAdd: { newIngredient in
                        ingredients.append(newIngredient)
                        triggerRefresh.toggle()
                    }, isSheetPresented: $isAddSheetPresented, isEditing: $isEditing)
                }
                .onAppear {
                    fetchData()
                }
                .id(triggerRefresh)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !isEditing {
                            Button("編輯") {
                                isEditing.toggle()
                            }
                        } else {
                            Button(action: {
                                if ingredients.contains { $0.isSelectedForDeletion } {
                                    showAlert.toggle()
                                } else {
                                    isEditing.toggle()
                                }
                            }) {
                                Text(ingredients.contains { $0.isSelectedForDeletion } ? "刪除" : "確定")
                            }
                            .padding()
                            .alert(isPresented: $showAlert) {
                                Alert(title: Text("確認刪除"), message: Text("您確定要刪除所選的食材嗎？"), primaryButton: .default(Text("確定")) {
                                    let selectedIngredients = ingredients.filter { $0.isSelectedForDeletion }
                                    selectedIngredients.forEach { ingredient in
                                        print("Deleting Ingredient: F_ID=\(ingredient.F_ID), U_ID=\(ingredient.U_ID)")
                                        sendIngredientData(F_ID: ingredient.F_ID, U_ID: ingredient.U_ID)
                                    }
                                    
                                    let indexSet = IndexSet(ingredients.indices.filter { ingredients[$0].isSelectedForDeletion })
                                    ingredients.remove(atOffsets: indexSet)
                                    
                                    fetchData()
                                    isEditing = false
                                }, secondaryButton: .cancel(Text("取消")) {
                                    ingredients.indices.forEach { index in
                                        ingredients[index].isSelectedForDeletion = false
                                    }
                                    isEditing = false
                                })
                            }
                        }
                    }
                }
            }
        }
        .id(triggerRefresh)
    }
    
    private func fetchData() {
        let networkManager = NetworkManager()
        networkManager.fetchData(from: "http://163.17.9.107/food/Stock.php") { result in
            switch result {
            case .success(let stocks):
                self.ingredients = stocks.compactMap { stock in
                    let name = stock.F_Name ?? "未知食材"
                    let unit = stock.F_Unit ?? "未指定单位"
                    let SK_SUM = stock.SK_SUM ?? 0
                    let image = stock.Food_imge ?? ""  // 确保Food_imge被正确解析

                    return StockIngredient(U_ID: stock.U_ID ?? UUID().uuidString, F_ID: stock.F_ID, F_Name: name, SK_SUM: SK_SUM, F_Unit: unit, Food_imge: image)
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    private func toggleSelection(_ index: Int) {
        ingredients[index].isSelectedForDeletion.toggle()
    }
    
    private func deleteSelectedIngredients() {
        let selectedIngredients = ingredients.filter { $0.isSelectedForDeletion }
        guard !selectedIngredients.isEmpty else {
            print("No ingredients selected for deletion")
            return
        }
        showAlert = true
    }
    
    private func sendIngredientData(F_ID: Int, U_ID: String) {
        let jsonDict: [String: Any] = [
            "F_ID": F_ID,
            "U_ID": U_ID
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict),
              let url = URL(string: "http://163.17.9.107/food/Stockdelete.php") else {
            print("Error creating JSON or URL")
            return
        }
        
        print("Sending to server: F_ID=\(F_ID), U_ID=\(U_ID)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending ingredient deletion data: \(error)")
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200, let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("Server response: \(responseString)")
            } else {
                print("Unexpected server response or data")
            }
        }.resume()
    }
    
    private func sendEditedIngredientData(F_ID: Int, U_ID: String, SK_SUM: Int) {
        let jsonDict: [String: Any] = [
            "F_ID": F_ID,
            "U_ID": U_ID,
            "SK_SUM": SK_SUM
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict),
              let url = URL(string: "http://163.17.9.107/food/StockEdit.php") else {
            print("Error creating JSON or URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending ingredient edited data: \(error)")
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200, let data = data,
               let responseString = String(data: data, encoding: .utf8) {
                print("Server response: \(responseString)")
            } else {
                print("Unexpected server response or data")
            }
        }.resume()
    }
}

struct StockView_Previews: PreviewProvider {
    static var previews: some View {
        StockView()
    }
}
