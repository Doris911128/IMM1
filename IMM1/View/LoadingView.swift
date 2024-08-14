//
//  LoadingView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/12.
//
import SwiftUI

struct LoadingView: View {
    private var gifURL: URL {
        URL(string: "http://163.17.9.107/food/gif/redpanda_walk.gif")!
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                GIFImageView(url: gifURL)

                    .position(x: geometry.size.width / 2, y: 140) // 設置位置
            }
        }
    }
}

#Preview {
    LoadingView()
}
