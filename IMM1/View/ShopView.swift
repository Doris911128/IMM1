import SwiftUI
import Foundation

// Define model structs
struct ResponseDa: Codable {
    var data: [Ingredient]
    var shopPlanData: [ShopPlan]

    enum CodingKeys: String, CodingKey {
        case data
        case shopPlanData = "shop_plan_data"
    }
}

struct ShopPlan: Codable {
    var uid: String
    var fid: String
    var amount: String

    enum CodingKeys: String, CodingKey {
        case uid = "U_ID"
        case fid = "F_ID"
        case amount = "SP_Amount"
    }
}

struct Ingredient: Identifiable, Codable {
    let id = UUID()
    let pID: String
    let uid: String
    let fid: Int
    let disID: Int
    var amount: Int
    let name: String
    let unit: String
    var stock: Int
    let P_DT: String

    enum CodingKeys: String, CodingKey {
        case pID = "P_ID"
        case uid = "U_ID"
        case fid = "F_ID"
        case disID = "Dis_ID"
        case amount = "A_Amount"
        case name = "F_Name"
        case unit = "F_Unit"
        case stock = "SK_SUM"
        case P_DT = "P_DT"
    }
}

// Define network manager
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
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            print(String(data: data, encoding: .utf8) ?? "Data could not be printed")

            do {
                let responseData = try JSONDecoder().decode(ResponseDa.self, from: data)
                
                // Convert raw data to RecipeWrapper
                var recipeWrappers: [RecipeWrapper] = responseData.data.map { ingredient in
                    let shopPlan = responseData.shopPlanData.first { $0.fid == String(ingredient.fid) && $0.uid == ingredient.uid }
                    return RecipeWrapper(sqlResult: ingredient, shopPlan: shopPlan)
                }

                // Print parsed data for debugging
                for wrapper in recipeWrappers {
                    print("Ingredient: \(wrapper.sqlResult.name), Unit: \(wrapper.sqlResult.unit), Plan Amount: \(wrapper.planAmount ?? "N/A")")
                }

                var aggregatedRecipes: [String: RecipeWrapper] = [:]

                for wrapper in recipeWrappers {
                    let name = wrapper.sqlResult.name
                    if var existingWrapper = aggregatedRecipes[name] {
                        existingWrapper.sqlResult.amount += wrapper.sqlResult.amount
                        existingWrapper.sqlResult.stock += wrapper.sqlResult.stock
                        aggregatedRecipes[name] = existingWrapper
                    } else {
                        aggregatedRecipes[name] = wrapper
                    }
                }

                let aggregatedArray = Array(aggregatedRecipes.values)
                completion(.success(aggregatedArray))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct RecipeWrapper: Codable {
    var sqlResult: Ingredient
    var shopPlan: ShopPlan?
    var isSelected: Bool = false

    var planAmount: String? {
        return shopPlan?.amount
    }
}

// Define views
struct RecipeView: View {
    @Binding var recipes: [RecipeWrapper]
    @State private var hiddenIngredients: Set<UUID> = []
    var onDeleteIngredient: (Ingredient) -> Void
    var onIngredientSelection: (Int, String, Int) -> Void
    @Binding var selectedIngredients: [Ingredient]
    @State private var quantityInputs: [UUID: String] = [:]

    init(recipes: Binding<[RecipeWrapper]>, onDeleteIngredient: @escaping (Ingredient) -> Void, selectedIngredients: Binding<[Ingredient]>, onIngredientSelection: @escaping (Int, String, Int) -> Void) {
        self._recipes = recipes
        self.onDeleteIngredient = onDeleteIngredient
        self._hiddenIngredients = State(initialValue: [])
        self._selectedIngredients = selectedIngredients
        self.onIngredientSelection = onIngredientSelection
    }

    var body: some View {
        if recipes.isEmpty {
            Spacer()
            Text("目前無採買項目")
            Spacer()
        } else {
            List {
                ForEach(recipes, id: \.sqlResult.id) { wrapper in
                    if !shouldHideIngredient(wrapper.sqlResult.id) && (Int(wrapper.planAmount ?? "0") ?? 0) > 0 {
                        Section(header: EmptyView()) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(" \(wrapper.sqlResult.name)")
                                    HStack {
                                        Text("採購數量: \(wrapper.planAmount ?? "0")\(wrapper.sqlResult.unit)")
                                            .padding(.trailing, -50)
                                    }
                                }
                                .padding(.vertical, 8)
                                Spacer()
                                    .padding(.trailing, -10)
                                TextField("數量", text: Binding(
                                    get: {
                                        self.quantityInputs[wrapper.sqlResult.id] ?? (wrapper.planAmount ?? "")
                                    },
                                    set: { newValue in
                                        self.quantityInputs[wrapper.sqlResult.id] = newValue
                                    }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .keyboardType(.numberPad)
                                Image(systemName: wrapper.isSelected ? "checkmark.square.fill" : "square")
                                    .foregroundColor(Color("BottonColor"))
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
        if let index = recipes.firstIndex(where: { $0.sqlResult.id == wrapper.sqlResult.id }) {
            let defaultQuantity = wrapper.planAmount ?? ""
            let quantity = Int(quantityInputs[wrapper.sqlResult.id] ?? defaultQuantity) ?? 0
            recipes[index].sqlResult.amount = quantity
            recipes[index].isSelected.toggle()
            if recipes[index].isSelected {
                selectedIngredients.append(recipes[index].sqlResult)
                onIngredientSelection(recipes[index].sqlResult.fid, recipes[index].sqlResult.uid, recipes[index].sqlResult.amount)
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
    @State private var userUID: String?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var sevenDaysAgo: Date {
        return Calendar.current.date(byAdding: .day, value: -7, to: currentDate)!
    }

    private var currentDate: Date {
        return Date()
    }

    func getUserUIDFromDatabase() {
        // 在這裡從資料庫中獲取用戶的 UID
    }

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
                        onIngredientSelection: handleIngredientSelection
                    )
                }
            }
        }
        .onAppear {
            getUserUIDFromDatabase()
            loadRecipes()
        }
        .onDisappear {
            sendSelectedIngredientsToBackend()
        }
    }

    private func handleIngredientSelection(_ fid: Int, _ uid: String, _ sksum: Int) {
        let jsonDict: [String: Any] = [
            "F_ID": fid,
            "U_ID": uid,
            "SK_SUM": sksum
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) {
            sendJSONDataToBackend(jsonData: jsonData)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("JSON String:", jsonString)
            }
        }
    }

    private var sevenDaysLater: Date {
        return Calendar.current.date(byAdding: .day, value: 6, to: currentDate)!
    }

    private var oneDayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
    }

    private func sendJSONDataToBackend(jsonData: Data) {
        guard let url = URL(string: "http://163.17.9.107/food/ShopStock.php") else {
            print("無效的 URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("發送JSON數據時出錯: \(error)")
                return
            }

            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                print("服務器響應錯誤: \(response.statusCode)")
                return
            }

            // Handle server response here if needed
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response from server: \(responseString)")
            }
        }

        task.resume()
    }

    private func loadRecipes() {
        ShopNetworkManager().fetchAndAggregateRecipes { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recipes):
                    self.recipes = recipes.sorted(by: { $0.sqlResult.name < $1.sqlResult.name }) // Sort by name
                    self.isLoading = false
                case .failure(let error):
                    print("Error loading recipes: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
}

struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView()
    }
}
