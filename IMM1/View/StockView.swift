//突破完全
//  StockView.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/12/17.
//
// 左右排版ＯＫ
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
}

struct IngredientInfo {
    let F_Name: String
    let F_ID: Int
}

// MARK: - 新增食材视图
struct AddIngredients: View {
    @State private var selectedIngredientIndex = 0
    @State private var newIngredientQuantity: String = ""
    @State private var showAlert = false
    var onAdd: (StockIngredient) -> Void
    
    @Binding var isSheetPresented: Bool
    @State private var ingredientsInfo: [IngredientInfo] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("新增食材")) {
                    Picker("選擇食材", selection: $selectedIngredientIndex) {
                        ForEach(0..<ingredientsInfo.count, id: \.self) { index in
                            Text(ingredientsInfo[index].F_Name)
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
                            let selectedInfo = ingredientsInfo[selectedIngredientIndex]
                            let newIngredient = StockIngredient(U_ID: UUID().uuidString, F_ID: selectedInfo.F_ID, F_Name: selectedInfo.F_Name, SK_SUM: SK_SUM)
                            onAdd(newIngredient)
                            let json = toJSONString(F_ID: newIngredient.F_ID, U_ID: newIngredient.U_ID, SK_SUM: newIngredient.SK_SUM)
                            sendDataToServer(json: json, F_ID: newIngredient.F_ID, U_ID: newIngredient.U_ID, SK_SUM: newIngredient.SK_SUM)
                            print("新增食材信息：F_ID=\(newIngredient.F_ID), U_ID=\(newIngredient.U_ID), SK_SUM=\(newIngredient.SK_SUM)")
                            isSheetPresented = false
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
    
    private func toJSONString(F_ID: Int, U_ID: String, SK_SUM: Int) -> String? {
        let jsonDict: [String: Any] = [
            "F_ID": F_ID,
            "U_ID": U_ID,
            "SK_SUM": SK_SUM // 注意这里修改为SK_SUM
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
                            }
                            
                            // 食材名称固定在左边
                            Text(ingredients[index].F_Name)
                                .foregroundColor(ingredients[index].isSelectedForDeletion ? .gray : .primary)
                            
                            Spacer()
                            
                            // 数量固定在右边
                            Text("\(ingredients[index].SK_SUM)")
                                .foregroundColor(ingredients[index].isSelectedForDeletion ? .gray : .primary)
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
                    }, isSheetPresented: $isAddSheetPresented)
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
                                let selectedItemsCount = ingredients.filter { $0.isSelectedForDeletion }.count
                                if selectedItemsCount > 0 {
                                    deleteSelectedIngredients()
                                } else {
                                    isEditing.toggle()
                                }
                                fetchData()  // Call fetchData to refresh data
                            }) {
                                Text(ingredients.contains { $0.isSelectedForDeletion } ? "刪除" : "保存")
                            }
                            .padding()
                        }
                    }
                }
            }
        }
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
    
    private func deleteSelectedIngredients() {
        let indexSet = IndexSet(ingredients.indices.filter { ingredients[$0].isSelectedForDeletion })
        ingredients.remove(atOffsets: indexSet)
        fetchData()  // Refresh the data after deletion
        isEditing = false
    }
}


struct StockView_Previews: PreviewProvider {
    static var previews: some View {
        StockView()
    }
}
