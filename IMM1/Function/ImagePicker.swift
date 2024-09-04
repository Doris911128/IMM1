// ImagePicker.swift

import SwiftUI
import UIKit

// 定義一個 ImagePicker 結構，符合 UIViewControllerRepresentable 協議
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage? // 綁定選擇的圖片
    @Environment(\.presentationMode) var presentationMode // 獲取當前視圖的呈現模式
    var sourceType: UIImagePickerController.SourceType // 新增來源類型參數
    
    // 定義一個 Coordinator 類，負責處理 UIImagePickerController 的委託方法
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker // 引用父級 ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent // 初始化時設置父級
        }
        
        // 當用戶選擇圖片後的回調
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // 嘗試從 info 中獲取原始圖片
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage // 更新綁定的圖片
            }
            parent.presentationMode.wrappedValue.dismiss() // 關閉圖片選擇器
        }
        
        // 當用戶取消選擇圖片的回調
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss() // 關閉圖片選擇器
        }
    }
    
    // 創建 Coordinator 實例
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // 創建 UIImagePickerController 實例
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator // 設置委託為 coordinator
        picker.sourceType = sourceType // 使用傳入的來源類型
        picker.allowsEditing = false // 禁止編輯
        return picker // 返回圖片選擇器
    }
    
    // 更新 UIViewController（這裡不需要更新）
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
