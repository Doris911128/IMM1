//  CA_Recipes_S.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/10/18.
//
//用於統一管理自訂和 AI 食譜

import Foundation

struct CA_Recipes: Codable
{
    var customRecipes: [CRecipe] // 自訂食譜
    var aiRecipes: [ChatRecord]  // AI 生成的食譜
}

struct CRecipe: Identifiable, Codable
{
    let id = UUID()
    let CR_ID : Int
    var f_name: String //菜名
    var ingredients: String //食材
    var method: String //煮法
    var UTips: String //小技巧
    var c_image_url: String? // 新增圖片 URL 欄位
}


//MARK: 此畫面主結構＿歷史聊天紀錄
struct ChatRecord: Identifiable, Codable
{
    var id: Int { Recipe_ID }
    let Recipe_ID: Int
    let U_ID: String
    var input: String
    let output: String
    var isAICol: Bool
    var ai_image_url: String? // 新增圖片 URL 欄位

    // 自定义解码方法，将 Int 转换为 Bool
    enum CodingKeys: String, CodingKey 
    {
        case Recipe_ID, U_ID, input, output, isAICol = "isAICol", ai_image_url
    }
    
    // init方法只在解碼過程中使用
    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        Recipe_ID = try container.decode(Int.self, forKey: .Recipe_ID)
        U_ID = try container.decode(String.self, forKey: .U_ID)
        input = try container.decode(String.self, forKey: .input)
        output = try container.decode(String.self, forKey: .output)
        let isAIColInt = try container.decode(Int.self, forKey: .isAICol)
        isAICol = isAIColInt == 1
        ai_image_url = try container.decodeIfPresent(String.self, forKey: .ai_image_url)
    }

    
}

