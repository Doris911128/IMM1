////
////  RecipeViewModel.swift
////  IMM1
////
////  Created by 朝陽資管 on 2024/8/5.
////
//
//import Foundation
//
//import SwiftUI
//import Combine
//
//class RecipeViewModel: ObservableObject {
//    @Published var dishesData: [Dishes] = []
//    @Published var foodData: [Food] = []
//    @Published var amountData: [Amount] = []
//    @Published var cookingMethod: String? = nil
//    @Published var isFavorited: Bool = false
//    
//    let U_ID: String
//    let Dis_ID: Int
//    
//    init(U_ID: String, Dis_ID: Int) {
//        self.U_ID = U_ID
//        self.Dis_ID = Dis_ID
//        loadMenuData()
//    }
//    
//    func loadMenuData() {
//        // 确保 Dis_ID 是有效的整数且已正确赋值
//        assert(Dis_ID > 0, "Dis_ID 必须大于 0")
//        
//        // 构建带有查询参数的 URL 字符串，使用实际的 Dis_ID 值
//        let urlString = "http://163.17.9.107/food/Dishes.php?id=\(Dis_ID)"
//        print("正在从此URL请求数据: \(urlString)")  // 打印 URL 以确认其正确性
//        
//        // 使用 URL 编码确保 URL 结构的正确性，避免 URL 中有特殊字符造成问题
//        guard let encodedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
//              let url = URL(string: encodedURLString)
//        else {
//            print("生成的 URL 无效")
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET" // 设置 HTTP 请求方法为 GET
//        request.addValue("application/json", forHTTPHeaderField: "Accept") // 请求头部指定期望响应格式为 JSON
//        
//        // 发起异步网络请求
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("网络请求错误: \(error?.localizedDescription ?? "未知错误")")
//                return
//            }
//            
//            // 检查并处理 HTTP 响应状态码
//            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
//                print("HTTP 错误: \(httpResponse.statusCode)")
//                return
//            }
//            
//            // 解析 JSON 数据
//            do {
//                let decoder = JSONDecoder()
//                let dishesData = try decoder.decode([Dishes].self, from: data)
//                DispatchQueue.main.async {
//                    self.dishesData = dishesData
//                    self.foodData = dishesData.first?.foods ?? []
//                    self.amountData = dishesData.first?.amounts ?? []
//                    
//                    // 如果存在烹饪方法的 URL，进行加载
//                    if let cookingUrl = dishesData.first?.D_Cook {
//                        self.loadCookingMethod(from: cookingUrl)
//                    }
//                    
//                    // 打印接收到的 JSON 数据，用于调试
//                    if let jsonStr = String(data: data, encoding: .utf8) {
//                        print("接收到的 JSON 数据: \(jsonStr)")
//                    }
//                    
//                    // 检查收藏状态
//                    self.checkIfFavorited(U_ID: self.U_ID, Dis_ID: "\(self.Dis_ID)")
//                }
//            } catch {
//                print("JSON 解析错误: \(error)")
//                if let jsonStr = String(data: data, encoding: .utf8) {
//                    print("接收到的数据字符串: \(jsonStr)")
//                }
//            }
//        }.resume() // 继续执行已暂停的请求
//    }
//}
