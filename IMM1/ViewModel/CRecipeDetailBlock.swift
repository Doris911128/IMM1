//
//  CRecipeDetailBlock.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/9/10.
//

import SwiftUI

// CRecipeDetailBlock 符合 CRecipeP 協議
struct CRecipeDetailBlock: View, CRecipeP
{
    let U_ID: String // 假設需要用戶ID?
    @Binding var Crecipe: CRecipe // 綁定 Recipe 物件 允許修改 Crecipe
    
    @State private var isLoading: Bool = true // 載入狀態
    @State private var loadingError: String? = nil // 加載錯誤訊息
    
    @State private var isEditing: Bool = false // 控制編輯彈出框顯示
    
    @State private var editedRecipeName: String = ""
    @State private var editedUFoodSteps: [String] = [] // 編輯後的食材
    @State private var editedUCookingSteps: [String] = [] // 編輯後的步驟
    @State private var editedUTips: [String] = [] // 編輯後的小技巧＆小貼士
    
    // 圖片相關狀態
        @State private var isImagePickerPresented = false
        @State private var selectedImage: UIImage? = nil
        @State private var imageURL: String? = nil
    
    // 宣告 focusedXXXXIndex 為 Int? 以追蹤當前的索引
    @State private var focusedUFoodIndex: Int? = nil// 新增變量來追蹤哪一個TextField被聚焦_食材
    @State private var focusedUCookingIndex: Int? = nil// 步驟
    @State private var focusedUFieldIndex: Int? = nil// 小技巧
    
    var data: [CRecipe]
    {
        [Crecipe]
    }// 全部的食譜數據
    
