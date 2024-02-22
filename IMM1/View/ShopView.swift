// MARK: 採購View

import SwiftUI

// Recipe.swift
struct Recipe
{
    var name: String
    var ingredients: [Ingredient]
}

struct Ingredient: Identifiable, Equatable
{
    var id = UUID()
    var name: String
    var quantity: String
    var quantityInput: String = ""
    var stock: Int
    
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool
    {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.quantity == rhs.quantity &&
        lhs.stock == rhs.stock
    }
}

// ShoppingList.swift
struct ShoppingList
{
    let days: Int
    var recipes: [Recipe]
}

struct IngredientRow: View
{
    var ingredient: Ingredient
    
    var body: some View
    {
        HStack
        {
            VStack(alignment: .leading)
            {
                Text("食材名稱: \(ingredient.name)")
                Text("數量: \(ingredient.quantity)")
            }
            Spacer()
            Image(systemName: "minus.circle")
                .foregroundColor(.red)
        }
    }
}

struct RecipeView: View
{
    @Binding var recipes: [Recipe]
    
    @State private var selectedIngredient: Ingredient?
    
    var onRecipeSelected: (Recipe) -> Void
    var onDeleteRecipe: (Recipe) -> Void
    var onDeleteIngredient: (Ingredient) -> Void
    
    var body: some View
    {
        if recipes.isEmpty
        {
            Text("目前無採買項目")
            
        } else
        {
            List
            {
                ForEach(Array(recipes.enumerated()), id: \.element.name) { index, recipe in
                    ForEach(recipe.ingredients.indices, id: \.self) { ingredientIndex in
                        let ingredient = recipes[index].ingredients[ingredientIndex]
                        HStack
                        {
                            VStack(alignment: .leading) // 左側文本
                            {
                                Text(" \(ingredient.name)")
                                HStack {
                                    Text("數量: \(ingredient.quantity)")
                                        .frame(width: 100, alignment: .leading)
                                        .padding(.trailing, -24)
                                    Spacer()
                                    Text("(庫存: \(ingredient.stock))")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .frame(width: 90, alignment: .leading)
                                        .padding(.leading, 0)
                                }
                            }
                            .frame(width: 200)
                            
                            TextField("數量", text: $recipes[index].ingredients[ingredientIndex].quantityInput) //在 TextField (數量輸入框)中添加 .onSubmit 來監聽回車事件
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit
                            {
                                updateQuantity(for: index, and: ingredientIndex) //在這裡執行確認操作，例如更新食材數量
                                recipes[index].ingredients[ingredientIndex].quantityInput = "" //清空數量輸入框
                            }
                            Image(systemName: selectedIngredient?.id == ingredient.id ? "checkmark.square" : "square") //選取標誌
                                .foregroundColor(.blue)
                                .onTapGesture
                            {
                                withAnimation
                                {
                                    if let selected = selectedIngredient
                                    {
                                        //如果已經有選擇的食材，並且是同一個食材，立即變更為 checkmark.square 並執行刪除操作
                                        if selected.id == ingredient.id
                                        {
                                            self.selectedIngredient = nil
                                            onDeleteIngredient(ingredient)
                                            return
                                        }
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) //延遲一秒後執行刪除操作
                                    {
                                        if self.selectedIngredient?.id == ingredient.id
                                        {
                                            onDeleteIngredient(ingredient)
                                        }
                                    } //否則，選擇新的食材
                                    self.selectedIngredient = ingredient
                                    updateQuantity(for: index, and: ingredientIndex)
                                }
                            }
                            .frame(width: 14)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
    
    private func getBinding(for recipeIndex: Int, and ingredientIndex: Int) -> Binding<String>
    {
        return Binding(
            get:
                {
                    recipes[recipeIndex].ingredients[ingredientIndex].quantityInput
                },
            set:
                { newValue in
                    recipes[recipeIndex].ingredients[ingredientIndex].quantityInput = newValue
                    
                    if let quantity = Int(newValue)
                    {
                        let existingUnit = separateQuantityAndUnit(recipes[recipeIndex].ingredients[ingredientIndex].quantity).unit
                        recipes[recipeIndex].ingredients[ingredientIndex].quantity = "\(quantity)" + existingUnit
                    }
                }
        )
    }
    private func separateQuantityAndUnit(_ input: String) -> (quantity: String, unit: String)
    {
        let numericCharacterSet = CharacterSet(charactersIn: "0123456789")
        let quantity = input.trimmingCharacters(in: numericCharacterSet.inverted) //找到數量部分
        let unit = input.trimmingCharacters(in: numericCharacterSet) //找到單位部分
        return (quantity, unit)
    }
    
    private func updateQuantity(for recipeIndex: Int, and ingredientIndex: Int)
    {
        if !recipes[recipeIndex].ingredients[ingredientIndex].quantityInput.isEmpty
        {
            let separatedValues = separateQuantityAndUnit(recipes[recipeIndex].ingredients[ingredientIndex].quantityInput) //分離數量和單位
            let currentValues = separateQuantityAndUnit(recipes[recipeIndex].ingredients[ingredientIndex].quantity) //分離原始數量和單位
        
            recipes[recipeIndex].ingredients[ingredientIndex].quantity = "\(separatedValues.quantity)" + currentValues.unit //更新數量，保留原來的單位

        }
    }
}

struct ShopView: View
{
    @State private var selectedRecipe: Recipe?
    @State private var shoppingList: ShoppingList = ShoppingList(days: 7, recipes: recipes)
    
    var body: some View
    {
        NavigationStack
        {
            VStack {
                Text("採購")
                RecipeView(
                    recipes: $shoppingList.recipes,
                    onRecipeSelected: { recipe in
                            selectedRecipe = recipe
                        },
                    onDeleteRecipe:{ recipe in
                            if let index = shoppingList.recipes.firstIndex(where: { $0.name == recipe.name })
                            {
                                shoppingList.recipes.remove(at: index)
                            }
                        },
                    onDeleteIngredient: { ingredient in
                        // MARK: 處理食材刪除邏輯
                        if let recipeIndex = shoppingList.recipes.firstIndex(where: { $0.ingredients.contains(where: { $0.id == ingredient.id }) })
                        {
                            if let ingredientIndex = shoppingList.recipes[recipeIndex].ingredients.firstIndex(where: { $0.id == ingredient.id })
                            {
                                shoppingList.recipes[recipeIndex].ingredients.remove(at: ingredientIndex)
                                
                                if shoppingList.recipes[recipeIndex].ingredients.isEmpty //如果食譜中沒有其他食材，則刪除整個食譜
                                {
                                    shoppingList.recipes.remove(at: recipeIndex)
                                }
                            }
                        }
                    }
                )
            }
        }
    }
}


// MARK: 預設的食譜
let recipes: [Recipe] = [
    Recipe(name: "義大利肉醬意大利麵", ingredients: [Ingredient(name: "義大利麵", quantity: "400克", stock: 50), Ingredient(name: "碎牛肉", quantity: "300克", stock: 30)]),
    Recipe(name: "烤雞", ingredients: [Ingredient(name: "雞腿", quantity: "4片", stock: 20), Ingredient(name: "橄欖油", quantity: "2湯匙", stock: 40), Ingredient(name: "迷迭香", quantity: "1茶匙", stock: 15)]),
    Recipe(name: "水煮魚", ingredients: [Ingredient(name: "魚片", quantity: "500克", stock: 50), Ingredient(name: "花椒", quantity: "适量", stock: 50), Ingredient(name: "薑", quantity: "适量", stock: 50)]),
]

struct ShopView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ShopView()
    }
}
