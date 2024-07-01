// 血壓（Blood Pressure）的英文縮寫是 BP

// MARK: 血壓View
import SwiftUI
import Charts

struct HypertensionRecord: Identifiable, Codable // 血壓紀錄
{
    var id = UUID()  // 在这里生成 UUID，不依赖 JSON 提供的 ID
    var hypertension: Double
    var date: Date
    
    enum CodingKeys: String, CodingKey {
        case hypertension = "BP"
        case date = "BP_DT"
    }
    
    init(hypertension: Double, date: Date = Date()) {
        self.hypertension = hypertension
        self.date = date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hypertensionString = try container.decode(String.self, forKey: .hypertension)
        guard let hypertensionDouble = Double(hypertensionString) else {
            throw DecodingError.dataCorruptedError(forKey: .hypertension, in: container, debugDescription: "血壓值應為可轉換為Double的字符串。")
        }
        hypertension = hypertensionDouble
        
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"  // 更新格式以包含秒
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = formatter.date(from: dateString) {
            self.date = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "日期字符串與格式器預期的格式不匹配。")
        }
    }
}

struct HypertensionTemperatureSensor: Identifiable // 包含ID和高血壓相關紀錄數組
{
    var id: String
    var records: [HypertensionRecord]
}

var HypertensionallSensors: [HypertensionTemperatureSensor] = // 存取TemperatureSensor數據
[
    .init(id: "血壓值", records: [])
]

// MARK: 日期func
private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm"  // 加入秒
    formatter.locale = Locale(identifier: "en_US_POSIX") // 使用 POSIX 以保證日期格式的嚴格匹配
    formatter.timeZone = TimeZone(secondsFromGMT: 0) // 根據需要調整時區
    
    return formatter.string(from: date)
}

struct HypertensionView: View
{
    let upperLimit: Double = 400.0 //輸入最大值
    
    @State private var displayMode: Int = 0  // 0 表示每日，1 表示每七日
    @State private var hypertension: String = ""
    @State private var chartData: [HypertensionRecord] = []
    @State private var isShowingList: Bool = false
    @State private var showAlert: Bool = false
    
    private func averagesEverySevenRecords() -> [HypertensionRecord] {
        let sortedRecords = chartData.sorted { $0.date < $1.date }
        var results: [HypertensionRecord] = []
        let batchSize = 7

        for batchStart in stride(from: 0, to: sortedRecords.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, sortedRecords.count)
            let batch = Array(sortedRecords[batchStart..<batchEnd])
            let totalHypertension = batch.reduce(0.0) { $0 + $1.hypertension }
            if !batch.isEmpty {
                let averageHypertension = totalHypertension / Double(batch.count)
                let recordDate = batch.first!.date
                let avgRecord = HypertensionRecord(hypertension: averageHypertension, date: recordDate)
                results.append(avgRecord)
            }
        }

        return results
    }

    private func averagesEveryThirtyRecords() -> [HypertensionRecord] {
        let sortedRecords = chartData.sorted { $0.date < $1.date }
        var results: [HypertensionRecord] = []
        let batchSize = 30

        for batchStart in stride(from: 0, to: sortedRecords.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, sortedRecords.count)
            let batch = Array(sortedRecords[batchStart..<batchEnd])
            let totalHypertension = batch.reduce(0.0) { $0 + $1.hypertension }
            if !batch.isEmpty {
                let averageHypertension = totalHypertension / Double(batch.count)
                let recordDate = batch.first!.date
                let avgRecord = HypertensionRecord(hypertension: averageHypertension, date: recordDate)
                results.append(avgRecord)
            }
        }

        return results
    }

    func connect(name: String, action: String) {
        let url = URL(string: "http://163.17.9.107/food/\(name).php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "action=\(action)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let data = data {
                print(String(decoding: data, as: UTF8.self))  // 打印原始 JSON 数据
                do {
                    let responseArray = try JSONDecoder().decode([HypertensionRecord].self, from: data)
                    DispatchQueue.main.async {
                        self.chartData = responseArray
                        print("成功解码并更新了 chartData，包含 \(responseArray.count) 条记录。")
                    }
                } catch {
                    print("解码数据失败: \(error)")
                }
            } else if let error = error {
                print("网络请求出错: \(error)")
            }
        }.resume()
    }
    
    func sendBPData(name: String, bp: Double, action: String) {
        let url = URL(string: "http://163.17.9.107/food/\(name).php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = "BP=\(bp)&action=\(action)"  // 確保 action 參數也被發送
        request.httpBody = postData.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print("Network request error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Response from server: \(jsonObject)")
                } else {
                    print("Received non-dictionary JSON response")
                }
            } catch {
                print("Failed to decode JSON: \(error)")
            }
        }.resume()
    }

    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                HStack
                {
                    Text("血壓紀錄")
                        .foregroundColor(Color.black)
                        .frame(width: 300, height: 50)
                        .font(.system(size: 33, weight: .bold))
                        .offset(x: -60)
                    
                    Button(action:
                            {
                        isShowingList.toggle()
                    }) {
                        Image(systemName: "list.dash")
                            .font(.title)
                            .foregroundColor(Color("BottonColor"))
                            .padding()
                            .cornerRadius(10)
                            .padding(.trailing, 20)
                            .imageScale(.large)
                    }
                    .offset(x: 10)
                }
                ScrollView(.horizontal) {
                    Chart(displayMode == 0 ? chartData : (displayMode == 1 ? averagesEverySevenRecords() : averagesEveryThirtyRecords())) { record in
                        LineMark(
                            x: .value("Date", formattedDate(record.date)),
                            y: .value("Value", record.hypertension)
                        )
                        .lineStyle(.init(lineWidth: 3))

                        PointMark(
                            x: .value("Date", formattedDate(record.date)),
                            y: .value("Value", record.hypertension)
                        )
                        .annotation(position: .top) {
                            Text("\(record.hypertension, specifier: "%.2f")")
                                .font(.system(size: 12))
                                .foregroundColor(Color.black)
                        }
                    }
                    .chartForegroundStyleScale(["血壓值": .orange])
                    .frame(width: max(350, Double(chartData.count) * 65), height: 200)
                    .padding(.top, 20)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.orange, lineWidth: 2)) // 添加边框
                    .shadow(color: Color.gray.opacity(10), radius: 10, x: 0, y: 5) // 添加阴影
                }
                .padding()
                
                VStack
                {
                    HStack
                    {
                        Text("血壓值輸入")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)
                            .foregroundColor(Color.black)
                        Picker("显示模式", selection: $displayMode) {
                            Text("每日").tag(0)
                            Text("每7日").tag(1)
                            Text("每30日").tag(2)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                    }
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
                                self.sendBPData(name: "BP", bp: hypertensionValue, action:"insert" )
                                self.connect(name: "BP", action: "fetch")
                                if let index = chartData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) //檢查是否已經有當天的紀錄存在
                                {
                                    chartData[index].hypertension = hypertensionValue //如果有，則更新當天的值
                                    
                                }
                                else
                                {
                                    let newRecord = HypertensionRecord(hypertension: hypertensionValue) //否則新增一條紀錄
                                    chartData.append(newRecord)
                                }
                                
                                hypertension = ""
                            }
                        }) {
                            Text("紀錄血壓")
                                .foregroundColor(Color("ButColor"))
                                .padding(10)
                                .frame(width: 300, height: 50)
                                .background(Color("BottonColor"))
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
            .onAppear{
                self.connect(name: "BP", action: "fetch")
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
//        .offset(y: -98)
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
