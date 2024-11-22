// 血壓（Blood Pressure）的英文縮寫是 BP

// MARK: 血壓View
import SwiftUI
import Charts

struct HypertensionRecord: Identifiable, Codable {
    var id = UUID()
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
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = formatter.date(from: dateString) {
            self.date = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "日期字符串與格式器預期的格式不匹配。")
        }
    }
    
    var category: String {
        switch hypertension {
        case ..<90:
            return "過低"
        case 90..<121:
            return "正常"
        case 121..<139:
            return "偏高"
        case 139..<159:
            return "過高"
        default:
            return "過高"
        }
    }
}

struct HypertensionTemperatureSensor: Identifiable {
    var id: String
    var records: [HypertensionRecord]
}

var HypertensionallSensors: [HypertensionTemperatureSensor] = [
    .init(id: "血壓值", records: [])
]

private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd HH:mm"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter.string(from: date)
}

struct HypertensionView: View {
    let upperLimit: Double = 400.0
    @Environment(\.colorScheme) var colorScheme
    @State private var displayMode: Int = 0
    @State private var hypertension: String = ""
    @State private var chartData: [HypertensionRecord] = []
    @State private var isShowingList: Bool = false
    @State private var showAlert: Bool = false
    @State private var animateChart = false
    
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
        let url = URL(string: "http://163.17.9.107/food/php/\(name).php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "action=\(action)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let data = data {
                print(String(decoding: data, as: UTF8.self))
                do {
                    let responseArray = try JSONDecoder().decode([HypertensionRecord].self, from: data)
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
    
    func sendBPData(name: String, bp: Double, action: String) {
        let url = URL(string: "http://163.17.9.107/food/php/\(name).php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = "BP=\(bp)&action=\(action)"
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
                    Text("血壓紀錄")
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
                                y: .value("Value", record.hypertension)
                            )
                            .lineStyle(.init(lineWidth: 2))  // 線條寬度2
                            .foregroundStyle(Color.orange)
                            .interpolationMethod(.catmullRom)  // 平滑曲線
                            
                            PointMark(
                                x: .value("Date", formattedDate(record.date)),
                                y: .value("Value", record.hypertension)
                            )
                            .foregroundStyle(Color.orange)
                            .annotation(position: .top) {
                                Text("\(record.hypertension, specifier: "%.2f")")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.black)
                            }
                        }
                        .chartForegroundStyleScale(["血壓值": .orange])  // 設定圖表顏色樣式
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
                        .accentColor(Color.orange)
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                    }
                    VStack(spacing: -5) {
                        TextField("請輸入血壓值", text: $hypertension)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onChange(of: hypertension) { newValue in
                                if let newValue = Double(newValue), newValue > upperLimit || newValue < 0 {
                                    showAlert = true
                                    hypertension = newValue > upperLimit ? String(upperLimit) : "0"
                                }
                            }
                        
                        Button(action: {
                            if let hypertensionValue = Double(hypertension), hypertensionValue >= 0 && hypertensionValue <= 400 {
                                self.sendBPData(name: "BP", bp: hypertensionValue, action: "insert")
                                self.connect(name: "BP", action: "fetch")
                                if let index = chartData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
                                    chartData[index].hypertension = hypertensionValue
                                } else {
                                    let newRecord = HypertensionRecord(hypertension: hypertensionValue)
                                    chartData.append(newRecord)
                                }
                                hypertension = ""
                            }
                        }) {
                            Text("紀錄血壓")
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
                connect(name: "BP", action: "fetch")
            }
            .sheet(isPresented: $isShowingList) {
                HypertensionRecordsListView(records: $chartData)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("警告"),
                    message: Text("輸入的血壓值需在 0 到 400 之間，請重新輸入。"),
                    dismissButton: .default(Text("確定"))
                )
            }
            .offset(y: -34)
        }
    }
}

