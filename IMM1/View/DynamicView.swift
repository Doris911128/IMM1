//
//  DynamicView.swift
//  GP110IM
//
//  Created by 朝陽資管 on 2023/10/27.

// MARK: 動態View（BMI 血壓 BP 血糖 BS 血脂 BL）
import SwiftUI
import Charts

// MARK: 日期func
private func formattedDate(_ date: Date) -> String
{
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.string(from: date)
}

struct DynamicView: View
{
    enum DynamicRecordType
    {
        case BMI, hypertension, hyperglycemia, hyperlipidemia
    }
    
    func recordButton(_ type: DynamicRecordType, title: String) -> some View
    {
        Button(action:
                {
            withAnimation {
                selectedRecord = type
            }
        }) {
            Text(title)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
        }
    }
    
    @State private var selectedRecord: DynamicRecordType = .BMI
    @State public var DynamicTitle:[String]=["BMI", "血壓" , "血糖", "血脂"]
    
    var body: some View
    {
        VStack(spacing: 20)
        {
            HStack
            {
                Spacer()
                Group
                {
                    recordButton(.BMI, title: "BMI")
                    recordButton(.hypertension, title: "血壓")
                    recordButton(.hyperglycemia, title: "血糖")
                    recordButton(.hyperlipidemia, title: "血脂")
                }
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.vertical, 8)
                Spacer()
            }
            Spacer()

            displaySelectedRecordView()
                .padding()
        }
    }
    
    @ViewBuilder
    func displaySelectedRecordView() -> some View
    {
        switch(selectedRecord)
        {
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
struct DynamicView_Previews: PreviewProvider
{
    static var previews: some View
    {
        DynamicView()
    }
}