    // MARK: 彈出編輯視圖
    var UeditView: some View
    {
        VStack(spacing: 20)
        {
            Text("食譜編輯區")
                .font(.title2)
                .bold()
                .padding()
            
            ScrollView
            {
                VStack(spacing: 15)
                {
                    // MARK: 食材編輯區塊
                    VStack(alignment: .leading)
                    {
                        Text("所需食材")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 5)
                        
                        ForEach(editedUFoodSteps.indices, id: \.self)
                        { index in
                            VStack
                            {
                                HStack(alignment: .top)
                                {
                                    Text("食材 \(index + 1)")
                                        .font(.system(size: 12))
                                        .bold()
                                        .foregroundColor(.gray)
                                    Spacer()
                                    
                                    //                                    // 右上：先前食材 (僅當 TextField 被選中時顯示)
                                    //                                    if focusedUFoodIndex == index
                                    //                                    {
                                    //                                        if index < foodSteps.count
                                    //                                        {
                                    //                                            Text("Before：\(foodSteps[index])")
                                    //                                                .font(.system(size: 12))
                                    //                                                .foregroundColor(.gray)
                                    //                                        } else
                                    //                                        {
                                    //                                            Text("無法提取先前食材")
                                    //                                                .font(.system(size: 12))
                                    //                                        }
                                    //                                    }
                                }
                                
                                // 顯示可編輯的 TextField，並綁定焦點
                                TextField("更新食材", text: $editedUFoodSteps[index])
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .onTapGesture
                                {
                                    focusedUFoodIndex = index
                                }
                                .onSubmit
                                {
                                    focusedUFoodIndex = nil
                                }
                            }
                            .padding(.horizontal, 15)
                        }
                        
                        // 新增食材按鈕
                        HStack
                        {
                            Spacer()
                            Button(action: {
                                editedUFoodSteps.append("")
                            })
                            {
                                HStack
                                {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                    
                                    Text("新增食材")
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(.orange)
                                }
                                .padding()
                                .background(
                                    Color.white
                                        .frame(width: 320, height: 50)
                                        .cornerRadius(10)
                                        .shadow(radius: 4)
                                )
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 15)
                    
                    
                    // MARK: 料理方法編輯區塊
                    VStack(alignment: .leading)
                    {
                        Text("料理方法")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 5)
                        
                        ForEach(editedUCookingSteps.indices, id: \.self)
                        { index in
                            VStack
                            {
                                HStack(alignment: .top)
                                {
                                    Text("步驟 \(index + 1)")
                                        .font(.system(size: 12))
                                        .bold()
                                        .foregroundColor(.gray)
                                    Spacer()
                                    
                                    //                                    if focusedUCookingIndex == index
                                    //                                    {
                                    //                                        if index < cookingUSteps.count
                                    //                                        {
                                    //                                            Text("Before：\(cookingUSteps[index])")
                                    //                                                .font(.system(size: 12))
                                    //                                                .foregroundColor(.gray)
                                    //                                        } else {
                                    //                                            Text("無法提取先前步驟")
                                    //                                                .font(.system(size: 12))
                                    //                                        }
                                    //                                    }
                                }
                                TextField("更新烹飪步驟", text: $editedUCookingSteps[index])
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .onTapGesture
                                {
                                    focusedUCookingIndex = index
                                }
                                .onSubmit
                                {
                                    focusedUCookingIndex = nil
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 新增步驟按鈕
                        HStack
                        {
                            Spacer()
                            Button(action: {
                                editedUCookingSteps.append("")
                            })
                            {
                                HStack
                                {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                    
                                    Text("新增步驟")
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(.orange)
                                }
                                .padding()
                                .background(
                                    Color.white
                                        .frame(width: 320, height: 50)
                                        .cornerRadius(10)
                                        .shadow(radius: 4)
                                )
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 15)
                    
                    
                    // MARK: 小技巧編輯區塊
                    VStack(alignment: .leading)
                    {
                        Text("小技巧")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                        //.padding(.leading, 20)
                            .padding(.bottom, 5)
                        
                        ForEach(editedUTips.indices, id: \.self)
                        { index in
                            VStack
                            {
                                HStack(alignment: .top)
                                {
                                    Text("技巧 \(index + 1)")
                                        .font(.system(size: 12))
                                        .bold()
                                        .foregroundColor(.gray)
                                    Spacer()
                                    
                                    //                                    if focusedUFieldIndex == index
                                    //                                    {
                                    //                                        Text("Before：\(tips[index])")
                                    //                                            .font(.system(size: 12))
                                    //                                            .foregroundColor(.gray)
                                    //                                    }
                                }
                                TextField("更新小技巧", text: $editedUTips[index])
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .onTapGesture
                                {
                                    focusedUFieldIndex = index
                                }
                                .onSubmit
                                {
                                    focusedUFieldIndex = nil
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 新增小技巧按鈕
                        HStack
                        {
                            Spacer()
                            Button(action: {
                                editedUTips.append("")
                            })
                            {
                                HStack
                                {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                    
                                    Text("新增小技巧")
                                        .font(.body)
                                        .bold()
                                        .foregroundColor(.orange)
                                }
                                .padding()
                                .background(
                                    Color.white
                                        .frame(width: 320, height: 50)
                                        .cornerRadius(10)
                                        .shadow(radius: 4)
                                )
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 15)
                }
                
            }
            
            
            // MARK: 確認和取消按鈕
            HStack
            {
                Button(action: {
                    isEditing = false // 關閉編輯
                })
                {
                    Text("取消")
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    applyUEdits()
                    isEditing = false // 確認後關閉編輯
                })
                {
                    Text("確認")
                        .font(.title3)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding()//左右
        
        .onAppear
        {
        }
    }
    
    // MARK: - 更新數據模型
    private func applyUEdits()
    {
        // 將編輯後的內容應用到數據模型中
        print("Edited food steps: \(editedUFoodSteps)")
        print("Edited cooking steps: \(editedUCookingSteps)")
        print("Edited tips: \(editedUTips)")
    }
    
    // MARK: - 須實現的 CRecipeP 協議方法
    func itemName() -> String
    {
        return Crecipe.f_name
    }
    
    func itemImageURL() -> URL?
    {
        return nil // 用戶自建食譜沒有圖片
    }
    
    // MARK: 標題畫面
    func HeaderView(size: CGSize, recordInput: String? = nil) -> AnyView
    {
        // 返回簡易名稱
        return AnyView(
            Text(itemName())
                .font(.largeTitle)
                .bold()
                .padding()
        )
    }
    
    // MARK: CCookbookView 烹飪書
    func CCookbookView(safeArea: EdgeInsets) -> AnyView {
        AnyView(
            VStack(spacing: 18) {
                // 食材顯示區塊
                if !Crecipe.ingredients.isEmpty {
                    VStack(alignment: .leading) {
                        Text("所需食材")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(Crecipe.ingredients.split(separator: "\n").map { String($0) }, id: \.self) { ingredient in
                            HStack(spacing: 25) {
                                Text("•")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                Text(ingredient)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 32)
                            .padding(.vertical, -2)
                        }
                    }
                }
                
                // 料理方法顯示區塊
                if !Crecipe.method.isEmpty {
                    VStack(alignment: .leading) {
                        Text("料理方法")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(Array(Crecipe.method.split(separator: "\n").enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top) {
                                let stepNumber = "\(index + 1)."
                                let stepDescription = step.trimmingCharacters(in: .whitespaces)
                                
                                Text(stepNumber)
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.orange)
                                    .frame(width: 30, alignment: .leading)
                                
                                Text(stepDescription)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 35)
                            .padding(.vertical, 3)
                        }
                    }
                }
                
                // 小技巧顯示區塊（僅當小技巧不為空時顯示）
                if !Crecipe.UTips.isEmpty
                {
                    VStack(alignment: .leading)
                    {
                        Text("小技巧")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.leading, 20)
                        
                        ForEach(Array(Crecipe.UTips.split(separator: "\n").enumerated()), id: \.offset) { index, tip in
                            HStack(alignment: .top) {
                                let tipNumber = "\(index + 1)."
                                let tipDescription = tip.trimmingCharacters(in: .whitespaces)
                                
                                Text(tipNumber)
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.orange)
                                    .frame(width: 30, alignment: .leading)
                                
                                Text(tipDescription)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 35)
                            .padding(.vertical, 3)
                        }
                    }
                }
            }
        )
    }
    
    // MARK: CRecipeDetailBlock body
    var body: some View
    {
        GeometryReader
        { geometry in
            let safeArea = geometry.safeAreaInsets
            let size = geometry.size

            ZStack(alignment: .topTrailing)
            {
                ScrollView(.vertical, showsIndicators: false)
                {
                    VStack
                    {
                        // 顯示封面
                        CoverView(safeArea: safeArea, size: size)

                        // 烹飪書視圖
                        CCookbookView(safeArea: safeArea)
                            .padding(.top)
                    }
                }
                .coordinateSpace(name: "SCROLL")
                
                

                // 顯示編輯視圖，當 isEditing 為 true 時
                if isEditing
                {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    UeditView // 顯示編輯視圖
                }
            }
            .toolbarBackground(Color("menusheetbackgroundcolor"), for: .navigationBar)  // 設置導航欄背景
            .toolbar
            {
                ToolbarItem(placement: .navigationBarTrailing)
                {
                    VStack
                    {
                        // 固定的編輯按鈕
                        Button(action: {
                            isEditing = true
                            // 初始化編輯資料
                            editedUFoodSteps = Crecipe.ingredients.split(separator: "\n").map { String($0) }
                            editedUCookingSteps = Crecipe.method.split(separator: "\n").map { String($0) }
                            editedUTips = Crecipe.UTips.split(separator: "\n").map { String($0) }
                        })
                        {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 25))
                                .foregroundColor(.orange)
                        }
                    }

                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
