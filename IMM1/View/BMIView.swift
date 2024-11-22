// MARK: BMIView

import SwiftUI
import Charts

class BMIRecordViewModel: ObservableObject
{
    @Published var bmiRecords: [BMIRecord]
    
    init(bmiRecords: [BMIRecord] = [])
    {
        self.bmiRecords = bmiRecords
    }
}

class TemperatureSensorViewModel: ObservableObject
{
    @Published var allSensors: [TemperatureSensor]
    
    init(allSensors: [TemperatureSensor] = [])
    {
        self.allSensors = allSensors
    }
}

struct BMIRecord: Identifiable, Decodable {
    var id = UUID()
    var H: Double
    var W: Double
    var bmi: Double
    var date: Date
    var timeStamp: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case H, W, date = "BMI_DT"
    }
    
    init(height: Double, weight: Double, date: Date) {
        self.H = height
        self.W = weight
        self.bmi = weight / ((height / 100) * (height / 100))
        self.date = date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let H = try container.decode(String.self, forKey: .H)
        let W = try container.decode(String.self, forKey: .W)
        let dateString = try container.decode(String.self, forKey: .date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let height = Double(H), let weight = Double(W), let date = dateFormatter.date(from: dateString) {
            self.init(height: height, weight: weight, date: date)
        } else {
            // Constructing the correct error if the date or numbers are not valid
            var errorDescription = ""
            if Double(H) == nil || Double(W) == nil {
                errorDescription += "Height or weight is not a valid number. "
            }
            if dateFormatter.date(from: dateString) == nil {
                errorDescription += "Date string does not match format yyyy-MM-dd."
            }
            
            // Correctly constructing and throwing a DecodingError
            let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: errorDescription)
            throw DecodingError.dataCorrupted(context)
        }
    }
}

struct TemperatureSensor: Identifiable
{
    var id: String
    var records: [BMIRecord]
}

private func formattedDate(_ date: Date) -> String
{
    let formatter = DateFormatter()
    formatter.dateFormat = "MM-dd"
    return formatter.string(from: date)
}


