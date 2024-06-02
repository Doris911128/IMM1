import SwiftUI

struct PastRecipesView: View {
    @AppStorage("U_ID") private var U_ID: String = ""
    
    @State private var dishesData: [Dishes] = []
    @State private var searchKeyword: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                Text("過往食譜")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                
                TextField("搜索食譜", text: $searchKeyword, onCommit: {
                    loadMenuData(keyword: searchKeyword)
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 20)
                .autocapitalization(.none)
                .focused($isTextFieldFocused)
                
                ScrollView(showsIndicators: false) {
                    LazyVStack {
                        ForEach(filteredDishesData(), id: \.Dis_ID) { dish in
                            NavigationLink(destination: Recipe_IP_View(Dis_ID: dish.Dis_ID)) {
                                RecipeBlock(
                                    imageName: dish.D_image,
                                    title: dish.Dis_Name,
                                    U_ID: U_ID,
                                    Dis_ID: "\(dish.Dis_ID)"
                                )
                            }
                            .padding(.bottom, 10)
                        }
                    }
                }
            }
            .onAppear {
                loadMenuData(keyword: "")
            }
            .contentShape(Rectangle()) // 使整个 VStack 可点击
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
    }
    
    // 加载菜单数据
    func loadMenuData(keyword: String) {
        let urlString = "http://163.17.9.107/food/Dishes.php?keyword=\(keyword)"
        print("正在從此URL請求數據: \(urlString)")

        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString)
        else {
            print("生成的 URL 无效")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("网络请求错误: \(error?.localizedDescription ?? "未知错误")")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                print("HTTP 错误: \(httpResponse.statusCode)")
                return
            }

            do {
                let decoder = JSONDecoder()
                let dishesData = try decoder.decode([Dishes].self, from: data)
                DispatchQueue.main.async {
                    self.dishesData = dishesData
                    if let jsonStr = String(data: data, encoding: .utf8) {
                        print("接收到的 JSON 数据: \(jsonStr)")
                    }
                }
            } catch {
                print("JSON 解析错误: \(error)")
                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("接收到的数据字符串: \(jsonStr)")
                }
            }
        }.resume()
    }
    
    // 根据搜索关键字过滤菜品数据
    func filteredDishesData() -> [Dishes] {
        if searchKeyword.isEmpty {
            return dishesData
        } else {
            let resultDisIDs = findRecipesByIngredientName(searchKeyword)
            return dishesData.filter { resultDisIDs.contains($0.Dis_ID) }
        }
    }
    
    // 根据食材名称查找对应的菜品ID，支持部分匹配
    func findRecipesByIngredientName(_ ingredientName: String) -> [Int] {
        var resultDisIDs: [Int] = []

        for dish in dishesData {
            if let foods = dish.foods, foods.contains(where: { $0.F_Name.contains(ingredientName) }) {
                resultDisIDs.append(dish.Dis_ID)
            }
        }
        
        return resultDisIDs
    }

}

#Preview {
    PastRecipesView()
}

