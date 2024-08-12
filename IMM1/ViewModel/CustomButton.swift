
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
            VStack 
            {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                Text(buttonText)
                    .foregroundColor(.black)
                    .font(.system(size: 18))
                Text(contentText)
                    .font(.system(size: 10))
                
            }
            .frame(width: 150, height: 150) // 设置为正方形
            .cornerRadius(10)
            .shadow(radius: 5)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}
