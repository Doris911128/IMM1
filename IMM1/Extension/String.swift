//
//  String.swift
//
//
//
//

import Foundation

// MARK: 擴充String區間擷取功能
extension String 
{
    subscript(_ range: CountableRange<Int>) -> String 
    {
        let start=index(startIndex, offsetBy: max(0, range.lowerBound))
        let end=index(start, offsetBy: min(self.count - range.lowerBound, range.upperBound-range.lowerBound))
        return String(self[start..<end])
    }
    
    subscript(_ range: CountablePartialRangeFrom<Int>) -> String 
    {
        let start=index(startIndex, offsetBy: max(0, range.lowerBound))
        return String(self[start...])
    }
}

extension String 
{
    subscript (index: Int) -> Character 
    {
        let charIndex = self.index(self.startIndex, offsetBy: index)
        return self[charIndex]
    }
    
    subscript (range: Range<Int>) -> Substring {
        let startIndex = self.index(self.startIndex, offsetBy: range.startIndex)
        let stopIndex = self.index(self.startIndex, offsetBy: range.startIndex + range.count)
        return self[startIndex..<stopIndex]
    }
    
}
extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions=[]) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions=[]) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions=[]) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions=[]) -> [Range<Index>] {
        var result: [Range<Index>]=[]
        var startIndex=self.startIndex
        while startIndex < endIndex,
              let range=self[startIndex...]
            .range(of: string, options: options) {
            result.append(range)
            startIndex=range.lowerBound < range.upperBound ? range.upperBound :
            index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
