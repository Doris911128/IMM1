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
    @State private var focusedUTipIndex: Int? = nil
    
    var data: [CRecipe]
    {
        [Crecipe]
    }// 全部的食譜數據
    
    // MARK: 彈出編輯視圖
    var UeditView: some View {
        VStack(spacing: 20) {
            Text("食譜編輯區")
                .font(.title2)
                .bold()
                .padding()

            ScrollView {
                VStack(spacing: 15) {

                    // MARK: 更新圖片按鈕
                    VStack {
                        Button(action: {
                            isImagePickerPresented = true // 顯示圖片選擇器
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.doc.fill")
                                    .font(.title)
                                    .foregroundColor(.orange)
                                Text("更新圖片")
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
                        .sheet(isPresented: $isImagePickerPresented) {
                            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
                        }

                        // 顯示圖片預覽和上傳按鈕
                        if let selectedImage = selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)

                            // 上傳圖片按鈕
                            Button(action: {
                                uploadImage(selectedImage) { result in
                                    switch result {
                                    case .success(let imageUrl):
                                        imageURL = imageUrl
                                    case .failure(let error):
                                        print("圖片上傳失敗: \(error.localizedDescription)")
                                    }
                                }
                            }) {
                                Text("上傳圖片")
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.orange)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    // MARK: 食譜名稱編輯區塊
                    VStack(alignment: .leading) {
                        Text("食譜名稱")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.orange)
                            .padding(.bottom, 5)
                        TextField("更新食譜名稱", text: $editedRecipeName)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 15)

                    

                    // MARK: 食材編輯區塊
                    VStack(alignment: .leading) {
                        Text("所需食材")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 5)

                        ForEach(editedUFoodSteps.indices, id: \.self) { index in
                            TextField("更新食材", text: $editedUFoodSteps[index])
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }

                        HStack {
                            Spacer()
                            Button(action: {
                                editedUFoodSteps.append("") // 新增食材
                            }) {
                                HStack {
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
                    VStack(alignment: .leading) {
                        Text("料理方法")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 5)

                        ForEach(editedUCookingSteps.indices, id: \.self) { index in
                            TextField("更新烹飪步驟", text: $editedUCookingSteps[index])
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }

                        HStack {
                            Spacer()
                            Button(action: {
                                editedUCookingSteps.append("") // 新增步驟
                            }) {
                                HStack {
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
                    VStack(alignment: .leading) {
                        Text("小技巧")
                            .foregroundStyle(.orange)
                            .font(.title2)
                            .bold()
                            .padding(.bottom, 5)

                        ForEach(editedUTips.indices, id: \.self) { index in
                            TextField("更新小技巧", text: $editedUTips[index])
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }

                        HStack {
                            Spacer()
                            Button(action: {
                                editedUTips.append("") // 新增小技巧
                            }) {
                                HStack {
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
            HStack {
                Button(action: {
                    isEditing = false // 關閉編輯
                }) {
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
                }) {
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
        .padding()
        .onAppear {
            // 初始化編輯內容
            editedRecipeName = Crecipe.f_name
            editedUFoodSteps = Crecipe.ingredients.split(separator: "\n").map { String($0) }
            editedUCookingSteps = Crecipe.method.split(separator: "\n").map { String($0) }
            editedUTips = Crecipe.UTips.split(separator: "\n").map { String($0) }
        }
    }

    
    // MARK: - 更新數據模型
       private func applyUEdits() {
           // 更新食譜的各個部分
           Crecipe.f_name = editedRecipeName
           Crecipe.ingredients = editedUFoodSteps.joined(separator: "\n")
           Crecipe.method = editedUCookingSteps.joined(separator: "\n")
           Crecipe.UTips = editedUTips.joined(separator: "\n")

           // 如果有圖片，則更新圖片 URL
           if let imageURL = imageURL {
               Crecipe.c_image_url = imageURL
           }
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
