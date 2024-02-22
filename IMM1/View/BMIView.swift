
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

struct BMIRecord: Identifiable 
{
    var id = UUID()
    var height: Double
    var weight: Double
    var bmi: Double
    var date: Date
    
    init(height: Double, weight: Double) 
    {
        self.height = height
        self.weight = weight
        self.bmi = weight / ((height / 100) * (height / 100))
        self.date = Date()
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
    @State private var height: String = ""
    @State private var weight: String = ""
    
    @ObservedObject private var bmiRecordViewModel = BMIRecordViewModel()
    @ObservedObject private var temperatureSensorViewModel = TemperatureSensorViewModel(allSensors: [TemperatureSensor(id: "BMI", records: [])])
    
    @State private var isShowingList: Bool = false
    @State private var isShowingDetailSheet: Bool = false
    
    
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
                        Chart(temperatureSensorViewModel.allSensors) 
                        {
                            sensor in
                            let groupedRecords = Dictionary(grouping: sensor.records, by: { formattedDate($0.date) })
                            let latestRecords = groupedRecords.mapValues { $0.last! }
                            
                            ForEach(latestRecords.sorted(by: { $0.key < $1.key }), id: \.key) 
                            {
                                date, record in
                                LineMark(
                                    x: .value("Day", date),
                                    y: .value("Value", record.bmi)
                                )
                                .lineStyle(.init(lineWidth: 5))
                                
                                PointMark(
                                    x: .value("Day", date),
                                    y: .value("Value", record.bmi)
                                )
                                .annotation(position: .top) 
                                {
                                    Text("\(record.bmi, specifier: "%.2f")")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("textcolor"))
                                }
                            }
                            
                            .foregroundStyle(by: .value("Location", sensor.id))
                            .symbol(by: .value("Sensor Location", sensor.id))
                            .symbolSize(100)
                        }
                        .chartForegroundStyleScale(["BMI": .orange])
                        
                        .frame(width: 350, height: 200)
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
                    
                    Button(action:
                            {
                        if let heightValue = Double(height), let weightValue = Double(weight)
                        {
                            if let existingRecordIndex = bmiRecordViewModel.bmiRecords.firstIndex(where:
                                                                                                    { formattedDate($0.date) == formattedDate(Date()) }) {
                                bmiRecordViewModel.bmiRecords[existingRecordIndex].height = heightValue
                                bmiRecordViewModel.bmiRecords[existingRecordIndex].weight = weightValue
                                bmiRecordViewModel.bmiRecords[existingRecordIndex].bmi = weightValue / ((heightValue / 100) * (heightValue / 100))
                            }
                            else
                            {
                                let newRecord = BMIRecord(height: heightValue, weight: weightValue)
                                bmiRecordViewModel.bmiRecords.append(newRecord)
                            }
                            
                            if let existingSensorIndex = temperatureSensorViewModel.allSensors.firstIndex(where: { $0.id == "BMI" }) {
                                if let existingRecordIndex = temperatureSensorViewModel.allSensors[existingSensorIndex].records.firstIndex(where: { formattedDate($0.date) == formattedDate(Date()) }) {
                                    temperatureSensorViewModel.allSensors[existingSensorIndex].records[existingRecordIndex].height = heightValue
                                    temperatureSensorViewModel.allSensors[existingSensorIndex].records[existingRecordIndex].weight = weightValue
                                    temperatureSensorViewModel.allSensors[existingSensorIndex].records[existingRecordIndex].bmi = weightValue / ((heightValue / 100) * (heightValue / 100))
                                }
                                else
                                {
                                    let newRecord = BMIRecord(height: heightValue, weight: weightValue)
                                    temperatureSensorViewModel.allSensors[existingSensorIndex].records.append(newRecord)
                                }
                            }
                            else
                            {
                                let newSensor = TemperatureSensor(id: "BMI", records: [BMIRecord(height: heightValue, weight: weightValue)])
                                temperatureSensorViewModel.allSensors.append(newSensor)
                            }
                            
                            height = ""
                            weight = ""
                            
                            isShowingDetailSheet.toggle()
                            
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
                            BMIRecordDetailView(record: bmiRecordViewModel.bmiRecords.last ?? BMIRecord(height: 0, weight: 0))
                        }
                    }
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
            Text("身高: \(String(format: "%.1f", record.height)) 公分")
            Text("體重: \(String(format: "%.1f", record.weight)) 公斤")
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
