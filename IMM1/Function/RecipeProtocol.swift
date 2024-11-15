//  RecipeProtocol.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/6.
//

//  管理詳細食譜內頁顯示的畫面跟方法
//  use in MenuView、Recipe_IP_View

import SwiftUI
import Foundation

// MARK: - 基礎協議：RecipeProtocol

// 是所有食譜相館的基礎協議，含通用數用和方法具體見RecipeP、AIRecipeP、CRecipeP
protocol RecipeProtocol: View
{
    associatedtype DataType
    var data: [DataType] { get }
    
    var U_ID: String { get }
    
    // 返回菜名或 AI 記錄名稱
    func itemName() -> String
    
    // 返回封面圖片的 URL，如果沒有圖片可以返回 nil
    func itemImageURL() -> URL?
    
    //適用於顯示頂部的封面圖片或背景
    func CoverView(safeArea: EdgeInsets, size: CGSize) -> AnyView
    
    // 標題視圖，根據滾動狀態顯示標題或其他信息
    func HeaderView(size: CGSize, recordInput: String?) -> AnyView
}

// MARK: 子協議：RecipeP
// 用於顯示單菜食譜的協議，繼承自RecipeProtocol 含載入選單資料、顯示食材清單及烹調方法
protocol RecipeP: RecipeProtocol where DataType == Dishes
{
    var Dis_ID: Int { get }
    var isFavorited: Bool? { get set }
    var dishesData: [Dishes] { get set }
    var foodData: [Food] { get set }
    var amountData: [Amount] { get set }
    var cookingMethod: String? { get set }
    var selectedDish: Dishes? { get set }
    
    // 從給定的 URL 載入烹飪方法
    func loadCookingMethod(from urlString: String)
    
    // 過濾對應菜色的食材數量
    func filteredAmounts(for dish: Dishes) -> [Amount]
    
    // 烹飪書畫面，包括所需食材和烹飪方法
    func CookbookView(safeArea: EdgeInsets) -> AnyView
}

// MARK: 子協議：AIRecipeP
// 用於顯示AI生成食譜的協議，繼承自RecipeProtocol 含載入AI資料、顯示數據內容方法
protocol AIRecipeP: RecipeProtocol where DataType == ChatRecord
{
    var aiRecipes: [ChatRecord] { get set }
    
    // 顯示 AI 烹飪書視圖，包括所需食材和 AI 生成的烹飪方法
    func AICookbookView(safeArea: EdgeInsets) -> AnyView
}

// MARK: 子協議：CRecipeP
// 用於顯示用戶自建食譜的協議，繼承自RecipeProtocol 含載入AI資料、顯示數據內容方法
protocol CRecipeP: RecipeProtocol where DataType == CRecipe
{
    var Crecipe: CRecipe { get set } // 修正為單一 CRecipe 型別
    
    //    // 顯示用戶自建的烹飪書視圖，包括所需食材和烹飪方法
    //    func CCookbookView(safeArea: EdgeInsets) -> AnyView
}

