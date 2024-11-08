//  F_RecipeBlock.swift
//  IMM1
//
//  Created by 朝陽資管 on 2024/9/10.
//

import SwiftUI
import Foundation

struct F_RecipeBlock: View
{
    let D_image: String
    let Dis_Name: String
    let U_ID: String
    let Dis_ID: Int
    @State private var isFavorited: Bool = false
    @State private var showAddToCategory: Bool = false
    @State private var selectedCategory: FavoriteView.Category?
    @State private var showDeleteConfirmation: Bool = false
    @State private var deleteCategory: FavoriteView.Category?
    @Binding var categories: [FavoriteView.Category]
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: Color
    {
        colorScheme == .dark ?  Color.white: Color.black
    }
    init(imageName: String, title: String, U_ID: String, Dis_ID: Int = 0, categories: Binding<[FavoriteView.Category]>) {
        self.D_image = imageName
        self.Dis_Name = title
        self.U_ID = U_ID
        self.Dis_ID = Dis_ID
        self._categories = categories
    }
    
    var body: some View {
        NavigationLink(destination: MRecipeView(U_ID: U_ID, Dis_ID: Dis_ID))
        {
            VStack {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: D_image)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(width: UIScreen.main.bounds.width - 40, height: 250)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width - 40, height: 250)
                                .cornerRadius(10)
                        case .failure:
                            Color.gray
                        @unknown default:
                            Color.gray
                        }
                    }
                    .padding(.top, 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack {
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
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: self.isFavorited ? "heart.fill" : "heart")
                                        .font(.title)
                                        .foregroundColor(.red)
                                )
                        }
                        .offset(y: 230)
                        .padding(.trailing, 10)
                        .symbolEffect(.bounce, value: self.isFavorited)
                        
                        Button(action: {
                            showAddToCategory = true
                        })
                        {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title)
                                .padding()
                                .clipShape(Circle())
                                .foregroundColor(.orange)
                        }
                        .padding(.top, -15)
                        .padding(.trailing, -10)
                    }
                }
                
                HStack(alignment: .bottom) {
                    Text(Dis_Name)
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .bold()
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .offset(x: 0, y: -80)
                    Spacer()
                }
                .offset(y: -5)
            }
            .padding(.horizontal, 20)
            .offset(y: -40)
            .onAppear {
                checkIfFavorited(U_ID: U_ID, Dis_ID: "\(Dis_ID)") { result in
                    switch result {
                    case .success(let favorited):
                        self.isFavorited = favorited
                    case .failure(let error):
                        print("Error checking favorite status: \(error.localizedDescription)")
                    }
                }
            }
            .contextMenu {
                Button(action: {
                    self.deleteCategory = nil
                    self.showDeleteConfirmation = true
                }) {
                    Text("刪除")
                    Image(systemName: "trash")
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("確認刪除"),
                    message: Text("您確定要刪除此分類嗎？"),
                    primaryButton: .destructive(Text("刪除")) {
                        if let category = deleteCategory {
                            print("刪除分類: \(category.name)")
                            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                                categories.remove(at: index)
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showAddToCategory) {
                VStack {
                    Text("選擇/刪除分類")
                        .font(.title2)
                        .padding()
                        .foregroundColor(backgroundColor)
                    Picker("選擇分類", selection: $selectedCategory) {
                        ForEach(categories) { category in
                            Text(category.name).tag(category as FavoriteView.Category?)
                        }
                        .accentColor(Color.orange)
                    }
                    .foregroundColor(.orange)
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    HStack {
                        Button("添加") {
                            if let category = selectedCategory {
                                let parameters = [
                                    "U_ID": U_ID,
                                    "Dis_ID": "\(Dis_ID)",
                                    "category_id": "\(category.id)",
                                    "category_name": category.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                ]
                                
                                guard let url = URL(string: "http://163.17.9.107/food/php/addFoodToCategory.php") else {
                                    print("Invalid URL")
                                    return
                                }
                                
                                var request = URLRequest(url: url)
                                request.httpMethod = "POST"
                                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                                
                                let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
                                request.httpBody = bodyString.data(using: .utf8)
                                
                                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                    if let error = error {
                                        print("Request error: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    guard let data = data else {
                                        print("No data received")
                                        return
                                    }
                                    
                                    if let responseString = String(data: data, encoding: .utf8) {
                                        print("Response: \(responseString)")
                                    } else {
                                        print("Unable to parse response data")
                                    }
                                }
                                
                                task.resume()
                                
                                showAddToCategory = false
                            }
                        }
                        .foregroundColor(.orange)
                        .padding()
                        
                        Button("移除") {
                            if let category = selectedCategory, let categoryId = categories.first(where: { $0.id == category.id })?.id {
                                let parameters = [
                                    "U_ID": U_ID,
                                    "Dis_ID": "\(Dis_ID)",
                                    "category_id": "\(categoryId)"
                                ]
                                
                                // 發送請求到 RemoveFoodFromCategory22.php，處理更新 Favorite 和刪除 F_Categories 表中的資料
                                guard let removeUrl = URL(string: "http://163.17.9.107/food/php/RemoveFoodFromCategory.php") else {
                                    print("Invalid URL for RemoveFoodFromCategory22.php")
                                    return
                                }
                                
                                var removeRequest = URLRequest(url: removeUrl)
                                removeRequest.httpMethod = "POST"
                                removeRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                                
                                let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
                                removeRequest.httpBody = bodyString.data(using: .utf8)
                                
                                let removeTask = URLSession.shared.dataTask(with: removeRequest) { data, response, error in
                                    if let error = error {
                                        print("Request error: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                                        print("No data received")
                                        return
                                    }
                                    
                                    print("Response from RemoveFoodFromCategory22: \(responseString)")
                                }
                                
                                removeTask.resume()
                                
                                // 隱藏添加到分類的視圖
                                showAddToCategory = false
                            }
                        }
                        .foregroundColor(.orange)
                        
                        .padding()
                    }
                }
                .padding()
            }
        }
    }
}
