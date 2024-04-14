//
//  BMIRecordViewModel.swift
//  IMM1
//
//  Created by Ｍac on 2024/4/14.
//

import Foundation

extension BMIRecordViewModel 
{
    func addOrUpdateRecord(newRecord: BMIRecord) 
    {
        if let index = self.bmiRecords.firstIndex(where:{ $0.date.isSameDay(as: newRecord.date) })
        {
            // 已存在相同日期的记录，更新它
            self.bmiRecords[index] = newRecord
        }
        else
        {
            // 无相同日期的记录，添加新记录
            self.bmiRecords.append(newRecord)
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

extension BMIRecordViewModel 
{
    func parseAndAddRecords(from jsonString: String) 
    {
        let jsonData = Data(jsonString.utf8)
        let decoder = JSONDecoder()
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let records = try decoder.decode([BMIRecord].self, from: jsonData)
            for record in records 
            {
                self.addOrUpdateRecord(newRecord: record)
            }
        } 
        catch
        {
            print("Error decoding JSON: \(error)")
        }
    }
}