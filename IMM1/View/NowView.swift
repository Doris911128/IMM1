import SwiftUI
import UIKit
import Foundation

struct DishService 
{
    static func loadDishes(completion: @escaping ([Dishes]) -> Void)
    {
        guard let url = URL(string: "http://163.17.9.107/food/Dishes.php") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else 
            {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do 
            {
                let dishes = try JSONDecoder().decode([Dishes].self, from: data)
                DispatchQueue.main.async 
                {
                    completion(dishes)
                }
            } catch 
            {
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
    
    @AppStorage("U_ID") private var U_ID: String = "" // 从 AppStorage 中读取 U_ID
    
    var body: some View 
    {
        NavigationStack 
        {
            ZStack 
            {
                VStack 
                { // 包住加號和發佈貼文
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
                            if let selectedDish = selectedDish
                            {
                                NavigationLink(destination: MenuView(Dis_ID: selectedDish.Dis_ID)) 
                                {
                                    RecipeBlock(
                                        imageName: selectedDish.D_image ?? "",
                                        title: selectedDish.Dis_Name ?? "",
                                        U_ID: U_ID,
                                        Dis_ID: "\(selectedDish.Dis_ID)" // 确保 Dis_ID 是字符串
                                    )
                                }
                            }
                        }
                        .padding(.trailing, 12)
                    }
                }
            }
        }
        .onAppear 
        {
            DishService.loadDishes 
            { dishes in
                self.dishesData = dishes
                self.selectedDish = dishes.first
            }
        }
    }
}

struct NowView_Previews: PreviewProvider 
{
    static var previews: some View 
    {
        NowView()
    }
}
