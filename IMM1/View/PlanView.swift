// MARK: 計畫View
import SwiftUI
import Foundation

struct Plan: Codable {
    let P_ID: String
    let U_ID: String
    let Dis_ID: Int
    let P_DT: Date
    let P_Bought: Bool
}

struct PlanView: View {
    // DateFormatter for formatting dates
    private let dateFormatter: DateFormatter
    
    @State private var plans: [String: [String]] = PlanManager.shared.loadPlans()
    
    // DateFormatter for displaying dates in MM/DD format
    private var displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var initialPlans: [String: [String]] = [:]
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: Date()) {
                let formattedDate = dateFormatter.string(from: date)
                initialPlans[formattedDate] = []
            }
        }
        _plans = State(initialValue: initialPlans)
    }

    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                Text("計畫")
                List
                {
                    ForEach(Array(plans.keys.sorted(by: <)), id: \.self) { day in
                        Section(header:
                                    HStack
                                {
                           
                            Text(self.displayDateFormatter.string(from: dateFormatter.date(from: day)!)).font(.title)
                            Text(getDayLabelText(for: day)) // 顯示 "第一天" 到 "第七天" 的文本
                            Spacer()
                            Button(action:
                                    {
                                plans[day]?.append("新計畫")
                            })
                            {
                                Image(systemName: "plus.circle")
                                    .imageScale(.large)
                                    .foregroundColor(.blue)
                            }
                        }
                        )
                        {
                            if let dayPlans = plans[day]
                            {
                                ForEach(dayPlans.indices, id: \.self) { index in
                                    let plan = dayPlans[index]
                                    NavigationLink(destination: EditPlanView(day: day, planIndex: index, plans: $plans))
                                    {
                                        Text(plan).font(.headline)
                                    }
                                }
                                .onDelete
                                { indices in
                                    plans[day]?.remove(atOffsets: indices)
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
    
    // MARK: 根據日期獲取 "第一天" 到 "第七天" 的文本
    private func getDayLabelText(for date: String) -> String
    {
        guard let index = Array(plans.keys.sorted(by: <)).firstIndex(of: date) else
        {
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
func savePlanToServer(plan: Plan) {
    guard let url = URL(string: "http://163.17.9.107/food/Plan.php") else {
        print("Invalid URL")
        return
    }
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601

    do {
        let jsonData = try encoder.encode(plan)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error saving plan: \(error)")
            } else if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response from server: \(responseString)")
                }
            }
        }.resume()
    } catch {
        print("Error encoding JSON: \(error)")
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
            decoder.dateDecodingStrategy = .iso8601
            let plans = try decoder.decode([Plan].self, from: jsonData)
            completion(plans, nil)
        } catch {
            print("Error decoding JSON: \(error)")
            completion(nil, error)
        }
    }.resume()
}

// Call this function to save a plan
//savePlanToServer(pID: "your_pID", uID: "your_uID", pDT: "your_pDT", pBought: 1)
