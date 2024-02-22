//
//  EditPlanView.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/12/10.
//

import SwiftUI



struct EditPlanView: View
{
    
    var day: String
    var planIndex: Int
   
    @State private var show1: [Bool] = [false, false, false, false, false, false, false]
    @State private var searchText: String = ""
    @State private var editedPlan = ""
    @State private var isShowingDetail = false
    
    @Binding var plans: [String: [String]]
    
    @Environment(\.presentationMode) var presentationMode

    // MARK: 懶人選項
    let foodOptions1: [FoodOption] = [
        FoodOption(name: "泡麵", backgroundImage: "泡麵"),
        FoodOption(name: "蔥油餅", backgroundImage: "蔥油餅"),
        FoodOption(name: "炒菜豆", backgroundImage: "炒菜豆"),
        FoodOption(name: "番茄炒蛋", backgroundImage: "番茄炒蛋")
        // 添加更多食物選項及其相應的背景圖片
    ]
    // MARK: 減肥選項
    let foodOptions2: [FoodOption] = [
        FoodOption(name: "青江菜", backgroundImage: "青江菜"),
        FoodOption(name: "炒蛋", backgroundImage: "炒蛋"),
        FoodOption(name: "雞胸肉", backgroundImage: "雞胸肉"),
        FoodOption(name: "花椰菜", backgroundImage: "花椰菜")
        // 添加更多食物選項及其相應的背景圖片
    ]
    // MARK: 省錢選項
    let foodOptions3: [FoodOption] = [
        FoodOption(name: "白菜滷", backgroundImage: "白菜滷"),
        FoodOption(name: "炒菠菜", backgroundImage: "炒菠菜"),
        FoodOption(name: "白蘿蔔排骨湯", backgroundImage: "白蘿蔔排骨湯"),
        FoodOption(name: "炒高麗菜", backgroundImage: "炒高麗菜")
        // 添加更多食物選項及其相應的背景圖片
    ]
    // MARK: 放縱選項
    let foodOptions4: [FoodOption] = [
        FoodOption(name: "炸鮮蚵", backgroundImage: "炸鮮蚵"),
        FoodOption(name: "脆皮烤鴨", backgroundImage: "脆皮烤鴨"),
        FoodOption(name: "鹽酥雞", backgroundImage: "鹽酥雞"),
        FoodOption(name: "炸薯條", backgroundImage: "炸薯條")
        // 添加更多食物選項及其相應的背景圖片
    ]
    // MARK: 養生選項
    let foodOptions5: [FoodOption] = [
        FoodOption(name: "四神湯", backgroundImage: "四神湯"),
        FoodOption(name: "蔬果汁", backgroundImage: "蔬果汁"),
        FoodOption(name: "白木耳湯", backgroundImage: "白木耳湯"),
        FoodOption(name: "香菇瘦肉養生粥", backgroundImage: "香菇瘦肉養生粥")
        // 添加更多食物選項及其相應的背景圖片
    ]
    // MARK: 今日推薦選項
    let foodOptions6: [FoodOption] = [
        FoodOption(name: "牛肉湯", backgroundImage: "牛肉湯"),
        FoodOption(name: "山藥排骨湯", backgroundImage: "山藥排骨湯"),
        FoodOption(name: "薑母鴨", backgroundImage: "薑母鴨"),
        FoodOption(name: "清燉羊肉", backgroundImage: "清燉羊肉")
        // 添加更多食物選項及其相應的背景圖片
    ]


    @State private var isShowingDetail7 = false

    // MARK: 聽天由命選項的View
    private var fateButton: some View {
        CustomButton(imageName: "聽天由命", buttonText: "聽天由命") 
        {
            isShowingDetail7.toggle()
        }
        .sheet(isPresented: $isShowingDetail7) 
        {
            VStack {
                Spacer()
                SpinnerView()
                    .background(Color.white) // 可以設定 SpinnerView 的背景色
                    .cornerRadius(10)
            }
            .edgesIgnoringSafeArea(.all)
        }
  
    }

    @ViewBuilder
    private func TempView(imageName: String, buttonText: String, isShowingDetail: Binding<Bool>, foodOptions: [FoodOption]) -> some View {
        CustomButton(imageName: imageName, buttonText: buttonText) {
            isShowingDetail.wrappedValue.toggle()
        }
        .sheet(isPresented: isShowingDetail) {
            FoodSelectionView(isShowingDetail: $isShowingDetail, editedPlan: $editedPlan, foodOptions: foodOptions)
        }
    }
    
    var body: some View
    {
        VStack
        {
            Text("選擇的食物: \(editedPlan)")
                .font(.title)
                .padding(.top,30)
                .opacity(editedPlan.isEmpty ? 0 : 1)
                .offset(y: -18)
            HStack
            {
            }
        }
        .navigationBarItems(trailing: Button("保存")
                            {
            if var dayPlans = plans[day]
            {
                dayPlans[planIndex] = editedPlan
                plans[day] = dayPlans
            }
            
            // 保存編輯計畫
            self.presentationMode.wrappedValue.dismiss()
        })
        NavigationStack
        {
            ScrollView
            {
                VStack(spacing:5)
                {
                    HStack(spacing:-20)
                    {
                        TextField("搜尋食譜.....", text: $searchText)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        
                        Button(action:
                                {
                            // 執行搜尋操作
                        })
                        {
                            Image(systemName: "magnifyingglass") // 放大鏡圖標
                                .padding()
                        }
                    }
                    .padding(.top, 10)
                    
                    let name=["懶人","減肥","省錢","放縱","養生","今日推薦","聽天由命"]
                    let show2=[foodOptions1,foodOptions2,foodOptions3,foodOptions4,foodOptions5,foodOptions6]
                    VStack(spacing: 30) {
                        ForEach(name.indices, id: \.self) { index in
                            if index == 6 {
                                fateButton // 顯示第七個選項的專用按鈕
                            } else {
                                self.TempView(
                                    imageName: name[index],
                                    buttonText: name[index],
                                    isShowingDetail: $show1[index],
                                    foodOptions: show2[index]
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
