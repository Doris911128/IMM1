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
struct HyperglycemiaRecord: Identifiable, Codable {
    var id = UUID()
    var hyperglycemia: Double
    var date: Date
    
    enum CodingKeys: String, CodingKey {
        case hyperglycemia = "BS"
        case date = "BS_DT"
    }
    
    init(hyperglycemia: Double, date: Date = Date()) {
        self.hyperglycemia = hyperglycemia
        self.date = date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hyperglycemiaString = try container.decode(String.self, forKey: .hyperglycemia)
        guard let hyperglycemiaDouble = Double(hyperglycemiaString) else {
            throw DecodingError.dataCorruptedError(forKey: .hyperglycemia, in: container, debugDescription: "血糖值应为可转换为Double的字符串。")
        }
        self.hyperglycemia = hyperglycemiaDouble
        
        let dateString = try container.decode(String.self, forKey: .date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = formatter.date(from: dateString) {
            self.date = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "日期字符串与格式器预期的格式不匹配。")
        }
    }
    
    var category: String {
        switch hyperglycemia {
        case ..<70:
            return "低血糖"
        case 70..<100:
            return "正常"
        case 100..<125:
            return "偏高"
        default:
            return "糖尿病"
        }
    }
}

struct HyperglycemiaTemperatureSensor: Identifiable {
    var id: String
    var records: [HyperglycemiaRecord]
}

var HyperglycemiaallSensors: [HyperglycemiaTemperatureSensor] = [
    .init(id: "血糖值", records: [])
]

private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter.string(from: date)
}

struct HyperglycemiaView: View {
    let upperLimit: Double = 300.0
    @State private var displayMode: Int = 0
    @State private var hyperglycemia: String = ""
    @State private var chartData: [HyperglycemiaRecord] = []
    @State private var isShowingList: Bool = false
    @State private var showAlert: Bool = false
    @State private var animateChart = false
    @Environment(\.colorScheme) var colorScheme
    private func averagesEverySevenRecords() -> [HyperglycemiaRecord] {
        let sortedRecords = chartData.sorted { $0.date < $1.date }
        var results: [HyperglycemiaRecord] = []
        let batchSize = 7
        
        for batchStart in stride(from: 0, to: sortedRecords.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, sortedRecords.count)
            let batch = Array(sortedRecords[batchStart..<batchEnd])
            let totalHyperglycemia = batch.reduce(0.0) { $0 + $1.hyperglycemia }
            if !batch.isEmpty {
                let averageHyperglycemia = totalHyperglycemia / Double(batch.count)
                let recordDate = batch.first!.date
                let avgRecord = HyperglycemiaRecord(hyperglycemia: averageHyperglycemia, date: recordDate)
                results.append(avgRecord)
            }
        }
        
        return results
    }
    
    private func averagesEveryThirtyRecords() -> [HyperglycemiaRecord] {
        let sortedRecords = chartData.sorted { $0.date < $1.date }
        var results: [HyperglycemiaRecord] = []
        let batchSize = 30
        
        for batchStart in stride(from: 0, to: sortedRecords.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, sortedRecords.count)
            let batch = Array(sortedRecords[batchStart..<batchEnd])
            let totalHyperglycemia = batch.reduce(0.0) { $0 + $1.hyperglycemia }
            if !batch.isEmpty {
                let averageHyperglycemia = totalHyperglycemia / Double(batch.count)
                let recordDate = batch.first!.date
                let avgRecord = HyperglycemiaRecord(hyperglycemia: averageHyperglycemia, date: recordDate)
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
                    let responseArray = try JSONDecoder().decode([HyperglycemiaRecord].self, from: data)
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
    
    func sendBPData(name: String, bs: Double, action: String) {
        let url = URL(string: "http://163.17.9.107/food/php/\(name).php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postData = "BS=\(bs)&action=\(action)"
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
                    Text("血糖紀錄")
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
                        
                        let chartWidth = CGFloat(max(300, records.count * 50)) // 動態寬度，50 為每個點的間隔
                        
                        Chart(records) { record in
                            LineMark(
                                x: .value("Date", formattedDate(record.date)),
                                y: .value("Value", record.hyperglycemia)
                            )
                            .lineStyle(.init(lineWidth: 2))  // 線條寬度
                            .foregroundStyle(Color.orange)
                            .interpolationMethod(.catmullRom)  // 平滑曲線
                            
                            PointMark(
                                x: .value("Date", formattedDate(record.date)),
                                y: .value("Value", record.hyperglycemia)
                            )
                            .foregroundStyle(Color.orange)
                            .annotation(position: .top) {
                                Text("\(record.hyperglycemia, specifier: "%.2f")")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.black)
                            }
                        }
                        .chartForegroundStyleScale(["血糖值": .orange])  // 設定圖表顏色樣式
                        .frame(width: chartWidth, height: 200)  // 動態寬度
                        .scaleEffect(animateChart ? 1 : 0.8)  // 動畫縮放效果
                        .opacity(animateChart ? 1 : 0)  // 動畫透明度
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
                        Text("血糖值輸入")
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
                        TextField("請輸入血糖值", text: $hyperglycemia)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { _ in }
                            .onChange(of: hyperglycemia) { newValue in
                                if let newValue = Double(newValue), newValue > upperLimit {
                                    showAlert = true
                                    hyperglycemia = String(upperLimit)
                                }
                            }
                        
                        Button(action: {
                            if let hyperglycemiaValue = Double(hyperglycemia) {
                                self.sendBPData(name: "BS", bs: hyperglycemiaValue, action:"insert")
                                self.connect(name: "BS", action: "fetch")
                                if let index = chartData.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: Date()) }) {
                                    chartData[index].hyperglycemia = hyperglycemiaValue
                                } else {
                                    let newRecord = HyperglycemiaRecord(hyperglycemia: hyperglycemiaValue)
                                    chartData.append(newRecord)
                                }
                                hyperglycemia = ""
                            }
                        }) {
                            Text("紀錄血糖")
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
                    animateChart = true // 當頁面出現時啟動動畫
                }
            }
            .onAppear {
                self.connect(name: "BS", action: "fetch")
            }
            .sheet(isPresented: $isShowingList) {
                HyperglycemiaRecordsListView(records: $chartData)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("警告"),
                    message: Text("輸入的血糖值需在 0 到 300 之間，請重新輸入。"),
                    dismissButton: .default(Text("確定"))
                )
            }
            .offset(y: -34)
        }
    }
}

