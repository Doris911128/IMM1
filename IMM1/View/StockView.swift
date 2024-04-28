// 時刻監控食材變動數量
import SwiftUI

// MARK: - 数据模型定义
struct Stock: Codable {
    let F_ID: Int
    let F_Name: String?
    let U_ID: String?
    let SK_SUM: Int?
}

struct StockIngredient: Identifiable {
    var id = UUID()
    let U_ID: String
    let F_ID: Int
    var F_Name: String
    var SK_SUM: Int
    var isSelectedForDeletion: Bool = false
    var isEditing: Bool = false // 表示是否处于编辑模式
}

struct IngredientInfo {
    let F_Name: String
    let F_ID: Int
}

// MARK: - 新增食材視圖
struct AddIngredients: View {
    @State private var selectedIngredientIndex = 0
    @State private var newIngredientQuantity: String = ""
    @State private var searchText = ""  // 搜索文本
    @State private var showAlert = false
    @State private var ingredientsInfo: [IngredientInfo] = []
    

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
                            Text(filteredIngredients[index].F_Name).tag(index)
                        }
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
                            let selectedInfo = filteredIngredients[selectedIngredientIndex]
                            let newIngredient = StockIngredient(U_ID: UUID().uuidString, F_ID: selectedInfo.F_ID, F_Name: selectedInfo.F_Name, SK_SUM: SK_SUM)
                            onAdd(newIngredient)
                            let json = toJSONString(F_ID: newIngredient.F_ID, U_ID: newIngredient.U_ID, SK_SUM: newIngredient.SK_SUM)
                            sendDataToServer(json: json, F_ID: newIngredient.F_ID, U_ID: newIngredient.U_ID, SK_SUM: newIngredient.SK_SUM)
                            print("新增食材信息：F_ID=\(newIngredient.F_ID), U_ID=\(newIngredient.U_ID), SK_SUM=\(newIngredient.SK_SUM)")
                            isSheetPresented = false
                            isEditing = false // 在這裡新增這行程式碼
                        } else {
                            showAlert = true
                        }
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("輸入無效字元"), message: Text("請確保輸入的數量是有效的"), dismissButton: .default(Text("好的")) {
                    newIngredientQuantity = ""
                })
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
                    if let name = stock.F_Name {
                        return IngredientInfo(F_Name: name, F_ID: stock.F_ID)
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

// MARK: - 主库存视图
struct StockView: View {
    @State private var ingredients: [StockIngredient] = []
    @State private var isAddSheetPresented = false
    @State private var isEditing: Bool = false
    @State private var showAlert = false
    @State private var triggerRefresh: Bool = false // 用于触发视图刷新
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("庫存")
                    .font(.title)
                    .padding()
                
                List {
                    ForEach(ingredients.indices, id: \.self) { index in
                        HStack {
                            if isEditing {
                                Button(action: {
                                    toggleSelection(index)
                                }) {
                                    Image(systemName: ingredients[index].isSelectedForDeletion ? "checkmark.square" : "square")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                // 显示食材名称
                                Text(ingredients[index].F_Name)
                                    .foregroundColor(ingredients[index].isSelectedForDeletion ? .gray : .primary)
                                
                                Spacer() // 创建自动扩展的空间
                                
                                // 显示可编辑的食材数量
//                                TextField("食材數量", value: $ingredients[index].SK_SUM, formatter: NumberFormatter())
//                                    .keyboardType(.numberPad)
//                                    .multilineTextAlignment(.trailing) // 右对齐
                                TextField("食材數量", value: $ingredients[index].SK_SUM, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing) // 右对齐
                                    .onChange(of: ingredients[index].SK_SUM) { newValue in
                                        sendEditedIngredientData(F_ID: ingredients[index].F_ID, U_ID: ingredients[index].U_ID, SK_SUM: newValue)
                                    }

                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing) // 右对齐

                            } else {
                                // 如果不处于编辑模式，显示只读的文本
                                Text(ingredients[index].F_Name)
                                    .foregroundColor(ingredients[index].isSelectedForDeletion ? .gray : .primary)
                                
                                Spacer() // 创建自动扩展的空间
                                
                                Text("\(ingredients[index].SK_SUM)")
                                    .foregroundColor(ingredients[index].isSelectedForDeletion ? .gray : .primary)
                                    .multilineTextAlignment(.trailing) // 右对齐
                            }
                        }
                    }
                }
                .padding()

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
                        triggerRefresh.toggle()  // 切换这个状态以触发视图刷新
                    }, isSheetPresented: $isAddSheetPresented, isEditing: $isEditing)
                }


                .onAppear {
                    fetchData()
                }
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
                                    // 确认删除操作
                                    // 删除选中的食材
                                    let selectedIngredients = ingredients.filter { $0.isSelectedForDeletion }
                                    selectedIngredients.forEach { ingredient in
                                        print("Deleting Ingredient: F_ID=\(ingredient.F_ID), U_ID=\(ingredient.U_ID)")
                                        sendIngredientData(F_ID: ingredient.F_ID, U_ID: ingredient.U_ID)
                                    }
                                    
                                    // 移除被删除的食材
                                    let indexSet = IndexSet(ingredients.indices.filter { ingredients[$0].isSelectedForDeletion })
                                    ingredients.remove(atOffsets: indexSet)
                                    
                                    // 删除后刷新数据并退出编辑模式
                                    fetchData()
                                    isEditing = false
                                }, secondaryButton: .cancel(Text("取消")) {
                                    // 取消勾选选中的食材
                                    ingredients.indices.forEach { index in
                                        ingredients[index].isSelectedForDeletion = false
                                    }
                                    isEditing = false // 恢复到未进入编辑模式的状态
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
                ingredients = stocks.compactMap { stock in
                    let name = stock.F_Name ?? "未知食材"
                    let SK_SUM = stock.SK_SUM ?? 0
                    return StockIngredient(U_ID: stock.U_ID ?? UUID().uuidString, F_ID: stock.F_ID, F_Name: name, SK_SUM: SK_SUM)
                }
            case .failure(let error):
                print("錯誤：\(error)")
            }
        }
    }
    
    private func toggleSelection(_ index: Int) {
        ingredients[index].isSelectedForDeletion.toggle()
    }
    
