//
//  RecipeBlock.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/5/12.
//
import SwiftUI
import Foundation

//MARK: 單一食譜顯示區塊
struct RecipeBlock: View
{
    let imageName: String
    let title: String
    let U_ID: String // 用於添加我的最愛
    let Dis_ID: String // 用於添加我的最愛
    
    @State private var isFavorited: Bool = false
    
    var body: some View
    {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(red: 0.961, green: 0.804, blue: 0.576))
            .frame(width: 330, height: 250)
            .overlay
        {
            VStack
            {
                AsyncImage(url: URL(string: imageName))
                { phase in
                    if let image = phase.image
                    {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 330, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    else
                    {
                        Color.gray
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .offset(y: -6)
                
                HStack(alignment: .bottom)
                {
                    Text(title)
                        .foregroundColor(.black)
                        .font(.system(size: 24))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                    
                    Image(systemName: self.isFavorited ? "heart.fill" : "heart")
                        .font(.title)
                        .foregroundStyle(.orange)
                        .colorMultiply(.red.opacity(0.6))
                        .onTapGesture
                    {
                        withAnimation(.easeInOut.speed(3))
                        {
                            self.isFavorited.toggle()
                            toggleFavorite(U_ID: U_ID, Dis_ID: Dis_ID, isFavorited: isFavorited)
                            { result in
                                switch result
                                {
                                case .success(let responseString):
                                    print("Success: \(responseString)")
                                case .failure(let error):
                                    print("Error: \(error.localizedDescription)")
                                    
                                }
                            }
                        }
                    }
                    .padding(.trailing, 10)
                    .symbolEffect(.bounce, value: self.isFavorited)
                }
                .offset(y: -5)
            }
        }
        .padding(.horizontal, 20)
        .onAppear
        {
            // 檢查是否已經被收藏
            checkIfFavorited(U_ID: U_ID, Dis_ID: Dis_ID)
            { result in
                switch result
                {
                case .success(let favorited):
                    self.isFavorited = favorited
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
