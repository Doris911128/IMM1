//PastRecipesView

import SwiftUI

struct PastRecipesView: View
{
    @AppStorage("U_ID") private var U_ID: String = "vqiVr6At0U"
    
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var pastRecipesData: [PastRecipe] = []
    @State private var searchKeyword: String = ""
    
    @State private var isLoading: Bool = false
    @State private var fetchError: String? = nil
    
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                Text("過往食譜")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                
                TextField("搜索食譜", text: $searchKeyword, onCommit:
                            {
                    P_loadMenuData(keyword: searchKeyword)
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 20)
                .autocapitalization(.none)
                .focused($isTextFieldFocused)
                if pastRecipesData.isEmpty 
                {
                    VStack
                    {
                        Spacer().frame(height: 115) // 调整此高度以控制顶部间距
                        
                        VStack 
                        {
                            Image("過往食譜")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180) // 调整图片大小
                        }
                        .padding(10)
                        
                        VStack
                        {
                            Text("無過往食譜")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer() // 自动将内容推到中心位置
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 确保内容在顶部对齐
                    
                }
                ScrollView(showsIndicators: false)
                {
                    LazyVStack
                    {
                        ForEach(filteredPastRecipesData(), id: \.Dis_ID)
                        { pastRecipe in
                            NavigationLink(destination: Recipe_IP_View(U_ID: U_ID, Dis_ID: pastRecipe.Dis_ID))
                            {
                                RecipeBlock(
                                    imageName: pastRecipe.D_image,
                                    title: pastRecipe.Dis_Name,
                                    U_ID: U_ID,
                                    Dis_ID: pastRecipe.Dis_ID
                                )
                            }
                            .padding(.bottom, -70)
                        }
                    }
                }
                
                if let fetchError = fetchError
                {
                    Text(fetchError)
                        .foregroundColor(.red)
                }
            }
            .onAppear
            {
                P_loadMenuData(keyword: "")
            }
            .contentShape(Rectangle()) // 使整个 VStack 可点击
            .onTapGesture
            {
                isTextFieldFocused = false
            }
        }
    }
    
    //MARK:  加载菜单数据
    func P_loadMenuData(keyword: String)
    {
        let urlString = "http://163.17.9.107/food/php/Pastrecipes.php?keyword=\(keyword)&U_ID=\(U_ID)"
        print("正在從此URL請求數據: \(urlString)")
        print("當前的 U_ID: \(U_ID)")
        
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString)
        else
        {
            print("生成的 URL 无效")
            fetchError = "生成的 URL 无效"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async
            {
                isLoading = false
            }
            
            guard let data = data, error == nil
            else
            {
                print("网络请求错误: \(error?.localizedDescription ?? "未知错误")")
                DispatchQueue.main.async
                {
                    
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode)
            {
                print("HTTP 错误: \(httpResponse.statusCode)")
                DispatchQueue.main.async
                {
                    
                }
                return
            }
            
            do
            {
                let decoder = JSONDecoder()
                let pastRecipesData = try decoder.decode([PastRecipe].self, from: data)
                DispatchQueue.main.async
                {
                    self.pastRecipesData = pastRecipesData
                    // 打印抓取到的数据
                    if let jsonStr = String(data: data, encoding: .utf8)
                    {
                        print("接收到的 JSON 数据: \(jsonStr)")
                    }
                }
            } catch
            {
                print("JSON 解析错误: \(error)")
                DispatchQueue.main.async
                {
                    
                }
                if let jsonStr = String(data: data, encoding: .utf8)
                {
                    print("接收到的数据字符串: \(jsonStr)")
                }
            }
        }.resume()
    }
    
    // 根据搜索关键字过滤菜品数据
    func filteredPastRecipesData() -> [PastRecipe]
    {
        if searchKeyword.isEmpty
        {
            return pastRecipesData
        } else
        {
            return pastRecipesData.filter { $0.Dis_ID.description.contains(searchKeyword) || $0.Dis_Name.contains(searchKeyword) }
        }
    }
}

#Preview
{
    PastRecipesView()
}
