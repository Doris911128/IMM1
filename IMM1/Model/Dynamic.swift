////
////  Dynamic.swift
////  GP110IM
////
////  Created by Mac on 2023/11/5.
//
////MARK: 血壓血糖血脂 英文縮寫
////血壓（Blood Pressure） 的英文縮寫是 BP
////血糖（Blood Sugar）    的英文縮寫是 BS 或 BG
////血脂（Blood Lipids）   的英文縮寫是 BL 或 BLP
//
//import Foundation
//import SwiftUI
//
//// 定义通用的记录结构
//class Record<T>: Identifiable
//{
//    var id = UUID()
//    var value: T
//    var date = Date()
//
//    init(value: T)
//    {
//        self.value = value
//    }
//}
//
//// 创建不同类型的记录
//let BMIRecord = Record(value: 40.0)
//let BPRecord = Record(value: 120.0)
//let BSRecord = Record(value: 5.2)
//let BLRecord = Record(value: 180)
//
//// 定义通用的传感器结构
//struct TemperatureSensor<T>: Identifiable
//{
//    var id = UUID()
//    var sensorID: String
//    var records: [Record<T>]
//
//    init(sensorID: String, records: [Record<T>])
//    {
//        self.sensorID = sensorID
//        self.records = records
//    }
//}
//var BMISensors: [TemperatureSensor<Double>] = [TemperatureSensor(sensorID: "BMI Sensor 1", records: [BMIRecord])]
//var BPSensors: [TemperatureSensor<Double>] = [TemperatureSensor(sensorID: "BP Sensor 1", records: [BPRecord])]
//var BSSensors: [TemperatureSensor<Double>] = [TemperatureSensor(sensorID: "BS Sensor 1", records: [BSRecord])]
//var BLSensors: [TemperatureSensor<Int>] = [TemperatureSensor(sensorID: "BL Sensor 1", records: [BLRecord])]
//
//func addRecordsToSensors() 
//{
//    BMISensors[0].records.append(BMIRecord)
//    BPSensors[0].records.append(BPRecord)
//    BSSensors[0].records.append(BSRecord)
//    BLSensors[0].records.append(BLRecord)
//}
