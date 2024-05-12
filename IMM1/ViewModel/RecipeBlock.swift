//
//  RecipeBlock.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/5/12.
//
import SwiftUI
import Foundation

//MARK:  單一食譜顯示區塊
struct RecipeBlock: View
{
    let imageName: String
    let title: String

    var body: some View
    {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(red: 0.961, green: 0.804, blue: 0.576))
            .frame(width: 330, height: 250)
            .overlay
        {
                VStack
                {
                    // 確保網路圖片可以顯示
                    // 使用 AsyncImage 來加載並調整網絡圖片
                    AsyncImage(url: URL(string: imageName))
                    { phase in
                        if let image = phase.image
                        {
                            image.resizable()  // 可調整大小的圖片
                                .aspectRatio(contentMode: .fill)  // 填滿容器，保持圖片比例
                                .frame(width: 330, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else
                        {
                            Color.gray  // 預載顯示灰色
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .offset(y: -6)

                    Text(title)
                        .foregroundColor(.black)
                        .font(.system(size: 24))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .offset(y: -5)
                }
            }
            .padding(.horizontal, 20)
    }
}
