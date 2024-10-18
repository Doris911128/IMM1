//  CA_Recipes_S.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/10/18.
//
//用於統一管理自訂和 AI 食譜

import Foundation

struct CA_Recipes_S: Codable 
{
    var customRecipes: [CustomRecipe] // 自訂食譜
    var aiRecipes: [AIRecipe]         // AI 生成的食譜
}


// 自訂食譜的結構
struct CustomRecipe: Codable, Identifiable 
{
    var id: Int { CR_ID }
    let CR_ID: Int
    let f_name: String
    let ingredients: String
    let method: String
    let UTips: String
    let c_image_url: String?
}

// AI 生成食譜的結構
struct AIRecipe: Codable, Identifiable 
{
    var id: Int { Recipe_ID }
    let Recipe_ID: Int
    let f_name: String
    let ingredients: String
    let method: String
    let UTips: String
    let ai_image_url: String?
}