struct HypertensionRecordsListView: View {
    @Binding var records: [HypertensionRecord]
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        NavigationStack {
            List {
                ForEach(records.indices, id: \.self) { index in
                    NavigationLink(destination: HypertensionRecordDetailViewPager(records: records, selectedIndex: index)) {
                        HStack {
                            hypertensionImage(for: records[index])
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
                                Text("\(formattedDate(records[index].date)): \(records[index].hypertension, specifier: "%.2f")")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }
                .onDelete(perform: deleteRecord)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            .navigationTitle("血壓紀錄列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
        .foregroundColor(.orange)
    }
    
    private func deleteRecord(at offsets: IndexSet) {
        // 获取要删除的血压值
        if let index = offsets.first {
            let bpToDelete = records[index].hypertension
            // 从本地数组中移除
            records.remove(atOffsets: offsets)
            // 调用删除函数从数据库中删除
            deleteBPRecord(bp: bpToDelete)
        }
    }
    func deleteBPRecord(bp: Double) {
        let url = URL(string: "http://163.17.9.107/food/php/BP.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = "BP=\(bp)&action=delete"
        request.httpBody = postData.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print("网络请求出错: \(error?.localizedDescription ?? "未知错误")")
                return
            }
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("服务器响应: \(jsonObject)")
                    // 处理响应（可选）
                } else {
                    print("收到非字典格式的 JSON 响应")
                }
            } catch {
                print("解码 JSON 失败: \(error)")
            }
        }.resume()
    }

    
    private func hypertensionImage(for record: HypertensionRecord) -> Image {
        switch record.category {
        case "過低":
            return Image(systemName: "waveform.path.ecg.rectangle")
        case "正常":
            return Image(systemName: "waveform.path.ecg.rectangle")
        case "偏高":
            return Image(systemName: "waveform.path.ecg.rectangle")
        case "過高":
            return Image(systemName: "waveform.path.ecg.rectangle")
        default:
            return Image(systemName: "waveform.path.ecg.rectangle")
        }
    }
    
    private func categoryColor(for record: HypertensionRecord) -> Color {
        switch record.category {
        case "過低": return Color.blue
        case "正常": return Color.green
        case "偏高": return Color.yellow
        case "過高": return Color.red
        default: return Color.gray
        }
    }
}

// MARK: 可滑動的血壓紀錄詳細視圖
struct HypertensionRecordDetailViewPager: View {
    let records: [HypertensionRecord]
    @State var selectedIndex: Int
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(records.indices, id: \.self) { index in
                HypertensionRecordDetailView(record: records[index])
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

// MARK: 血壓紀錄詳細資訊視圖
struct HypertensionRecordDetailView: View {
    var record: HypertensionRecord
    
    var body: some View {
        VStack {
            hypertensionImage(for: record)
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
                .foregroundColor(.orange)
            colorLegend
                .frame(height: 20)
                .padding(.bottom, 40)
            Text("日期：\(formattedDate(record.date))")
                .font(.title2)
                .padding(.bottom, 10)
            Text("血壓：\(String(format: "%.2f", record.hypertension))")
                .font(.title2)
                .padding(.bottom, 5)
            Text("分類：\(record.category)")
                .foregroundColor(Color("BottonColor"))
                .font(.title2)
                .padding(.bottom, 5)
        }
        .navigationTitle("血壓 詳細資訊")
    }
    
    private func hypertensionImage(for record: HypertensionRecord) -> Image {
        switch record.category {
        case "過低":
            return Image(systemName: "waveform.path.ecg.rectangle")
        case "正常":
            return Image(systemName: "waveform.path.ecg.rectangle")
        case "偏高":
            return Image(systemName: "waveform.path.ecg.rectangle")
        case "過高":
            return Image(systemName: "waveform.path.ecg.rectangle")
        default:
            return Image(systemName: "waveform.path.ecg.rectangle")
        }
    }
    
    private func categoryColor(for record: HypertensionRecord) -> Color {
        switch record.category {
        case "過低": return Color.blue
        case "正常": return Color.green
        case "偏高": return Color.yellow
        case "過高": return Color.red
        default: return Color.red
        }
    }
    
    private var colorLegend: some View {
        HStack(spacing: 0) {
            ColorBox(color: .blue, label: "偏低")
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
    
}

struct HypertensionView_Previews: PreviewProvider {
    static var previews: some View {
        HypertensionView()
    }
}
