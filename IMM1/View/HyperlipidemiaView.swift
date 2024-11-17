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
struct HyperlipidemiaRecord: Identifiable, Codable {
    var id = UUID()
    var hyperlipidemia: Double
    var date: Date
    
    enum CodingKeys: String, CodingKey {
        case hyperlipidemia = "BL"
        case date = "BL_DT"
    }
    
    init(hyperlipidemia: Double, date: Date = Date()) {
        self.hyperlipidemia = hyperlipidemia
        self.date = date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hyperlipidemiaString = try container.decode(String.self, forKey: .hyperlipidemia)
        guard let hyperlipidemiaDouble = Double(hyperlipidemiaString) else {
            throw DecodingError.dataCorruptedError(forKey: .hyperlipidemia, in: container, debugDescription: "血脂值應為可轉換為Double的字符串。")
        }
        self.hyperlipidemia = hyperlipidemiaDouble
        
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = formatter.date(from: dateString) {
            self.date = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "日期字符串與格式器預期的格式不匹配。")
        }
    }
    
    var category: String {
        switch hyperlipidemia {
        case ..<200:
            return "正常"
        case 200..<241:
            return "偏高"
        default:
            return "過高"
        }
    }
}

// MARK: 包含ID和高血脂相關紀錄數組
struct HyperlipidemiaTemperatureSensor: Identifiable {
    var id: String
    var records: [HyperlipidemiaRecord]
}

// MARK: 存取TemperatureSensor數據
var HyperlipidemiaallSensors: [HyperlipidemiaTemperatureSensor] = [
    .init(id: "血脂值", records: [])
]

// MARK: 日期func
private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.string(from: date)
}

