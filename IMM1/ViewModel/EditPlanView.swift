// EditPlanView.swift

import SwiftUI
import Foundation

// 定義從服務器中獲取的食物數據結構
struct FoodData: Codable {
    let Dis_Name: String
    let D_image: String
    // 添加其他屬性，如果需要的話
}

// 定義函式，從指定的 URL 加載食物數據
func fetchFoodData(from url: URL, completion: @escaping ([FoodData]?, Error?) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let data = data else {
            completion(nil, NSError(domain: "com.example", code: 0, userInfo: [NSLocalizedDescriptionKey: "未收到數據"]))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let foodData = try decoder.decode([FoodData].self, from: data)
            completion(foodData, nil)
        } catch {
            completion(nil, error)
        }
    }.resume()
}

struct EditPlanView: View {
    
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
        FoodOption(name: "番茄炒蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/1.jpg")!),
        FoodOption(name: "荷包蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/2.jpg")!),
        FoodOption(name: "炒高麗菜", backgroundImage: URL(string: "http://163.17.9.107/food/images/3.jpg")!)
        // 添加更多食物選項及其相應的背景圖片
    ]
    // MARK: 減肥選項
    let foodOptions2: [FoodOption] = [
        FoodOption(name: "番茄炒蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/1.jpg")!),
        FoodOption(name: "荷包蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/2.jpg")!),
        FoodOption(name: "炒高麗菜", backgroundImage: URL(string: "http://163.17.9.107/food/images/3.jpg")!)
        // 添加更多食物選項及其相應的背景圖片
    ]
    // MARK: 省錢選項
    let foodOptions3: [FoodOption] = [
        FoodOption(name: "番茄炒蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/1.jpg")!),
        FoodOption(name: "荷包蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/2.jpg")!),
        FoodOption(name: "炒高麗菜", backgroundImage: URL(string: "http://163.17.9.107/food/images/3.jpg")!)
        // 添加更多食物選項及其相應的背景圖片
    ]
    // MARK: 放縱選項
    let foodOptions4: [FoodOption] = [
        FoodOption(name: "番茄炒蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/1.jpg")!),
        FoodOption(name: "荷包蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/2.jpg")!),
        FoodOption(name: "炒高麗菜", backgroundImage: URL(string: "http://163.17.9.107/food/images/3.jpg")!)
        // 添加更多食物選項及其相應的背景圖片
    ]
    // MARK: 養生選項
    let foodOptions5: [FoodOption] = [
        FoodOption(name: "番茄炒蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/1.jpg")!),
        FoodOption(name: "荷包蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/2.jpg")!),
        FoodOption(name: "炒高麗菜", backgroundImage: URL(string: "http://163.17.9.107/food/images/3.jpg")!)
        // 添加更多食物選項及其相應的背景圖片
    ]
    // MARK: 今日推薦選項
    let foodOptions6: [FoodOption] = [
        FoodOption(name: "番茄炒蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/1.jpg")!),
        FoodOption(name: "荷包蛋", backgroundImage: URL(string: "http://163.17.9.107/food/images/2.jpg")!),
        FoodOption(name: "炒高麗菜", backgroundImage: URL(string: "http://163.17.9.107/food/images/3.jpg")!)
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
    
    var body: some View {
        VStack {
            Text("選擇的食物: \(editedPlan)")
                .font(.title)
                .padding(.top,30)
                .opacity(editedPlan.isEmpty ? 0 : 1)
                .offset(y: -18)
            HStack {}
        }
        .navigationBarItems(trailing: Button("保存") {
            if var dayPlans = plans[day] {
                dayPlans[planIndex] = editedPlan
                plans[day] = dayPlans
                
                // 在保存成功後調用 fetchFoodData 以獲取食物數據
                if let url = URL(string: "http://163.17.9.107/food/Dishes.php") {
                    fetchFoodData(from: url) { foodData, error in
                        if let error = error {
                            print("發生錯誤：", error)
                        } else if let foodData = foodData {
                            print("獲取的食物數據：", foodData)
                        }
                    }
                } else {
                    print("無效的 URL")
                }
            }
            self.presentationMode.wrappedValue.dismiss()
        })
        NavigationView {
            ScrollView {
                VStack(spacing:5) {
                    HStack(spacing:-20) {
                        TextField("搜尋食譜.....", text: $searchText)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button(action: {
                            // 執行搜尋操作
                        }) {
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
