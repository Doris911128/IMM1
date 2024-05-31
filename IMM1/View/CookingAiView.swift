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

struct CardView: View
{
    let dish: Dishes
    @State private var cookSteps: [String] = ["載入中..."]

    var body: some View
    {
        ScrollView(.horizontal, showsIndicators: false)
        {
            HStack(spacing: 20)
            {
                ForEach(cookSteps.indices, id: \.self)
                { index in
                    VStack(alignment: .leading)
                    {
                        //圖片
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
            .onAppear
            {
                loadCookDetails(from: dish.D_Cook)
            }
        }
    }

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
            } else
            {
                DispatchQueue.main.async
                {
                    cookSteps = ["無法載入資料"]
                }
            }
        }
        task.resume()
    }

    func splitSteps(_ text: String) -> [String]
    {
            // 使用行分割方法
            var steps = text.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            // 確保每步驟是以數字和句點開頭
            var stepIndex = 1
            var result: [String] = []
            var currentStep = ""

            for step in steps {
                if step.hasPrefix("\(stepIndex).")
                {
                    if !currentStep.isEmpty
                    {
                        result.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    currentStep = step
                    stepIndex += 1
                } else
                {
                    currentStep += " \(step)"
                }
            }
           
        if !currentStep.isEmpty
        {
            result.append(currentStep.trimmingCharacters(in: .whitespacesAndNewlines))
        }
            return result
    }
}

#Preview
{
    CookingAiView()
}
