
//  CustomButton.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/12/10.
//
import SwiftUI

struct CustomButton: View {
    var imageName: String  // 按鈕圖片名稱
    var buttonText: String // 按鈕文字內容
    var action: () -> Void // 點擊按鈕時的動作

    var body: some View {
        Button(action: action) {
            HStack {
                Text(buttonText)
                    .foregroundColor(.black)
                    .font(.custom("Arial", size: 40))
                    .padding(.leading, 20)
                Spacer()

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .alignmentGuide(HorizontalAlignment.trailing) { _ in 150 } // 將圖片向右靠齊
            }
            .padding(10)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}
