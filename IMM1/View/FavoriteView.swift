//Favorite.swift最愛View
//
//  Created on 2023/8/18.
//

import SwiftUI

struct FavoriteView: View
{
    let U_ID: String // 用於添加我的最愛
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes? = nil
    @State private var isLoading: Bool = true // 載入狀態
    @State private var loadingError: String? = nil // 加載錯誤訊息
    
    // MARK: 載入最愛資料func
    func loadUFavData()
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/Favorite.php")
        else
        {
            print("生成的 URL 無效")
            self.isLoading = false
            self.loadingError = "無效的URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async
            {
                self.isLoading = false
            }
            
            if let error = error
            {
                DispatchQueue.main.async
                {
                    self.loadingError = error.localizedDescription
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
            else
            {
                DispatchQueue.main.async
                {
                    self.loadingError = "伺服器錯誤"
                }
                return
            }
            
            if let data = data
            {
                do
                {
                    let decoder = JSONDecoder()
                    let dishes = try decoder.decode([Dishes].self, from: data)
                    DispatchQueue.main.async
                    {
                        self.dishesData = dishes
                    }
                } catch
                {
                    DispatchQueue.main.async
                    {
                        self.loadingError = "JSON解析錯誤: \(error.localizedDescription)"
                    }
                }
            }
        }.resume()
        
    }
    
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                Text("我的最愛")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                
                if isLoading
                {
                    //MARK: 想要載入中轉圈圈動畫
                    VStack
                    {
                        Spacer()
                        ProgressView("載入中...").progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = loadingError
                {
                    VStack
                    {
                        Text("載入失敗: \(error)").font(.body).foregroundColor(.red)
                        Spacer().frame(height: 120)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if dishesData.isEmpty
                {
                    ZStack
                    {
                        GeometryReader
                        { geometry in
                            VStack
                            {
                                Image("最愛")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 180)
                                    .position(x: geometry.size.width / 2, y: geometry.size.height / 3) // 向上移動圖片
                            }
                            VStack
                            {
                                Spacer().frame(height: geometry.size.height / 2) // 向下移动文字
                                VStack
                                {
                                    Text("暫未新增任何親最愛食譜")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                    NavigationLink(destination: PastRecipesView())
                                    {
                                        Text("前往“過往食譜”添加更多＋＋")
                                            .font(.system(size: 18))
                                            .foregroundColor(.blue).underline()
                                    }
                                    Spacer().frame(height: 300)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else
                {
                    ScrollView(showsIndicators: false)
                    {
                        LazyVStack
                        {
                            ForEach(dishesData, id: \.Dis_ID)
                            { dish in
                                NavigationLink(destination: MRecipeView(U_ID: "", Dis_ID: dish.Dis_ID, showAICookingButton: false))
                                {
                                    RecipeBlock(imageName: dish.D_image, title: dish.Dis_Name, U_ID: "", Dis_ID: dish.Dis_ID)
                                }
                                .padding(.bottom, -70)
                            }
                        }
                    }
                }
            }
            .onAppear
            {
                loadUFavData()
            }
        }
    }
}


struct FavoriteView_Previews: PreviewProvider 
{
    static var previews: some View 
    {
        ContentView()
    }
}
