//
//  TagButton.swift
//  Graduation_Project
//
//  Created by Mac on 2023/8/21.
//

import SwiftUI

extension View
{
    // MARK: 紀錄用戶身體健康指標標籤
    func _Tag1Button(image: String, title: String, fore: Color, back: Color) -> some View
    {
        HStack
        {
            Image(image)

            Text("(title)")
                .bold()
                .font(.body)
                .foregroundColor(fore)
                .padding()
                .frame(width: 90, height: 25)
                .background(back)
                .cornerRadius(100)
                .shadow(color: Color(.systemGray3), radius: 5, y: 5)
        }
    }

    // MARK: 用戶成就標籤
    func _Tag2Button(image: String, title: String, fore: Color, back: Color) -> some View
    {
        HStack(spacing: 10)
        {
           
            Image(systemName: image) //系統圖標
                .font(.title3) //字體大小
                .foregroundColor(fore)

            Text("(title)成就")
                .bold()
                .font(.body)
                .foregroundColor(fore)
                .padding()
                .frame(width: 160, height: 25)
                .background(back)
                .cornerRadius(100)
                .shadow(color: Color(.systemGray3), radius: 5, y: 5)
        }
        .frame(maxWidth: .infinity)
    }
}
