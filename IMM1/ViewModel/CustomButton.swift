
//  CustomButton.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/12/10.
//

import SwiftUI

struct CustomButton: View {
    var imageName: String  // 按钮图片名称
    var buttonText: String // 按钮文字内容
    var backgroundColor: Color // 按钮背景色
    var action: () -> Void // 点击按钮时的动作

    var body: some View {
        Button(action: action) {
            VStack {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                Text(buttonText)
                    .foregroundColor(.black)
                    .font(.custom("Arial", size: 20))
            }
            .frame(width: 150, height: 150) // 设置为正方形
            .background(backgroundColor) // 添加背景色
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}