struct HyperglycemiaRecordsListView: View {
    @Binding var records: [HyperglycemiaRecord]
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        NavigationStack {
            List {
                ForEach(records.indices, id: \.self) { index in
                    NavigationLink(destination: HyperglycemiaRecordDetailViewPager(records: records, selectedIndex: index)) {
                        HStack {
                            hyperglycemiaImage(for: records[index])
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
                                Text("\(formattedDate(records[index].date)): \(records[index].hyperglycemia, specifier: "%.2f")")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }
                .onDelete(perform: deleteRecord)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            .navigationTitle("血糖紀錄列表")
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
    
    private func hyperglycemiaImage(for record: HyperglycemiaRecord) -> Image {
        return Image(systemName: "medical.thermometer")
    }
    
    private func categoryColor(for record: HyperglycemiaRecord) -> Color {
        switch record.category {
        case "低血糖": return Color.blue
        case "正常": return Color.green
        case "偏高": return Color.yellow
        case "糖尿病": return Color.red
        default: return Color.gray
        }
    }
}

// MARK: 可滑動的血糖紀錄詳細視圖
struct HyperglycemiaRecordDetailViewPager: View {
    let records: [HyperglycemiaRecord]
    @State var selectedIndex: Int
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(records.indices, id: \.self) { index in
                HyperglycemiaRecordDetailView(record: records[index])
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

// MARK: 血糖紀錄詳細資訊視圖
struct HyperglycemiaRecordDetailView: View {
    var record: HyperglycemiaRecord
    
    var body: some View {
        VStack {
            hyperglycemiaImage(for: record)
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
                .padding(.bottom, 40)
            Text("日期：\(formattedDate(record.date))")
                .font(.title2)
                .padding(.bottom, 10)
            
            Text("血糖：\(String(format: "%.2f", record.hyperglycemia))")
                .font(.title2)
                .padding(.bottom, 5)
            Text("分類：\(record.category)")
                .foregroundColor(Color("BottonColor"))
                .font(.title2)
                .padding(.bottom, 5)
        }
        .navigationTitle("血糖 詳細資訊")
    }
    
    private func hyperglycemiaImage(for record: HyperglycemiaRecord) -> Image {
        return Image(systemName: "medical.thermometer")
    }
    
    private func categoryColor(for record: HyperglycemiaRecord) -> Color {
        switch record.category {
        case "低血糖": return Color.blue
        case "正常": return Color.green
        case "偏高": return Color.yellow
        case "糖尿病": return Color.red
        default: return Color.gray
        }
    }
    
    private var colorLegend: some View {
        HStack(spacing: 0) {
            ColorBox(color: .blue, label: "低血糖")
            ColorBox(color: .green, label: "正常")
            ColorBox(color: .yellow, label: "偏高")
            ColorBox(color: .red, label: "糖尿病")
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

struct HyperglycemiaView_Previews: PreviewProvider {
    static var previews: some View {
        HyperglycemiaView()
    }
}
