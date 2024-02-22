//
//  Favorite.swift
//
//  Created on 2023/8/18.
//

// MARK: 最愛View
import SwiftUI

struct FavoriteView: View 
{
    var body: some View 
    {
        ScrollView 
        {
            VStack(spacing: 20) 
            {
                ForEach(0..<10) 
                { _ in
                    VStack(alignment: .leading)
                    {
                        HStack {
                            Circle() //頭像
                                .fill(Color(.systemGray3))
                                .frame(width: 50)
                            Text("收藏料理") //收藏料理
                                .font(.title3)
                                .foregroundColor(.black)
                        }
                        Text("料理作法") //料理作法
                            .font(.title2)
                            .foregroundColor(.black)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray3))
                            .cornerRadius(30)
                    }
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
}

struct FavoriteView_Previews: PreviewProvider 
{
    static var previews: some View 
    {
        ContentView()
    }
}
