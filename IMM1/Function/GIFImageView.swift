//
//  GIFImageView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/12.
//

import SwiftUI
import UIKit
import ImageIO

struct GIFImageView: UIViewRepresentable {
    let url: URL
    let frameDuration: TimeInterval = 3.0 // 每帧的持续时间

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        loadGIF(from: url) { image in
            DispatchQueue.main.async {
                imageView.image = image
            }
        }
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    private func loadGIF(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            completion(UIImage.animatedImage(withAnimatedGIFData: data, frameDuration: frameDuration))
        }.resume()
    }
}

extension UIImage {
    class func animatedImage(withAnimatedGIFData data: Data, frameDuration: TimeInterval) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var durations = [Double]()
        
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
                
                // Calculate the duration of each frame
                let frameProperties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as NSDictionary?
                let gifProperties = frameProperties?[kCGImagePropertyGIFDictionary as String] as? NSDictionary
                let delayTime = gifProperties?[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double ?? 0.1
                durations.append(delayTime)
            }
        }
        
        let totalDuration = durations.reduce(0, +)
        let adjustedDurations = durations.map { $0 * (frameDuration / totalDuration) }
        let adjustedTotalDuration = adjustedDurations.reduce(0, +)
        
        return UIImage.animatedImage(with: images, duration: adjustedTotalDuration)
    }
}
