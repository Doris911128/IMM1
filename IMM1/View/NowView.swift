//  NowView.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/12/1.
//

// MARK: 立即煮介面
import SwiftUI
import UIKit
import Foundation

struct DishService
{
    static func loadDishes(completion: @escaping ([Dishes]) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/Dishes.php") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do {
                let dishes = try JSONDecoder().decode([Dishes].self, from: data)
                DispatchQueue.main.async {
                    completion(dishes)
                }
            } catch {
                print("Error decoding JSON: \(error)")
                completion([])
            }
        }.resume()
    }
}

struct NowView: View
{
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes? = nil // 用于存储用户选择的菜品信息
    
//    init() {
//            // 這裡直接在初始化時呼叫異步方法
//            DishService.loadDishes { dishes in
//                self.dishesData = dishes
//                self.selectedDish = dishes.first // 預設選擇第一道菜
//            }
//        }
    
    var body: some View
    {
        NavigationStack
        {
            ZStack
            {
                VStack // 包住加號和發佈貼文
                {
                    Text("立即煮")
                        .font(.largeTitle)
                        .bold()
                        .offset(x: 10, y: 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // MARK: 料理顯示區
                    ScrollView(showsIndicators: false)
                    {
                        VStack
                        {
                            NavigationLink(destination: MenuView(Dis_ID: selectedDish?.Dis_ID ?? 1)) {
                                                   RoundedRectangleBlock(imageName: selectedDish?.D_image ?? "", title: selectedDish?.Dis_Name ?? "")
                                           }
//                            NavigationLink(destination: MenuView())
//                            {
//                                RoundedRectangleBlock(imageName: "1", title: "炸豬排")
//                            }
//                            NavigationLink(destination: MenuView())
//                            {
//                                RoundedRectangleBlock(imageName: "1", title: "日式魚排")
//                            }
                        }
                        .padding(.trailing, 12)
                    }
                }
            }
        }
        .onAppear {
            DishService.loadDishes { dishes in
                self.dishesData = dishes
                self.selectedDish = dishes.first
            }
        }
    }
}

// MARK: 文章發布後格式
struct RoundedRectangleBlock: View
{
    let imageName: String
    let title: String
    
    init(imageName: String, title: String)
    {
        self.imageName = imageName
        self.title = title
    }
    
    var body: some View
    {
        Spacer()
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(red: 0.961, green: 0.804, blue: 0.576))
            .frame(width: 330, height: 250)
            .overlay {
                VStack {
                    Image(imageName)
                        .resizable()
                        .frame(width: 330, height: 170)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .offset(y: -18)
                    Text(title)
                        .foregroundColor(Color.black)
                        .padding(.horizontal, 10)
                        .font(.system(size: 24))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(y: -15)
                }
            }
            .padding(20)
    }
}


struct NowView_Previews: PreviewProvider
{
    static var previews: some View
    {
        NowView()
    }
}
