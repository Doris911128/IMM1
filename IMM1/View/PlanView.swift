// MARK: 計畫View
import SwiftUI
import Foundation


struct Plan: Codable {
    let P_ID: String
    let U_ID: String
    let Dis_ID: String
    let P_DT: String
    let P_Bought: String
    let Dis_name: String
}




struct PlanView: View {
    // DateFormatter for formatting dates
    private let dateFormatter: DateFormatter
    
    @State private var plans: [String: [String]] = [:]
    
    // DateFormatter for displaying dates in MM/DD format
    private var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    func convertPlansToDictionary(plans: [Plan]) -> [String: [String]] {
        var plansDict = [String: [String]]()
        let currentDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 6, to: currentDate)!
        
        // 遍歷七天內的日期，初始化字典中的鍵
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: currentDate) {
                plansDict[dateFormatter.string(from: date)] = []
            }
        }
        
        // 將計畫數據添加到字典中
        for plan in plans {
            guard let planDate = dateFormatter.date(from: plan.P_DT) else {
                continue
            }
            // 檢查計畫日期是否在接下來的七天內，並添加到相應的日期中
            if planDate >= currentDate && planDate <= endDate {
                let date = dateFormatter.string(from: planDate)
                if plansDict[date] == nil {
                    plansDict[date] = []
                }
                plansDict[date]?.append(plan.Dis_name)
            }
        }
        return plansDict
    }


    // 修改 fetchPlansFromServer 的調用和處理
    func updatePlans() {
        fetchPlansFromServer { plans, error in
            if let plans = plans {
                DispatchQueue.main.async {
                    self.plans = convertPlansToDictionary(plans: plans) // 轉換後更新狀態
                }
            } else if let error = error {
                print("Failed to fetch plans: \(error)")
            }
        }
    }

    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text("計畫")
                List {
                    ForEach(Array(plans.keys.sorted(by: <)), id: \.self) { day in
                        Section(header:
                            HStack {
                                Text(self.displayDateFormatter.string(from: dateFormatter.date(from: day)!)).font(.title)
                                Text(getDayLabelText(for: day)) // 顯示 "第一天" 到 "第七天" 的文本
                                Spacer()
                                Button(action: {
                                    plans[day]?.append("新計畫")
                                }) {
                                    Image(systemName: "plus.circle")
                                        .imageScale(.large)
                                        .foregroundColor(.blue)
                                }
                            }
                        ) {
                            if let dayPlans = plans[day] {
                                ForEach(dayPlans.indices, id: \.self) { index in
                                    let plan = dayPlans[index]
                                    NavigationLink(destination: EditPlanView(day: day, planIndex: index, plans: $plans)) {
                                        Text(plan).font(.headline)
                                    }
                                }
                                .onDelete { indices in
                                    plans[day]?.remove(atOffsets: indices)
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .onAppear {
            updatePlans() // 在視圖顯示時獲取計畫
        }
    }

    // MARK: 根據日期獲取 "第一天" 到 "第七天" 的文本
    private func getDayLabelText(for date: String) -> String {
        guard let index = Array(plans.keys.sorted(by: <)).firstIndex(of: date) else {
            return ""
        }
        let dayNumber = (index % 7) + 1
        return "第\(dayNumber)天"
    }
}



struct PlanView_Previews: PreviewProvider
{
    static var previews: some View
    {
        PlanView()
    }
}



func fetchPlansFromServer(completion: @escaping ([Plan]?, Error?) -> Void) {
    guard let url = URL(string: "http://163.17.9.107/food/Plan.php") else {
        print("Invalid URL")
        completion(nil, NSError(domain: "InvalidURL", code: 0, userInfo: nil))
        return
    }
    
    URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Error: Invalid HTTP response")
            completion(nil, NSError(domain: "HTTPError", code: 0, userInfo: nil))
            return
        }
        
        guard let jsonData = data else {
            print("Error: No data received")
            completion(nil, NSError(domain: "NoDataError", code: 0, userInfo: nil))
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let plans = try decoder.decode([Plan].self, from: jsonData)
            completion(plans, nil)
        } catch {
            print("Error decoding JSON: \(error)")
            completion(nil, error)
        }
    }.resume()
}
