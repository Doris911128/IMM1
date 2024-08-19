// ShopView.swift

import SwiftUI
import Foundation

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
    let foodImage: String
    var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: P_DT)
    }
    
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
        case foodImage = "Food_imge"
    }
}

class ShopNetworkManager
{
    func fetchAndAggregateRecipes(completion: @escaping (Result<[RecipeWrapper], Error>) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/php/Shop.php") else {
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
            
            // 打印原始 JSON 数据
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON Data: \(jsonString)")
            }
            
            do {
                let responseData = try JSONDecoder().decode(ResponseDa.self, from: data)
                
                // Filter out ingredients with P_DT before today
                let today = Calendar.current.startOfDay(for: Date())
                let filteredData = responseData.data.filter { ingredient in
                    guard let ingredientDate = ingredient.date else {
                        return false
                    }
                    return ingredientDate >= today
                }
                
                // Convert raw data to RecipeWrapper
                let recipeWrappers: [RecipeWrapper] = filteredData.map { ingredient in
                    let shopPlan = responseData.shopPlanData.first { $0.fid == String(ingredient.fid) && $0.uid == ingredient.uid }
                    return RecipeWrapper(sqlResult: ingredient, shopPlan: shopPlan)
                }
                
                // Print parsed data for debugging
                for wrapper in recipeWrappers {
                    print("Ingredient: \(wrapper.sqlResult.name), Unit: \(wrapper.sqlResult.unit), Plan Amount: \(wrapper.planAmount ?? "N/A"), Food Image:\(wrapper.sqlResult.foodImage)")
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
                print("Error decoding data: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}

struct RecipeWrapper: Codable
{
    var sqlResult: Ingredient
    var shopPlan: ShopPlan?
    var isSelected: Bool = false
    
    var planAmount: String?
    {
        return shopPlan?.amount
    }
}

struct RecipeView: View
{
    @Binding var recipes: [RecipeWrapper]
    
    var onDeleteIngredient: (Ingredient) -> Void
    var onIngredientSelection: (Int, String, Int) -> Void
    
    @Binding var selectedIngredients: [Ingredient]
    @Binding var ingredients: [StockIngredient] // 添加对 ingredients 的绑定
    
    @State private var quantityInputs: [UUID: String] = [:]
    @State private var hiddenIngredients: Set<UUID> = []
    
    init(recipes: Binding<[RecipeWrapper]>, onDeleteIngredient: @escaping (Ingredient) -> Void, selectedIngredients: Binding<[Ingredient]>, onIngredientSelection: @escaping (Int, String, Int) -> Void, ingredients: Binding<[StockIngredient]>) {
        self._recipes = recipes
        self.onDeleteIngredient = onDeleteIngredient
        self._selectedIngredients = selectedIngredients
        self.onIngredientSelection = onIngredientSelection
        self._ingredients = ingredients // 正确绑定 ingredients
    }
    
    var body: some View
    {
        if recipes.isEmpty
        {
            VStack
            {
                Spacer().frame(height: 200) // 调整此高度以控制顶部间距
                VStack
                {
                    Image("採購")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180) // 调整图片大小
                }
                VStack
                {
                    Text("目前無採買項目")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                Spacer() // 自动将内容推到中心位置
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 确保内容在顶部对齐
        } else if recipes.allSatisfy({ recipe in
            // 確認所有 recipes 中的食材是否都存在於 ingredients 中
            ingredients.contains(where: { $0.F_ID == recipe.sqlResult.fid })
        }) {
            VStack {
                Spacer().frame(height: 200)
                VStack {
                    Image("已採購")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                }
                VStack {
                    Text("已有所需採購食材，快去烹飪吧")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
 else
        {
            List
            {
                ForEach(recipes, id: \.sqlResult.id)
                { wrapper in
                    if !shouldHideIngredient(wrapper.sqlResult.id) && (Int(wrapper.planAmount ?? "0") ?? 0) > 0 {
                        Section(header: EmptyView())
                        {
                            HStack(alignment: .top)
                            {
                                if let imageUrl = URL(string: wrapper.sqlResult.foodImage)
                                {
                                    AsyncImage(url: imageUrl)
                                    { phase in
                                        switch phase
                                        {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 100, height: 100)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(10)
                                        case .success(let image):
                                            image.resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(10)
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(10)
                                        @unknown default:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 100, height: 100)
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(10)
                                        }
                                    }
                                    .onAppear
                                    {
                                        print("Loading image from URL: \(imageUrl)")
                                    }
                                } else
                                {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(10)
                                        .onAppear {
                                            print("Invalid URL for image: \(wrapper.sqlResult.foodImage)")
                                        }
                                }
                                Spacer()
                                    .frame(width: 30) // 添加間隔
                                
                                VStack(alignment: .leading) {
                                    Text(" \(wrapper.sqlResult.name)")
                                        .font(.system(size: 20)) // 设置字体大小
                                        .fontWeight(.bold) // 设置字体粗细
                                        .lineLimit(nil) // 允许多行显示
                                        .fixedSize(horizontal: false, vertical: true) // 固定垂直尺寸
                                    
                                    HStack {
                                        Text("採購數量: \(wrapper.planAmount ?? "0")\(wrapper.sqlResult.unit)")
                                            .font(.system(size: 12))
                                            .padding(.trailing, -50)
                                    }
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
                                }
                                .padding(.vertical, 8)
                                
                                Spacer()
                                
                                Image(systemName: wrapper.isSelected ? "checkmark.square.fill" : "square")
                                    .foregroundColor(Color("BottonColor"))
                                    .onTapGesture {
                                        toggleIngredientSelection(wrapper)
                                    }
                                    .frame(maxHeight: .infinity)
                            }
                            .padding(.vertical, 8) // 增加垂直填充，防止内容太紧凑
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

struct ShopView: View
{
    @State private var recipes: [RecipeWrapper] = []
    @State private var isLoading = true
    @State private var selectedIngredients: [Ingredient] = []
    @State private var userUID: String?
    @State private var ingredients: [StockIngredient] = [] // 初始化 ingredients 数组
    
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
        // 在这里从数据库中获取用户的 UID
    }
    
    private func sendSelectedIngredientsToBackend() {
        // 在这里实现将所选食材发送到后端的逻辑
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("採購")
                        .font(.title)
                }
                Text("你需要採購的食材")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                if isLoading {
                    ProgressView("加载中...")
                } else {
                    RecipeView(
                        recipes: $recipes,
                        onDeleteIngredient: { ingredient in
                            // 更新选定的食材...
                        },
                        selectedIngredients: $selectedIngredients,
                        onIngredientSelection: handleIngredientSelection,
                        ingredients: $ingredients // 将 ingredients 传递给 RecipeView
                    )
                }
            }
        }
        .onAppear {
            getUserUIDFromDatabase()
            loadRecipes()
            loadIngredients() // 确保加载库存食材
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
        guard let url = URL(string:"http://163.17.9.107/food/php/ShopStock.php") else {
            print("无效的 URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("发送JSON数据时出错: \(error)")
                return
            }
            
            if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                print("服务器响应错误: \(response.statusCode)")
                return
            }
            
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
                    self.recipes = recipes.sorted(by: { $0.sqlResult.name < $1.sqlResult.name })
                    self.isLoading = false
                case .failure(let error):
                    print("Error loading recipes: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadIngredients()
    {
        // 加载库存食材的逻辑
        let networkManager = NetworkManager()
        networkManager.fetchData(from: "http://163.17.9.107/food/php/Stock.php") { result in
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
}


struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView()
    }
}
