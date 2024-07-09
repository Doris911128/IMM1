//  食譜份數暫時未新增因要更動版面
//  立即主食譜顯示+烹飪模式AI
//  MenuView.swift
//
//

import SwiftUI
import Foundation

struct MenuView: View
{
    init(U_ID: String, Dis_ID: Int = 0, isFavorited: Bool = false)
    {
        self.U_ID = U_ID
        self.Dis_ID = Dis_ID
        self._isFavorited = State(initialValue: isFavorited)
    }
    let U_ID: String // 用於添加我的最愛
    let Dis_ID: Int // 用於添加我的最愛
    @State private var isFavorited: Bool

    @State private var dishesData: [Dishes] = []
    @State private var foodData: [Food] = []
    @State private var amountData: [Amount] = []
    
    @State private var cookingMethod: String? // 新增一個狀態來儲存從URL加載的烹飪方法
    @State private var selectedDish: Dishes?
    
    //var Dis_ID: Int // 從外部接收 Dish ID
    
//    private var selectedDish: Dishes? //var selectedDish: Dishes?
//    {
//        dishesData.first(where: { $0.Dis_ID == Dis_ID })
//    }
    
    // 過濾對應菜品的食材數量
    private func filteredAmounts(for dish: Dishes) -> [Amount]
    {
        amountData.filter { $0.Dis_ID == dish.Dis_ID }
    }
    
