import SwiftUI

struct Cook: Codable, Identifiable {
    let id = UUID()
    let P_ID: String
    let U_ID: String
    let Dis_ID: String
    let P_DT: String
    let P_Bought: String
    let Dis_name: String

    enum CodingKeys: String, CodingKey {
        case P_ID
        case U_ID
        case Dis_ID
        case P_DT
        case P_Bought
        case Dis_name
    }
}

struct CookView: View {
    @State private var plans: [Cook] = []
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            VStack {
                Text("烹飪")
                    .offset(x: 0, y: 23)
                
                HStack {
                    Spacer()
                    if isEditing {
                        Button(action: {
                            isEditing.toggle()
                        }) {
                            Text("完成")
                        }
                        .padding(.trailing, 20)
                    } else {
                        Button(action: {
                            isEditing.toggle()
                        }) {
                            Text("編輯")
                        }
                        .padding(.trailing, 20)
                    }
                }
            }
            .padding(.top, -23)
            
            List {
                ForEach(computeDays(), id: \.self) { day in
                    VStack(alignment: .leading, spacing: 10) {
                        let dateString = day.dateString
                        Text("\(dateString) 第 \(day.dayIndex + 1) 天")
                            .font(.headline)
                        
                        let dayPlans = plans.filter { $0.P_DT == dateString }
                        if dayPlans.isEmpty {
                            Text("沒有計畫").font(.subheadline).foregroundColor(.gray)
                        } else {
                            ForEach(dayPlans, id: \.P_ID) { plan in
                                Text(plan.Dis_name).font(.subheadline)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let day = computeDays()[index].dateString
                        plans.removeAll { $0.P_DT == day }
                    }
                }
            }
            .onAppear {
                fetchCookPlansFromServer { fetchedPlans, error in
                    if let fetchedPlans = fetchedPlans {
                        DispatchQueue.main.async {
                            self.plans = fetchedPlans
                        }
                    } else if let error = error {
                        print("Failed to fetch plans: \(error)")
                    }
                }
            }
            .scrollIndicators(.hidden)
            .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
            
            NavigationLink(destination: NowView()) {
                Text("立即煮")
                    .padding()
            }
        }
    }

    func computeDays() -> [Day] {
        var days: [Day] = []
        for dayIndex in 0..<7 {
            if let targetDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: Date()) {
                let targetDateComponents = Calendar.current.dateComponents([.month, .day], from: targetDate)
                let dateString = "\(targetDateComponents.month ?? 0)/\(targetDateComponents.day ?? 0)"
                
                let day = Day(dateString: dateString, dayIndex: dayIndex)
                days.append(day)
            }
        }
        return days
    }
    
    struct Day: Hashable {
        let dateString: String
        let dayIndex: Int
    }
}

struct CookView_Previews: PreviewProvider {
    static var previews: some View {
        CookView()
    }
}

func fetchCookPlansFromServer(completion: @escaping ([Cook]?, Error?) -> Void) {
    guard let url = URL(string: "http://163.17.9.107/food/Plan.php") else {
        completion(nil, NSError(domain: "InvalidURL", code: 0, userInfo: nil))
        return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(nil, error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            completion(nil, NSError(domain: "HTTPError", code: 0, userInfo: nil))
            return
        }
        
        guard let data = data else {
            completion(nil, NSError(domain: "NoDataError", code: 0, userInfo: nil))
            return
        }
        
        do {
            // 打印原始的JSON数据
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Fetched JSON: \(jsonString)")
            }
            
            let plans = try JSONDecoder().decode([Cook].self, from: data)
            completion(plans, nil)
        } catch {
            completion(nil, error)
        }
    }.resume()
}
