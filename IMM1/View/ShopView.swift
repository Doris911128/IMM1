import SwiftUI
import Foundation

// 修改 RecipeWrapper，添加 isSelected 屬性
struct RecipeWrapper: Codable {
    var sqlResult: Ingredient
    var shopPlan: ShopPlan? // 將 shopPlan 改為可選的
    var isSelected: Bool = false // 新添加的 isSelected 屬性

    enum CodingKeys: String, CodingKey {
        case sqlResult = "sql_result"
        case shopPlan = "shop_plan"
    }

    var planAmount: String? {
        return shopPlan?.amount
    }
}

struct ShopPlan: Codable {
    var amount: String

    enum CodingKeys: String, CodingKey {
        case amount = "SP_Amount"
    }
}

struct Ingredient: Identifiable, Codable {
    let id = UUID()
    let uid: String
    var pID: String?
    var fid: Int
    var disID: Int?
    var amount: Int
    var name: String
    var unit: String
    var stock: Int?
    var P_DT: String? // 添加日期屬性

    enum CodingKeys: String, CodingKey {
        case uid = "U_ID"
        case pID = "P_ID"
        case fid = "F_ID"
        case disID = "Dis_ID"
        case amount = "A_Amount"
        case name = "F_Name"
        case unit = "F_Unit"
        case stock = "SK_SUM"
        case P_DT = "P_DT" // 指定日期屬性的 CodingKey
    }
}

// Network Manager
class ShopNetworkManager {
    func fetchAndAggregateRecipes(completion: @escaping (Result<[RecipeWrapper], Error>) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/Shop.php") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "未接收到数据"])))
                return
            }

            // Debugging: print the received JSON data as a string
            print(String(data: data, encoding: .utf8) ?? "Data could not be printed")