//    private func deleteSelectedIngredients() {
//        let selectedIngredients = ingredients.filter { $0.isSelectedForDeletion }
//
//        selectedIngredients.forEach { ingredient in
//            print("Deleting Ingredient: F_ID=\(ingredient.F_ID), U_ID=\(ingredient.U_ID)")
//            sendIngredientData(F_ID: ingredient.F_ID, U_ID: ingredient.U_ID)
//        }
//
//        let indexSet = IndexSet(ingredients.indices.filter { ingredients[$0].isSelectedForDeletion })
//        ingredients.remove(atOffsets: indexSet)
//        fetchData()  // Refresh the data after deletion
//        isEditing = false
//    }
    private func deleteSelectedIngredients() {
        let selectedIngredients = ingredients.filter { $0.isSelectedForDeletion }
        
        // 檢查是否有選擇的食材需要刪除
        guard !selectedIngredients.isEmpty else {
            print("No ingredients selected for deletion")
            return
        }
        
        // 彈出警示框，讓使用者確認是否要刪除
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
    func sendEditedIngredientData(F_ID: Int, U_ID: String, SK_SUM: Int) {
        let jsonDict: [String: Any] = [
            "F_ID": F_ID,
            "U_ID": U_ID,
            "SK_SUM": SK_SUM
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
            guard let url = URL(string: "http://163.17.9.107/food/Stockupdate.php") else {
                print("Invalid URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending data to server: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Data sent successfully")
                } else {
                    print("Server responded with status code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                }
            }.resume()
        } catch {
            print("Error creating JSON data: \(error)")
        }
    }

}


struct StockView_Previews: PreviewProvider {
    static var previews: some View {
        StockView()
    }
}