struct HyperlipidemiaView: View {
    let upperLimit: Double = 500.0
    @State private var displayMode: Int = 0  // 0 表示每日，1 表示每七日
    @State private var hyperlipidemia: String = ""
    @State private var chartData: [HyperlipidemiaRecord] = []
    @State private var isShowingList: Bool = false //列表控制
    @State private var showAlert: Bool = false//
    @State private var animateChart = false // 控制圖表動畫的狀態
    @Environment(\.colorScheme) var colorScheme
    func connect(name: String, action: String) {
        let url = URL(string: "http://163.17.9.107/food/php/\(name).php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "action=\(action)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let data = data {
                print(String(decoding: data, as: UTF8.self))  // 打印原始 JSON 数据
                do {
                    let responseArray = try JSONDecoder().decode([HyperlipidemiaRecord].self, from: data)
                    DispatchQueue.main.async {
                        self.chartData = responseArray.reversed()
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
        let url = URL(string: "http://163.17.9.107/food/php/\(name).php")!
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
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("血脂紀錄")
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .frame(width: 300, height: 50)
                        .font(.system(size: 33, weight: .bold))
                        .offset(x: -60)
                    
                    Button(action: {
                        isShowingList.toggle()
                    }) {
                        Image(systemName: "list.dash")
                            .font(.title)
                            .foregroundColor(Color(.orange))
                            .padding()
                            .cornerRadius(10)
                            .padding(.trailing, 20)
                            .imageScale(.large)
                    }
                    .offset(x: 10)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        let records = displayMode == 0 ?
                        chartData :
                        (displayMode == 1 ? averagesEverySevenRecords() : averagesEveryThirtyRecords())
                        
                        let chartWidth = CGFloat(max(300, records.count * 50)) // 每個資料點間隔50，最小寬度300
                        
                        Chart(records) { record in
                            LineMark(
                                x: .value("Date", formattedDate(record.date)),
                                y: .value("Value", record.hyperlipidemia)
                            )
                            .lineStyle(.init(lineWidth: 2))  // 線條寬度2
                            .foregroundStyle(Color.orange)
                            .interpolationMethod(.catmullRom)  // 平滑曲線
                            
                            PointMark(
                                x: .value("Date", formattedDate(record.date)),
                                y: .value("Value", record.hyperlipidemia)
                                
                            )
                            .foregroundStyle(Color.orange)
                            .annotation(position: .top) {
                                Text("\(record.hyperlipidemia, specifier: "%.2f")")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.black)
                            }
                        }
                        .chartForegroundStyleScale(["血脂值": .orange])  // 設定圖表顏色樣式
                        .frame(width: chartWidth, height: 200)  // 動態調整寬度
                        .scaleEffect(animateChart ? 1 : 0.8)  // 縮放動畫
                        .opacity(animateChart ? 1 : 0)  // 淡入動畫
                        .animation(.easeInOut(duration: 0.8), value: animateChart)  // 平滑動畫
                        .chartXAxis {
                                   AxisMarks() { _ in
                                       AxisGridLine()
                                           .foregroundStyle(colorScheme == .dark ? Color.white : Color.black).foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                                       AxisTick()
                                       AxisValueLabel()
                                           .foregroundStyle(colorScheme == .dark ? Color.white : Color.black) // X 轴日期颜色
                                   }
                               }
                               // 设置 Y 轴的网格线颜色
                               .chartYAxis {
                                   AxisMarks() { _ in
                                       AxisGridLine()
                                           .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
                                       AxisTick()
                                       AxisValueLabel()
                                           .foregroundStyle(colorScheme == .dark ? Color.white : Color.black) // Y 轴标签颜色
                                   }
                               }
                    }
                    .padding()
                }
                .frame(width: 350, height: 250)
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.orange, lineWidth: 2))
                .shadow(color: Color.gray.opacity(0.3), radius: 10, x: 0, y: 5)
                
                
                VStack {
                    HStack {
                        Text("血脂值輸入") //血脂值輸入
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)
                            .foregroundColor(Color.black)
                        Picker("显示模式", selection: $displayMode) {
                            Text("每日").tag(0)
                            Text("每7日").tag(1)
                            Text("每30日").tag(2)
                        }
                        .accentColor(Color.orange)
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        
                    }
                    VStack(spacing: -5) //使用者輸入
                    {
                        TextField("請輸入血脂值", text: $hyperlipidemia)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { _ in }
                            .onChange(of: hyperlipidemia) { newValue in
                                if let newValue = Double(newValue), newValue > upperLimit {
                                    showAlert = true //當輸入的值超過上限時，會顯示警告
                                    hyperlipidemia = String(upperLimit) //將輸入值截斷為上限值
                                }
                            }
                        
                        Button(action: {
                            if let hyperlipidemiaValue = Double(hyperlipidemia) {
                                if hyperlipidemiaValue < 0 {
                                    showAlert = true
                                } else {
                                    self.sendBPData(name: "BL", bl: hyperlipidemiaValue, action:"insert")
                                    self.connect(name: "BL", action: "fetch")
                                    if let index = chartData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
                                        chartData[index].hyperlipidemia = hyperlipidemiaValue // 更新當天的值
                                    } else {
                                        let newRecord = HyperlipidemiaRecord(hyperlipidemia: hyperlipidemiaValue) // 新增一條紀錄
                                        chartData.append(newRecord)
                                    }
                                    hyperlipidemia = ""
                                }
                            }
                        }) {
                            Text("紀錄血脂")
                                .foregroundColor(Color("ButColor"))
                                .padding(10)
                                .frame(width: 300, height: 50)
                                .background(Color(.orange))
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
            .onAppear {
                withAnimation {
                    animateChart = true // 當頁面顯示時啟用動畫
                }
                connect(name: "BL", action: "fetch")
            }
            .sheet(isPresented: $isShowingList) {
                HyperlipidemiaRecordsListView(records: $chartData)
            }
            .alert(isPresented: $showAlert) { //超過上限警告
                Alert(
                    title: Text("警告"),
                    message: Text("輸入的血脂值需在 0 到 500 之間，請重新輸入。"),
                    dismissButton: .default(Text("確定"))
                )
            }
            .offset(y: -34)
        }
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
    
