// MARK: 烹飪View
import SwiftUI

struct CookView: View {
    @State private var plans: [String: [String]] = [:]

    var body: some View {
        NavigationStack {
            VStack {
                Text("烹飪")
                HStack {
                    Spacer()
                    NavigationLink(destination: AdjustedView()) {
                        Text("調整計畫")
                            .offset(x: -20, y: -20)
                    }
                }

                List {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        VStack(alignment: .leading, spacing: 10) {
                            let currentDate = Calendar.current.dateComponents([.month, .day], from: Date())
                            if let targetDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: Date()) {
                                let targetDateComponents = Calendar.current.dateComponents([.month, .day], from: targetDate)
                                let dateString = "\(targetDateComponents.month ?? 0)/\(targetDateComponents.day ?? 0)"
                                Text("\(dateString) 第 \(dayIndex + 1) 天")
                                    .font(.headline)
                                    .padding(.bottom, 5)

                                // Check if plans for this date exist
                                if let dayPlans = plans[dateString] {
                                    ForEach(dayPlans, id: \.self) { plan in
                                        Text(plan).font(.subheadline)
                                    }
                                } else {
                                    Text("沒有計畫").font(.subheadline).foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }

                .onAppear {
                    print("CookView appeared. Refresh plans if needed.")
                    print("Current plans: \(plans)")
                }

                .padding(.top, -20)
                .scrollIndicators(.hidden)

                NavigationLink(destination: NowView()) {
                    Text("立即煮")
                        .padding()
                }
            }
        }
    }
}


struct CookView_Previews: PreviewProvider {
    static var previews: some View {
        CookView()
    }
}