    // MARK: 讀取php從後端加載菜譜數據
    // 在 MenuView.swift 中的 loadMenuData 方法
    func loadMenuData()
    {
        // 確保 Dis_ID 是有效的整數且已正確賦值
        assert(Dis_ID > 0, "Dis_ID 必須大於 0")

        // 構建帶有查詢參數的 URL 字串，使用實際的 Dis_ID 值
        let urlString = "http://163.17.9.107/food/Dishes.php?id=\(Dis_ID)"
        print("正在從此URL請求數據: \(urlString)")  // 打印 URL 以確認其正確性

        // 使用 URL 編碼確保 URL 結構的正確性，避免 URL 中有特殊字符造成問題
        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedURLString)
        else
        {
            print("生成的 URL 無效")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET" // 設定 HTTP 請求方法為 GET
        request.addValue("application/json", forHTTPHeaderField: "Accept")// 請求頭部指定期望回應格式為 JSON

        // 發起異步網絡請求
        URLSession.shared.dataTask(with: request) { data, response, error in
                   guard let data = data, error == nil else {
                       print("網絡請求錯誤: \(error?.localizedDescription ?? "未知錯誤")")
                       return
                   }

            // 檢查並處理 HTTP 響應狀態碼
//            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
//                print("HTTP 錯誤: \(httpResponse.statusCode)")
//                if let result = try? JSONDecoder().decode([String: String].self, from: data) {
//                    print("錯誤訊息: \(result["error"] ?? "無錯誤訊息")")
//                }
//                return
//            }
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode)
            {
                print("HTTP 錯誤: \(httpResponse.statusCode)")
                return
            }
            

            // 解析 JSON 數據
            do
            {
                let decoder = JSONDecoder()
                let dishesData = try decoder.decode([Dishes].self, from: data)
                DispatchQueue.main.async
                {
                    self.dishesData = dishesData
                    self.selectedDish = self.dishesData.first(where: { $0.Dis_ID == self.Dis_ID })
                    self.foodData = self.selectedDish?.foods ?? []
                    self.amountData = self.selectedDish?.amounts ?? []

                    // 如果存在烹飪方法的 URL，進行加載
                    if let cookingUrl = self.selectedDish?.D_Cook
                    {
                        self.loadCookingMethod(from: cookingUrl)
                    }
                    
                    // 打印接收到的Dis_ID JSON 字串，用於調試
//                    if let jsonStr = String(data: data, encoding: .utf8)
//                    {
//                        print("接收到的 JSON 數據: \(jsonStr)")
//                    }
                    // 打印所有菜譜的 JSON 數據
                    if let jsonStr = String(data: data, encoding: .utf8)
                    {
                        print("接收到的 JSON 數據: \(jsonStr)")
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
        }.resume() // 繼續執行已暫停的請求
    }
    
    // MARK: 從URL加載烹飪方法
    private func loadCookingMethod(from urlString: String)
    {
        guard let url = URL(string: urlString)
        else
        {
            print("無效的烹飪方法 URL Invalid URL for cooking method")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error
            {
                print("加載烹飪方法失敗 Failed to load cooking method: \(error)")
                return
            }

            if let data = data, let cookingText = String(data: data, encoding: .utf8)
            {
                DispatchQueue.main.async
                {
                    self.cookingMethod = cookingText
                }
            }
        }.resume()
    }
    
    // MARK: 封面畫面
    @ViewBuilder
    private func CoverView(safeArea: EdgeInsets, size: CGSize) -> some View
    {
        let height: CGFloat = size.height * 0.5

        GeometryReader { reader in
            let minY: CGFloat = reader.frame(in: .named("SCROLL")).minY // ScrollView的最小Y值
            let size: CGSize = reader.size // 當前畫面的大小
            let progress: CGFloat = minY / (height * (minY > 0 ? 0.5 : 0.8)) // 滑動狀態的數值

            // 檢查是否有菜餚數據並嘗試加載圖片
            if let dish = dishesData.first
            {
                AsyncImage(url: URL(string: dish.D_image)) { phase in
                    switch phase {
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

//                                         HStack(spacing: 5) {
//                                             Image(systemName: "timer")
//                                             Text("時間：")
//                                             Text("一輩子")
//                                         }
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
                        Color.gray // 加載失敗或正在加載時顯示灰色背景
                    @unknown default:
                        EmptyView()
                    }
                }
                .offset(y: -minY) // 往上滑動的時候 圖片及陰影也要跟著往上滑動
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
    }
    
    // MARK: 標題畫面
    @ViewBuilder
    private func HeaderView(size: CGSize) -> some View
    {
        let Dis_Name = dishesData.first(where: { $0.Dis_ID == Dis_ID })?.Dis_Name ?? "Unknown Dish" // 根据 Dis_ID 找到对应的菜品名称

            GeometryReader
            { reader in
                let minY: CGFloat = reader.frame(in: .named("SCROLL")).minY //ScrollView的最小Y值
                let height: CGFloat = size.height * 0.5
                let progress: CGFloat = minY / (height * (minY > 0 ? 0.5 : 0.8)) //滑動狀態的數值
            
            HStack(spacing: 20)
            {
                if(progress > 6 ) //在 HeaderView 的 ViewBuilder 中
                {
                    Spacer(minLength: 0)
                }
                else // 利用progress的數值變化改變透明度 15會讓專輯標題在HeaderView的位置时 出现以下内容
                {
                    Spacer(minLength: 0)
                    
                    // MARK: 滑動後顯示的料理名稱
                    Text(Dis_Name)
                        .bold()
                        .font(.title3)
                        .transition(.opacity.animation(.smooth))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                    
                    Spacer(minLength: 0)
                }
            }
            .foregroundStyle(.orange) //控制最愛追蹤按鈕的顏色
            .padding()
            .background(Color("menusheetbackgroundcolor").opacity(progress > 6 ? 0 : 1)) //利用progress的數值變化改變透明度 11會讓專輯標題在HeaderView的位置時 出現背景顏色
            .animation(.smooth.speed(2), value: progress<6)
            .offset(y: -minY)
            // MARK: HeaderView的progress
            .onChange(of: progress)
            {
                print("HeaderView的progress值: \(progress)")
            }
        }
    }
    
    // MARK: 烹飪書畫面
    @ViewBuilder
    private func CookbookView(safeArea: EdgeInsets) -> some View
    {
        VStack(spacing: 20)
        {
            // 所需食材
            Text("所需食材")
                .foregroundStyle(.orange)
                .font(.title2)
                .offset(x: -130)
            
            if let selectedDish = selectedDish
            {
                // 根據選擇的菜譜ID過濾相應的菜譜食材數量
                let filteredAmounts = amountData.filter { $0.Dis_ID == selectedDish.Dis_ID }
                        
                // 遍歷過濾後的菜譜食材數量
                ForEach(filteredAmounts, id: \.F_ID) { amount in
                      
                    // 在食材數據中查找對應的食材
                    if let food = foodData.first(where: { $0.F_ID == amount.F_ID })
                    {
                        //let amountString = amount.A_Amount
                        Text("\(food.F_Name) \(amount.A_Amount) \(food.F_Unit)")
                    }
                }
            } else
            {
                Text("載入中...") // 或顯示載入狀態
            }

            // 烹飪方法
            Text("料理方法")
                .foregroundStyle(.orange)
                .font(.title2)
                .offset(x: -130)
            ScrollView
            {
                if let method = cookingMethod
                {
                    Text(method) // 使用已有的 cookingMethod 顯示烹飪方法
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                } else
                {
                    Text("載入中...") // 或顯示載入狀態
                }
            }

            // 影片教學
            Text("影片教學")
                .foregroundStyle(.orange)
                .font(.title2)
                .offset(x: -130)
            Text(dishesData.first?.D_Video ?? "無影片資訊")
        }
        .onAppear
        {
            if let cookingUrl = selectedDish?.D_Cook
            {
                loadCookingMethod(from: cookingUrl)
            }
        }
    }
    
    // MARK: body
    var body: some View
    {
        GeometryReader
        {
            let safeArea: EdgeInsets=$0.safeAreaInsets //當前畫面的safeArea
            let size: CGSize=$0.size //GeometryReader的大小
            
            ScrollView(.vertical, showsIndicators: false)
            {
                VStack
                {
                    // MARK: CoverView
                    self.CoverView(safeArea: safeArea, size: size)
                    
                    // MARK: CookbookView
                    self.CookbookView(safeArea: safeArea).padding(.top)
                    
                    // MARK: HeaderView
                    self.HeaderView(size: size)
                }
            }
            .coordinateSpace(name: "SCROLL") //抓取ScrollView的各項數值
            .overlay(
                //MARK: 前往烹飪模式AI按鈕
                VStack
                {
                    Spacer()
                    HStack
                    {
                        Spacer()
                        NavigationLink(destination: CookingAiView())
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
                           
                            Text("AI Cooking")
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 10) // 控制按鈕上下內邊距
                            .padding(.horizontal,10) // 控制按鈕左右內邊距
                            .background(Color.orange)
                            .clipShape(CustomCorners(cornerRadius: 30, corners: [.topLeft, .bottomLeft]))
                            .shadow(radius: 10)
                        }
                        .padding(.bottom, 50) // 調整按鈕的垂直位置
                    }
                }
            )
        }
        .toolbarBackground(Color("menusheetbackgroundcolor"), for: .navigationBar)
        .toolbar
        {
            ToolbarItem(placement: .navigationBarTrailing)
            {
                Button(action:
                {
                    //您的操作代碼在這裡
                    withAnimation(.easeInOut.speed(3))
                    {
                        self.isFavorited.toggle()
                        toggleFavorite(U_ID: U_ID, Dis_ID: Dis_ID, isFavorited: isFavorited) { result in
                            switch result
                            {
                            case .success(let responseString):
                                print("Success: \(responseString)")
                            case .failure(let error):
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    }
                })
                {
                    Image(systemName: self.isFavorited ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(.orange) //設定愛心為橘色
                }
                .animation(.none) //移除這行如果不需要動畫
            }
        }
        .onAppear
        {
            print("顯示的 Dis_ID: \(Dis_ID)")
            loadMenuData()
        }
    }
}

// 自定義“烹飪模式AI按鈕”圓角方向
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

#Preview
{
    MenuView(U_ID:"ofmyRwDdZy",Dis_ID: 1)
}
