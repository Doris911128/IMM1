//  User.swift
//
//
//
//
import Foundation

class User: ObservableObject, Decodable {
    
    @Published var id: String
    @Published var account: String
    @Published var password: String
    @Published var name: String
    @Published var gender: String
    @Published var birthday: String
    @Published var height: String
    @Published var weight: String
    @Published var like1: String
    @Published var like2: String
    @Published var like3: String
    @Published var like4: String

    // MARK: 初始化
    init(id: String = "",
         account: String = "",
         password: String = "",
         name: String = "",
         gender: String = "",
         birthday: String = "",
         height: String = "0.0",
         weight: String = "0.0",
         like1: String = "0.0",
         like2: String = "0.0",
         like3: String = "0.0",
         like4: String = "0.0") {
        
        self.id = id
        self.account = account
        self.password = password
        self.name = name
        self.gender = gender
        self.birthday = birthday
        self.height = height
        self.weight = weight
        self.like1 = like1
        self.like2 = like2
        self.like3 = like3
        self.like4 = like4
    }
    
    // MARK: 可失败的初始化方法
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.account = try container.decode(String.self, forKey: .account)
        self.password = try container.decode(String.self, forKey: .password)
        self.name = try container.decode(String.self, forKey: .name)
        self.gender = try container.decode(String.self, forKey: .gender)
        self.birthday = try container.decode(String.self, forKey: .birthday)
        self.height = try container.decode(String.self, forKey: .height)
        self.weight = try container.decode(String.self, forKey: .weight)
        self.like1 = try container.decode(String.self, forKey: .like1)
        self.like2 = try container.decode(String.self, forKey: .like2)
        self.like3 = try container.decode(String.self, forKey: .like3)
        self.like4 = try container.decode(String.self, forKey: .like4)
    }
    
    // MARK: 枚举定义编码键
    enum CodingKeys: String, CodingKey {
        case id
        case account
        case password
        case name
        case gender
        case birthday
        case height
        case weight
        case like1
        case like2
        case like3
        case like4
    }
}
