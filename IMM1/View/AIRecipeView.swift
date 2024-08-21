//
//  AIRecipeView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/14.
//

import SwiftUI

struct AIRecipeView: View 
{
    let U_ID: String // 用於添加收藏
    
    @State private var chatRecords: [ChatRecord] = []
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes? = nil
    @State private var isLoading: Bool = true // 加载状态
    @State private var loadingError: String? = nil // 加載错误信息
    
    // 加载用户收藏的 AI 生成的食谱数据
    func loadAICData() {
        guard let url = URL(string: "http://163.17.9.107/food/php/GetRecipe1.php") else {
            print("生成的 URL 無效")
            self.isLoading = false
            self.loadingError = "無效的URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.loadingError = error.localizedDescription
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.loadingError = "伺服器錯誤"
                }
                return
            }
            
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let recipes = try decoder.decode([ChatRecord].self, from: data)
                    DispatchQueue.main.async {
                        // 过滤出 isAIColed 为 true 的数据，表示收藏的内容
                        self.chatRecords = recipes.filter { $0.isAICol }
                    }
                } catch {
                    DispatchQueue.main.async {
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
                Text("AI食譜庫")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                
                //                if isLoading
                //                {
                //                    //MARK: 想要載入中轉圈圈動畫
                //                    VStack
                //                    {
                //                        Spacer()
                //                        ProgressView("載入中...").progressViewStyle(CircularProgressViewStyle())
                //                        Spacer()
                //                    }
                //                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                //                } else if let error = loadingError
                //                {
                //                    VStack
                //                    {
                //                        Text("載入失敗: \(error)").font(.body).foregroundColor(.red)
                //                        Spacer().frame(height: 120)
                //                    }
                //                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                //                } else 
                if dishesData.isEmpty
                {
                    ZStack
                    {
                        GeometryReader
                        { geometry in
                            VStack
                            {
                                Image("空AI食譜")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 180, height: 180)
                                    .position(x: geometry.size.width / 2, y: geometry.size.height / 3) // 向上移动图片
                            }
                            VStack
                            {
                                Spacer().frame(height: geometry.size.height / 2) // 向下移动文字
                                VStack
                                {
                                    Text("暫未新增任何AI食譜")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                    NavigationLink(destination: AIView())
                                    {
                                        Text("前往“AI食譜”添加更多＋＋")
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
                    //                    ScrollView(showsIndicators: false)
                    //                    {
                    //                        LazyVStack
                    //                        {
                    //                            ForEach(dishesData, id: \.Dis_ID)
                    //                            { dish in
                    //                                NavigationLink(destination: Recipe_IP_View(U_ID: "", Dis_ID: dish.Dis_ID))
                    //                                {
                    //                                    RecipeBlock(imageName: dish.D_image, title: dish.Dis_Name, U_ID: "", Dis_ID: dish.Dis_ID)
                    //                                }
                    //                                .padding(.bottom, -70)
                    //                            }
                    //                        }
                    //                    }
                    VStack(spacing: 20) {  // 设置卡片之间的垂直间距
                        ForEach(chatRecords) { record in
                            ZStack {
                                // 背景卡片
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                                    .shadow(radius: 4)
                                
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("問：\(record.input)")
                                            .fontWeight(.bold)
                                        Spacer()
                                        
                                        VStack {
                                            Button(action: {
                                                toggleAIColmark(U_ID: record.U_ID, Recipe_ID: record.Recipe_ID, isAICol: !record.isAICol) { result in
                                                    switch result {
                                                    case .success(let response):
                                                        print("Toggled AICol successfully: \(response)")
                                                    case .failure(let error):
                                                        print("Error toggling AICol: \(error.localizedDescription)")
                                                    }
                                                }
                                            }) {
                                                Image(systemName: record.isAICol ? "bookmark.fill" : "bookmark")
                                                    .font(.title)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        
                                        .offset(y:-22)
                                    }
                                    Text("答：\(record.output)")
                                        .foregroundColor(.gray)
                                }
                                .padding() // 内容内边距
                            }
                            .padding(.horizontal)  // 设置卡片的水平间距
                        }
                    }
                    .padding(.vertical) // 添加顶端和底端的间距
                }
            }
            .onAppear {
                loadAICData() // 加载数据
            }
        }
    }
}
#Preview {
    AIRecipeView(U_ID:"ofmyRwDdZy")
}
