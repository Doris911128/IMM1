// User.swift

import Foundation

class User: ObservableObject, Decodable
{
    @Published var id: String
    @Published var account: String
    // MARK: 註解密碼部分1
    //@Published var password: String ->註解原因：回傳訊息會顯示缺少該值，但密碼返回會造成安全問題，日後優化需添加於後端添加金鑰等解決
    @Published var name: String
    @Published var gender: String
    @Published var birthday: String
    @Published var height: String
    @Published var weight: String
    
    
    // MARK: 初始化
    init(id: String = "",
         account: String = "",
         password: String = "",
         name: String = "",
         gender: String = "",
         birthday: String = "",
         height: String = "0.0",
         weight: String = "0.0") {
        self.id = id
        self.account = account
        //self.password = password // MARK: 註解密碼部分2
        self.name = name
        self.gender = gender
        self.birthday = birthday
        self.height = height
        self.weight = weight
        
    }
    
    // MARK: 可失敗的初始化方法
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.account = try container.decodeIfPresent(String.self, forKey: .account) ?? "" // 解碼U_Acc字段，如果不存在則賦空字串
        //self.password = try container.decode(String.self, forKey: .password) // MARK: 註解密碼部分3
        self.name = try container.decode(String.self, forKey: .name)
        self.gender = try container.decode(String.self, forKey: .gender)
        self.birthday = try container.decode(String.self, forKey: .birthday)
        self.height = try container.decodeIfPresent(String.self, forKey: .height) ?? "" // 身高字段可為空
        self.weight = try container.decodeIfPresent(String.self, forKey: .weight) ?? "" // 體重字段可為空
        
    }
    
    // MARK: 枚舉定義編碼鍵
    enum CodingKeys: String, CodingKey {
        case id = "U_ID"
        case account = "U_Acc"
        //case password = "U_Pas" // MARK: 註解密碼部分4
        case name = "U_Name"
        case gender = "U_Gen"
        case birthday = "U_Bir"
        case height = "H"
        case weight = "W"
        
    }
    
    // 更新用戶信息的方法
    func update(with userInfo: User) {
        DispatchQueue.main.async {
            self.name = userInfo.name
            self.gender = userInfo.gender
            self.birthday = userInfo.birthday
            self.height = userInfo.height
            self.weight = userInfo.weight
            
        }
    }
    
    // MARK: 從後端獲取用戶信息並更新視圖
    func fetchUserInfo(completion: @escaping (User?) -> Void) {
        guard let url = URL(string: "http://163.17.9.107/food/php/Login.php") else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("No data received: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                let userInfo = try JSONDecoder().decode(User.self, from: data)
                completion(userInfo)
            } catch {
                print("Error decoding user info: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
}
