//
//  CookingAiView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/5/24.
//

import SwiftUI

struct CookingAiView: View
{
    // 示例數據
    let dishesData: [Dishes] = [
        Dishes(Dis_ID: 1, Dis_Name: "t蕃茄炒蛋", D_Cook: "http://163.17.9.107/food/dishes/1.txt", D_image: "http://163.17.9.107/food/images/1.jpg", D_Video: "xxxxxxxxx")
    ]
    //@State private var dishesData: [Dishes] = []
    @State private var foodData: [Food] = []
    @State private var amountData: [Amount] = []
    var body: some View
    {
        NavigationView
        {
            ScrollView(.horizontal, showsIndicators: false)
            {
                HStack(spacing: 20)
                {
                    ForEach(dishesData, id: \.Dis_ID)
                    { dish in
                        CardView(dish: dish)
                            //.frame(width: UIScreen.main.bounds.width * 0.8) // 調整卡片寬度
                            //.padding(.horizontal, 20) // 添加水平間距
                    }
                }
                .padding()
            }
            .navigationTitle(dishesData.first?.Dis_Name ?? "Unknown食譜名稱")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CardView: View {
    let dish: Dishes
    @State private var cookSteps: [String] = ["載入中..."]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(cookSteps.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
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
                            .font(.headline)
                            .padding([.leading, .trailing])
                        
                        Text(cookSteps[index])
                            .font(.body)
                            .padding()
                        
                        Spacer()
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .frame(width: UIScreen.main.bounds.width * 0.8, height: UIScreen.main.bounds.height * 0.6)
                }
            }
            .padding(.horizontal, 20)
            .onAppear {
                loadCookDetails(from: dish.D_Cook)
            }
        }
    }

    func loadCookDetails(from urlString: String) {
        guard let url = URL(string: urlString) else {
            cookSteps = ["無效的URL"]
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let details = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    cookSteps = splitSteps(details)
                }
            } else {
                DispatchQueue.main.async {
                    cookSteps = ["無法載入資料"]
                }
            }
        }
        task.resume()
    }

    func splitSteps(_ text: String) -> [String] {
        // 使用正則表達式來分割步驟
        let pattern = "(?<=\\d\\.\\s)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        var results: [String] = []
        var lastEndIndex = text.startIndex
        
        regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let match = match {
                let stepRange = Range(match.range, in: text)!
                if lastEndIndex < stepRange.lowerBound {
                    let stepText = String(text[lastEndIndex..<stepRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !stepText.isEmpty {
                        results.append(stepText)
                    }
                    lastEndIndex = stepRange.lowerBound
                }
            }
        }
        
        if lastEndIndex < text.endIndex {
            let stepText = String(text[lastEndIndex..<text.endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !stepText.isEmpty {
                results.append(stepText)
            }
        }
        
        return results
    }
}

#Preview
{
    CookingAiView()
}
