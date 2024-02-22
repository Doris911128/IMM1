//
//  Recipe.swift
//  Graduation_Project
//
//  Created by Ｍac on 2023/9/11.
//

import SwiftUI

func overlayRectangleWithText() -> some View 
{
    return
    ZStack
    {
        // MARK: 矩形背景
        Rectangle()
            .frame(width: 400, height: 150)
            .foregroundColor(Color("menusheetbackgroundcolor"))

        HStack(alignment:.center)
        {
            VStack(alignment: .center)
            {
                // MARK: 食譜照片
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray)
                    .frame(width: 180, height: 100)
                // MARK: 食譜名稱
                Text("番茄炒蛋")
                    .foregroundColor(Color("textcolor"))
                    .font(.body)
            }
            // MARK: 所需食材及料理方式
            Text("XXXXXXXXXXXXXXXXXXXXXXXXXX")
                .foregroundColor(Color("textcolor"))
                .font(.body)
        }
        .foregroundColor(Color.black)
        .padding(.horizontal) //在水平方向上添加安全區塊
    }
}
