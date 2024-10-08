//
//  FoodSelectionView.swift
//  IM110CYUT
//
//  Created by ï¼­ac on 2023/12/10.
//

import SwiftUI

extension Dishes {
    func toFoodOption() -> FoodOption {
        let imageUrlString = self.D_image ?? "defaultImageURL"
        let imageUrl = URL(string: imageUrlString) ?? URL(string: "defaultImageURL")!
        let serving = self.Dis_serving ?? "N/A"
        return FoodOption(name: self.Dis_Name, backgroundImage: imageUrl, serving: serving)
    }
}



struct FoodSelectionView: View
{
    @Binding var isShowingDetail: Bool
    @Binding var editedPlan: String
    @Binding var foodOptions: [FoodOption]
    var categoryTitle: String
    @Environment(\.presentationMode) var presentationMode
    
    struct RecipeBlock: View
    {
        var imageName: String
        var title: String
        var U_ID: String
        var Dis_ID: Int
        
        var body: some View
        {
            VStack
            {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .padding(5)
            .frame(width: 120)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(categoryTitle)
                    .font(.system(size: 40))
                    .bold()
                    .padding(.leading)
                Spacer()
            }
            .padding(.top)
            
            ScrollView {
                ForEach(foodOptions, id: \.id) { foodOption in
                    Button(action: {
                        self.editedPlan = foodOption.name
                        self.isShowingDetail.toggle()
                    }) {
                        ZStack {
                            AsyncImage(url: foodOption.backgroundImage) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: UIScreen.main.bounds.width - 40, height: 250)
                                        .cornerRadius(10)
                                    VStack(alignment: .leading) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(foodOption.name)
                                                    .font(.title)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal)
                                                    .padding(.vertical, 10)
                                                    .bold()
                                                    .cornerRadius(8)
                                                    .shadow(radius: 4)
                                                    .offset(x: 0, y: -100)
                                                Text(foodOption.serving)
                                                    .font(.title2)
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal)
                                                    .padding(.vertical, 5)
                                                    .shadow(radius: 2)
                                                    .offset(x: 0, y: -120)
                                            }
                                            Spacer()
                                        }
                                    }
                                case .failure:
                                    Text("Failed to load image")
                                }
                            }
                            VStack {
                                Spacer()
                                    .padding()
                            }
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.bottom, -70)
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(20)
        .onAppear {
            print("Food options: \(foodOptions)")
        }
    }
}
