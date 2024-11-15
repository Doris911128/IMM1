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

struct RecipeView: View {
    @Binding var recipes: [RecipeWrapper]
    var onDeleteIngredient: (Ingredient) -> Void
    var onIngredientSelection: (Int, String, Int) -> Void
    @Binding var selectedIngredients: [Ingredient]
    @Binding var ingredients: [StockIngredient]
    
    @Binding var isAllSelected: Bool // 跟踪是否已经选择所有食材
    
    @State private var quantityInputs: [UUID: String] = [:]
    @State private var hiddenIngredients: Set<UUID> = []
    @State private var showPurchasedMessage = false
    @State private var purchasedIngredientName: String = ""
    @State private var showPurchaseAnimation = false
    @State private var showAlert = false
    
    init(
        recipes: Binding<[RecipeWrapper]>,
        onDeleteIngredient: @escaping (Ingredient) -> Void,
        selectedIngredients: Binding<[Ingredient]>,
        onIngredientSelection: @escaping (Int, String, Int) -> Void,
        ingredients: Binding<[StockIngredient]>,
        isAllSelected: Binding<Bool> // 新增參數
    ) {
        self._recipes = recipes
        self.onDeleteIngredient = onDeleteIngredient
        self._selectedIngredients = selectedIngredients
        self.onIngredientSelection = onIngredientSelection
        self._ingredients = ingredients
        self._isAllSelected = isAllSelected // 初始化 isAllSelected
    }
    
    var body: some View {
        VStack {
            if isAllSelected {
                // 當所有方塊都被選擇後顯示 PurchasedIngredientsView
                PurchasedIngredientsView()
            } else {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showAlert = true
                        }) {
                            Text("全選")
                                .font(.system(size: 18))
                                .foregroundColor(Color("BottonColor"))
                                .padding(.trailing, 16)
                        }
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("全部採購"),
                            message: Text("是否確定要全部採購？"),
                            primaryButton: .default(Text("確認")) {
                                selectAllIngredients()
                                PurchasedIngredientsView()
                            },
                            secondaryButton: .cancel(Text("取消"))
                        )
                    }
                    
                    List {
                        
                        ForEach(recipes, id: \.sqlResult.id) { wrapper in
                            if (Int(wrapper.planAmount ?? "0") ?? 0) > 0 {
                                Section(header: EmptyView()) {
                                    if !hiddenIngredients.contains(wrapper.sqlResult.id) {
                                        RecipeItemView(
                                            
                                            wrapper: wrapper,
                                            hiddenIngredients: $hiddenIngredients,
                                            quantityInputs: $quantityInputs,
                                            onIngredientSelection: onIngredientSelection
                                        )
                                        .transition(.opacity)
                                        
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 25))
                .animation(.easeInOut, value: hiddenIngredients)
                .scrollIndicators(.hidden) // 隱藏滾動條
            }
        }
    }
    
    private func selectAllIngredients() {
        withAnimation(.easeInOut(duration: 0.5)) {
            recipes.forEach { recipe in
                if !hiddenIngredients.contains(recipe.sqlResult.id) {
                    hiddenIngredients.insert(recipe.sqlResult.id)
                    onIngredientSelection(
                        recipe.sqlResult.fid,
                        recipe.sqlResult.uid,
                        recipe.sqlResult.amount
                    )
                }
            }
            // 將 isAllSelected 設為 true
            isAllSelected = true
        }
    }
}

