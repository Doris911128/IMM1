//突破完全
//  StockView.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/12/17.
//

import SwiftUI

struct Stock: Codable {
    let F_ID: Int
    let F_Name: String?
    let U_ID: String?
    let SK_SUM: Int?
}

// MARK: 庫存食材格式
struct StockIngredient: Identifiable {
    let U_ID: String
    var id = UUID()
    var F_Name: String
    var quantity: Int
    var isSelectedForDeletion: Bool = false
}

// MARK: 新增採購食材
struct AddIngredients: View {
    @State private var selectedIngredientIndex = 0
    @State private var newIngredientQuantity: String = ""
    @State private var showAlert = false
    var onAdd: (StockIngredient) -> Void

    @Binding var isSheetPresented: Bool
    @State private var ingredientNames: [String] = [] // 使用 @State 属性存储食材名称 （多這行）

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("新增食材")) {
                    Picker("選擇食材", selection: $selectedIngredientIndex) {
                        ForEach(0..<ingredientNames.count) { index in
                            Text(ingredientNames[index])
                                .tag(index)
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
                                    if let quantity = Int(newIngredientQuantity), quantity > 0 {
                                        let newIngredient = StockIngredient(U_ID: UUID().uuidString, F_Name: ingredientNames[selectedIngredientIndex], quantity: quantity)
                                        onAdd(newIngredient)
                                        isSheetPresented = false
                                    } else {
                                        showAlert = true
                                    }
                                }
                            }
                        }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("輸入無效字元"), message: Text("請確保輸入的數量是有效的"), dismissButton: .default(Text("好的")) {
                    // 清空文本框
                    newIngredientQuantity = ""
                })
            }
        }
        .onAppear {
            // 在视图出现时更新食材名称数组
            fetchIngredientNames()
        }
    }

    private func fetchIngredientNames() {
        // 在这里获取食材名称数据
        let networkManager = NetworkManager()
        networkManager.fetchData { result in
            switch result {
            case .success(let responses):
                // 提取食材名称，并赋值给 ingredientNames
                ingredientNames = responses.compactMap { $0.F_Name }
            case .failure(let error):
                print("Failed to fetch ingredient names: \(error)")
            }
        }
    }
    
//    // MARK: 要抓資料庫的食材
//    private let ingredientNames = ["食材1", "食材2", "食材3", "食材4", "食材5", "食材3", "食材4", "食材5"]

    private func sendDataToServer() {
        guard let url = URL(string: "http://163.17.9.107/food/Stock.php") else {
            print("Invalid URL")
            return
        }

        // 创建要发送的数据
        let requestData: [String: Any] = [
            "quantity": Int(newIngredientQuantity) ?? 0
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestData, options: [])

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response as? HTTPURLResponse, error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

                if response.statusCode == 200 {
                    // Data sent successfully
                    print("Data sent successfully")

                    // 打印食材及数量
                    print("食材: \(ingredientNames[selectedIngredientIndex]), 數量: \(newIngredientQuantity)")

                } else {
                    // HTTP请求失败
                    print("HTTP Status Code: \(response.statusCode)")
                    print("Data sending failed")
                }
            }.resume()
        } catch {
            print("Error serializing data: \(error.localizedDescription)")
        }
    }

}

class NetworkManager {
    func fetchData(completion: @escaping (Result<[Stock], Error>) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/Stock.php") else {
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
                let responses = try decoder.decode([Stock].self, from: data)
                completion(.success(responses))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

}

// MARK: 庫存主介面
struct StockView: View {
    @State private var ingredients: [StockIngredient] = []
//    @State private var ingredientNames: [String] = [] // 添加一个属性用于存储食材名称

    @State private var isAddSheetPresented = false
    @State private var isEditing: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("庫存")
                    .font(.title)
                    .padding()