struct BMIView: View {
    @EnvironmentObject private var user: User
    @State private var height: String = ""
    @State private var weight: String = ""
    @Environment(\.colorScheme) var colorScheme // 获取系统的深浅模式
    @StateObject private var bmiRecordViewModel = BMIRecordViewModel()
    @StateObject private var temperatureSensorViewModel = TemperatureSensorViewModel(allSensors: [TemperatureSensor(id: "BMI", records: [])])
    @State private var displayMode: Int = 0 // 0 for Daily, 1 for Weekly
    @State private var isShowingList: Bool = false
    @State private var isShowingDetailSheet: Bool = false
    @State private var isLoading: Bool = true // Add a loading state
    @State private var animateChart = false // 控制圖表動畫的狀態
    // 控制 Alert 的顯示
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    func postBMI(height: Double, weight: Double, name: String) {
        guard let url = URL(string: "http://163.17.9.107/food/php/\(name).php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "H=\(String(height))&W=\(String(weight))"
        request.httpBody = postString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.bmiRecordViewModel.parseAndAddRecords(from: responseString)
                }
            }
        }.resume()
    }
    
    func connect(name: String) {
        let url: URL = URL(string: "http://163.17.9.107/food/php/\(name).php")!
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        print("Response from server: \(responseString)")
                        self.bmiRecordViewModel.parseAndAddRecords(from: responseString)
                        self.isLoading = false // Set loading state to false
                    }
                }
            } else if let error = error {
                print("Error: \(error)")
                self.isLoading = false // Ensure loading state is false in case of error
            }
        }.resume()
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("BMI紀錄")
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
                        bmiRecordViewModel.bmiRecords.reversed() :
                        (displayMode == 1 ?
                         bmiRecordViewModel.averagesEverySevenRecordsSorted().reversed() :
                            bmiRecordViewModel.averagesEveryThirtyRecordsSorted().reversed())
                        
                        let chartWidth = CGFloat(max(300, records.count * 50)) // 動態調整寬度
                        
                        Chart(records) { record in
                            LineMark(
                                x: .value("Date", formattedDate(record.date)),
                                y: .value("BMI", record.bmi)
                            )
                            .lineStyle(.init(lineWidth: 2)) // 線條寬度
                            .foregroundStyle(Color.orange)  // 統一顏色
                            .interpolationMethod(.catmullRom) // 平滑曲線
                            
                            PointMark(
                                x: .value("Date", formattedDate(record.date)),
                                y: .value("BMI", record.bmi)
                            )
                            .foregroundStyle(Color.orange)
                            .annotation(position: .top) {
                                Text("\(record.bmi, specifier: "%.2f")")
                                    .font(.system(size: 12))
                                    .foregroundColor(.black)
                            }
                        }
                        .chartForegroundStyleScale(["BMI值": .orange])
                        .frame(width: chartWidth, height: 200)
                        .scaleEffect(animateChart ? 1 : 0.8) // 縮放效果
                        .opacity(animateChart ? 1 : 0) // 動畫透明度
                        .animation(.easeInOut(duration: 0.8), value: animateChart) // 平滑動畫
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
                        Text("BMI計算")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 20)
                            .foregroundColor(Color("TextColor"))
                        
                        Picker("顯示模式", selection: $displayMode) {
                            Text("每日").tag(0)
                            Text("每7日").tag(1)
                            Text("每30日").tag(2)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(Color.orange)
                    }
                    
                    VStack(spacing: -5) {
                        TextField("請輸入身高（公分）", text: $height)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onChange(of: height) { newValue in
                                height = newValue.filter { "0123456789.".contains($0) }
                                if let heightValue = Double(height), !(0...300).contains(heightValue) {
                                    height = ""
                                    alertMessage = "身高超出範圍（0-300公分）！"
                                    showAlert = true
                                }
                            }
                        
                        TextField("請輸入體重（公斤）", text: $weight)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onChange(of: weight) { newValue in
                                weight = newValue.filter { "0123456789.".contains($0) }
                                if let weightValue = Double(weight), !(0...600).contains(weightValue) {
                                    weight = ""
                                    alertMessage = "體重超出範圍（0-600公斤）！"
                                    showAlert = true
                                }
                            }
                    }
                    
                    
                    Button(action: {
                        if let heightValue = Double(height), let weightValue = Double(weight) {
                            postBMI(height: heightValue, weight: weightValue, name: "BMI")
                            connect(name: "FindBMI")
                            
                            let today = Date()
                            let newRecord = BMIRecord(height: heightValue, weight: weightValue, date: today)
                            bmiRecordViewModel.addOrUpdateRecord(newRecord: newRecord)
                            
                            height = ""
                            weight = ""
                        }
                    }) {
                        Text("計算BMI")
                            .foregroundColor(Color("ButColor"))
                            .padding(10)
                            .frame(width: 300, height: 50)
                            .background(Color(.orange))
                            .cornerRadius(100)
                            .font(.title3)
                    }
                    .padding()
                    .offset(y: -20)
                    .sheet(isPresented: $isShowingList) {
                        NavigationStack {
                            BMIRecordsListView(records: $bmiRecordViewModel.bmiRecords, temperatureSensorViewModel: temperatureSensorViewModel)
                        }
                    }
                    .sheet(isPresented: $isShowingDetailSheet) {
                        NavigationStack {
                            BMIRecordDetailView(record: bmiRecordViewModel.bmiRecords.last ?? BMIRecord(height: 0, weight: 0, date: Date()))
                        }
                    }
                }
                .offset(y: 24)
            }
            .onAppear {
                withAnimation {
                    animateChart = true // 當頁面出現時啟動動畫
                }
            }
            .onAppear {
                if isLoading {
                    connect(name: "FindBMI")
                }
            }
            .onTapGesture {
                dismissKeyboard()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("輸入錯誤"), message: Text(alertMessage), dismissButton: .default(Text("確定")))
            }
            .padding(.bottom, 25)
            .offset(y: 0)
            .background(colorScheme == .dark ? Color.black : Color.white) // 深色模式使用灰色背景，浅色模式使用白色背景
        }
    }
}

struct BMIRecordsListView: View {
    @Binding var records: [BMIRecord]
    @ObservedObject var temperatureSensorViewModel: TemperatureSensorViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedIndex: Int = 0  // 新增選中的索引
    
