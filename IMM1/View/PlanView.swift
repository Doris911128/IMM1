// MARK: 計畫View
import SwiftUI

struct PlanView: View
{
    @State private var plans: [String: [String]] =
    {
        var initialPlans: [String: [String]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        
        for i in 0..<7
        {
            if let date = Calendar.current.date(byAdding: .day, value: i, to: Date())
            {
                let formattedDate = dateFormatter.string(from: date)
                initialPlans[formattedDate] = []
            }
        }
        return initialPlans
    }()
    
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
                            Text(day).font(.title)
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
func savePlanToServer(P_ID: String,U_ID: String,Dis_ID: String, P_DT: String,P_Bought:String) {
    guard let url = URL(string: "http://163.17.9.107/food/Plan.php") else {
        print("Invalid URL")
        return
    }
    
    let data: [String: Any] = [
        "P_ID":P_ID,
        "U_ID":U_ID,
        "Dis_ID": Dis_ID,
        "P_DT": P_DT,
        "P_Bought": P_Bought
        
    ]
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
    } catch {
        print("Error serializing JSON: \(error)")
    }
    
    URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("Error saving plan: \(error)")
        } else if let data = data {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response from server: \(responseString)")
            }
        }
    }.resume()
}


// Call this function to save a plan
//savePlanToServer(pID: "your_pID", uID: "your_uID", pDT: "your_pDT", pBought: 1)
