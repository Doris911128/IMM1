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

struct CookPlan: Codable, Identifiable {
    let id = UUID()
    let P_ID: String
    let U_ID: String
    let Dis_ID: String
    let P_DT: String
    let P_Bought: String
    let Dis_name: String
    let D_image: String

    enum CodingKeys: String, CodingKey {
        case P_ID
        case U_ID
        case Dis_ID
        case P_DT
        case P_Bought
        case Dis_name
        case D_image
    }
}
struct CookView: View {
    @State private var plans: [CookPlan] = []
    @State private var isEditing = false
    
    struct RecipeBlock: View {
        let D_image: String
        let Dis_Name: String
        let U_ID: String
        let Dis_ID: String
        @State private var isFavorited: Bool
        
        init(imageName: String, title: String, U_ID: String, Dis_ID: String, isFavorited: Bool = false) {
            self.D_image = imageName
            self.Dis_Name = title
            self.U_ID = U_ID
            self.Dis_ID = Dis_ID
            self._isFavorited = State(initialValue: isFavorited)
        }
        
        var body: some View {
            VStack {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: D_image)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 330, height: 450)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Color.gray
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Button(action: {
                        withAnimation(.easeInOut.speed(3)) {
                            self.isFavorited.toggle()
                            toggleFavorite(U_ID: U_ID, Dis_ID: Dis_ID, isFavorited: isFavorited) { result in
                                switch result {
                                case .success(let responseString):
                                    print("Success: \(responseString)")
                                case .failure(let error):
                                    print("Error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: self.isFavorited ? "heart.fill" : "heart")
                                    .font(.title)
                                    .foregroundColor(.red)
                            )
                    }
                    .offset(x: -135, y: 510) // 調整按鈕位置
                    .padding(.trailing, 10)
                    .symbolEffect(.bounce, value: self.isFavorited)
                }
                
                HStack(alignment: .bottom) {
                    Text(Dis_Name)
                        .foregroundColor(.black)
                        .font(.system(size: 24))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 10)
                }
                .offset(y: -5)
            }
            .padding(.horizontal, 20)
            .offset(y: -40)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 日期顯示部分
                HStack {
                    ForEach(computeDays(), id: \.self) { day in
                        Text(day.dateString)
                            .font(.system(size: 20, weight: .bold))
                            .padding(.top, 10)
                    }
                }
                
                ScrollViewReader { scrollView in
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 20) {
                            ForEach(computeDays(), id: \.self) { day in
                                let dateString = day.dateString
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    let dayPlans = plans.filter { $0.P_DT == dateString }
                                    if dayPlans.isEmpty {
                                        Text("尚無計畫")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    } else {
                                        LazyHStack(spacing: 10) {
                                            ForEach(dayPlans, id: \.P_ID) { CookPlan in
                                                HStack {
                                                    NavigationLink(destination: MenuView(Dis_ID: Int(CookPlan.Dis_ID) ?? 0)) {
                                                        RecipeBlock(imageName: CookPlan.D_image, title: CookPlan.Dis_name, U_ID: CookPlan.U_ID, Dis_ID: CookPlan.Dis_ID)
                                                    }
                                                    
                                                    if isEditing {
                                                        Button(action: {
                                                            if let index = plans.firstIndex(where: { $0.P_ID == CookPlan.P_ID }) {
                                                                plans.remove(at: index)
                                                            }
                                                        }) {
                                                            Image(systemName: "minus.circle")
                                                                .foregroundColor(.red)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                .id(dateString)
                            }
                        }
                        .padding(.horizontal)
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
                }
            }
        }
    }
    
    func computeDays() -> [Day] {
        var days: [Day] = []
        if let targetDate = Calendar.current.date(byAdding: .day, value: 0, to: Date()) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: targetDate)
            
            let day = Day(dateString: dateString, dayIndex: 0)
            days.append(day)
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

func fetchCookPlansFromServer(completion: @escaping ([CookPlan]?, Error?) -> Void) {
    guard let url = URL(string: "http://163.17.9.107/food/Cook.php") else {
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
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Fetched JSON: \(jsonString)")
            }
            
            let plans = try JSONDecoder().decode([CookPlan].self, from: data)
            completion(plans, nil)
        } catch {
            completion(nil, error)
        }
    }.resume()
}
