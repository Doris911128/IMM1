import SwiftUI

struct CookView: View {
    
    @State private var plans: [String: [String]] = [:]
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("烹飪")
                    .offset(x:0,y:23)
                
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
            .padding(.top,-23)
            
            
            List {
                ForEach(computeDays(), id: \.self) { day in
                    VStack(alignment: .leading, spacing: 10) {
                        let dateString = day.dateString
                        Text("\(dateString) 第 \(day.dayIndex + 1) 天")
                            .font(.headline)
                        //                                .padding(.bottom, 5)
                        
                        if let dayPlans = plans[dateString] {
                            ForEach(dayPlans, id: \.self) { plan in
                                Text(plan).font(.subheadline)
                            }
                        } else {
                            Text("沒有計畫").font(.subheadline).foregroundColor(.gray)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        plans.removeValue(forKey: computeDays()[index].dateString)
                    }
                }
            }
            .onAppear {
                print("CookView appeared. Refresh plans if needed.")
                print("Current plans: \(plans)")
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
                
                // 隨機產生 1 到 3 個計畫
                let numPlans = Int.random(in: 1...3)
                var dayPlans: [String] = []
                for _ in 0..<numPlans {
                    dayPlans.append("計畫 \(Int.random(in: 1...1000))")
                }
                
                // 將計畫存入 plans 字典
                plans[dateString] = dayPlans
                
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
