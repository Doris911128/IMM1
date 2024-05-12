//  MenuView.swift
//
//

import SwiftUI
import Foundation

struct MenuView: View
{
    @State private var dishesData: [Dishes] = []
    @State private var foodData: [Food] = []
    @State private var amountData: [Amount] = []
    
    @State private var cookingMethod: String? // 新增一個狀態來儲存從URL加載的烹飪方法
    @State private var selectedDish: Dishes?
    
    var Dis_ID: Int // 接受传递的 Dis_ID
    
//    private var selectedDish: Dishes? //var selectedDish: Dishes?
//    {
//        dishesData.first(where: { $0.Dis_ID == Dis_ID })
//    }
    
    private func filteredAmounts(for dish: Dishes) -> [Amount]
    {
        amountData.filter { $0.Dis_ID == dish.Dis_ID }
    }
    

//    // MARK: Test data
//    // 菜譜結構
//    let dishesData: [Dishes] = [
//        Dishes(Dis_ID: 1, Dis_Name: "蕃茄炒蛋", D_Cook: "http://163.17.9.107/food/dishes/1.txt", D_image: "http://163.17.9.107/food/images/1.jpg", D_Video: "xxxxxxxxx")
//    ]
//    // 食材結構
//    let foodData: [Food] = [
//        Food(F_ID: 1, F_Name: "雞蛋", F_Unit: "顆"),
//        Food(F_ID: 2, F_Name: "番茄", F_Unit: "顆"),
//        Food(F_ID: 7, F_Name: "蔥", F_Unit: "把")
//    ]
//    // 菜譜食材數量結構
//    let  AmountData: [Amount] = [
//        Amount(A_ID:1,Dis_ID: 1,F_ID: 1,A_Amount:3),
//        Amount(A_ID:2,Dis_ID: 1,F_ID: 2,A_Amount:2),
//        Amount(A_ID:3,Dis_ID: 1,F_ID: 7,A_Amount:0.3)
//    ]
    
    // MARK: 讀取php從後端加載菜譜數據
    // 在 MenuView.swift 中的 loadMenuData 方法
    func loadMenuData() {
        // 确保 Dis_ID 是一个有效的整数并已正确赋值
        assert(Dis_ID > 0, "Dis_ID must be greater than 0")
        
        // 添加调试语句，确认实际接收到的 Dis_ID 值
        let urlString = "http://163.17.9.107/food/Dishes.php?id=\(Dis_ID)"
        print("Requesting data from URL: \(urlString)") // 确认 URL
        
        // 确保 URL 正确处理，进行 URL 编码
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        // 创建一个 URLRequest 对象，并设置请求方法和请求头
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // 发起网络请求
        URLSession.shared.dataTask(with: request) { data, response, error in
            // 处理网络请求的结果
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Invalid response")
                return
            }

            if let data = data {
                do {
                    // 解析 JSON 数据
                    let decoder = JSONDecoder()
                    let dishesData = try decoder.decode([Dishes].self, from: data)
                    DispatchQueue.main.async {
                        // 更新 UI
                        self.dishesData = dishesData
                        self.selectedDish = self.dishesData.first(where: { $0.Dis_ID == self.Dis_ID })
                        // 加载烹饪方法
                        if let cookingUrl = self.selectedDish?.D_Cook {
                            self.loadCookingMethod(from: cookingUrl)
                        }
                    }
                } catch {
                    print("Error decoding JSON: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    // MARK: 從URL加載烹飪方法
    private func loadCookingMethod(from urlString: String)
    {
        guard let url = URL(string: urlString)
        else {
            print("Invalid URL for cooking method")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to load cooking method: \(error)")
                return
            }
            
            if let data = data, let cookingText = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async
                {
                    self.cookingMethod = cookingText
                }
            }
        }.resume()
    }
    // MARK: 封面畫面
    @ViewBuilder
    private func CoverView(safeArea: EdgeInsets, size: CGSize) -> some View {
        let height: CGFloat = size.height * 0.5

        GeometryReader { reader in
            let minY: CGFloat = reader.frame(in: .named("SCROLL")).minY // ScrollView的最小Y值
            let size: CGSize = reader.size // 當前畫面的大小
            let progress: CGFloat = minY / (height * (minY > 0 ? 0.5 : 0.8)) // 滑動狀態的數值

            // 檢查是否有菜餚數據並嘗試加載圖片
            if let dish = dishesData.first {
                AsyncImage(url: URL(string: dish.D_image)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                             .scaledToFill()
                             .frame(width: size.width, height: size.height + (minY > 0 ? minY : 0))
                             .clipped()
                             .overlay(
                                 ZStack(alignment: .bottom) {
                                     LinearGradient(colors: [
                                         Color("menusheetbackgroundcolor").opacity(0 - progress),
                                         Color("menusheetbackgroundcolor").opacity(0.2 - progress),
                                         Color("menusheetbackgroundcolor").opacity(0.4 - progress),
                                         Color("menusheetbackgroundcolor").opacity(0.6 - progress),
                                         Color("menusheetbackgroundcolor").opacity(0.8 - progress),
                                         Color("menusheetbackgroundcolor")
                                     ], startPoint: .top, endPoint: .bottom)
                                     
                                     VStack(spacing: 0) {
                                         Text(dish.Dis_Name)
                                             .bold()
                                             .font(.largeTitle)
                                             .foregroundStyle(.orange)

                                         HStack(spacing: 5) {
                                             Image(systemName: "timer")
                                             Text("時間：")
                                             Text("一輩子")
                                         }
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
                .onChange(of: progress) {
                    print("CoverView的progress值: \(progress)")
                }
            } else {
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
    private func CookbookView(safeArea: EdgeInsets) -> some View {
        VStack(spacing: 20) {
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
                               let formattedAmount = String(format: "%.1f", amount.A_Amount)
                                Text("\(food.F_Name) \(formattedAmount) \(food.F_Unit)")
                    }
                }
            } else {
                Text("載入中...") // 或顯示載入狀態
            }

            // 烹飪方法
            Text("料理方法")
                .foregroundStyle(.orange)
                .font(.title2)
                .offset(x: -130)
            ScrollView {
                if let method = cookingMethod {
                    Text(method) // 使用已有的 cookingMethod 顯示烹飪方法
                } else {
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
        .onAppear {
            if let cookingUrl = selectedDish?.D_Cook {
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
        }
        .toolbarBackground(Color("menusheetbackgroundcolor"), for: .navigationBar)
        .toolbar
        {
            ToolbarItem(placement: .navigationBarTrailing)
            {
                Button(action: {
                    //您的操作代碼在這裡
                }) {
                    Image(systemName: "heart")
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
#Preview {
    MenuView(Dis_ID: 1)
}
