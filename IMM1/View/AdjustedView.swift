//
//  AdjustView.swift
//  IM110CYUT
//
//  Created by Ｍac on 2023/11/26.
//


// MARK: 採買View
import SwiftUI

struct AdjustedDish 
{
    var dishName: String
    var components: [AdjustedIngredient]
}

struct AdjustedIngredient 
{
    var ingredientName: String
    var amount: String
}

struct AdjustedPlan 
{
    var planDays: Int
    var dishes: [AdjustedDish]
}



struct AdjustedDishItemView: View 
{
    @Binding var dishes: [AdjustedDish]
    
    var onDishSelected: (AdjustedDish) -> Void
    
    var body: some View 
    {
        List
        {
            ForEach(Array(dishes.enumerated()), id: \.element.dishName) 
            { index, dish in
                ForEach(dish.components.indices, id: \.self)
                { componentIndex in
                    HStack
                    {
                        VStack(alignment: .leading)
                        {
                            Text("菜餚名稱：\(dishes[index].components[componentIndex].ingredientName)")
                            Text("數量：\(dishes[index].components[componentIndex].amount)")
                        }
                        Spacer()
                    }
                }
                .onMove 
                { indices, newOffset in
                    // 處理食材重新排序
                    dishes[index].components.move(fromOffsets: indices, toOffset: newOffset)
                }
            }
        }
    }
}


struct AdjustedView: View 
{
    @State private var selectedDish: AdjustedDish?
    @State private var adjustedPlan = AdjustedPlan(planDays: 7, dishes: [])
    
    var body: some View 
    {
        NavigationView 
        {
            VStack 
            {
                AdjustedDishItemView(dishes: $adjustedPlan.dishes) { dish in
                    selectedDish = dish
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("調整計畫")
                .navigationBarItems(trailing: EditButton())
            }
        }
    }
}

struct AdjustedView_Previews: PreviewProvider 
{
    static var previews: some View 
    {
        AdjustedView()
    }
}
