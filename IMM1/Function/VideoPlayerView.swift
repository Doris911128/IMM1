//
//  VideoPlayerView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/12.
//

import Foundation
import SwiftUI
import AVKit

import WebKit

// UIViewRepresentable 将 UIKit 的 WKWebView 包装到 SwiftUI 中
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false // 禁止滚动
        webView.backgroundColor = .clear // 背景透明
        webView.isOpaque = false // 不显示默认背景色
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

struct VideoPlayerView: View {
    let videoURL: URL

    var body: some View {
        WebView(url: videoURL)
            .frame(width: 350, height: 200)  // 设置 WebView 的大小
            .cornerRadius(15)  // 设置圆角
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color("BottonColor"), lineWidth: 2)  // 添加边框
            )
    }
}

