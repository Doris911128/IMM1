//  Favorite.swift
//
//  Created on 2023/8/18.
//

// MARK: 最愛View
import SwiftUI

struct FavoriteView: View
{
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes? = nil

    func loadUFavData()
    {
        guard let url = URL(string: "http://163.17.9.107/food/Favorite.php")
        else
        {
            print("生成的 URL 無效")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request)
        { data, response, error in
            if let data = data
            {
                do
                {
                    let decoder = JSONDecoder()
                    let dishes = try decoder.decode([Dishes].self, from: data)
                    DispatchQueue.main.async
                    {
                        self.dishesData = dishes
                    }
                }
                catch
                {
                    print("Error decoding JSON: \(error)")
                }
            }
        }.resume()
    }
    
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                Text("我的最愛")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                
                ScrollView(showsIndicators: false)
                {
                    LazyVStack
                    {
                        ForEach(dishesData, id: \.Dis_ID)
                        { dish in
                            NavigationLink(destination: Recipe_IP_View(Dis_ID: dish.Dis_ID))
                            {
                                RecipeBlock(
                                    imageName: dish.D_image ?? "",
                                    title: dish.Dis_Name,
                                    U_ID: "", // 假設 U_ID 不再需要傳遞
                                    Dis_ID: "\(dish.Dis_ID)"
                                )
                            }
                            .padding(.bottom, 10)
                        }
                    }
                }
            }
            .onAppear
            {
                loadUFavData()
            }
        }
    }
}

struct FavoriteView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView()
    }
}