    private func averagesEveryThirtyRecords() -> [HyperlipidemiaRecord] {
        let sortedRecords = chartData.sorted { $0.date < $1.date }
        var results: [HyperlipidemiaRecord] = []
        let batchSize = 30
        
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
struct HyperlipidemiaRecordsListView: View {
    @Binding var records: [HyperlipidemiaRecord]
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        NavigationStack {
            List {
                ForEach(records.indices, id: \.self) { index in
                    NavigationLink(destination: HyperlipidemiaRecordDetailViewPager(records: records, selectedIndex: index)) {
                        HStack {
                            hyperlipidemiaImage(for: records[index])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .padding(8)
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.orange, lineWidth: 1)
                                )
                                .padding(.trailing, 8)
                                .foregroundColor(categoryColor(for: records[index]))
                            VStack(alignment: .leading) {
                                Text(records[index].category)
                                Text("\(formattedDate(records[index].date)): \(records[index].hyperlipidemia, specifier: "%.2f")")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }
                
                .onDelete(perform: deleteRecord)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            .navigationTitle("血脂紀錄列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
        .foregroundColor(.orange)
    }
    
    private func deleteRecord(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
    }
    
    private func hyperlipidemiaImage(for record: HyperlipidemiaRecord) -> Image {
        switch record.category {
        case "正常": return Image(systemName: "drop.circle")
        case "偏高": return Image(systemName: "drop.circle")
        case "過高": return Image(systemName: "drop.circle")
        default: return Image(systemName: "drop.circle")
        }
    }
    
    private func categoryColor(for record: HyperlipidemiaRecord) -> Color {
        switch record.category {
        case "正常": return Color.green
        case "偏高": return Color.yellow
        case "過高": return Color.red
        default: return Color.red
        }
    }
}

// MARK: 可滑動的血脂紀錄詳細視圖
struct HyperlipidemiaRecordDetailViewPager: View {
    let records: [HyperlipidemiaRecord]
    @State var selectedIndex: Int
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(records.indices, id: \.self) { index in
                HyperlipidemiaRecordDetailView(record: records[index])
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

// MARK: 編輯血脂紀錄視圖
struct HyperlipidemiaRecordDetailView: View {
    var record: HyperlipidemiaRecord
    
    var body: some View {
        VStack {
            hyperlipidemiaImage(for: record)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
                .padding()
                .cornerRadius(100)
                .foregroundColor(categoryColor(for: record))
                .overlay(
                    Circle()
                        .stroke(LinearGradient(
                            gradient: Gradient(colors: [categoryColor(for: record), .white]),
                            startPoint: .top,
                            endPoint: .bottom),
                                lineWidth: 4)
                )
                .padding()
            
            colorLegend
                .frame(height: 20)
                .padding(.bottom, 60)
            Text("日期：\(formattedDate(record.date))")
                .font(.title2)
                .padding(.bottom, 10)
            Text("血脂：\(String(format: "%.2f", record.hyperlipidemia))")
                .font(.title2)
                .padding(.bottom, 5)
            Text("分類：\(record.category)")
                .foregroundColor(Color("BottonColor"))
                .font(.title2)
                .padding(.bottom, 5)
        }
        .navigationTitle("血脂 詳細資訊")
    }
    
    private func hyperlipidemiaImage(for record: HyperlipidemiaRecord) -> Image {
        switch record.category {
        case "正常": return Image(systemName: "drop.circle")
        case "偏高": return Image(systemName: "drop.circle")
        case "過高": return Image(systemName: "drop.circle")
        default: return Image(systemName: "drop.circle")
        }
    }
    
    private func categoryColor(for record: HyperlipidemiaRecord) -> Color {
        switch record.category {
        case "正常": return Color.green
        case "偏高": return Color.yellow
        case "過高": return Color.red
        default: return Color.red
        }
    }
}

// MARK: ColorLegend
private var colorLegend: some View {
    HStack(spacing: 0) {
        ColorBox(color: .green, label: "正常")
        ColorBox(color: .yellow, label: "偏高")
        ColorBox(color: .red, label: "過高")
    }
    .padding()
}

private struct ColorBox: View {
    var color: Color
    var label: String
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: 20, height: 20)
            Text(label)
                .font(.caption)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HyperlipidemiaView_Previews: PreviewProvider {
    static var previews: some View {
        HyperlipidemiaView()
    }
}