struct EmptyShopView: View {
    var body: some View {
        VStack {
            Spacer().frame(height: 200)
            Image("採購")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
            Text("目前無採買項目")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct PurchasedIngredientsView: View {
    var body: some View {
        VStack {
            Spacer().frame(height: 200)
            Image("已採購")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
            Text("已有所需採購食材，快去烹飪吧")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            Spacer()
        }
        
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct RecipeItemView: View {
    let wrapper: RecipeWrapper
    @Binding var hiddenIngredients: Set<UUID>
    @Binding var quantityInputs: [UUID: String] // 绑定用户输入数量
    var onIngredientSelection: (Int, String, Int) -> Void
    @State private var isPurchased: Bool = false
    var body: some View {
        HStack(alignment: .top) {
            if let imageUrl = URL(string: wrapper.sqlResult.foodImage) {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
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
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
            
            Spacer().frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(" \(wrapper.sqlResult.name)")
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text("採購數量: \(wrapper.planAmount ?? "0")\(wrapper.sqlResult.unit)")
                        .font(.system(size: 12))
                        .padding(.trailing, -50)
                }
                
                // TextField 绑定用户输入
                TextField(
                    "數量",
                    text: Binding(
                        get: {
                            // 默認值為 planAmount，如果不存在則返回空字串
                            quantityInputs[wrapper.sqlResult.id] ?? (wrapper.planAmount ?? "")
                        },
                        set: { newValue in
                            // 僅允許數字輸入
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            quantityInputs[wrapper.sqlResult.id] = filtered
                        }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 80)
                .keyboardType(.numberPad)
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            Image(systemName: isPurchased ? "checkmark.square.fill" : "square") // 根據選擇狀態更改圖示
                           .foregroundColor(isPurchased ? .green : Color("BottonColor"))
                           .onTapGesture {
                               withAnimation(.easeInOut(duration: 0.3)) {
                                   isPurchased.toggle() // 切換選擇狀態
                                   hiddenIngredients.insert(wrapper.sqlResult.id)

                                   let amountToSend: Int
                                   if let inputAmount = quantityInputs[wrapper.sqlResult.id], let amount = Int(inputAmount), amount > 0 {
                                       amountToSend = amount
                                   } else if let defaultAmount = Int(wrapper.planAmount ?? "0"), defaultAmount > 0 {
                                       amountToSend = defaultAmount
                                   } else {
                                       amountToSend = 0
                                   }

                                   onIngredientSelection(wrapper.sqlResult.fid, wrapper.sqlResult.uid, amountToSend)
                               }
                           }
                           .frame(maxHeight: .infinity)
                   }
        
        .padding(.vertical, 8)
        .transition(.opacity)
    }
}

struct PurchasedMessageView: View
{
    @Binding var purchasedIngredientName: String
    @Binding var showPurchaseAnimation: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Text("已採購食材：\(purchasedIngredientName)")
                .font(.body)
                .padding()
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(10)
                .scaleEffect(showPurchaseAnimation ? 1 : 0.8)
                .opacity(showPurchaseAnimation ? 1 : 0)
                .animation(.easeInOut(duration: 0.8), value: showPurchaseAnimation)
        }
        .zIndex(1)
    }
    
}


struct ShopView: View {
    @State private var recipes: [RecipeWrapper] = []
    @State private var isLoading = true
    @State private var selectedIngredients: [Ingredient] = []
    @State private var userUID: String?
    @State private var ingredients: [StockIngredient] = [] // 初始化 ingredients 数组
    @State private var isAllSelected = false // 跟踪是否已经选择所有食材
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private var currentDate: Date {
        return Date()
    }
    
    private var sevenDaysAgo: Date {
        return Calendar.current.date(byAdding: .day, value: -7, to: currentDate)!
    }
    
    private var sevenDaysLater: Date {
        return Calendar.current.date(byAdding: .day, value: 6, to: currentDate)!
    }
    
    private var oneDayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
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
                           .frame(maxWidth: .infinity, alignment: .center) // 使「採購」置中
                   }
                   
                   Text("您需要採購的食材")
                       .font(.system(size: 12))
                       .foregroundColor(.gray)
                   
                   if isLoading {
                       // 加載中時顯示進度指示器
                       ProgressView("加載中...")
                   } else if recipes.isEmpty && selectedIngredients.isEmpty {
                       // 當菜單和已選食材都為空時顯示 EmptyShopView
                       EmptyShopView()
                           .transition(.opacity)
                   } else if allRecipesInStock() {
                       // 如果所有菜單的食材都在庫存中，顯示 PurchasedIngredientsView
                       PurchasedIngredientsView()
                           .transition(.opacity)
                   } else {
                       // 否則顯示菜單的主視圖
                       RecipeView(
                           recipes: $recipes,
                           onDeleteIngredient: { ingredient in
                               // 更新選定的食材...
                           },
                           selectedIngredients: $selectedIngredients,
                           onIngredientSelection: handleIngredientSelection,
                           ingredients: $ingredients,
                           isAllSelected: $isAllSelected // 傳遞 isAllSelected
                       )
                   }
               }
               .onAppear {
                   loadRecipes()
                   loadIngredients()
               }
               .onDisappear {
                   sendSelectedIngredientsToBackend()
               }
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
       
       private func sendJSONDataToBackend(jsonData: Data) {
           guard let url = URL(string: "http://163.17.9.107/food/php/ShopStock.php") else {
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
                    
                    // 檢查新增的食材是否不在已選中的食材列表中
                    if !recipes.allSatisfy({ recipe in
                        ingredients.contains(where: { $0.F_ID == recipe.sqlResult.fid })
                    }) {
                        isAllSelected = false
                    }
                    
                    self.isLoading = false
                case .failure(let error):
                    print("Error loading recipes: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    
    
    private func allRecipesInStock() -> Bool {
         for recipe in recipes {
             if let ingredient = ingredients.first(where: { $0.F_ID == recipe.sqlResult.fid }) {
                 // 如果库存量不足（可以加入其他條件判斷）
                 if ingredient.SK_SUM < recipe.sqlResult.amount {
                     return false
                 }
             } else {
                 // 如果沒有找到對應的庫存食材
                 return false
             }
         }
         return true
     }

     
     private func loadIngredients() {
         let networkManager = NetworkManager()
         networkManager.fetchData(from: "http://163.17.9.107/food/php/Stock.php") { result in
             DispatchQueue.main.async {
                 switch result {
                 case .success(let stocks):
                     self.ingredients = stocks.compactMap { stock in
                         let name = stock.F_Name ?? "未知食材"
                         let unit = stock.F_Unit ?? "未指定單位"
                         let SK_SUM = stock.SK_SUM ?? 0
                         let image = stock.Food_imge ?? "" // 確保圖片路徑有效
                         return StockIngredient(U_ID: stock.U_ID ?? UUID().uuidString, F_ID: stock.F_ID, F_Name: name, SK_SUM: SK_SUM, F_Unit: unit, Food_imge: image)
                     }
                 case .failure(let error):
                     print("Error loading ingredients: \(error)")
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
