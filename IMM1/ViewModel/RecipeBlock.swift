//
//  RecipeBlock.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/5/12.
//
import SwiftUI
import Foundation

struct RecipeBlock: View {
    let D_image: String
    let Dis_Name: String
    let U_ID: String
    let Dis_ID: Int
    @State private var isFavorited: Bool

    init(imageName: String, title: String, U_ID: String, Dis_ID: Int = 0, isFavorited: Bool = false) {
        self.D_image = imageName
        self.Dis_Name = title
        self.U_ID = U_ID
        self.Dis_ID = Dis_ID
        self._isFavorited = State(initialValue: isFavorited)
    }

    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: D_image)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width - 40, height: 250)
                            .cornerRadius(10)
                    } else {
                        Color.gray
                    }
                }
                .padding(.top, 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button(action: {
                    withAnimation(.easeInOut.speed(3)) {
                        self.isFavorited.toggle()
                        toggleFavorite(U_ID: U_ID, Dis_ID: Dis_ID, isFavorited: isFavorited) { result in
                            switch result {
                            case .success(let responseString):
                                print("Success: \(responseString)")
                            case .failure(let error):
                                print("Error: \(error.localizedDescription)")
                            }
                        }
                    }
                }) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: self.isFavorited ? "heart.fill" : "heart")
                                .font(.title)
                                .foregroundColor(.red)
                        )
                }
                .offset(y: 230)
                .padding(.trailing, 10)
                .symbolEffect(.bounce, value: self.isFavorited)
            }
            
            HStack(alignment: .bottom) {
                Text(Dis_Name)
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .bold()
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .offset(x: 0, y: -80)
                Spacer()
            }
            .offset(y: -5)
        }
        .padding(.horizontal, 20)
        .offset(y: -40)
        .onAppear {
            checkIfFavorited(U_ID: U_ID, Dis_ID: "\(Dis_ID)") { result in
                switch result {
                case .success(let favorited):
                    self.isFavorited = favorited
                case .failure(let error):
                    print("Error checking favorite status: \(error.localizedDescription)")
                }
            }
        }
    }
}
