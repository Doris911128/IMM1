//
//  ImagePicker.swift
//  GP110IM
//
//  Created by 朝陽資管 on 2023/10/22.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable 
{
    @Binding var selectedImages: [UIImage]  //使用陣列來存儲多張照片
    
    func makeUIViewController(context: Context) -> UIImagePickerController 
    {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator 
    {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate 
    {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) 
        {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
        {
            if let image = info[.originalImage] as? UIImage
            {
                parent.selectedImages.append(image) //將選擇的照片添加到陣列中
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) 
        {
            picker.dismiss(animated: true)
        }
    }
}
