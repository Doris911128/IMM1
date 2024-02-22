//血壓（Blood Pressure）的英文縮寫是 BP


// MARK: 血壓View
import SwiftUI
import Charts

struct HypertensionRecord: Identifiable //血壓紀錄
{
    var id = UUID()
    var hypertension: Double
    var date: Date
    
    init(hypertension: Double)
    {
        self.hypertension = hypertension
        self.date = Date()
    }
}

struct HypertensionTemperatureSensor: Identifiable //包含ID和高血壓相關紀錄數組
{
    var id: String
    var records: [HypertensionRecord]
}

var HypertensionallSensors: [HypertensionTemperatureSensor] = //存取TemperatureSensor數據
[
    .init(id: "血壓值", records: [])
]

// MARK: 日期func
private func formattedDate(_ date: Date) -> String
{
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm"
    return formatter.string(from: date)
}

struct HypertensionView: View
{
    let upperLimit: Double = 400.0 //輸入最大值
    
    @State private var hypertension: String = ""
    @State private var chartData: [HypertensionRecord] = []
    @State private var isShowingList: Bool = false
    @State private var scrollToBottom: Bool = false
    @State private var showAlert: Bool = false
    
    var body: some View
    {
        NavigationView
        {
            VStack
            {
                HStack
                {
                    Text("血壓紀錄")
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
                    HStack(spacing: 30)
                    {
                        Chart(HypertensionallSensors) { sensor in
                            let groupedRecords = Dictionary(grouping: chartData, by: { formattedDate($0.date) })
                            let latestRecords = groupedRecords.mapValues { $0.last! }
                            
                            ForEach(latestRecords.sorted(by: { $0.key < $1.key }), id: \.key) { date, record in
                                LineMark(
                                    x: .value("Hour", formattedDate(record.date)),
                                    y: .value("Value", record.hypertension)
                                )
                                .lineStyle(.init(lineWidth: 5))
                                
                                PointMark(
                                    x: .value("Hour", formattedDate(record.date)),
                                    y: .value("Value", record.hypertension)
                                )
                                .annotation(position: .top)
                                {
                                    Text("\(record.hypertension, specifier: "%.2f")")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("textcolor"))
                                }
                            }
                            .foregroundStyle(by: .value("Location", sensor.id))
                            .symbol(by: .value("Sensor Location", sensor.id))
                            .symbolSize(100)
                        }
                        .chartForegroundStyleScale(["血壓值": .orange])
                        .frame(width: 350, height: 200)
                        
                    }
                }
                .padding()
                
                VStack
                {
                    Text("血壓值輸入")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .foregroundColor(Color("textcolor"))
                    
                    VStack(spacing: -5)
                    {
                        TextField("請輸入血壓值", text: $hypertension)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) {
                                _ in
                            }
                            .onChange(of: hypertension)
                        {
                            newValue in
                            if let newValue = Double(newValue), newValue > upperLimit
                            {
                                showAlert = true //當輸入的值超過上限時，會顯示警告
                                hypertension = String(upperLimit) //將輸入值截斷為上限值
                            }
                        }
                        
                        Button(action:
                                {
                            if let hypertensionValue = Double(hypertension)
                            {
                                let newRecord = HypertensionRecord(hypertension: hypertensionValue)
                                
                                if let existingRecordIndex = chartData.lastIndex(where: { $0.date > Date().addingTimeInterval(-6 * 60 * 60) }) {
                                    chartData[existingRecordIndex] = newRecord
                                }
                                else
                                {
                                    chartData.append(newRecord)
                                    scrollToBottom = true
                                }
                                
                                hypertension = ""
                            }
                        }) {
                            Text("紀錄血壓")
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
                HypertensionRecordsListView(records: $chartData)
            }
            // MARK: 超過上限警告
            .alert(isPresented: $showAlert)
            {
                Alert(
                    title: Text("警告"),
                    message: Text("輸入的血壓值最高為400，請重新輸入。"),
                    dismissButton: .default(Text("確定"))
                )
            }
        }
        .offset(y: -46)
    }
}

struct HypertensionRecordsListView: View
{
    @Binding var records: [HypertensionRecord]
    
    var body: some View
    {
        NavigationStack
        {
            List
            {
                ForEach(records)
                {
                    record in
                    NavigationLink(destination: EditHypertensionRecordView(record: $records[records.firstIndex(where: { $0.id == record.id })!]))
                    {
                        Text("\(formattedDate(record.date)): \(record.hypertension, specifier: "%.2f")")
                    }
                }
                .onDelete(perform: deleteRecord)
            }
            .navigationTitle("血壓紀錄列表")
            .toolbar
            {
                ToolbarItem(placement: .navigationBarTrailing)
                {
                    EditButton()
                }
            }
        }
    }
    // MARK: 列表刪除功能_歷史紀錄刪除
    private func deleteRecord(at offsets: IndexSet)
    {
        records.remove(atOffsets: offsets)
    }
}

// MARK: 編輯
struct EditHypertensionRecordView: View
{
    @Binding var record: HypertensionRecord
    @State private var editedHypertension: String = ""
    @State private var originalHypertension: Double = 0.0
    @State private var showAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View
    {
        VStack
        {
            TextField("血壓值", text: $editedHypertension)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .onAppear
            {
                editedHypertension = String(record.hypertension)
                originalHypertension = record.hypertension
            }
            
            Button("保存")
            {
                if let editedValue = Double(editedHypertension)
                {
                    if editedValue <= 400.0
                    {
                        record.hypertension = editedValue
                        presentationMode.wrappedValue.dismiss()
                    }
                    else
                    {
                        showAlert = true //用戶修改的值超過400，顯示警告
                    }
                }
            }
            .padding()
        }
        .navigationTitle("編輯血壓值")
        .alert(isPresented: $showAlert) //超過上限警告
        {
            Alert(
                title: Text("警告"),
                message: Text("輸入的血壓值最高為400，請重新輸入。"),
                dismissButton: .default(Text("確定"))
            )
        }
    }
}

struct HypertensionView_Previews: PreviewProvider
{
    static var previews: some View
    {
        HypertensionView()
    }
}
