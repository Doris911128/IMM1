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
                    .offset(x: -20, y: -20)

//                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .background(Color("BackColor")) // Set background color
            .edgesIgnoringSafeArea(.all) // Extend background color to safe area
            .padding(.vertical, 50) // Set vertical padding to 50
        }
    }
}

#Preview {
    LoadingView()
}
