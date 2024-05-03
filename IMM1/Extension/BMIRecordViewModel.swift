//
//  BMIRecordViewModel.swift
//  IMM1
//
//  Created by Ｍac on 2024/4/14.
//

import Foundation

extension BMIRecordViewModel {
    func addOrUpdateRecord(newRecord: BMIRecord) {
        if let index = self.bmiRecords.firstIndex(where: { $0.date.isSameDay(as: newRecord.date) }) {
            // 比较现有记录和新记录的时间戳
            if self.bmiRecords[index].timeStamp < newRecord.timeStamp {
                self.bmiRecords[index] = newRecord
            }
        } else {
            self.bmiRecords.append(newRecord)
        }
        
        // 每次添加或更新记录后，重新排序数组
        self.bmiRecords.sort(by: { $0.date < $1.date })
    }
    
    func parseAndAddRecords(from jsonString: String) {
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
    func records(for range: TimeRange) -> [BMIRecord] {
            let now = Date()
            let calendar = Calendar.current
            var startDate: Date
            
            switch range {
            case .week:
                startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
            case .month:
                startDate = calendar.date(byAdding: .month, value: -1, to: now)!
            case .threeMonths:
                startDate = calendar.date(byAdding: .month, value: -3, to: now)!
            case .sixMonths:
                startDate = calendar.date(byAdding: .month, value: -6, to: now)!
            case .year:
                startDate = calendar.date(byAdding: .year, value: -1, to: now)!
            }

            return bmiRecords.filter { $0.date >= startDate }
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

enum TimeRange {
    case week
    case month
    case threeMonths
    case sixMonths
    case year
}