// MARK: extension：RecipeProtocol
extension RecipeProtocol
{
    // MARK: 封面畫面
    // 適用於顯示頂部的封面圖片或背景
    func CoverView(safeArea: EdgeInsets, size: CGSize) -> AnyView
    {
        let height: CGFloat = size.height * 0.5
        
        return AnyView(
            GeometryReader
            { reader in
                let minY: CGFloat = reader.frame(in: .named("SCROLL")).minY
                let size: CGSize = reader.size
                let progress: CGFloat = minY / (height * (minY > 0 ? 0.5 : 0.8))
                
                // 判斷圖片URL是否存在，存在則使用AsyncImage，否則使用默認圖片
                ZStack(alignment: .bottom)
                {
                    if let imageUrl = itemImageURL()
                    {
                        AsyncImage(url: imageUrl)
                        { phase in
                            switch phase
                            {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size.width, height: size.height + (minY > 0 ? minY : 0))
                                    .clipped()
                            case .empty, .failure:
                                Color.gray
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else
                    {
                        Image("自訂食材預設圖片")
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width, height: size.height + (minY > 0 ? minY : 0))
                            .clipped() // 防止圖片溢出框架
                    }
                    
                    // 漸變背景和標題部分
                    LinearGradient(colors:
                                    [
                                        Color("menusheetbackgroundcolor").opacity(0 - progress),
                                        Color("menusheetbackgroundcolor").opacity(0.2 - progress),
                                        Color("menusheetbackgroundcolor").opacity(0.4 - progress),
                                        Color("menusheetbackgroundcolor").opacity(0.6 - progress),
                                        Color("menusheetbackgroundcolor").opacity(0.8 - progress),
                                        Color("menusheetbackgroundcolor")
                                    ], startPoint: .top, endPoint: .bottom)
                    
                    VStack(spacing: 0)
                    {
                        Text(itemName())
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
                .offset(y: -minY)
                .onChange(of: progress)
                {
                    print("CoverView的progress值: \(progress)")
                }
            }
                .frame(height: height + safeArea.top)
        )
    }
    
    
    // MARK: 標題畫面
    // 標題視圖，根據滾動狀態顯示標題或其他信息
    func HeaderView(size: CGSize, recordInput: String? = nil) -> AnyView
    {
        let name = itemName()
        
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
                        
                        // 滑動後顯示對應料理名稱
                        Text(name)
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
                .animation(.smooth.speed(2), value: progress < 6)
                .offset(y: -minY)
                .onChange(of: progress)
                {
                    print("HeaderView的progress值: \(progress)")
                }
            }
        )
    }
    
    
}

// MARK: extension：RecipeP
extension RecipeP
{
    func itemName() -> String
    {
        return dishesData.first(where: { $0.Dis_ID == Dis_ID })?.Dis_Name ?? "Unknown Dish"
    }
    
    func itemImageURL() -> URL?
    {
        guard let urlString = dishesData.first(where: { $0.Dis_ID == Dis_ID })?.D_image,
              let url = URL(string: urlString), UIApplication.shared.canOpenURL(url)
        else
        {
            return nil
        }
        return url
    }
    
    // MARK: loadCookingMethod
    //從給定的 URL 載入烹飪方法
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
    
    // MARK: filteredAmounts過濾對應菜色的食材數量
    func filteredAmounts(for dish: Dishes) -> [Amount]
    {
        return amountData.filter { $0.Dis_ID == dish.Dis_ID }
    }
    
    // MARK: CookbookView烹飪書畫面
    //包括所需食材和烹飪方法
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
                                            .frame(width: 25, alignment: .leading)
                                        
                                        Text(stepDescription)//各步驟煮法
                                            .font(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading,1) // 編號和文本距離
                                            .lineSpacing(2)  // 行距
                                    }
                                    .padding(.horizontal, 25) // 内容左右的留白
                                    .padding(.vertical, 3) // 上下留白
                                }
                            }
                        }
                        // else {
                        //     LoadingView() // 载入画面
                        // }
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
            }//最後一個包圍的vVStack
            
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

// MARK: extension：AIRecipeP
extension AIRecipeP {
    func itemName() -> String {
        // 確保有可用的 chatRecord 並解包 output
        guard let output = aiRecipes.first?.output else {
            return "Unknown AI Recipe"
        }
        
        // 使用 extractRecipeName 方法提取名稱
        return output.extractRecipeName() ?? "Unknown AI Recipe"
    }
    
    func itemImageURL() -> URL? {
        return nil  // AI 生成的食譜可能沒有封面圖片
    }
}

// MARK: extension：CRecipeP
extension CRecipeP
{
    func itemName() -> String
    {
        return Crecipe.f_name ?? "Unknown Recipe Name"
    }
    
    func itemImageURL() -> URL?
    {
        return nil  // AI 生成的食譜可能沒有封面圖片
    }
}
