//
//  Forum.swift
//  
//
//
//

import Foundation

// MARK: 論壇結構
struct Forum: Hashable 
{
    let id: String //ID
    let title: String //標題
    let text: String //內容
    let secure: Bool //隱私
    let author: String //作者
}
