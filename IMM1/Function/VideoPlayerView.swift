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
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

struct VideoPlayerView: View
{
    let videoURL: URL
    @State private var player: AVPlayer = AVPlayer()
    @State private var isPlaying: Bool = false
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        ZStack(alignment: .center) {
            // 视频播放器本身
            VideoPlayer(player: player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .cornerRadius(15)
            
            // 播放按钮
            Button(action: {
                togglePlayPause()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
                    .opacity(0.8)
            }
        }
        .onAppear {
            player = AVPlayer(url: videoURL)
        }
        .frame(width: 350, height: 200) // 确保整个 VideoPlayerView 的范围
        .cornerRadius(15) // 设置整体背景的圆角
    }

    // 切换播放和暂停
    private func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    // 加载视频的缩略图
    private func loadThumbnail() {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1.0, preferredTimescale: 600) // 获取视频1秒处的图像
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            self.thumbnailImage = UIImage(cgImage: imageRef)
        } catch {
            print("Error generating thumbnail: \(error)")
        }
    }
}

