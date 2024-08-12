//
//  LoadingView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/12.
//

import SwiftUI

struct LoadingView: View 
{
    private var gifURL: URL 
    {
        URL(string: "http://163.17.9.107/food/gif/redpanda_walk.gif")!
    }
    var body: some View
    {
        
        VStack {
            Text("小熊貓走路")
                .font(.largeTitle)
                .padding()
            
            GIFImageView(url: gifURL)
                .frame(width: 300, height: 300)  // 设置尺寸
        }
    }
}

#Preview {
    LoadingView()
}
