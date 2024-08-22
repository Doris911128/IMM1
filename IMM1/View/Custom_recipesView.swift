//
//  Custom_recipesView.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/8/22.
//

import SwiftUI

struct Custom_recipesView: View {
    let U_ID: String // 用於添加收藏
    
    @State private var recipes: [Recipe] = []
    @State private var showingAddRecipeView = false
    @State private var selectedRecipe: Recipe? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("自訂食譜庫")
                    .font(.largeTitle)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                        ForEach(recipes) { recipe in
                            Button(action: {
                                selectedRecipe = recipe
                            }) {
                                Text(recipe.name)
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 100)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                }
                
                Button(action: {
                    showingAddRecipeView.toggle()
                }) {
                    Text("新增自訂食譜")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            .sheet(isPresented: $showingAddRecipeView) {
                AddRecipeView(recipes: $recipes)
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}

struct AddRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var recipes: [Recipe]
    
    @State private var name = ""
    @State private var ingredients = ""
    @State private var method = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("食物名稱")) {
                    TextField("輸入食物名稱", text: $name)
                }
                
                Section(header: Text("所需食材")) {
                    TextField("輸入所需食材", text: $ingredients)
                        .frame(height: 100)
                }
                
                Section(header: Text("製作方法")) {
                    TextEditor(text: $method)
                        .frame(height: 200)
                }
                
                Button(action: saveRecipe) {
                    Text("儲存")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("新增食譜")
        }
    }
    
    private func saveRecipe() {
        let newRecipe = Recipe(name: name, ingredients: ingredients, method: method)
        recipes.append(newRecipe)
        dismiss()
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(recipe.name)
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 10)
            
            Text("所需食材")
                .font(.headline)
            Text(recipe.ingredients)
                .padding(.bottom, 10)
            
            Text("製作方法")
                .font(.headline)
            Text(recipe.method)
                .padding(.bottom, 10)
            
            Spacer()
        }
        .padding()
        .navigationTitle("食譜內容")
    }
}

struct Recipe: Identifiable {
    let id = UUID()
    let name: String
    let ingredients: String
    let method: String
}

#Preview {
    Custom_recipesView(U_ID: "ofmyRwDdZy")
}
