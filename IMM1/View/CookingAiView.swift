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
    case small, medium, large
}

struct CookingAiView: View 
{
    var disID: Int // 新增接收 Dis_ID
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes?
    
    var body: some View 
    {
        NavigationView 
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
                            CardView(dish: selectedDish)
                                .frame(maxWidth: .infinity, alignment: .center) // 卡片水平居中
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity, alignment: .center) // 让卡片垂直居中
                }
                
                // 添加相機視圖
                CameraView()
                    .frame(width: 100, height: 100) // 使用 frame 修飾符調整大小
                    .background(Color.black)
                    .cornerRadius(10)
                    .padding()
            }
            .edgesIgnoringSafeArea(.top) // 忽略安全区域，使标题紧贴屏幕顶部
        }
        .onAppear 
        {
            loadDishesData() // 畫面加載時加載菜譜數據
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
                DispatchQueue.main.async
                {
                    cookSteps = splitSteps(details)
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
            fontSize = .large
        case .large:
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
        case .large:
            return .title
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
                                // 圖片
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 150)
                                    .cornerRadius(10)
                                    .overlay(
                                        Text("Image")
                                            .foregroundColor(.white)
                                            .bold()
                                    )
                                    .padding()
                                
                                Text("步驟 \(index + 1)")
                                    .font(font(for: fontSize)) // 調整字體大小
                                    .fontWeight(.bold) // 保持粗體
                                    .padding([.leading, .trailing])
                                
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
