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
    @State private var scrollOffset: CGFloat = 0 // 滑動偏移
    @State private var gesture: String = ""
    @State private var currentIndex: Int = 0 // 當前卡片索引
    @State private var stepsCount: Int = 0 // 新增狀態變量來跟蹤步驟數量
    @State private var showHint: Bool = false
    @State private var hintMessage: String = ""
    @State private var showHelp: Bool = false // 新增狀態控制彈跳視窗
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View
    {
        NavigationView
        {
            ZStack
            {
                VStack
                {
                    HStack
                    {
                        Text(selectedDish?.Dis_Name ?? "Unknown食譜名稱")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.leading)
                        
                        Spacer()
                        
                        // 說明按鈕
                        Button(action: {
                            showHelp = true // 顯示彈跳視窗
                        }) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.title)
                                .foregroundColor(.orange)
                        }
                        .padding(.trailing)
                    }
                    .padding(.top, 95)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .zIndex(1)
                    
                    ScrollView(.horizontal, showsIndicators: false)
                    {
                        HStack(spacing: 20)
                        {
                            if let selectedDish = selectedDish
                            {
                                CardView(dish: selectedDish,
                                         stepsCount: $stepsCount,
                                         currentIndex: $currentIndex,
                                         showHintMessage: showHintMessage)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .offset(x: scrollOffset)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                            }
                        }
                        .padding(.horizontal)
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    
                    // 手勢檢測視圖
                    HandPoseDetectionView(onGestureDetected: { detectedGesture in
                        if !showHelp { // 僅在未顯示說明視窗時生效
                            self.gesture = detectedGesture
                            updateScrollOffset()
                        }
                    })
                    .frame(width: 310, height: 200)
                    .background(Color.black)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                    .padding(3)
                }
                .blur(radius: showHelp ? 5 : 0) // 底層模糊
                .allowsHitTesting(!showHelp) // 禁用底層互動
                
                // 將提示視圖放在最上層
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
                            .padding(.bottom, 20)
                            .transition(.opacity)
                        
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.5))
                            .onAppear(){
                                DispatchQueue.main.asyncAfter(deadline: .now() + 7)
                                {
                                    withAnimation
                                    {
                                        self.showHint = false
                                    }
                                }
                            }
                    }
                    .zIndex(2) // 提升層級，確保顯示在最上層
                }
                
                // 彈跳視窗
                if showHelp
                {
                    VStack(spacing: 20)
                    {
                        Text("功能說明")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("本功能透過手勢切換來查看每個菜譜的烹飪步驟")
                        
                        Text("「👍」表示向前、「👎」表示向後")
                            .multilineTextAlignment(.leading)
                        
                        Text("＊請正確維持手勢「👍」、「👎」，否則容易切換步驟失敗＊")
                            .multilineTextAlignment(.leading)
                        
                        Button(action: {
                            print("按下關閉按鈕") // 確認是否觸發
                            withAnimation {
                                showHelp = false
                            }
                        }) {
                            Text("關閉")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .frame(maxWidth: 300)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                    .zIndex(3)
                }
            }
            .edgesIgnoringSafeArea(.top) // 忽略安全区域，使标题紧贴屏幕顶部
            
        }
        .onAppear
        {
            loadDishesData() // 畫面加載時加載菜譜數據
        }
        
    }
    
    
    func showHintMessage(_ message: String, duration: Double = 2.0)
    {
        hintMessage = message
        showHint = true
        withAnimation {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                showHint = false
            }
        }
    }
    
    
    
    func updateScrollOffset()
    {
        let screenWidth = UIScreen.main.bounds.width
        
        //手勢滑動能依照卡片大小的變更自動調整
        let cardWidth: CGFloat = UIScreen.main.bounds.width * 0.85 + 20 // 卡片寬度 + 間距
        
        let stepCard = stepsCount
        
        switch gesture {
        case "👎":
            if currentIndex < stepCard - 1 {
                currentIndex += 1
                withAnimation(.easeInOut(duration: 0.5)) {
                    scrollOffset -= cardWidth
                }
                print("當前卡片索引: \(currentIndex + 1), 總步驟數: \(stepCard)")
                showHintMessage("「👎向後」", duration: 7.5)
            } else {
                showHintMessage("這是最後一張卡片，無法向後滑動", duration: 5)
            }
        case "👍":
            if currentIndex > 0 {
                currentIndex -= 1
                withAnimation(.easeInOut(duration: 0.5)) {
                    scrollOffset += cardWidth
                }
                print("當前卡片索引: \(currentIndex + 1), 總步驟數: \(stepCard)")
                showHintMessage("「👍向前」", duration: 7.5)
            } else {
                showHintMessage("這是第一張卡片，無法向前滑動")
            }
        case "✋":
            showHintMessage("請比出「👎向後」或「👍向前」的手勢來滑動卡片", duration: 5)
            break
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
    @Binding var currentIndex: Int
    @State private var cookSteps: [String] = ["載入中..."]
    @State private var fontSize: FontSize = .medium // 新增狀態變量來跟蹤字體大小
    @Environment(\.colorScheme) var colorScheme
    
    // 新增接收父層方法的參數
    var showHintMessage: (String, Double) -> Void
    
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
                                    .padding([.leading, .trailing ,.top])
                                
                                Text(cookSteps[index])
                                    .font(font(for: fontSize))
                                    .padding()
                                
                                    .lineLimit(nil) // 允許多行文本
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white) // 深色模式背景為灰色帶透明度，淺色模式背景為白色
                            
                            .cornerRadius(15)
                            .shadow(radius: 3)
                            //卡片大小
                            .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.height * 0.45)
                            
                            //字體切換按鈕
                            Button(action: {
                                toggleFontSize()
                                showHintMessage("字體已切換", 1.5)
                            }) {
                                Image(systemName: "textformat.size")
                                    .font(.title2)
                                    .padding()
                            }
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .padding()
                        }
                    }
                }
                .padding(20)
                .onAppear {
                    loadCookDetails(from: dish.D_Cook ?? "")
                    if currentIndex == 0 {
                        showHintMessage("左右滑動以查看步驟", 3.0)
                    }
                }
                
            }
            
        }
        
    }
    
}

#Preview
{
    CookingAiView(disID: 1)
}