    init(records: Binding<[BMIRecord]>, temperatureSensorViewModel: TemperatureSensorViewModel) {
        self._records = records
        self.temperatureSensorViewModel = temperatureSensorViewModel
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(records.reversed()), id: \.id) { record in
                    NavigationLink(destination: BMIRecordDetailViewPager(records: records, selectedIndex: records.firstIndex(where: { $0.id == record.id })!)) {
                        HStack {
                            bmiImage(for: record)
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
                            VStack(alignment: .leading) {
                                Text(BMIRecordDetailView.bmiCategory(for: record))
                                Text("\(formattedDate(record.date)): \(record.bmi, specifier: "%.2f")")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }
                .onDelete(perform: deleteRecord)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            }
            .navigationTitle("BMI紀錄列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
        .foregroundColor(.orange)
    }
    
    func deleteRecord(at offsets: IndexSet) {
        offsets.forEach { index in
            // 根據顯示順序反轉索引
            let recordToDelete = records.reversed()[index]

            // 刪除資料請求伺服器
            guard let url = URL(string: "http://163.17.9.107/food/php/deleteBMI.php") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let formattedDate: String = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.string(from: recordToDelete.date)
            }()
            
            let postData = "H=\(recordToDelete.H)&W=\(recordToDelete.W)&BMI_DT=\(formattedDate)"
            print("Deleting record with data: \(postData)") // 调试用日志
            request.httpBody = postData.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    print("删除请求出错: \(error?.localizedDescription ?? "未知错误")")
                    return
                }
                do {
                    if let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let status = response["status"] as? String, status == "success" {
                        // 成功刪除資料，更新本地陣列
                        DispatchQueue.main.async {
                            // 注意：這裡需要根據反轉後的資料索引進行刪除
                            if let indexToDelete = records.firstIndex(where: { $0.id == recordToDelete.id }) {
                                records.remove(at: indexToDelete)
                            }
                        }
                    } else {
                        print("删除失败: \(String(data: data, encoding: .utf8) ?? "无法解析的响应")")
                    }
                } catch {
                    print("解析响应失败: \(error)")
                }
            }.resume()
        }
    }



    private func bmiImage(for record: BMIRecord) -> Image {
        switch BMIRecordDetailView.bmiCategory(for: record) {
        case "過瘦": return Image("too_thin")
        case "標準": return Image("standard")
        case "過重": return Image("heavy")
        case "輕度肥胖": return Image("too_heavy")
        case "中度肥胖": return Image("mild_obesuty")
        default: return Image("sever_obesuty")
        }
    }
}

// MARK: BMIRecordDetailViewPager - 支援左右滑動的詳細檢視

struct BMIRecordDetailViewPager: View {
    let records: [BMIRecord]
    @State var selectedIndex: Int
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(records.indices.reversed(), id: \.self) { index in
                BMIRecordDetailView(record: records[index])
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}


extension Double
{
    func rounded(toPlaces places: Int) -> Double
    {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

struct BMIRecordDetailView: View {
    var record: BMIRecord
    
    var body: some View {
        VStack {
            bmiImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200) // 放大圖片
                .padding()
                .cornerRadius(100)
                .overlay(
                    Circle()
                        .stroke(LinearGradient(
                            gradient: Gradient(colors: [categoryColor, .white]),
                            startPoint: .top,
                            endPoint: .bottom),
                                lineWidth: 4) // 細邊框
                )
                .padding()
                .offset(y: -30) // 向上移動圖片
            
            // Color Strip
            colorLegend
                .frame(height: 20)
                .padding(.bottom, 30)
            
            
            Text("日期：\(formattedDate(record.date))")
                .font(.title2)
                .padding(.bottom, 5)
            Text("身高：\(String(format: "%.1f", record.H)) 公分")
                .font(.title2) // 放大字體
                .padding(.bottom,5)
            Text("體重：\(String(format: "%.1f", record.W)) 公斤")
                .font(.title2) // 放大字體
                .padding(.bottom,5)
            Text("BMI：\(String(format: "%.2f", record.bmi))")
                .font(.title2) // 放大字體
                .padding(.bottom,5)
            Text("分類：\(bmiCategory)")
                .foregroundColor(Color("BottonColor"))
                .font(.title2) // 放大字體
                .padding(.bottom,5)
        }
        .navigationTitle("BMI 詳細資訊")
    }
    
    var bmiCategory: String {
        BMIRecordDetailView.bmiCategory(for: record)
    }
    
    static func bmiCategory(for record: BMIRecord) -> String {
        switch record.bmi {
        case ..<18.5:
            return "過瘦"
        case 18.5..<24:
            return "標準"
        case 24..<27:
            return "過重"
        case 27..<30:
            return "輕度肥胖"
        case 30..<35:
            return "中度肥胖"
        default:
            return "重度肥胖"
        }
    }
    
    private var bmiImage: Image {
        switch bmiCategory {
        case "過瘦":
            return Image("too_thin")
        case "標準":
            return Image("standard")
        case "過重":
            return Image("heavy")
        case "輕度肥胖":
            return Image("too_heavy")
        case "中度肥胖":
            return Image("mild_obesuty")
        default:
            return Image("sever_obesuty")
        }
    }
    
    private var categoryColor: Color {
        switch record.bmi {
        case ..<18.5:
            return Color(red: 0.5, green: 0.5, blue: 0.2)
        case 18.5..<24:
            return .green
        case 24..<27:
            return .yellow
        case 27..<30:
            return .orange
        case 30..<35:
            return .orange
        default:
            return .red
        }
    }
    private var colorLegend: some View {
        HStack(spacing: 0) {
            ColorBox(color: Color(red: 0.5, green: 0.5, blue: 0.2), label: "過瘦")
            ColorBox(color: .green, label: "標準")
            ColorBox(color: .yellow, label: "過重")
            ColorBox(color: .orange, label: "輕度肥胖")
            ColorBox(color: .red, label: "重度肥胖")
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




struct BMIView_Previews: PreviewProvider
{
    static var previews: some View
    {
        BMIView()
    }
}
