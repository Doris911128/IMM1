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
    formatter.dateFormat = "MM-dd HH:mm"
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
            selectedRecord = type
        }) {
            Text(title)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
        }
    }
    @State private var selectedRecord: DynamicRecordType = .BMI
    @State public var DynamicTitle:[String]=["BMI", "血壓" , "血糖", "血脂"]
    
    //創建一些示例傳感器和記錄
//    let BMISensors: [TemperatureSensor<Double>] = [TemperatureSensor(sensorID: "BMI Sensor 1", records: [BMIRecord])]
//    let BPSensors: [TemperatureSensor<Double>] = [TemperatureSensor(sensorID: "BP Sensor 1", records: [BPRecord])]
//    let BSSensors: [TemperatureSensor<Double>] = [TemperatureSensor(sensorID: "BS Sensor 1", records: [BSRecord])]
//    let BLSensors: [TemperatureSensor<Int>] = [TemperatureSensor(sensorID: "BL Sensor 1", records: [BLRecord])]

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
        switch selectedRecord
        {
        case .BMI:
            BMIView().animation(nil)
        case .hypertension:
            HypertensionView().animation(nil)
        case .hyperglycemia:
            HyperglycemiaView().animation(nil)
        case .hyperlipidemia:
            HyperlipidemiaView().animation(nil)
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
