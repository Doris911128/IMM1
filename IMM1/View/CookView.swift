//CookView
import SwiftUI

struct Cook: Codable, Identifiable
{
    let id = UUID()
    let P_ID: String
    let U_ID: String
    let Dis_ID: Int
    let P_DT: String
    let P_Bought: String
    let Dis_name: String
    
    enum CodingKeys: String, CodingKey
    {
        case P_ID
        case U_ID
        case Dis_ID
        case P_DT
        case P_Bought
        case Dis_name
    }
}

struct CookPlan: Codable, Identifiable
{
    let id = UUID()
    let P_ID: String
    let U_ID: String
    let Dis_ID: Int
    let P_DT: String
    let P_Bought: String
    let Dis_name: String
    let D_image: String
    
    enum CodingKeys: String, CodingKey
    {
        case P_ID
        case U_ID
        case Dis_ID
        case P_DT
        case P_Bought
        case Dis_name
        case D_image
    }
}

struct CookView: View
{
    @State private var plans: [CookPlan] = []
    @State private var isEditing = false
    
    var body: some View
    {
        NavigationView
        {
            VStack
            {
                HStack
                {
                    ForEach(computeDays(), id: \.self) { day in
                        Text(day.dateString)
                            .font(.system(size: 20, weight: .bold))
                            .padding(.top, 10)
                    }
                }
                
                ScrollViewReader
                { scrollView in
                    ScrollView(.horizontal)
                    {
                        LazyHStack(spacing: 20)
                        {
                            ForEach(computeDays(), id: \.self)
                            { day in
                                let dateString = day.dateString
                                
                                VStack(alignment: .leading, spacing: 10)
                                {
                                    let dayPlans = plans.filter { $0.P_DT == dateString }
                                    if dayPlans.isEmpty
                                    {
                                        Text("尚無計畫")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .padding(.leading, 150)
                                            .padding(.top, 300)
                                        Spacer()
                                    } else
                                    {
                                        LazyHStack(spacing: 10)
                                        {
                                            ForEach(dayPlans, id: \.P_ID) { plan in
                                                HStack
                                                {
                                                    NavigationLink(destination: MenuView(U_ID: "", Dis_ID: Int(plan.Dis_ID) ?? 0))
                                                    {
                                                        RecipeBlock(imageName: plan.D_image, title: plan.Dis_name, U_ID: plan.U_ID, Dis_ID: plan.Dis_ID)
                                                    }
                                                    
                                                    if isEditing
                                                    {
                                                        Button(action:
                                                                {
                                                            if let index = plans.firstIndex(where: { $0.P_ID == plan.P_ID }) {
                                                                plans.remove(at: index)
                                                            }
                                                        })
                                                        {
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
                                .frame(minHeight: 500) // 设置最小高度，确保日期部分在没有计划时也在正确位置
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onAppear
                    {
                        fetchCookPlansFromServer
                        { fetchedPlans, error in
                            if let fetchedPlans = fetchedPlans
                            {
                                DispatchQueue.main.async
                                {
                                    self.plans = fetchedPlans
                                }
                            } else if let error = error
                            {
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
    
    func computeDays() -> [Day]
    {
        var days: [Day] = []
        if let targetDate = Calendar.current.date(byAdding: .day, value: 0, to: Date())
        {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: targetDate)
            
            let day = Day(dateString: dateString, dayIndex: 0)
            days.append(day)
        }
        return days
    }
    
    struct Day: Hashable
    {
        let dateString: String
        let dayIndex: Int
    }
}

struct CookView_Previews: PreviewProvider
{
    static var previews: some View
    {
        CookView()
    }
}

func fetchCookPlansFromServer(completion: @escaping ([CookPlan]?, Error?) -> Void)
{
    guard let url = URL(string: "http://163.17.9.107/food/Cook.php") else {
        completion(nil, NSError(domain: "InvalidURL", code: 0, userInfo: nil))
        return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error
        {
            completion(nil, error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200
        else
        {
            completion(nil, NSError(domain: "HTTPError", code: 0, userInfo: nil))
            return
        }
        
        guard let data = data
        else
        {
            completion(nil, NSError(domain: "NoDataError", code: 0, userInfo: nil))
            return
        }
        
        do
        {
            if let jsonString = String(data: data, encoding: .utf8)
            {
                print("Fetched JSON: \(jsonString)")
            }
            
            let plans = try JSONDecoder().decode([CookPlan].self, from: data)
            completion(plans, nil)
        } catch
        {
            completion(nil, error)
        }
    }.resume()
}
