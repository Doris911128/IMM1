//
//  CookingAiView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/5/24.
//

import SwiftUI


// 定義字體大小枚舉
enum FontSize
{
    case small, medium
}

struct CookingAiView: View
{
    var disID: Int // 新增接收 Dis_ID
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes?
    @State private var scrollOffset: CGFloat = 0 // 滑动偏移
    @State private var gesture: String = ""
    @State private var currentIndex: Int = 0 // 当前卡片索引
    @State private var stepsCount: Int = 0 // 新增狀態變量來跟蹤步驟數量
    
    @State private var showHint: Bool = false
    @State private var hintMessage: String = ""
    
    var body: some View
    {
        NavigationView
        {
            ZStack
            {
                VStack(spacing: 0)
                {
                    HStack
                    {
                        Text(selectedDish?.Dis_Name ?? "Unknown食譜名稱")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.leading)
                        Spacer()
                    }
                    .padding(.top, 95) // 根据需要调整顶部 padding
                    .background(Color.white)
                    .zIndex(1)
                    
                    ScrollView(.horizontal, showsIndicators: false)
                    {
                        HStack(spacing: 20)
                        {
                            if let selectedDish = selectedDish
                            {
                                CardView(dish: selectedDish, stepsCount: $stepsCount) // 传递步驟數量
                                    //.frame(maxWidth: .infinity, alignment: .center) // 卡片水平居中
                                    .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.height * 0.5) // 設置外部框架大小，不影響滑動邏輯
                                    .offset(x: scrollOffset) // 应用滑动偏移
                                
                            }
                        }
                        .padding(.horizontal)
                        .frame(maxHeight: .infinity, alignment: .center) // 让卡片垂直居中
                        
                    }
                    
                    // 添加 HandPoseDetectionView
                    HandPoseDetectionView(onGestureDetected: { detectedGesture in
                        self.gesture = detectedGesture
                        updateScrollOffset()
                    })
                    .frame(width: 300, height: 200)
                    .background(Color.black)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                    .padding()
                    
                }
                .edgesIgnoringSafeArea(.top) // 忽略安全区域，使标题紧贴屏幕顶部
                
                
                // 顯示提示訊息
                if showHint
                {
                    VStack
                    {
                        Spacer()
                        Text(hintMessage)
                            .font(.headline)
                            .padding()
                            .background(Color.yellow)
                            .cornerRadius(8)
                            .transition(.opacity)
                            .onAppear
                        {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3)
                            {
                                withAnimation
                                {
                                    self.showHint = false
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear
        {
            loadDishesData() // 畫面加載時加載菜譜數據
        }
    }
    
//    func updateScrollOffset() {
//        let screenWidth = UIScreen.main.bounds.width
//        let cardWidth = screenWidth * 0.85
//        let stepCard = stepsCount
//        
//        switch gesture {
//        case "👎":
//            if currentIndex < stepCard - 1 {
//                currentIndex += 1
//                withAnimation(.easeInOut(duration: 0.5)) {
//                    scrollOffset -= cardWidth
//                }
//                print("當前卡片索引: \(currentIndex + 1), 總步驟數: \(stepCard)")
//                
//            }
//        case "👍":
//            if currentIndex > 0 {
//                currentIndex -= 1
//                withAnimation(.easeInOut(duration: 0.5)) {
//                    scrollOffset += cardWidth
//                }
//                print("當前卡片索引: \(currentIndex + 1), 總步驟數: \(stepCard)")
//            }
//        case "✋":
//            break
//        default:
//            break
//        }
//    }
    
    func updateScrollOffset() {
            let screenWidth = UIScreen.main.bounds.width
            let cardWidth = screenWidth * 0.85
            let stepCard = stepsCount
            
            switch gesture {
            case "👎":
                if currentIndex < stepCard - 1 {
                    currentIndex += 1
                    withAnimation(.easeInOut(duration: 0.5)) {
                        scrollOffset -= cardWidth
                    }
                    hintMessage = "前往下一步驟 (\(currentIndex + 1)/\(stepCard))"
                    showHint = true
                } else {
                    hintMessage = "已到達最後一步驟"
                    showHint = true
                }
                
            case "👍":
                if currentIndex > 0 {
                    currentIndex -= 1
                    withAnimation(.easeInOut(duration: 0.5)) {
                        scrollOffset += cardWidth
                    }
                    hintMessage = "返回上一步驟 (\(currentIndex + 1)/\(stepCard))"
                    showHint = true
                } else {
                    hintMessage = "已在第一步驟"
                    showHint = true
                }
                
            case "✋":
                hintMessage = "手勢偵測：請做出 👍 或 👎 手勢"
                showHint = true
                
            default:
                break
            }
        }
    
    // 從後端載入菜譜數據的方法
    func loadDishesData()
    {
        let urlString = "http://163.17.9.107/food/php/Dishes.php"
        guard let url = URL(string: urlString)
        else
        {
            print("無效的 URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil
            else
            {
                print("網絡請求錯誤: \(error?.localizedDescription ?? "未知錯誤")")
                return
            }
            
            do
            {
                let decoder = JSONDecoder()
                let dishesData = try decoder.decode([Dishes].self, from: data)
                DispatchQueue.main.async
                {
                    self.dishesData = dishesData
                    self.selectedDish = dishesData.first { $0.Dis_ID == disID }
                }
            } catch
            {
                print("JSON 解析錯誤: \(error)")
            }
        }.resume()
    }
}


struct CardView: View
{
    let dish: Dishes
    @Binding var stepsCount: Int // 绑定步驟數量
    @State private var cookSteps: [String] = ["載入中..."]
    @State private var fontSize: FontSize = .medium // 新增狀態變量來跟蹤字體大小
    
    //煮法網址載入
    func loadCookDetails(from urlString: String)
    {
        guard let url = URL(string: urlString)
        else
        {
            cookSteps = ["無效的URL"]
            return
        }
        
        let task = URLSession.shared.dataTask(with: url)
        { data, response, error in
            if let data = data, let details = String(data: data, encoding: .utf8)
            {
                let steps = splitSteps(details)
                DispatchQueue.main.async
                {
                    cookSteps = steps
                    cookSteps = splitSteps(details)
                    stepsCount = steps.count // 更新步驟數量
                    print("此道料理有 \(steps.count) 步驟")
                    
                    
                }
            }
            else
            {
                DispatchQueue.main.async
                {
                    cookSteps = ["無法載入資料"]
                }
            }
        }
        task.resume()
    }
    
    //煮法步驟分割
    func splitSteps(_ text: String) -> [String]
    {
        // 使用行分割方法
        var steps = text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
        
        // 確保每步驟是以數字和句點開頭
        var stepIndex = 1
        var result: [String] = []
        var currentStep = ""
        
        for step in steps
        {
            if step.hasPrefix("\(stepIndex).")
            {
                if !currentStep.isEmpty
                {
                    result.append(removeStepNumber(currentStep))
                }
                currentStep = step
                stepIndex += 1
            }
            else
            {
                currentStep += " \(step)"
            }
        }
        
        if !currentStep.isEmpty
        {
            result.append(removeStepNumber(currentStep))
        }
        return result
    }
    
    // 移除煮法步驟編號
    func removeStepNumber(_ text: String) -> String
    {
        let pattern = "^\\d+\\.\\s*"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex?.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "") ?? text
    }
    
    // 切換字體大小方法
    func toggleFontSize() 
    {
        switch fontSize 
        {
        case .small:
            fontSize = .medium
        case .medium:
            fontSize = .small
        }
    }
    
    // 根據字體大小枚舉返回對應的字體
    func font(for size: FontSize) -> Font 
    {
        switch size 
        {
        case .small:
            return .body
        case .medium:
            return .title2
        }
    }
    
    
    var body: some View
    {
        VStack
        {
            ScrollView(.horizontal, showsIndicators: false)
            {
                HStack(spacing: 20)
                {
                    ForEach(cookSteps.indices, id: \.self)
                    { index in
                        ZStack(alignment: .bottomTrailing)
                        {
                            VStack(alignment: .leading)
                            {
                                
                                Text("步驟 \(index + 1)")
                                    .font(font(for: fontSize)) // 調整字體大小
                                    .fontWeight(.bold) // 保持粗體
                                    .padding([.leading, .trailing, .top])
                                
                                Text(cookSteps[index])
                                    .font(font(for: fontSize))
                                    .padding()
                                Spacer()
                            }
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            //卡片大小
                            .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.6)
                           // .scaleEffect(x: 1.01, y: 0.7) // 寬度增加5%，高度縮小到67%
                            
                            //字體切換按鈕
                            Button(action: {
                                toggleFontSize()
                            })
                            {
                                Image(systemName: "textformat.size")
                                    .font(.title2)
                                    .padding()
                            }
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .padding()
                        }
                    }
                }
                .padding(20)
                .onAppear
                {
                    loadCookDetails(from: dish.D_Cook ?? "")
                }
            }
        }
    }
}

#Preview
{
    CookingAiView(disID: 1)
}
