//血糖（Blood Sugar）的英文縮寫是 BS
//
//  HyperglycemiaView.swift 高血糖
//
//  Created by 0911
//

// MARK: 血糖View
import SwiftUI
import Charts

// MARK: 血糖紀錄
struct HyperglycemiaRecord: Identifiable
{
    var id = UUID()
    var hyperglycemia: Double
    var date: Date
    
    init(hyperglycemia: Double)
    {
        self.hyperglycemia = hyperglycemia
        self.date = Date()
    }
}

// MARK: 包含ID和高血糖相關紀錄數組
struct HyperglycemiaTemperatureSensor: Identifiable
{
    var id: String
    var records: [HyperglycemiaRecord]
}

// MARK: 存取TemperatureSensor數據
var HyperglycemiaallSensors: [HyperglycemiaTemperatureSensor] = [
    .init(id: "血糖值", records: [])
]

// MARK: 日期func
private func formattedDate(_ date: Date) -> String
{
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd"
    return formatter.string(from: date)
}

struct HyperglycemiaView: View
{
    let upperLimit: Double = 300.0
    
    @State private var hyperglycemia: String = ""
    @State private var chartData: [HyperglycemiaRecord] = []
    @State private var isShowingList: Bool = false
    @State private var scrollToBottom: Bool = false
    @State private var showAlert: Bool = false//
    
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                HStack
                {
                    Text("血糖紀錄")
                        .foregroundColor(Color("textcolor"))
                        .frame(width: 300, height: 50)
                        .font(.system(size: 33, weight: .bold))
                        .offset(x:-60)
                    
                    Button(action:
                            {
                        isShowingList.toggle()
                    }) {
                        Image(systemName: "list.dash")
                            .font(.title)
                            .foregroundColor(Color(hue: 0.031, saturation: 0.803, brightness: 0.983))
                            .padding()
                            .cornerRadius(10)
                            .padding(.trailing, 20)
                            .imageScale(.large)
                    }
                    .offset(x:10)
                }
                ScrollView(.horizontal)
                {
                    Chart(HyperglycemiaallSensors)
                    {
                        sensor in
                        ForEach(chartData)
                        {
                            record in
                            LineMark(
                                x: .value("Hour", formattedDate(record.date)),
                                y: .value("Value", record.hyperglycemia)
                            )
                            .lineStyle(.init(lineWidth: 5))
                            
                            PointMark(
                                x: .value("Hour", formattedDate(record.date)),
                                y: .value("Value", record.hyperglycemia)
                            )
                            .annotation(position: .top)
                            {
                                Text("\(record.hyperglycemia, specifier: "%.2f")")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("textcolor"))
                            }
                        }
                        .foregroundStyle(by: .value("Location", sensor.id))
                        .symbol(by: .value("Sensor Location", sensor.id))
                        .symbolSize(100)
                    }
                    .chartForegroundStyleScale([
                        "血糖值": .orange
                    ])
                    .frame(width: 350, height: 200)
                }
                .padding()
                VStack
                {
                    Text("血糖值輸入")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .foregroundColor(Color("textcolor"))
                    
                    VStack(spacing: -5)
                    {
                        TextField("請輸入血糖值", text: $hyperglycemia)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification))
                        {
                            _ in
                        }
                        .onChange(of: hyperglycemia)
                        {
                            newValue in
                            if let newValue = Double(newValue), newValue > upperLimit
                            {
                                showAlert = true //當輸入的值超過上限時，會顯示警告
                                hyperglycemia = String(upperLimit) //將輸入值截斷為上限值
                            }
                        }
                        
                        Button(action:
                                {
                            if let hyperglycemiaValue = Double(hyperglycemia)
                            {
                                if let existingRecordIndex = chartData.firstIndex(where:{ Calendar.current.isDate($0.date, inSameDayAs: Date()) })
                                {
                                    chartData[existingRecordIndex].hyperglycemia = hyperglycemiaValue //找到當天的記錄
                                }
                                else
                                {
                                    let newRecord = HyperglycemiaRecord(hyperglycemia: hyperglycemiaValue) //創建新的當天記錄
                                    chartData.append(newRecord)
                                }
                                hyperglycemia = ""
                                scrollToBottom = true //將標誌設為true，以便滾動到底部
                            }
                        }) {
                            Text("紀錄血糖")
                                .foregroundColor(Color("textcolor"))
                                .padding(10)
                                .frame(width: 300, height: 50)
                                .background(Color(hue: 0.031, saturation: 0.803, brightness: 0.983))
                                .cornerRadius(100)
                                .font(.title3)
                        }
                        .padding()
                        .offset(y: 10)
                    }
                    .onTapGesture
                    {
                        self.dismissKeyboard()
                    }
                }
                .offset(y: 10)
            }
            .sheet(isPresented: $isShowingList)
            {
                HyperglycemiaRecordsListView(records: $chartData)
            }
            .alert(isPresented: $showAlert) //超過上限警告
            {
                Alert(
                    title: Text("警告"),
                    message: Text("輸入的血糖值最高為300，請重新輸入。"),
                    dismissButton: .default(Text("確定"))
                )
            }
        }
        .offset(y: -98)
    }
}

// MARK: 列表記錄
struct HyperglycemiaRecordsListView: View
{
    @Binding var records: [HyperglycemiaRecord]
    
    var body: some View
    {
        NavigationStack
        {
            List
            {
                ForEach(records)
                {
                    record in
                    NavigationLink(destination: EditHyperglycemiaRecordView(record: $records[records.firstIndex(where: { $0.id == record.id })!])) {
                        Text("\(formattedDate(record.date)): \(record.hyperglycemia, specifier: "%.2f")")
                    }
                }
                .onDelete(perform: deleteRecord)
            }
            .navigationTitle("血糖紀錄列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing)
                {
                    EditButton()
                }
            }
        }
    }
    // MARK: 列表刪除功能
    private func deleteRecord(at offsets: IndexSet)
    {
        records.remove(atOffsets: offsets)
    }
}

// MARK: 編輯血糖紀錄視圖
struct EditHyperglycemiaRecordView: View
{
    @Binding var record: HyperglycemiaRecord
    
    @State private var editedHyperglycemia: String = ""
    @State private var originalHypertension: Double = 0.0
    @State private var showAlert: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View
    {
        VStack
        {
            TextField("血糖值", text: $editedHyperglycemia)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .onAppear
            {
                editedHyperglycemia = String(record.hyperglycemia)
            }
            
            Button("保存")
            {
                if let editedValue = Double(editedHyperglycemia)
                {
                    if editedValue <= 300 //檢查是否超過上限
                    {
                        record.hyperglycemia = editedValue
                        presentationMode.wrappedValue.dismiss()
                    }
                    else
                    {
                        showAlert = true //超過上限時顯示警告
                    }
                }
            }
            .padding()
        }
        .navigationTitle("編輯血糖值")
        .alert(isPresented: $showAlert) //超過上限時顯示警告
        {
            Alert(
                title: Text("警告"),
                message: Text("輸入的血糖值最高為300，請重新輸入。"),
                dismissButton: .default(Text("確定"))
            )
        }
    }
}

struct HyperglycemiaView_Previews: PreviewProvider
{
    static var previews: some View
    {
        HyperglycemiaView()
    }
}
