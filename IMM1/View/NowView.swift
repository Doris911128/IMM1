// NowView.swift

import SwiftUI
import UIKit
import Foundation

// MARK: [struct] DishService
struct DishService
{
    static func loadDishes(completion: @escaping ([Dishes]) -> Void)
    {
        guard let url = URL(string: "http://163.17.9.107/food/php/Dishes.php")
        else { return }
        
        URLSession.shared.dataTask(with: url)
        { data, response, error in
            guard let data = data, error == nil
            else
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

// MARK: NowView
struct NowView: View
{
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes? = nil
    @EnvironmentObject private var user: User
    
    // MARK: NowView body
    var body: some View
    {
        NavigationStack
        {
            ZStack
            {
                VStack
                {
                    Text("立即煮")
                        .font(.largeTitle)
                        .bold()
                        .offset(x: 10, y: 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // MARK: 料理顯示區
                    ScrollView(showsIndicators: false)
                    {
                        VStack {
                            if let selectedDish = selectedDish
                            {
                                NavigationLink(destination: MRecipeView(U_ID: " ", Dis_ID: selectedDish.Dis_ID))
                                {
                                    RecipeBlock(
                                        imageName: selectedDish.D_image,
                                        title: selectedDish.Dis_Name,
                                        U_ID: " ",
                                        Dis_ID: selectedDish.Dis_ID
                                    )
                                }
                            }
                        }
                        .padding(.trailing, 12)
                        .background(
                            CustomCorners(cornerRadius: 30, corners: [.topLeft, .bottomRight]) // 應用 CustomCorners
                                .fill(Color.white)
                                .shadow(radius: 5)
                        )
                    }
                }
            }
        }
        .onAppear
        {
            user.fetchUserInfo
            { fetchedUser in
                if let fetchedUser = fetchedUser
                {
                    self.user.update(with: fetchedUser)
                    
                    DishService.loadDishes
                    { dishes in
                        self.dishesData = dishes
                        self.selectedDish = dishes.first
                    }
                }
            }
        }
    }
}

// struct NowView_Previews: PreviewProvider {
//     static var previews: some View {
//         NowView().environmentObject(User())
//     }
// }

