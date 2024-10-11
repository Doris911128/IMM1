//Favorite.swift最愛View
//
//  Created on 2023/8/18.
//

import SwiftUI

struct FavoriteView: View {
    let U_ID: String
    
    @State private var dishesData: [Dishes] = []
    @State private var selectedDish: Dishes? = nil
    @State private var isLoading: Bool = true
    @State private var loadingError: String? = nil
    @State private var categories: [Category] = [] // 更新為 Category 類型
    @State private var showAddCategoryAlert: Bool = false
    @State private var newCategoryName: String = ""
    @State private var selectedCategory: Category? = nil // 更新為 Category 類型
    @State private var showDeleteConfirmation: Bool = false
    @State private var categoryToDelete: Category? = nil
    @State private var isEditing: Bool = false
    @State private var editingCategory: Category? = nil
    @State private var editedCategoryName: String = ""
    @State private var isLongPressing: Bool = false // 用來標記是否在進行長按
    // 編輯按鈕的 action
    func editCategory(category: Category) {
        editedCategoryName = category.name
        editingCategory = category
        isEditing = true
    }

    struct Category: Identifiable, Decodable, Hashable {
        let id: Int // 對應 "category_id"
        var name: String // 對應 "category_name"，更改為 var 以便可以修改
        var isDeleting: Bool = false // 新增變量來控制顯示刪除按鈕
        
        private enum CodingKeys: String, CodingKey {
            case id = "category_id"
            case name = "category_name"
        }
    }

