import SwiftUI
import Foundation

// Models
struct RecipeWrapper: Codable {
    var sqlResult: Ingredient // Maps to `sql_result`
       fileprivate var shopPlan: ShopPlan? // Make this fileprivate or internal

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
    var pID: String? // Make optional
    var disID: Int? // Make optional
    var amount: Int
    var name: String
    var unit: String
    var stock: Int? // Make optional

    enum CodingKeys: String, CodingKey {
        case pID = "P_ID"
        case disID = "Dis_ID"
        case amount = "A_Amount"
        case name = "F_Name"
        case unit = "F_Unit"
        case stock = "SK_SUM"
    }
}



// Network Manager
class ShopNetworkManager {
    func fetchRecipes(completion: @escaping (Result<[RecipeWrapper], Error>) -> Void) {
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
                let recipeWrappers = try JSONDecoder().decode([RecipeWrapper].self, from: data)
                completion(.success(recipeWrappers))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

struct RecipeView: View {
    @Binding var recipes: [RecipeWrapper]

    var onDeleteIngredient: (Ingredient) -> Void

    var body: some View {
        if recipes.isEmpty {
            Spacer()
            Text("目前無採買項目")
            Spacer()
        } else {
            List {
                ForEach(recipes, id: \.sqlResult.id) { wrapper in
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
                            TextField("數量", text: .constant("")) // 添加文本框
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .keyboardType(.numberPad)
                            Image(systemName: "square")
                                .foregroundColor(.orange)
                                .onTapGesture {
                                    onDeleteIngredient(wrapper.sqlResult)
                                }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 25)) // 添加外边距
            .background(Color.white)
            .cornerRadius(10) // 添加圆角
        }
    }
}




struct ShopView: View {
    @State private var recipes: [RecipeWrapper] = []
    @State private var isLoading = true

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
                            if let index = recipes.firstIndex(where: { $0.sqlResult.id == ingredient.id }) {
                                recipes.remove(at: index)
                            }
                        }
                    )
                }
            }
        }
        .onAppear {
            loadRecipes()
        }
    }

    private func loadRecipes() {
        ShopNetworkManager().fetchRecipes { result in
            switch result {
            case .success(let loadedRecipes):
                self.recipes = loadedRecipes
                self.isLoading = false
            case .failure(let error):
                print("獲取菜譜資料失敗: \(error)")
                self.isLoading = false
            }
        }
    }
}

// SwiftUI Preview
struct ShopView_Previews: PreviewProvider {
    static var previews: some View {
        ShopView()
    }
}
