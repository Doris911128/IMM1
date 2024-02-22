//
//  FireStore.swift
//
//
//
//

import Foundation
import FirebaseFirestore

//Firebase Firestore
struct FireStore
{
    let firestore: Firestore //Firestore環境
    
    // MARK: 初始化
    init()
    {
        self.firestore=Firestore.firestore()
    }
    
    // MARK: 刪除
    func deleteData(id: String) //刪除Firestore中指定節點的所有資料
    {
        self.firestore
            .collection("Forum") //Forum節點
            .document(id) //指定ID節點
            .delete() //刪除所有資料
    }
    // MARK: 查詢
    func getData(completion: @escaping (QuerySnapshot?, Error?) -> Void) //查詢Firestore中指定節點的所有資料

    {
        self.firestore
            .collection("Forum") //Forum節點
            .getDocuments {(result, error) in //該節點的所有資料
                if let error=error
                {
                    completion(nil, error) //查詢錯誤 -> (空值, 錯誤資訊)
                } else
                {
                    completion(result, nil) //查詢成功 -> (查詢結果, 空值)
                }
            }
    }
    //MARK: 寫入
    func setData(id: String, title: String, text: String, secure: Bool, author: String, completion: @escaping (Bool, Error?) -> Void) //將資料寫入Firestore
    {
        self.firestore
            .collection("Forum")  //創建或寫入Forum節點
            .document(id) //創建或寫入該id節點
        
            .setData(["Title": title, "Text": text, "Secure": secure, "Author": author]) //寫入Title欄位 Text欄位 Secure欄位 Author欄位
        { error in
            if let error=error 
            {
                completion(false, error) //寫入失敗 -> (失敗, 錯誤資訊)
            } else {
                completion(true, nil) //寫入成功 -> (成功, 空值)
            }
        }
    }
}
