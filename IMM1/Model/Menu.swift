//
//  Menu.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/4/12.
//

import Foundation
// MARK: 菜譜結構
struct Dishes: Codable
{
    let Dis_ID: Int //ID
    let Dis_Name: String //名稱
    let D_Cook: String //煮法
    let D_image: String //照片
    let D_Video: String //影片

    // 添加初始化方法，接受传递的 Dis_ID
    init(Dis_ID: Int = 0,
         Dis_Name: String = "",
         D_Cook: String  = "",
         D_image: String  = "",
         D_Video: String  = ""
    )
    {
        self.Dis_ID = Dis_ID
        self.Dis_Name = Dis_Name
        self.D_Cook = D_Cook
        self.D_image = D_image
        self.D_Video = D_Video
    }
}



//let dishesData: [Dishes] = [
//    Dishes(Dis_ID: 1, Dis_Name: "t蕃茄炒蛋", D_Cook: "http://163.17.9.107/food/dishes/1.txt", D_image: "http://163.17.9.107/food/images/1.jpg", D_Video: "xxxxxxxxx"), Dishes(Dis_ID: 2, Dis_Name: "t荷包蛋", D_Cook: "http://163.17.9.107/food/dishes/2.txt", D_image: "http://163.17.9.107/food/images/2.jpg", D_Video: "xxxxxxxxx")
//]

// MARK: 食材結構
struct Food: Codable
{
    let F_ID: Int //ID
    let F_Name: String //名稱
    let F_Unit: String //食材單位
    
    // 添加初始化方法，接受传递的 F_ID
    init(F_ID: Int = 0,
         F_Name: String = "",
         F_Unit: String  = ""
    )
    {
        self.F_ID = F_ID
        self.F_Name = F_Name
        self.F_Unit = F_Unit
    }
}

//let  foodData: [Food] = [
//    Food(F_ID: 1, F_Name: "t雞蛋", F_Unit: "顆"),
//    Food(F_ID: 2, F_Name: "t番茄", F_Unit: "顆"),
//    Food(F_ID: 7, F_Name: "t蔥", F_Unit: "把")
//]

// MARK: 菜譜食材數量結構
struct Amount: Codable
{
    let A_ID: Int //主鍵
    let Dis_ID: Int //外來鍵
    let F_ID: Int //外來鍵
    let A_Amount: Float//外來鍵
    
    // 添加初始化方法，接受传递的 A_ID
    init(A_ID: Int = 0,
         Dis_ID: Int = 0,
         F_ID: Int = 0,
         A_Amount: Float  = 0.0
    )
    {
        self.A_ID = A_ID
        self.Dis_ID = Dis_ID
        self.F_ID = F_ID
        self.A_Amount = A_Amount
    }
}

//let  amountData: [Amount] = [
//    Amount(A_ID:1,Dis_ID: 1,F_ID: 1,A_Amount:3),
//    Amount(A_ID:2,Dis_ID: 1,F_ID: 2,A_Amount:2),
//    Amount(A_ID:3,Dis_ID: 1,F_ID: 7,A_Amount:0.3)
//]
