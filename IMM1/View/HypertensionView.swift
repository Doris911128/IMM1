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
    
    @State private var displayMode: Int = 0
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
                        .foregroundColor(Color.black)
                        .frame(width: 300, height: 50)
                        .font(.system(size: 33, weight: .bold))
                        .offset(x: -60)
                    
                    Button(action: {
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
                        .foregroundStyle(Color.orange)
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
                    .chartForegroundStyleScale(["血壓值": .orange])
                    .frame(width: max(350, Double(chartData.count) * 100), height: 200) // 将宽度调整为每个数据点有更多空间
                    .padding(.top, 20)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.orange, lineWidth: 2))
                    .shadow(color: Color.gray.opacity(10), radius: 10, x: 0, y: 5)
                }
                .padding()
                
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
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                    }
                    VStack(spacing: -5) {
                        TextField("請輸入血壓值", text: $hypertension)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { _ in }
                            .onChange(of: hypertension) { newValue in
                                if let newValue = Double(newValue), newValue > upperLimit {
                                    showAlert = true
                                    hypertension = String(upperLimit)
                                }
                            }
                        
                        Button(action: {
                            if let hypertensionValue = Double(hypertension) {
                                self.sendBPData(name: "BP", bp: hypertensionValue, action:"insert")
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
            .onAppear {
                self.connect(name: "BP", action: "fetch")
            }
            .sheet(isPresented: $isShowingList) {
                HypertensionRecordsListView(records: $chartData)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("警告"),
                    message: Text("輸入的血壓值最高為400，請重新輸入。"),
                    dismissButton: .default(Text("確定"))
                )
            }
        }
    }
}

struct HypertensionRecordsListView: View {
    @Binding var records: [HypertensionRecord]

    var body: some View {
        NavigationStack {
            List {
                ForEach(records) { record in
                    NavigationLink(destination: HypertensionRecordDetailView(record: record)) {
                        HStack {
                            hypertensionImage(for: record)
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
                                .foregroundColor(categoryColor(for: record))
                            VStack(alignment: .leading) {
                                Text(record.category)
                                Text("\(formattedDate(record.date)): \(record.hypertension, specifier: "%.2f")")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }
                .onDelete(perform: deleteRecord)
            }
            .navigationTitle("血壓紀錄列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func deleteRecord(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
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
        case "過低":
            return Color.blue
        case "正常":
            return Color.green
        case "偏高":
            return Color.yellow
        case "過高":
            return Color.red
        default:
            return Color.gray
        }
    }
}

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
                //.offset(y: -50) // 向上移動圖片
        
            // Color Strip
            colorLegend
                .frame(height: 20)
                .padding(.bottom, 60)
            Text("血壓：\(String(format: "%.2f", record.hypertension))")
                .font(.title)
                .padding(.bottom, 5)
            Text("分類：\(record.category)")
                .foregroundColor(Color("BottonColor"))
                .font(.title)
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
            return Image(systemName: "waveform.path.ecg.rectanglee")
        default:
            return Image(systemName: "waveform.path.ecg.rectangle")
        }
    }

    private func categoryColor(for record: HypertensionRecord) -> Color {
        switch record.category {
        case "過低":
            return Color.blue
        case "正常":
            return Color.green
        case "偏高":
            return Color.yellow
        case "過高":
            return Color.red
        default:
            return Color.red
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
            .frame(maxWidth: .infinity) // 使每个 ColorBox 充满可用宽度
        }
    }
}

struct HypertensionView_Previews: PreviewProvider {
    static var previews: some View {
        HypertensionView()
    }
}
