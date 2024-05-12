//
//  CustomButton.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/12/10.
//

import SwiftUI

struct CustomButton: View
{
    var imageName: String
    var buttonText: String
    var action: () -> Void
    
    var body: some View
    {
        Button(action: action)
        {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 350, height: 150)
                .cornerRadius(10)
                .overlay(
                    Text(buttonText)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .font(.custom("按鈕", size: 60))
                        .padding()
                )
                .opacity(0.8)
        }
    }
}
