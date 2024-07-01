//
//  FoodSelectionView.swift
//  IM110CYUT
//
//  Created by ï¼­ac on 2023/12/10.
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
    @Binding var foodOptions: [FoodOption]
    @Environment(\.presentationMode) var presentationMode
   
    struct RecipeBlock: View {
            var imageName: String
            var title: String
            var U_ID: String
            var Dis_ID: String
            
            var body: some View {
                VStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100) // 設置圖片大小
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
                .frame(width: 120) // 設置整個 RecipeBlock 的寬度
            }
        }
    var body: some View {
        VStack {
            ScrollView {
                ForEach(foodOptions, id: \.name) { foodOption in
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
                                            Text(foodOption.name)
                                                .font(.title)
                                                .foregroundColor(.white)
                                                .padding(.horizontal)
                                                .padding(.vertical, 10)
                                                .bold()
                                                .cornerRadius(8)
                                                .shadow(radius: 4)
                                                .offset(x: 0, y: -80) // 调整文字位置
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
                    .padding(.bottom, -50) // 调整按钮间距
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
