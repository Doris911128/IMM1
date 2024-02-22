//血脂（Blood Lipids）的英文縮寫是 BL
//
//
//  HyperlipidemiaView.swift 高血脂
//
//  Created by 0911
//

// MARK: 血脂View
import SwiftUI
import Charts

// MARK: 血脂紀錄
struct HyperlipidemiaRecord: Identifiable
{
    var id = UUID()
    var hyperlipidemia: Double
    var date: Date
    
    init(hyperlipidemia: Double)
    {
        self.hyperlipidemia = hyperlipidemia
        self.date = Date()
    }
}

// MARK: 包含ID和高血脂相關紀錄數組
struct HyperlipidemiaTemperatureSensor: Identifiable
{
    var id: String
    var records: [HyperlipidemiaRecord]
}

// MARK: 存取TemperatureSensor數據
var HyperlipidemiaallSensors: [HyperlipidemiaTemperatureSensor] = [
    .init(id: "血脂值", records: [])
]

// MARK: 日期func
private func formattedDate(_ date: Date) -> String
{
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd"
    return formatter.string(from: date)
}

struct HyperlipidemiaView: View
{
    let upperLimit: Double = 500.0
    
    @State private var hyperlipidemia: String = ""
    @State private var chartData: [HyperlipidemiaRecord] = []
    @State private var isShowingList: Bool = false //列表控制
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
                    Text("血脂紀錄")
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
                            Chart(HyperlipidemiaallSensors)
                            {
                                sensor in
                                ForEach(chartData) //動態顯示用戶輸入的數據
                                {
                                    record in
                                    LineMark(
                                        x: .value("Hour", formattedDate(record.date)),
                                        y: .value("Value", record.hyperlipidemia)
                                    )
                                    .lineStyle(.init(lineWidth: 5))
                                    
                                    PointMark(
                                        x: .value("Hour", formattedDate(record.date)),
                                        y: .value("Value", record.hyperlipidemia)
                                    )
                                    .annotation(position: .top)
                                    {
                                        Text("\(record.hyperlipidemia, specifier: "%.2f")")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("textcolor"))
                                    }
                                }
                                .foregroundStyle(by: .value("Location", sensor.id))
                                .symbol(by: .value("Sensor Location", sensor.id))
                                .symbolSize(100)
                            }
                            .chartForegroundStyleScale([
                                "血脂值": .orange
                            ])
                            .frame(width: 350, height: 200)
                    }
                    .padding()
                VStack
                {
                    Text("血脂值輸入") //血脂值輸入
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .foregroundColor(Color("textcolor"))
                    VStack(spacing: -5) //使用者輸入
                    {
                        TextField("請輸入血脂值", text: $hyperlipidemia)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification))
                        {_ in}
                        .onChange(of: hyperlipidemia)
                        { newValue in
                            if let newValue = Double(newValue), newValue > upperLimit
                            {
                                showAlert = true //當輸入的值超過上限時，會顯示警告
                                hyperlipidemia = String(upperLimit) //將輸入值截斷為上限值
                            }
                        }
                        Button(action:
                                {
                            if let hyperlipidemiaValue = Double(hyperlipidemia)
                            {
                                if let index = chartData.firstIndex(where:{ Calendar.current.isDate($0.date, inSameDayAs: Date()) }) //檢查是否已經有當天的紀錄存在
                                {
                                    chartData[index].hyperlipidemia = hyperlipidemiaValue //如果有，則更新當天的值

                                }
                                else
                                {
                                    let newRecord = HyperlipidemiaRecord(hyperlipidemia: hyperlipidemiaValue) //否則新增一條紀錄
                                    chartData.append(newRecord)
                                }
                                
                                hyperlipidemia = ""
                            }
                        }) {
                            Text("紀錄血脂")
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
                    .onTapGesture {
                        self.dismissKeyboard()
                    }
                }
                .offset(y: 10)
            }
            .sheet(isPresented: $isShowingList)
            {
                HyperlipidemiaRecordsListView(records: $chartData)
            }
            .alert(isPresented: $showAlert) //超過上限警告
            {
                Alert(
                    title: Text("警告"),
                    message: Text("輸入的血脂值最高為500，請重新輸入。"),
                    dismissButton: .default(Text("確定"))
                )
            }
        }
        .offset(y: -98)
    }
}

// MARK: 列表記錄
struct HyperlipidemiaRecordsListView: View
{
    @Binding var records: [HyperlipidemiaRecord]
    
    var body: some View
    {
        NavigationStack
        {
            List
            {
                ForEach(records)
                {
                    record in
                    NavigationLink(destination: EditHyperlipidemiaRecordView(record: $records[records.firstIndex(where: { $0.id == record.id })!])) {
                        Text("\(formattedDate(record.date)): \(record.hyperlipidemia, specifier: "%.2f")")
                    }
                }
                .onDelete(perform: deleteRecord)
            }
            .navigationTitle("血脂紀錄列表")
            .toolbar 
            {
                ToolbarItem(placement: .navigationBarTrailing)
                {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteRecord(at offsets: IndexSet)
    {
        records.remove(atOffsets: offsets)
    }
}

// MARK: 編輯血脂紀錄視圖
struct EditHyperlipidemiaRecordView: View
{
    @Binding var record: HyperlipidemiaRecord
    
    @State private var editedHyperlipidemia: String = ""
    @State private var originalHypertension: Double = 0.0
    @State private var showAlert: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View
    {
        VStack
        {
            TextField("血脂值", text: $editedHyperlipidemia)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .onAppear
            {
                editedHyperlipidemia = String(record.hyperlipidemia)
            }
            
            Button("保存")
            {
                if let editedValue = Double(editedHyperlipidemia)
                {
                    if editedValue <= 500 //檢查是否超過上限

                    {
                        record.hyperlipidemia = editedValue
                        presentationMode.wrappedValue.dismiss()
                    } else //超過上限時顯示警告
                    {
                        showAlert = true
                    }
                }
            }
            .padding()
        }
        .navigationTitle("編輯血脂值")
        .alert(isPresented: $showAlert) //超過上限時顯示警告
        {
            Alert(
                title: Text("警告"),
                message: Text("輸入的血脂值最高為500，請重新輸入。"),
                dismissButton: .default(Text("確定"))
            )
        }
    }
}

struct HyperlipidemiaView_Previews: PreviewProvider
{
    static var previews: some View
    {
        HyperlipidemiaView()
    }
}
