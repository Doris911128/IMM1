//
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
    @State public var DynamicTitle: [String] = ["BMI", "血壓", "血糖", "血脂"]
    
    func recordButton(_ type: DynamicRecordType, title: String) -> some View {
        Button(action: {
            withAnimation {
                selectedRecord = type
            }
        }) {
            Text(title)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selectedRecord == type ? Color.orange : Color.clear, lineWidth: 2)
                )
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                recordButton(.BMI, title: "BMI")
                recordButton(.hypertension, title: "血壓")
                recordButton(.hyperglycemia, title: "血糖")
                recordButton(.hyperlipidemia, title: "血脂")
                Spacer()
            }
            .frame(height: 50) // Adjust the height as needed
            
            Spacer() // This spacer will push the content to the top
            
            displaySelectedRecordView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(Color.white) // Optional background color
        }
        //.edgesIgnoringSafeArea(.bottom) // Optional: If you want to ensure content extends to the bottom edge
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

// MARK: Preview
struct DynamicView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicView()
    }
}
