
//  CustomButton.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/12/10.
//

import SwiftUI

struct CustomButton: View
{
    var imageName: String  // 按钮图片名称
    var buttonText: String // 按钮文字内容
    var contentText: String
    var action: () -> Void // 点击按钮时的动作
    
    var body: some View
    {
        Button(action: action)
        {
            VStack(spacing: 0)
            {
                Spacer().frame(height: 10)
                VStack
                {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle()) // 将图像裁剪为圆形
                }
                
                VStack(spacing: 5)
                {
                    Text(buttonText)
                        .foregroundColor(Color("BottonColor"))
                        .font(.system(size: 18))
                    Text(contentText)
                        .font(.system(size: 10))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
            }
            .frame(width: 150, height: 200) // 设置整个按钮的尺寸
            .cornerRadius(15) // 设置整体背景的圆角
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color("BottonColor")
                        .opacity(0.3), lineWidth: 2) // 添加一致的轻微边框
            )
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}
