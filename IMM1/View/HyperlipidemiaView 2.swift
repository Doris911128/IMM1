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
struct HyperlipidemiaRecord: Identifiable,Codable
{
    var id = UUID()
    var hyperlipidemia: Double
    var date: Date
    
    enum CodingKeys: String, CodingKey {
        case hyperlipidemia = "BL"
        case date = "BL_DT"
    }
    
    init(hyperlipidemia: Double,date: Date = Date())
    {
        self.hyperlipidemia = hyperlipidemia
        self.date = date
    }
    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hyperlipidemiaString = try container.decode(String.self, forKey: .hyperlipidemia)
        guard let hyperlipidemiaDouble = Double(hyperlipidemiaString) else {
            throw DecodingError.dataCorruptedError(forKey: .hyperlipidemia, in: container, debugDescription: "血脂值應為可轉換為Double的字符串。")
        }
        hyperlipidemia = hyperlipidemiaDouble
        
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd "
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = formatter.date(from: dateString) {
            self.date = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "日期字符串與格式器預期的格式不匹配。")
        }
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
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.string(from: date)
}

struct HyperlipidemiaView: View
{
    let upperLimit: Double = 500.0
    @State private var displayMode: Int = 0  // 0 表示每日，1 表示每七日
    @State private var hyperlipidemia: String = ""
    @State private var chartData: [HyperlipidemiaRecord] = []
    @State private var isShowingList: Bool = false //列表控制
    @State private var scrollToBottom: Bool = false
    @State private var showAlert: Bool = false//
    
    func connect(name: String, action: String) {
        let url = URL(string: "http://163.17.9.107/food/\(name).php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "action=\(action)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let data = data {
                print(String(decoding: data, as: UTF8.self))  // 打印原始 JSON 数据
                do {
                    let responseArray = try JSONDecoder().decode([HyperlipidemiaRecord].self, from: data)
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
    func sendBPData(name: String, bl: Double, action: String) {
        let url = URL(string: "http://163.17.9.107/food/\(name).php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = "BL=\(bl)&action=\(action)"  // 確保 action 參數也被發送
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
                ScrollView(.horizontal) {
                                    Chart(displayMode == 0 ? chartData : averagesEverySevenRecords()) { record in
                                        LineMark(
                                            x: .value("Date", formattedDate(record.date)),
                                            y: .value("Hyperlipidemia", record.hyperlipidemia)
                                        )
                                        .lineStyle(.init(lineWidth: 3))

                                        PointMark(
                                            x: .value("Date", formattedDate(record.date)),
                                            y: .value("Hyperlipidemia", record.hyperlipidemia)
                                        )
                                        .annotation(position: .top) {
                                            Text("\(record.hyperlipidemia, specifier: "%.2f")")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color("textcolor"))
                                        }
                                    }
                                    .chartForegroundStyleScale([
                                        "血脂值": .orange
                                    ])
                                    .frame(width: max(350, Double(chartData.count) * 65), height: 200)
                                    .padding(.top, 20)
                }
                .padding()
                
                VStack
                {
                    HStack
                    {
                        Text("血脂值輸入") //血脂值輸入
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)
                            .foregroundColor(Color("textcolor"))
                        Picker("显示模式", selection: $displayMode) {
                            Text("每日").tag(0)
                            Text("每七日").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                    }
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
                                self.sendBPData(name: "BL", bl: hyperlipidemiaValue, action:"insert" )
                                self.connect(name: "BL", action: "fetch")
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
            .onAppear{
                self.connect(name: "BL", action: "fetch")
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
    private func averagesEverySevenRecords() -> [HyperlipidemiaRecord] {
        let sortedRecords = chartData.sorted { $0.date < $1.date }
        var results: [HyperlipidemiaRecord] = []
        let batchSize = 7

        for batchStart in stride(from: 0, to: sortedRecords.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, sortedRecords.count)
            let batch = Array(sortedRecords[batchStart..<batchEnd])
            let totalHyperlipidemia = batch.reduce(0.0) { $0 + $1.hyperlipidemia }
            if !batch.isEmpty {
                let averageHyperlipidemia = totalHyperlipidemia / Double(batch.count)
                let recordDate = batch.first!.date
                let avgRecord = HyperlipidemiaRecord(hyperlipidemia: averageHyperlipidemia, date: recordDate)
                results.append(avgRecord)
            }
        }

        return results
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