            do {
                var recipeWrappers = try JSONDecoder().decode([RecipeWrapper].self, from: data)

                // Aggregate recipes with the same name
                var aggregatedRecipes: [String: RecipeWrapper] = [:]

                for wrapper in recipeWrappers {
                    let name = wrapper.sqlResult.name
                    if var existingWrapper = aggregatedRecipes[name] {
                        // Update the amount and stock
                        existingWrapper.sqlResult.amount += wrapper.sqlResult.amount
                        existingWrapper.sqlResult.stock = (existingWrapper.sqlResult.stock ?? 0) + (wrapper.sqlResult.stock ?? 0)
                        aggregatedRecipes[name] = existingWrapper
                    } else {
                        aggregatedRecipes[name] = wrapper
                    }
                }

                // Convert to an array
                let aggregatedArray = Array(aggregatedRecipes.values)
                completion(.success(aggregatedArray))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct RecipeView: View {
    @Binding var recipes: [RecipeWrapper]
    @State private var hiddenIngredients: Set<UUID> = []
    var onDeleteIngredient: (Ingredient) -> Void
    var onIngredientSelection: (Int, String, Int) -> Void // 修改回調函數的參數

    @Binding var selectedIngredients: [Ingredient]
    
    // 使用字典来存储每个食材的输入值
    @State private var quantityInputs: [UUID: String] = [:]

    init(recipes: Binding<[RecipeWrapper]>, onDeleteIngredient: @escaping (Ingredient) -> Void, selectedIngredients: Binding<[Ingredient]>, onIngredientSelection: @escaping (Int, String, Int) -> Void) {
        self._recipes = recipes
        self.onDeleteIngredient = onDeleteIngredient
        self._hiddenIngredients = State(initialValue: [])
        self._selectedIngredients = selectedIngredients // 將 selectedIngredients 綁定到屬性
        self.onIngredientSelection = onIngredientSelection // 更新回調函數的參數
    }

    var body: some View {
        if recipes.isEmpty {
            Spacer()
            Text("目前無採買項目")
            Spacer()
        } else {
            List {
                ForEach(recipes, id: \.sqlResult.id) { wrapper in
                    if !shouldHideIngredient(wrapper.sqlResult.id) {
                        Section(header: EmptyView()) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(" \(wrapper.sqlResult.name)")
                                    HStack {
                                        Text("採購數量: \(wrapper.planAmount ?? "0")\(wrapper.sqlResult.unit)")
                                            .padding(.trailing, -50) // 添加额外的右侧间距
                                    }
                                }
                                .padding(.vertical, 8)
                                Spacer()
                                    .padding(.trailing, -10) // 添加右侧 padding
                                TextField("數量", text: Binding(
                                    get: {
                                        // 当用户输入时，直接返回输入的值
                                        self.quantityInputs[wrapper.sqlResult.id] ?? (wrapper.planAmount ?? "")
                                    },
                                    set: { newValue in
                                        // 当用户输入时，直接更新 quantityInputs
                                        self.quantityInputs[wrapper.sqlResult.id] = newValue
                                }))

                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .keyboardType(.numberPad)
                                Image(systemName: wrapper.isSelected ? "checkmark.square.fill" : "square")
                                    .foregroundColor(wrapper.isSelected ? .green : .orange)
                                    .onTapGesture {
                                        toggleIngredientSelection(wrapper)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 25))
        }
    }

    private func toggleIngredientSelection(_ wrapper: RecipeWrapper) {
             // 更新 isSelected 属性的逻辑...
             if let index = recipes.firstIndex(where: { $0.sqlResult.id == wrapper.sqlResult.id }) {
                 // 获取默认值...
                 let defaultQuantity = wrapper.planAmount ?? ""
                 
                 // 直接从 quantityInputs 中获取值，如果没有则使用默认值...
                 let quantity = Int(quantityInputs[wrapper.sqlResult.id] ?? defaultQuantity) ?? 0
                 recipes[index].sqlResult.amount = quantity
                 
                 recipes[index].isSelected.toggle()
                 
                 // 当用户勾选食材时，将其 UUID 添加到 hiddenIngredients 集合中...
                 if recipes[index].isSelected {
                     selectedIngredients.append(recipes[index].sqlResult)
                     onIngredientSelection(recipes[index].sqlResult.fid, recipes[index].sqlResult.uid, recipes[index].sqlResult.amount)
                     
                     // 将食材的 UUID 添加到 hiddenIngredients 集合中...
                     hiddenIngredients.insert(wrapper.sqlResult.id)
                 } else {
                     if let selectedIndex = selectedIngredients.firstIndex(where: { $0.id == wrapper.sqlResult.id }) {
                         selectedIngredients.remove(at: selectedIndex)
                     }
                 }
             }
         }





    private func shouldHideIngredient(_ id: UUID) -> Bool {
        return hiddenIngredients.contains(id)
    }
}

struct ShopView: View {
    @State private var recipes: [RecipeWrapper] = []
    @State private var isLoading = true
    @State private var selectedIngredients: [Ingredient] = []
    @State private var userUID: String? // 用戶的 UID

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var sevenDaysAgo: Date {
        return Calendar.current.date(byAdding: .day, value: 7, to: currentDate)!
    }

    private var currentDate: Date {
        return Date()
    }

    // 在此處獲取和設置用戶的 UID
    func getUserUIDFromDatabase() {
        // 在這裡從您的資料庫中獲取用戶的 UID
        // 並將其存儲在 userUID 中
        // 這裡僅為示例，您需要根據您的應用程序邏輯來實現
        // 例如，如果您使用 Firebase，您可以通過 Auth.currentUser?.uid 獲取用戶的 UID
        // 或者您可以使用自定義的身份驗證系統從自己的服務器獲取用戶的 UID
    }

    // 在 ShopView 中添加 sendSelectedIngredientsToBackend 方法
    private func sendSelectedIngredientsToBackend() {
        // 在這裡實現將所選食材發送到後端的邏輯
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text("採購")
                
                if isLoading {
                    ProgressView("加載中...")
                } else {
                    RecipeView(
                        recipes: $recipes,
                        onDeleteIngredient: { ingredient in
                            // 更新選定的食材...
                        },
                        selectedIngredients: $selectedIngredients,
                        onIngredientSelection: handleIngredientSelection // 使用新的回調函數
                    )
                }
            }
        }
        .onAppear {
            getUserUIDFromDatabase() // 在視圖出現時從資料庫獲取用戶的 UID
            loadRecipes()
        }
        // Send selected ingredients to backend when the view disappears
        .onDisappear {
            sendSelectedIngredientsToBackend()
        }
    }

    // 修改 handleIngredientSelection 方法，接受用戶的 UID 作為參數
    private func handleIngredientSelection(_ fid: Int, _ uid: String, _ sksum: Int) {
        // 將值轉換成字典
        let jsonDict: [String: Any] = [
            "F_ID": fid,
            "U_ID": uid,
            "SK_SUM": sksum
        ]
        
        // 將字典轉換成 JSON 數據
        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) {
            // 調用 sendJSONDataToBackend 函數，將 JSON 數據發送到後端
            sendJSONDataToBackend(jsonData: jsonData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                           // 打印 JSON 字符串
                           print("JSON String:", jsonString)
                       }
        }
    }

    
    private func loadRecipes() {
        // 獲取當前日期和7天前的日期
        let currentDateStr = dateFormatter.string(from: currentDate)
        let sevenDaysAgoStr = dateFormatter.string(from: sevenDaysAgo)
        
        print("Current Date String:", currentDateStr)
        print("Seven Days Ago String:", sevenDaysAgoStr)

        // 使用日期參數構建URL
        guard let url = URL(string: "http://163.17.9.107/food/Shop.php?start_date=\(sevenDaysAgoStr)&end_date=\(currentDateStr)") else {
            print("Invalid URL")
            self.isLoading = false
            return
        }

        // 發送URL請求
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil else {
                print("Error:", error!)
                self.handleLoadingError()
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Invalid HTTP response")
                self.handleLoadingError()
                return
            }

            guard let data = data else {
                print("No data received")
                self.handleLoadingError()
                return
            }

            do {
                let recipeWrappers = try JSONDecoder().decode([RecipeWrapper].self, from: data)
                self.aggregateRecipes(recipeWrappers)
            } catch {
                print("Error decoding JSON:", error)
                self.handleLoadingError()
            }
        }.resume()
    }

    private func makeURL(startDate: String, endDate: String) -> URL? {
        let urlString = "http://163.17.9.107/food/Shop.php?start_date=\(startDate)&end_date=\(endDate)"
        return URL(string: urlString)
    }
    
    private func handleLoadingError() {
        self.isLoading = false
    }
    
    private func aggregateRecipes(_ recipeWrappers: [RecipeWrapper]) {
        var aggregatedRecipes: [String: RecipeWrapper] = [:]
        
        for wrapper in recipeWrappers {
            guard let dateStr = wrapper.sqlResult.P_DT, let recipeDate = dateFormatter.date(from: dateStr) else {
                continue // Skip if the date is invalid
            }
            
            // Check if the recipe date is within the last 7 days
            if isWithinLastSevenDays(date: recipeDate) {
                let name = wrapper.sqlResult.name
                if var existingWrapper = aggregatedRecipes[name] {
                    existingWrapper.sqlResult.amount += wrapper.sqlResult.amount
                    existingWrapper.sqlResult.stock = (existingWrapper.sqlResult.stock ?? 0) + (wrapper.sqlResult.stock ?? 0)
                    aggregatedRecipes[name] = existingWrapper
                } else {
                    aggregatedRecipes[name] = wrapper
                }
            }
        }
        
        let aggregatedArray = Array(aggregatedRecipes.values)
        
        DispatchQueue.main.async {
            self.recipes = aggregatedArray
            self.isLoading = false
        }
    }
    
    private func isWithinLastSevenDays(date: Date) -> Bool {
        return date <= sevenDaysAgo && date >= currentDate
    }
}
private func sendJSONDataToBackend(jsonData: Data) {
    // 構建要發送的URL
    guard let url = URL(string: "http://163.17.9.107/food/ShopStock.php") else {
        print("Invalid URL")
        return
    }

    // 構建 HTTP 請求
    var request = URLRequest(url: url)
    request.httpMethod = "POST" // 使用 POST 方法
    request.setValue("application/json", forHTTPHeaderField: "Content-Type") // 設置 Content-Type 為 JSON

    // 將 JSON 數據設置為 HTTP 請求的主體
    request.httpBody = jsonData

    // 發送 HTTP 請求
    URLSession.shared.dataTask(with: request) { data, response, error in
        // 檢查是否有錯誤
        if let error = error {
            print("Error:", error)
            return
        }

        // 檢查服務器響應
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            print("Invalid HTTP response")
            return
        }

        // 成功響應
        print("Data sent successfully")
    }.resume()
}

// SwiftUI Preview
struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView()
    }
}