                // MARK: 庫存清單
                List {
                    ForEach(ingredients.indices, id: \.self) { index in
                        HStack {
                            // MARK: 編輯功能
                            if isEditing {
                                Button(action: {
                                    toggleSelection(index)
                                }) {
                                    Image(systemName: ingredients[index].isSelectedForDeletion ? "checkmark.square" : "square")
                                }
                                .buttonStyle(BorderlessButtonStyle()) //非編輯模式下點擊按鈕不觸發滑動刪除
                            }

                            Text("\(ingredients[index].F_Name): \(ingredients[index].quantity)")
                                .foregroundColor(ingredients[index].isSelectedForDeletion ? .gray : .primary)

                            Spacer()

                            // MARK: 開啟編輯後的文字框
                            if isEditing {
                                TextField("數量", value: $ingredients[index].quantity, formatter: NumberFormatter())
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(width: 50)
                            }
                        }
                    }
                }
                .padding()

                HStack {
                    // MARK: 新增食材鍵
                    if isEditing {
                        Button("新增食材") {
                            isAddSheetPresented.toggle()
                        }
                        .padding()
                    }
                }
                .padding()

                // MARK: 新增食材的SHEET
                .sheet(isPresented: $isAddSheetPresented) {
                    AddIngredients(onAdd: { newIngredient in
                        ingredients.append(newIngredient)
                    }, isSheetPresented: $isAddSheetPresented)
                }
                .onAppear {
                    fetchData()
                }
            }
            // MARK: 右上角編輯鍵
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // MARK: 開啟編輯鍵
                        if !isEditing {
                            Button("編輯") {
                                isEditing.toggle()
                            }
                        } else {
                            // MARK: 編輯後顯示刪除或保存
                            Button(action: {
                                // Check if any item is selected for deletion
                                let selectedItemsCount = ingredients.filter { $0.isSelectedForDeletion }.count
                                if selectedItemsCount > 0 {
                                    // Perform deletion logic here
                                    deleteSelectedIngredients()
                                } else {
                                    // Cancel editing mode
                                    isEditing.toggle()
                                }
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
    func fetchData() {
        let networkManager = NetworkManager()
        networkManager.fetchData { result in
            switch result {
            case .success(let responses):
                // 使用 compactMap 转换数据，确保所有元素都能转换为 StockIngredient，对于缺失的数据使用默认值
                ingredients = responses.compactMap { response in
                    // 使用 ?? 运算符提供默认值
                    let name = response.F_Name ?? "未知食材"
                    let quantity = response.SK_SUM ?? 0
                    return StockIngredient(U_ID: response.U_ID ?? UUID().uuidString, F_Name: name, quantity: quantity)
                }
            case .failure(let error):
                print("錯誤：\(error)")
                // 處理錯誤
            }
        }
    }

//    func fetchData() {
//        let networkManager = NetworkManager()
//        networkManager.fetchData { result in
//            switch result {
//            case .success(let responses):
//                // 将获取到的数据用于初始化 ingredients
//                ingredients = responses.compactMap { response in
//                    guard let name = response.F_Name, let quantity = response.SK_SUM
//                    else {
//                        // 如果食材名称或数量为空，初始化为默认值
//                        return nil
//                    }
//                    return StockIngredient(name: name, quantity: Int(quantity) ?? 0)
//                }
//            case .failure(let error):
//                print("錯誤：\(error)")
//                // 處理錯誤
//            }
//        }
//    }

    // MARK: 編輯採購清單方法
    private func toggleSelection(_ index: Int) {
        ingredients[index].isSelectedForDeletion.toggle()
    }

    // MARK: 刪除採購清單方法
    private func deleteSelectedIngredients() {
        // Filter out the selected indices and convert them to IndexSet
        let indexSet = IndexSet(ingredients.indices.filter { ingredients[$0].isSelectedForDeletion })
        ingredients.remove(atOffsets: indexSet)

        // Exit editing mode after deletion
        isEditing = false
    }
}

struct StockView_Previews: PreviewProvider {
    static var previews: some View {
        StockView()
    }
}
