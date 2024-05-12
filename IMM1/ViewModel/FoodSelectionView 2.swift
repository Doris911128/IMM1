//
//  FoodSelectionView.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/12/10.
//

import SwiftUI

extension Dishes {
    func toFoodOption() -> FoodOption {
        return FoodOption(name: self.Dis_Name, backgroundImage: URL(string: self.D_image)!)
    }
}

struct FoodSelectionView: View {
    
    @Binding var isShowingDetail: Bool
    @Binding var editedPlan: String
    var foodOptions: [FoodOption] = []
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("選擇一個食物：")
                .font(.title)
                .padding()

            ScrollView {
                ForEach(foodOptions, id: \.name) { foodOption in
                    Button(action: {
                        self.editedPlan = foodOption.name
                        self.isShowingDetail.toggle()
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: UIScreen.main.bounds.width - 40, height: 150)
                                .cornerRadius(10)
                                .opacity(0.8)
                                .offset(y: 40)
                                .font(.title)

                            AsyncImage(url: foodOption.backgroundImage) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: UIScreen.main.bounds.width - 40, height: 150)
                                        .cornerRadius(10)
                                case .failure:
                                    Text("Failed to load image")
                                }
                            }

                            VStack {
                                Spacer()
                                Label(foodOption.name, systemImage: "")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding()
                                    .offset(y: 45)
                            }
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.bottom, 60)
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(20)
    }
  
}
