//
//  RecipeProtocol.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/6.
//

//  管理詳細食譜內頁顯示的畫面跟方法
//  use in MenuView、Recipe_IP_View

import SwiftUI
import Foundation

protocol RecipeProtocol: View
{
    var U_ID: String { get }
    var Dis_ID: Int { get }
    var isFavorited: Bool? { get set } // 使用可选值
    var dishesData: [Dishes] { get set }
    var foodData: [Food] { get set }
    var amountData: [Amount] { get set }
    var cookingMethod: String? { get set }
    var selectedDish: Dishes? { get set }
    
    func loadMenuData()
    func loadCookingMethod(from urlString: String)
    func filteredAmounts(for dish: Dishes) -> [Amount]
    func CoverView(safeArea: EdgeInsets, size: CGSize) -> AnyView
    func HeaderView(size: CGSize) -> AnyView
    func CookbookView(safeArea: EdgeInsets) -> AnyView
}

extension RecipeProtocol
{
    // MARK: 過濾對應菜品的食材數量
    func filteredAmounts(for dish: Dishes) -> [Amount]
    {
        return amountData.filter { $0.Dis_ID == dish.Dis_ID }
    }
    
    // MARK: 讀取php從後端加載菜譜數據
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
    
    // MARK: 從URL加載烹飪方法
    func loadCookingMethod(from urlString: String)
    {
        guard let url = URL(string: urlString)
        else
        {
            print("無效的烹飪方法 URL Invalid URL for cooking method")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("加載烹飪方法失敗 Failed to load cooking method: \(error)")
                return
            }
            
            if let data = data, let cookingText = String(data: data, encoding: .utf8)
            {
                DispatchQueue.main.async
                {
                    var mutableSelf = self
                    mutableSelf.cookingMethod = cookingText
                }
            }
        }.resume()
    }
    
    // MARK: 封面畫面
    func CoverView(safeArea: EdgeInsets, size: CGSize) -> AnyView
    {
        let height: CGFloat = size.height * 0.5
        
        return AnyView(
            GeometryReader
            { reader in
                let minY: CGFloat = reader.frame(in: .named("SCROLL")).minY
                let size: CGSize = reader.size
                let progress: CGFloat = minY / (height * (minY > 0 ? 0.5 : 0.8))
                
                if let dish = dishesData.first
                {
                    AsyncImage(url: URL(string: dish.D_image)) { phase in
                        switch phase
                        {
                        case .success(let image):
                            image.resizable()
                                .scaledToFill()
                                .frame(width: size.width, height: size.height + (minY > 0 ? minY : 0))
                                .clipped()
                                .overlay(
                                    ZStack(alignment: .bottom)
                                    {
                                        LinearGradient(colors: [
                                            Color("menusheetbackgroundcolor").opacity(0 - progress),
                                            Color("menusheetbackgroundcolor").opacity(0.2 - progress),
                                            Color("menusheetbackgroundcolor").opacity(0.4 - progress),
                                            Color("menusheetbackgroundcolor").opacity(0.6 - progress),
                                            Color("menusheetbackgroundcolor").opacity(0.8 - progress),
                                            Color("menusheetbackgroundcolor")
                                        ], startPoint: .top, endPoint: .bottom)
                                        
                                        VStack(spacing: 0)
                                        {
                                            Text(dish.Dis_Name)
                                                .bold()
                                                .font(.largeTitle)
                                                .foregroundStyle(.orange)
                                                .bold()
                                                .font(.body)
                                                .foregroundStyle(.gray)
                                                .padding(.top)
                                        }
                                        .opacity(1.1 + (progress > 0 ? -progress : progress))
                                        .padding(.bottom, 50)
                                        .offset(y: minY < 0 ? minY : 0)
                                    }
                                )
                        case .empty, .failure:
                            Color.gray
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .offset(y: -minY)
                    .onChange(of: progress)
                    {
                        print("CoverView的progress值: \(progress)")
                    }
                } else
                {
                    Color.gray.frame(width: size.width, height: size.height + (minY > 0 ? minY : 0))
                }
            }
                .frame(height: height + safeArea.top)
        )
    }
    
    // MARK: 標題畫面
    func HeaderView(size: CGSize) -> AnyView
    {
        let Dis_Name = dishesData.first(where: { $0.Dis_ID == Dis_ID })?.Dis_Name ?? "Unknown Dish"
        
        return AnyView(
            GeometryReader
            { reader in
                let minY: CGFloat = reader.frame(in: .named("SCROLL")).minY
                let height: CGFloat = size.height * 0.5
                let progress: CGFloat = minY / (height * (minY > 0 ? 0.5 : 0.8))
                
                HStack(spacing: 20)
                {
                    if(progress > 6)
                    {
                        Spacer(minLength: 0)
                    } else
                    {
                        Spacer(minLength: 0)
                        
                        // 滑動後顯示對應料理名稱
                        Text(Dis_Name)
                            .bold()
                            .font(.title3)
                            .transition(.opacity.animation(.smooth))
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)
                        Spacer(minLength: 0)
                    }
                }
                .foregroundStyle(.orange)
                .padding()
                .background(Color("menusheetbackgroundcolor").opacity(progress > 6 ? 0 : 1))
                .animation(.smooth.speed(2), value: progress<6)
                .offset(y: -minY)
                .onChange(of: progress)
                {
                    print("HeaderView的progress值: \(progress)")
                }
            }
        )
    }
    
    // MARK: 烹飪書畫面
    func CookbookView(safeArea: EdgeInsets) -> AnyView
    {
        return AnyView(
            VStack(spacing: 20)
            {
                Text("所需食材")
                    .foregroundStyle(.orange)
                    .font(.title2)
                    .offset(x: -130)
                
                // 水平滚动视图显示食材
                ScrollView(.horizontal, showsIndicators: false)
                {
                    HStack(spacing: -20)
                    {
                        if let selectedDish = selectedDish
                        {
                            let filteredAmounts = amountData.filter { $0.Dis_ID == selectedDish.Dis_ID }
                            
                            ForEach(filteredAmounts, id: \.A_ID) { amount in
                                if let food = foodData.first(where: { $0.F_ID == amount.F_ID })
                                {
                                    IngredientCardView(
                                        imageName: food.Food_imge,  // 使用 food.Food_imge 加载图片
                                        amount: "\(amount.A_Amount)",  // 将数量转换为字符串
                                        unit: food.F_Unit,
                                        name: food.F_Name
                                    )
                                }
                            }
                        }
                    }
                    //.padding(.horizontal, 15)
                }
                
                Text("料理方法")
                    .foregroundStyle(.orange)
                    .font(.title2)
                    .offset(x: -130)
                ScrollView
                {
                    if let method = cookingMethod
                    {
                        Text(method)
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                    }
                    //                    else
                    //                    {
                    //                        LoadingView()//載入畫面
                    //                    }
                }
                
                Text("參考影片")
                    .foregroundStyle(.orange)
                    .font(.title2)
                    .offset(x: -130)
                
                // 使用 WebView 播放 YouTube 视频
                if let videoURLString = dishesData.first?.D_Video,
                   let videoID = URLComponents(string: videoURLString)?.queryItems?.first(where: { $0.name == "v" })?.value,
                   let embedURL = URL(string: "https://www.youtube.com/embed/\(videoID)")
                {
                    WebView(url: embedURL)
                        .frame(width: 350, height: 200)  // 设置 WebView 的大小
                        .cornerRadius(15)  // 设置圆角
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color("BottonColor"), lineWidth: 2)  // 添加边框
                        )
                } else
                {
                    Text("無影片資訊")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
                .onAppear
            {
                if let cookingUrl = selectedDish?.D_Cook
                {
                    loadCookingMethod(from: cookingUrl)
                }
            }
        )
    }
}

//MARK: 食材左右滑動
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
                        .clipShape(Circle()) // 将图片裁剪为圆形
                        .shadow(radius: 3) // 可选：为图片添加阴影
                case .failure:
                    Circle() // 显示为圆形的灰色占位符
                        .fill(Color.gray)
                        .frame(width: 60, height: 60)
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                @unknown default:
                    EmptyView()
                }
            }
            
            // 显示食材的数量和单位
            Text("\(amount) \(unit)")
                .font(.system(size: 18))
                .bold()
                .foregroundColor(.black)
            
            // 显示食材名称
            Text(name)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }
        .padding(10)
        .background(Color("BottonColor").opacity(0.2))
        .clipShape(Capsule())  // 使用 Capsule 代替 RoundedRectangle 使其成为胶囊形状
        .shadow(radius: 3)
        .frame(width: 120)  // 根据内容调整宽度
    }
}