    func addCategory(name: String, U_ID: String) {
        guard let url = URL(string: "http://163.17.9.107/food/php/add_category.php") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "U_ID=\(U_ID)&category_name=\(name)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server error or invalid response")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            do {
                let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
                print("Response: \(String(describing: result))")
                DispatchQueue.main.async {
                    if let status = result?["status"], status == "success" {
                        let newCategory = Category(id: 0, name: name) // 新建 Category 對象，ID 暫時設為 0
                        categories.append(newCategory)
                    } else if let error = result?["error"] {
                        print("Error from server: \(error)")
                    }
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }
    func loadCategoriesFood(categoryId: Int) {
        guard let url = URL(string: "http://163.17.9.107/food/php/getDishesByCategory.php?category_id=\(categoryId)") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server error or invalid response")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let decoder = JSONDecoder()
                let dishes = try decoder.decode([Dishes].self, from: data)
                DispatchQueue.main.async {
                    self.dishesData = dishes
                    print("Loaded dishes: \(self.dishesData)")
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }

    func loadCategories() {
        guard let url = URL(string: "http://163.17.9.107/food/php/get_categories.php") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server error or invalid response")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let jsonString = String(data: data, encoding: .utf8)
                print("Raw JSON: \(String(describing: jsonString))")  // 調試輸出
                
                let decoder = JSONDecoder()
                let categoriesResponse = try decoder.decode([Category].self, from: data)
                DispatchQueue.main.async {
                    self.categories = categoriesResponse
                    print("Loaded categories: \(self.categories)") // 調試輸出
                    
                    // 不再自動選擇第一個分類，只加載所有食物
                    loadUFavData()
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }

    // Example: when the user selects a category
    func selectCategory(_ category: Category) {
        selectedCategory = category
        print("Selected category name: \(category.name), ID: \(category.id)")

        if let categoryId = selectedCategory?.id {
            loadCategoriesFood(categoryId: categoryId) // 传递正确的参数
        }
    }

    // 更新的 filteredDishes 計算屬性
    // 基於 Dis_ID 進行去重
    var filteredDishes: [Dishes] {
        if let selectedCategory = selectedCategory {
            let uniqueDishes = Dictionary(grouping: dishesData.filter { $0.category_id == selectedCategory.id }, by: { $0.Dis_ID })
                .compactMap { $0.value.first }
            return uniqueDishes
        } else {
            let uniqueDishes = Dictionary(grouping: dishesData, by: { $0.Dis_ID })
                .compactMap { $0.value.first }
            return uniqueDishes
        }
    }

    func deleteCategory(id: Int) {
        guard let url = URL(string: "http://163.17.9.107/food/php/categoriesdelete.php") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "category_id=\(id)&U_ID=\(U_ID)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("Error: \(error.localizedDescription)")
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    print("Server error or invalid response")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    print("No data received")
                }
                return
            }
            
            do {
                let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
                DispatchQueue.main.async {
                    if let status = result?["status"], status == "success" {
                        // 成功刪除，更新 UI
                        self.categories.removeAll { $0.id == id }
                        if selectedCategory?.id == id {
                            selectedCategory = nil
                        }
                        loadUFavData() // 在此處呼叫，刪除後立即重新加載
                    } else if let error = result?["error"] {
                        print("Error from server: \(error)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("JSON parsing error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    func loadUFavData() {
        let urlString = "http://163.17.9.107/food/php/Favorite.php"
        
        // 檢查 URL 是否有效
        guard let url = URL(string: urlString) else {
            print("生成的 URL 無效")
            self.isLoading = false
            self.loadingError = "無效的URL"
            return
        }

        // 配置請求
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // 發送請求
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            // 錯誤處理
            if let error = error {
                DispatchQueue.main.async {
                    self.loadingError = error.localizedDescription
                }
                return
            }

            // 確認 HTTP 狀態碼
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.loadingError = "伺服器錯誤"
                }
                return
            }

            // 處理響應資料
            if let data = data {
                do {
                    let jsonString = String(data: data, encoding: .utf8)
                    print("Raw JSON Response: \(String(describing: jsonString))")
                    
                    let decoder = JSONDecoder()
                    let dishes = try decoder.decode([Dishes].self, from: data)
                    DispatchQueue.main.async {
                        self.dishesData = dishes
                        print("Loaded dishes: \(self.dishesData)")
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.loadingError = "JSON 解析錯誤: \(error.localizedDescription)"
                    }
                    print("JSON parsing error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    func updateCategoryName(for category: Category, with newName: String) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            var updatedCategory = categories[index]
            updatedCategory.name = newName
            categories[index] = updatedCategory
        }
    }

    // 提交編輯的 action
    func updateCategory() {
        guard let category = editingCategory else { return }
        guard let url = URL(string: "http://163.17.9.107/food/php/update_category.php") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "category_id=\(category.id)&U_ID=\(U_ID)&category_name=\(editedCategoryName)"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server error or invalid response")
                return
            }
            DispatchQueue.main.async {
                updateCategoryName(for: category, with: editedCategoryName)
                isEditing = false
                editingCategory = nil
                editedCategoryName = ""
            }
        }.resume()
    }

    var body: some View {
          NavigationStack {
              VStack(alignment: .leading) {
                  HStack {
                      Text("我的最愛")
                          .font(.largeTitle)
                          .bold()
                      Spacer()
                      Button(action: {
                          showAddCategoryAlert = true
                      }) {
                          Image(systemName: "plus.circle.fill")
                              .font(.title)
                      }
                  }
                  .padding(.horizontal, 20)
                  .padding(.bottom,-10)
                  
                  ScrollView(.horizontal, showsIndicators: false) {
                      HStack(spacing: 8) {
                          ForEach(categories) { category in
                              ZStack(alignment: .topTrailing) {
                                  Button(action: {
                                      if !isLongPressing {
                                          if selectedCategory?.id == category.id {
                                              selectedCategory = nil
                                              loadUFavData() // 加載所有食物
                                          } else {
                                              selectedCategory = category
                                          }
                                      }
                                      isLongPressing = false
                                  }) {
                                      Text(category.name)
                                          .padding(.vertical, 10)
                                          .padding(.horizontal, 16)
                                          .background(selectedCategory?.id == category.id ? Color.blue.opacity(0.4) : Color.blue.opacity(0.2))
                                          .cornerRadius(15)
                                          .lineLimit(1)
                                          .truncationMode(.tail)
                                  }
                                  .gesture(
                                      LongPressGesture(minimumDuration: 0.5)
                                          .onEnded { _ in
                                              if let index = categories.firstIndex(where: { $0.id == category.id }) {
                                                  categories[index].isDeleting.toggle()
                                              }
                                              isLongPressing = true
                                          }
                                  )
                                  
                                  if category.isDeleting {
                                      HStack {
                                          Button(action: {
                                              editCategory(category: category)
                                          }) {
                                              Image(systemName: "pencil.circle.fill")
                                                  .foregroundColor(.blue)
                                                  .font(.system(size: 24))
                                                  .padding(8)
                                          }
                                          .offset(x: 30, y: -10)
                                          
                                          Button(action: {
                                              deleteCategory(id: category.id)
                                          }) {
                                              Image(systemName: "xmark.circle.fill")
                                                  .foregroundColor(.red)
                                                  .font(.system(size: 24))
                                                  .padding(8)
                                          }
                                          .offset(x: 10, y: -10)
                                      }
                                  }
                              }
                          }
                      }
                      .padding(.top, 10)
                      .padding(.horizontal, 20)
                  }
                  .frame(minHeight: 50) // 設置最小高度

                  if isLoading {
                      VStack {
                          Spacer()
                          ProgressView("載入中...").progressViewStyle(CircularProgressViewStyle())
                          Spacer()
                      }
                      .frame(maxWidth: .infinity, maxHeight: .infinity)
                  } else if let error = loadingError {
                      VStack {
                          Text("載入失敗: \(error)").font(.body).foregroundColor(.red)
                          Spacer().frame(height: 120)
                      }
                      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                  } else if filteredDishes.isEmpty {
                      GeometryReader
                      { geometry in
                          VStack
                          {
                              Image(selectedCategory == nil ? "最愛" : "烹飪")
                                  .resizable()
                                  .scaledToFit()
                                  .frame(width: 180, height: 180)
                              .position(x: geometry.size.width / 2, y: geometry.size.height / 3) // 向上移动图片
                          }
                          VStack
                          {
                              Spacer().frame(height: geometry.size.height / 2) // 向下移动文字
                              VStack
                              {
                                  Text(selectedCategory == nil ? "暫無最愛食譜" : "該分類為空")
                                      .font(.system(size: 18))
                                      .foregroundColor(.gray)
                                  NavigationLink(destination: PastRecipesView())
                                  {
                                      Text(selectedCategory == nil ? "前往“過往食譜”添加更多＋＋" : "")
                                          .font(.system(size: 18))
                                          .foregroundColor(.blue).underline()
                                  }
                                  Spacer().frame(height: 300)
                              }
                              VStack {
                                  
                                    
                                  Spacer()
                              }
                              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                          }
                      }
                  } else {
                      ScrollView(showsIndicators: false) {
                          LazyVStack {
                              ForEach(filteredDishes) { dish in
                                  F_RecipeBlock(
                                      imageName: dish.D_image,
                                      title: dish.Dis_Name,
                                      U_ID: U_ID,
                                      Dis_ID: dish.Dis_ID,
                                      categories: $categories
                                  )
                                  .padding(.bottom, -70)
                              }

                          }
                      }
                  }
              }
              .onAppear {
                  loadCategories() // 加載分類
                  loadUFavData() // 加載特定分類的食物
              }
              
              if isEditing {
                  VStack {
                      Text("編輯分類")
                          .font(.title2)
                          .padding()
                      TextField("新的分類名稱", text: $editedCategoryName)
                          .textFieldStyle(RoundedBorderTextFieldStyle())
                          .padding()
                      Button("確定") {
                          if !editedCategoryName.isEmpty {
                              updateCategory()
                          }
                      }
                      .padding()
                      Button("取消") {
                          isEditing = false
                          editingCategory = nil
                          editedCategoryName = ""
                      }
                  }
                  .padding()
              }
          }
         
          .sheet(isPresented: $showAddCategoryAlert) {
              VStack {
                  Text("新增分類")
                      .font(.title2)
                      .padding()
                  TextField("分類名稱", text: $newCategoryName)
                      .textFieldStyle(RoundedBorderTextFieldStyle())
                      .padding()
                  Button("確定") {
                      if !newCategoryName.isEmpty {
                          addCategory(name: newCategoryName, U_ID: U_ID)
                          newCategoryName = ""
                          showAddCategoryAlert = false
                      }
                  }
                  .padding()
                  Button("取消") {
                      showAddCategoryAlert = false
                  }
              }
              .padding()
          }
          .alert(isPresented: $showDeleteConfirmation) {
              Alert(
                  title: Text("刪除分類"),
                  message: Text("確定要刪除這個分類嗎？"),
                  primaryButton: .destructive(Text("刪除")) {
                      if let category = categoryToDelete {
                          deleteCategory(id: category.id)
                          categoryToDelete = nil
                      }
                  },
                  secondaryButton: .cancel()
              )
          }
      }
  }

struct FavoriteView_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteView(U_ID: "test")
    }
}
