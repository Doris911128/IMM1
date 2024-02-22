//
//  User.swift
//
//
//
//
import Foundation

// MARK: 提供所有View使用的User結構
class User: ObservableObject
{
    
    @Published var id: String //ID
    
    @Published var account: String //帳號
    @Published var password: String //密碼
    
    @Published var name: String //名字
    @Published var gender: String //性別
    @Published var birthday: String //生日
    
    @Published var height: String //身高
    @Published var weight: String //體重
    
    @Published var like1 : String //偏好1
    @Published var like2 : String //偏好2
    @Published var like3 : String //偏好3
    @Published var like4 : String //偏好4


    // MARK: 初始化
    init()
    {
        self.id=""
        self.account=""
        self.password=""
        self.name=""
        self.gender=""
        self.birthday=""
        self.height="0.0"
        self.weight="0.0"
        self.like1="0.0"
        self.like2="0.0"
        self.like3="0.0"
        self.like4="0.0"
    }

    // MARK: 刪除
    func deleteUser()
    {
        self.id=""
        self.account=""
        self.password=""
        self.name=""
        self.gender=""
        self.birthday=""
        self.height="0.0"
        self.weight="0.0"
        self.like1="0.0"
        self.like2="0.0"
        self.like3="0.0"
        self.like4="0.0"
    }
    // MARK: 更新
    func setUser(id: String, account: String, password: String, name: String, gender: String, birthday: String, height: String, weight: String ,like1: String,like2: String,like3: String,like4: String)
    {
        self.id=id
        self.account=account
        self.password=password
        self.name=name
        self.gender=gender
        self.birthday=birthday
        self.height=height
        self.weight=weight
        self.like1=like1
        self.like2=like2
        self.like3=like3
        self.like4=like4
    }
}
