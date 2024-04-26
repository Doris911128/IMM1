//
//  BMIRecordViewModel.swift
//  IMM1
//
//  Created by Ｍac on 2024/4/14.
//

import Foundation

extension BMIRecordViewModel
{
    func addOrUpdateRecord(newRecord: BMIRecord) {
           if let index = self.bmiRecords.firstIndex(where: { $0.date.isSameDay(as: newRecord.date) }) {
               // 比較現有記錄和新記錄的时间戳
               if self.bmiRecords[index].timeStamp < newRecord.timeStamp {
                   self.bmiRecords[index] = newRecord
               }
           } else {
               self.bmiRecords.append(newRecord)
           }
       }
    
    func parseAndAddRecords(from jsonString: String)
    {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        if let jsonData = jsonString.data(using: .utf8) {
            do {
                let records = try decoder.decode([BMIRecord].self, from: jsonData)
                DispatchQueue.main.async {
                    // 使用 addOrUpdateRecord 方法更新或添加新记录
                    for record in records {
                        self.addOrUpdateRecord(newRecord: record)
                    }
                }
            } catch {
                print("Error decoding BMI records: \(error)")
            }
        }
    }
}

extension Date
{
    // Helper 函数来检查两个日期是否是同一天
    func isSameDay(as otherDate: Date) -> Bool
    {
        let calendar = Calendar.current
        return calendar.isDate(self, inSameDayAs: otherDate)
    }
}



