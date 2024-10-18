//  MRecipeView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/9/3.
//  取代舊重複視圖

import SwiftUI
import Foundation

struct MRecipeView: View, RecipeP
{
    let U_ID: String // 用於添加我的最愛
    let Dis_ID: Int // 用於添加我的最愛
    
    var data: [Dishes]
    {
        dishesData
    }
    var showAICookingButton: Bool = true // 控制AI Cooking顯示
    
    @State var isFavorited: Bool? = nil // 使用可选值
    
    @State var dishesData: [Dishes] = []
    @State var foodData: [Food] = []
    @State var amountData: [Amount] = []
    
    @State var cookingMethod: String? // 新增一個狀態來儲存從URL加載的烹飪方法
    @State var selectedDish: Dishes?
    
    
    // MARK: - RecipeP 協議要求的實作方法
    
    // MARK: 烹飪書畫面
    func CookbookView(safeArea: EdgeInsets) -> AnyView
    {
        return AnyView(
            VStack(spacing: 18)
            {
                // MARK: 所需食材
                VStack
                {
                    Text("所需食材")
                        .foregroundStyle(.orange)
                        .font(.title2)
                        .offset(x: -130)
                        .bold()
                    
                    // 水平滾動顯示食材區塊
                    ScrollView(.horizontal, showsIndicators: false)
                    {
                        HStack(spacing: -20)
                        {
                            if let selectedDish = selectedDish
                            {
                                let filteredAmounts = amountData.filter { $0.Dis_ID == selectedDish.Dis_ID }
                                
                                ForEach(filteredAmounts, id: \.A_ID)
                                { amount in
                                    if let food = foodData.first(where: { $0.F_ID == amount.F_ID })
                                    {
                                        IngredientCardView(
                                            imageName: food.Food_imge,
                                            amount: "\(amount.A_Amount)", //數量轉字元
                                            unit: food.F_Unit,
                                            name: food.F_Name
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                
                // MARK: 料理方法
                VStack
                {
                    Text("料理方法")
                        .foregroundStyle(.orange)
                        .font(.title2)
                        .offset(x: -130)
                        .bold()
                    
                    ScrollView
                    {
                        if let method = cookingMethod
                        {
                            let steps = method.components(separatedBy: "\n")
                            
                            ForEach(steps, id: \.self)
                            { step in
                                let trimmedStep = step.trimmingCharacters(in: .whitespaces)
                                let stepComponents = trimmedStep.split(maxSplits: 1, whereSeparator: { $0 == "." })
                                
                                if stepComponents.count == 2
                                {
                                    let stepNumber = stepComponents[0] + "." // 步驟編號部分
                                    let stepDescription = stepComponents[1].trimmingCharacters(in: .whitespaces)  // 步驟描述部分
                                    
                                    HStack(alignment: .top)
                                    {
                                        Text(stepNumber)//步驟數字
                                            .font(.body)
                                            .bold()
                                            .foregroundColor(.orange)
                                            .frame(width: 20, alignment: .leading)
                                        
                                        Text(stepDescription)//各步驟煮法
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading,1) // 編號和文本距離
                                            .lineSpacing(2)  // 行距
                                    }
                                    .padding(.horizontal, 35) // 内容左右的留白
                                    .padding(.vertical, 3) // 上下留白
                                }
                            }
                        }
                    }
                }
                
                // MARK: 參考影片
                VStack
                {
                    Text("參考影片")
                        .foregroundStyle(.orange)
                        .font(.title2)
                        .offset(x: -130)
                        .bold()
                    
                    // 使用 WebView 播放 YouTube
                    if let videoURLString = dishesData.first?.D_Video,
                       let videoID = URLComponents(string: videoURLString)?.queryItems?.first(where: { $0.name == "v" })?.value,
                       let embedURL = URL(string: "https://www.youtube.com/embed/\(videoID)")
                    {
                        WebView(url: embedURL)
                            .frame(width: 350, height: 200)  // 設置 WebView 的大小
                            .cornerRadius(15)  // 圓角
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color("BottonColor"), lineWidth: 2)  // 添加邊框
                            )
                    } else
                    {
                        Text("無影片資訊")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }//最後一個包圍的VStack
            
                .onAppear
            {
                if let cookingUrl = selectedDish?.D_Cook
                {
                    loadCookingMethod(from: cookingUrl)
                }
            }
        )
    }
    
    // MARK: 標題畫面
    func HeaderView(size: CGSize, recordInput: String? = nil) -> AnyView
    {
        return AnyView(
            GeometryReader
            { reader in
                let minY: CGFloat = reader.frame(in: .named("SCROLL")).minY
                let height: CGFloat = size.height * 0.5
                let progress: CGFloat = minY / (height * (minY > 0 ? 0.5 : 0.8))
                
                HStack(spacing: 20)
                {
                    if progress > 6
                    {
                        Spacer(minLength: 0)
                    } else
                    {
                        Spacer(minLength: 0)
                        Text(itemName())
                            .bold()
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                        Spacer(minLength: 0)
                    }
                }
                .foregroundStyle(.orange)
                .padding()
                .background(Color("menusheetbackgroundcolor").opacity(progress > 6 ? 0 : 1))
                .offset(y: -minY)
            }
        )
    }
    
    // MARK: 讀取php從後端加載菜譜數據並更新視圖
    func loadMenuData()
    {
        assert(Dis_ID > 0, "Dis_ID 必須大於 0")
        
        let urlString = "http://163.17.9.107/food/php/Dishes.php?id=\(Dis_ID)"
        print("正在從此URL請求數據: \(urlString)")
        
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString)
        else
        {
            print("生成的 URL 無效")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request)
        { data, response, error in
            guard let data = data, error == nil
            else
            {
                print("網絡請求錯誤: \(error?.localizedDescription ?? "未知錯誤")")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode)
            {
                print("HTTP 錯誤: \(httpResponse.statusCode)")
                return
            }
            
            do
            {
                let decoder = JSONDecoder()
                let dishesData = try decoder.decode([Dishes].self, from: data)
                DispatchQueue.main.async
                {
                    var mutableSelf = self
                    mutableSelf.dishesData = dishesData
                    mutableSelf.selectedDish = mutableSelf.dishesData.first(where: { $0.Dis_ID == mutableSelf.Dis_ID })
                    mutableSelf.foodData = mutableSelf.selectedDish?.foods ?? []
                    mutableSelf.amountData = mutableSelf.selectedDish?.amounts ?? []
                    
                    if let cookingUrl = mutableSelf.selectedDish?.D_Cook
                    {
                        mutableSelf.loadCookingMethod(from: cookingUrl)
                    }
                    
                    if let jsonStr = String(data: data, encoding: .utf8)
                    {
                        print("接收到的 JSON 數據: \(jsonStr)")
                    }
                    
                    checkIfFavorited(U_ID: U_ID, Dis_ID: "\(Dis_ID)")
                    { result in
                        switch result
                        {
                        case .success(let favorited):
                            DispatchQueue.main.async
                            {
                                mutableSelf.isFavorited = favorited
                            }
                        case .failure(let error):
                            print("Error checking favorite status: \(error.localizedDescription)")
                        }
                    }
                }
            } catch
            {
                print("JSON 解析錯誤: \(error)")
                if let jsonStr = String(data: data, encoding: .utf8)
                {
                    print("接收到的數據字串: \(jsonStr)")
                }
            }
        }.resume()
    }
    
    func itemName() -> String
    {
        return dishesData.first(where: { $0.Dis_ID == Dis_ID })?.Dis_Name ?? "Unknown Dish"
    }
    
    func itemImageURL() -> URL?
    {
        return dishesData.first(where: { $0.Dis_ID == Dis_ID }).flatMap { URL(string: $0.D_image) }
    }
    
    // MARK: MRecipeView body
    var body: some View
    {
        GeometryReader
        { geometry in
            let safeArea = geometry.safeAreaInsets //當前畫面的safeArea
            let size = geometry.size //GeometryReader的大小
            
            ScrollView(.vertical, showsIndicators: false)
            {
                VStack
                {
                    // CoverView 封面
                    self.CoverView(safeArea: safeArea, size: size)
                    
                    // CookbookView 烹飪書畫面
                    self.CookbookView(safeArea: safeArea).padding(.top)
                    
                    // HeaderView 標題畫面
                    self.HeaderView(size: size)
                }
            }
            .coordinateSpace(name: "SCROLL") //抓取ScrollView的各項數值
            .overlay(
                
                //MARK: 前往烹飪模式AI按鈕 (僅當需要時添加)
                VStack
                {
                    Spacer()
                    if showAICookingButton // 根據 showAICookingButton 來決定是否顯示按鈕
                    {
                        HStack
                        {
                            Spacer()
                            NavigationLink(destination: CookingAiView(disID: Dis_ID))
                            {
                                HStack
                                {
                                    ZStack
                                    {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 40, height: 40)
                                        
                                        Image("chef-hat-one-2")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    }
                                    
                                    Text("輔助烹飪模式")
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 10)
                                .background(Color.orange)
                                .clipShape(CustomCorners(cornerRadius: 30, corners: [.topLeft, .bottomLeft]))
                            }
                            .padding(.bottom, 17)
                            .shadow(radius: 5)
                        }
                    }
                }
            )
        }
        .toolbarBackground(Color("menusheetbackgroundcolor"), for: .navigationBar)
        .toolbar
        {
            // 愛心收藏按鈕
            ToolbarItem(placement: .navigationBarTrailing)
            {
                Button(action: {
                    withAnimation(.easeInOut.speed(3))
                    {
                        if let isFavorited = isFavorited
                        {
                            self.isFavorited = !isFavorited
                            toggleFavorite(U_ID: U_ID, Dis_ID: Dis_ID, isFavorited: self.isFavorited!) { result in
                                switch result
                                {
                                case .success(let responseString):
                                    print("Success: \(responseString)")
                                case .failure(let error):
                                    print("Error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                })
                {
                    Image(systemName: (isFavorited ?? false) ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .onAppear
        {
            print("顯示的 Dis_ID: \(Dis_ID)")
            loadMenuData()
        }
    }
}

//MARK: 自定義“烹飪模式AI按鈕”圓角方向
struct CustomCorners: Shape
{
    var cornerRadius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path
    {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        return Path(path.cgPath)
    }
}

//MARK: 食材左右滑動膠囊
struct IngredientCardView: View
{
    let imageName: String
    let amount: String
    let unit: String
    let name: String
    
    var body: some View
    {
        VStack(spacing: 3)
        {
            // 使用 AsyncImage 加载食材图片
            AsyncImage(url: URL(string: imageName))
            { phase in
                switch phase
                {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle()) // 將圖片裁切為圓形
                case .failure:
                    Image("自訂食材預設圖片")
                        .frame(width: 60, height: 60)
                        .clipShape(Circle()) // 將圖片裁切為圓形
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                @unknown default:
                    EmptyView()
                }
            }
            
            // 顯示食材的數量和單位
            Text("\(amount) \(unit)")
                .font(.system(size: 18))
                .bold()
                .foregroundColor(.black)
            
            // 顯示食材名稱
            Text(name)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(Color("BackColor"))
        }
        .padding(10)
        .background(Color("BottonColor")
                    //.opacity(0.2) //不透明度
        )
        .clipShape(Capsule())  // 使用 Capsule 取代 RoundedRectangle 使其成為膠囊形狀
        .shadow(radius: 3)  // 添加陰影
        .frame(width: 120)  // 根據內容調整寬度
    }
}


#Preview
{
    MRecipeView(U_ID: "ofmyRwDdZy", Dis_ID: 1)
}
