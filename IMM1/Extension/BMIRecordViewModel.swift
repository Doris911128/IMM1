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
    func averagesEverySevenRecordsSorted() -> [BMIRecord] {
        // 先按日期排序
        let sortedRecords = bmiRecords.sorted { $0.date < $1.date }
        var results = [BMIRecord]()
        let batchSize = 7
        
        // 将排序好的记录分批处理，每批7筆
        for batchStart in stride(from: 0, to: sortedRecords.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, sortedRecords.count)
            let batch = Array(sortedRecords[batchStart..<batchEnd])
            
            // 计算每批的平均身高和体重
            let totalHeight = batch.reduce(0.0) { $0 + $1.H }
            let totalWeight = batch.reduce(0.0) { $0 + $1.W }
            if !batch.isEmpty {
                let averageHeight = totalHeight / Double(batch.count)
                let averageWeight = totalWeight / Double(batch.count)
                _ = averageWeight / ((averageHeight / 100) * (averageHeight / 100))
                
                // 使用批次中的第一筆记录的日期
                let recordDate = batch.first!.date
                let avgRecord = BMIRecord(height: averageHeight, weight: averageWeight, date: recordDate)
                results.append(avgRecord)
            }
        }
        
        return results
    }
    func weeklyAverages() -> [BMIRecord] {
        let calendar = Calendar.current  // 定义 calendar
        let grouped = Dictionary(grouping: bmiRecords) { calendar.startOfWeek(for: $0.date) }
        var weeklyAverages = [BMIRecord]()
        for (_, records) in grouped {
            let totalHeight = records.reduce(0.0, { $0 + $1.H })
            let totalWeight = records.reduce(0.0, { $0 + $1.W })
            if let firstRecord = records.first, records.count > 0 {
                let averageHeight = totalHeight / Double(records.count)
                let averageWeight = totalWeight / Double(records.count)
                _ = averageWeight / ((averageHeight / 100) * (averageHeight / 100))
                let avgRecord = BMIRecord(height: averageHeight, weight: averageWeight, date: firstRecord.date)
                weeklyAverages.append(avgRecord)
            }
        }
        return weeklyAverages.sorted(by: { $0.date < $1.date })
    }
    func averagesEveryThirtyRecordsSorted() -> [BMIRecord] {
        let sortedRecords = bmiRecords.sorted { $0.date < $1.date }
        var results = [BMIRecord]()
        let batchSize = 30
        
        for batchStart in stride(from: 0, to: sortedRecords.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, sortedRecords.count)
            let batch = Array(sortedRecords[batchStart..<batchEnd])
            
            let totalHeight = batch.reduce(0.0) { $0 + $1.H }
            let totalWeight = batch.reduce(0.0) { $0 + $1.W }
            if !batch.isEmpty {
                let averageHeight = totalHeight / Double(batch.count)
                let averageWeight = totalWeight / Double(batch.count)
                _ = averageWeight / ((averageHeight / 100) * (averageHeight / 100))
                
                let recordDate = batch.first!.date
                let avgRecord = BMIRecord(height: averageHeight, weight: averageWeight, date: recordDate)
                results.append(avgRecord)
            }
        }
        
        return results
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
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
