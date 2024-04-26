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
struct HyperglycemiaRecord: Identifiable,Codable
{
    var id = UUID()
    var hyperglycemia: Double
    var date: Date
    
    enum CodingKeys: String, CodingKey {
        case hyperglycemia = "BS"
        case date = "BS_DT"
    }
    
    init(hyperglycemia: Double)
    {
        self.hyperglycemia = hyperglycemia
        self.date = Date()
    }
    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hyperglycemiaString = try container.decode(String.self, forKey: .hyperglycemia)
        guard let hyperglycemiaDouble = Double(hyperglycemiaString) else {
            throw DecodingError.dataCorruptedError(forKey: .hyperglycemia, in: container, debugDescription: "血壓值應為可轉換為Double的字符串。")
        }
        hyperglycemia = hyperglycemiaDouble
        
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
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.string(from: date)
}

struct HyperglycemiaView: View
{
    let upperLimit: Double = 300.0
    
    @State private var hyperglycemia: String = ""
    @State private var chartData: [HyperglycemiaRecord] = []
    @State private var isShowingList: Bool = false
    @State private var scrollToBottom: Bool = false
    @State private var showAlert: Bool = false
    
    func connect(name: String, action: String) {
        let url = URL(string: "http://163.17.9.107/food/\(name).php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "action=\(action)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let data = data {
                print(String(decoding: data, as: UTF8.self))  // 打印原始 JSON 数据
                do {
                    let responseArray = try JSONDecoder().decode([HyperglycemiaRecord].self, from: data)
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
    func sendBPData(name: String, bs: Double, action: String) {
        let url = URL(string: "http://163.17.9.107/food/\(name).php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = "BS=\(bs)&action=\(action)"  // 確保 action 參數也被發送
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
                                self.sendBPData(name: "BS", bs: hyperglycemiaValue, action:"insert" )
                                self.connect(name: "BS", action: "fetch")
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
            .onAppear{
                self.connect(name: "BS", action: "fetch")
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
