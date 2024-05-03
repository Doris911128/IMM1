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


struct BMIView: View
{
    @EnvironmentObject private var user: User
    @State private var height: String = ""
    @State private var weight: String = ""
    
    @ObservedObject private var bmiRecordViewModel = BMIRecordViewModel()
    @ObservedObject private var temperatureSensorViewModel = TemperatureSensorViewModel(allSensors: [TemperatureSensor(id: "BMI", records: [])])
    
    @State private var isShowingList: Bool = false
    @State private var isShowingDetailSheet: Bool = false
    
    func postBMI(height: Double, weight: Double, name: String) {
        guard let url = URL(string: "http://163.17.9.107/food/\(name).php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 设置POST请求的body
        let postString = "H=\(String(height))&W=\(String(weight))"
        request.httpBody = postString.data(using: .utf8)

        // Print the body data to be sent
        print("Sending data to server: \(postString)") // 在這裡添加 print 語句

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    // 解析JSON字符串并将记录添加到ViewModel
                    self.bmiRecordViewModel.parseAndAddRecords(from: responseString)
                }
            }
        }.resume()
    }


    func connect(name: String)
    {
        let url: URL = URL(string: "http://163.17.9.107/food/\(name).php")!
        var request: URLRequest = URLRequest(url: url)
        
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let data = data
            {
                if let responseString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        // 解析 JSON 字串並將記錄添加到 ViewModel
                        self.bmiRecordViewModel.parseAndAddRecords(from: responseString)
                        //self.isShowingList = true // 顯示列表，如果需要
                    }
                }
            } else if let error = error {
                print("Error: \(error)")
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
                    Text("BMI紀錄")
                        .foregroundColor(Color("textcolor"))
                        .frame(width: 300, height: 50)
                        .font(.system(size: 33, weight: .bold))
                        .offset(x:-60)
                    
                    Button(action:
                            {
                        //self.connect(name: "Dynamics")
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
                    HStack(spacing: 30) {
                        Chart(bmiRecordViewModel.bmiRecords) { record in
                            LineMark(
                                x: .value("Date", formattedDate(record.date)),
                                y: .value("BMI", record.bmi)
                            )
                            .lineStyle(.init(lineWidth: 2))

                            PointMark(
                                x: .value("Date", formattedDate(record.date)),
                                y: .value("BMI", record.bmi)
                            )
                            .annotation(position: .top) {
                                Text("\(record.bmi, specifier: "%.2f")")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color("textcolor"))
                            }
                        }
                        .chartForegroundStyleScale(["BMI": .orange])
                        // 動態調整寬度
                        .frame(width: max(350, Double(bmiRecordViewModel.bmiRecords.count) * 65), height: 200)
                    }
                    .padding()
                }


                
                VStack(spacing: 10)
                {
                    Text("BMI計算")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                        .foregroundColor(Color("textcolor"))
                    
                    VStack(spacing: -5)
                    {
                        TextField("請輸入身高（公分）", text: $height)
                            .padding()
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { _ in
                                height = height.filter { "0123456789.".contains($0) }
                            }
                        
                        TextField("請輸入體重（公斤）", text: $weight)
                            .padding()
                            .offset(y: 0)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 330)
                            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { _ in
                                weight = weight.filter { "0123456789.".contains($0) }
                            }
                    }
                    
                    Button(action: {
                        if let heightValue = Double(height), let weightValue = Double(weight) {
                            // 调用postBMI发送数据
                            postBMI(height: heightValue, weight: weightValue, name: "BMI")
                            self.connect(name: "FindBMI")
                            // 其余逻辑保持不变
                            let today = Date()
                            let newRecord = BMIRecord(height: heightValue, weight: weightValue, date: today)
                            bmiRecordViewModel.addOrUpdateRecord(newRecord: newRecord)
                            
                            height = ""
                            weight = ""
                        }
                    }) {
                        Text("計算BMI")
                            .foregroundColor(Color("textcolor"))
                            .padding(10)
                            .frame(width: 300, height: 50)
                            .background(Color(hue: 0.031, saturation: 0.803, brightness: 0.983))
                            .cornerRadius(100)
                            .font(.title3)
                    }

                    .padding()
                    .offset(y: -20)
                    .sheet(isPresented: $isShowingList)
                    {
                        NavigationStack
                        {
                            BMIRecordsListView(records: $bmiRecordViewModel.bmiRecords, temperatureSensorViewModel: temperatureSensorViewModel)
                        }
                    }
                    .sheet(isPresented: $isShowingDetailSheet)
                    {
                        NavigationStack
                        {
                            BMIRecordDetailView(record: bmiRecordViewModel.bmiRecords.last ?? BMIRecord(height: 0, weight: 0, date: Date()))
                        }
                    }
                }.onAppear{
                    self.connect(name: "FindBMI")
                }
                .onTapGesture
                {
                    self.dismissKeyboard()
                }
                .padding(.bottom, 25)
            }
        }
    }
}

struct BMIRecordsListView: View
{
    @Binding var records: [BMIRecord]
    @ObservedObject var temperatureSensorViewModel: TemperatureSensorViewModel
    
    init(records: Binding<[BMIRecord]>, temperatureSensorViewModel: TemperatureSensorViewModel)
    {
        self._records = records
        self.temperatureSensorViewModel = temperatureSensorViewModel
    }
    
    var body: some View
    {
        NavigationStack
        {
            List
            {
                ForEach(records)
                {
                    record in
                    NavigationLink(destination: BMIRecordDetailView(record: record))
                    {
                        Text("\(formattedDate(record.date)): \(record.bmi, specifier: "%.2f")")
                    }
                }
                .onDelete(perform: deleteRecord)
            }
            .navigationTitle("BMI紀錄列表")
            .toolbar
            {
                ToolbarItem(placement: .navigationBarTrailing)
                {
                    EditButton()
                }
            }
        }
    }
    
    // MARK: 刪除
    private func deleteRecord(at offsets: IndexSet)
    {
        records.remove(atOffsets: offsets)
        
        if let sensorIndex = temperatureSensorViewModel.allSensors.firstIndex(where: { $0.id == "BMI" }) // 更新TemperatureSensor的records
        {
            temperatureSensorViewModel.allSensors[sensorIndex].records = records
        }
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

struct BMIRecordDetailView: View
{
    var record: BMIRecord
    var body: some View
    {
        VStack
        {
            bmiImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .padding()
            Text("身高: \(String(format: "%.1f", record.H)) 公分")
            Text("體重: \(String(format: "%.1f", record.W)) 公斤")
            Text("你的BMI為: \(String(format: "%.2f", record.bmi))")
            Text("BMI分類: \(bmiCategory)")
                .foregroundColor(categoryColor)
                .font(.headline)
        }
        .navigationTitle("BMI 詳細資訊")
    }
    
    private var bmiCategory: String
    {
        switch record.bmi
        {
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
    
    private var bmiImage: Image
    {
        switch bmiCategory
        {
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
    
    private var categoryColor: Color
    {
        switch record.bmi
        {
        case ..<18.5:
            return .blue
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
}


struct BMIView_Previews: PreviewProvider
{
    static var previews: some View
    {
        BMIView()
    }
}
