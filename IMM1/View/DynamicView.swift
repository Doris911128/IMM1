//  DynamicView.swift
//  GP110IM
//
//  Created by 朝陽資管 on 2023/10/27.

// MARK: 動態View（BMI 血壓 BP 血糖 BS 血脂 BL）
import SwiftUI
import Charts

struct DynamicView: View {
    enum DynamicRecordType {
        case BMI, hypertension, hyperglycemia, hyperlipidemia
    }
    
    @State private var selectedRecord: DynamicRecordType = .BMI
    
    func recordButton(_ type: DynamicRecordType, title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity) // 讓每個按鈕填滿可用空間
            .padding(.vertical, 8)
            .background(selectedRecord == type ? Color.orange : Color.clear)
            .foregroundColor(selectedRecord == type ? .white : .black)
            .onTapGesture {
                withAnimation {
                    selectedRecord = type
                }
            }
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 0) { // 設定按鈕之間的間隔為 0，確保完全填滿
                recordButton(.BMI, title: "BMI")
                recordButton(.hypertension, title: "血壓")
                recordButton(.hyperglycemia, title: "血糖")
                recordButton(.hyperlipidemia, title: "血脂")
            }
            .frame(maxWidth: .infinity, maxHeight: 50) // 讓 HStack 完全填滿可用空間
            .background(Color.white) // 確保 HStack 背景顏色與外框分離
            .overlay( // 使用 overlay 將邊框套在 HStack 上
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange, lineWidth: 2)
            )
            .padding(.horizontal, 15) // 控制左右間距，讓邊框緊貼視圖邊緣

            Spacer()
            
            displaySelectedRecordView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(Color.white)
        }
        .background(Color.white) // 確保整個背景一致
    }
    
    @ViewBuilder
    func displaySelectedRecordView() -> some View {
        switch(selectedRecord) {
        case .BMI:
            BMIView()
        case .hypertension:
            HypertensionView()
        case .hyperglycemia:
            HyperglycemiaView()
        case .hyperlipidemia:
            HyperlipidemiaView()
        }
    }
}

struct DynamicView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicView()
    }
}
