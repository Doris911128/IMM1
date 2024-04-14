//
//  BMI.swift
//  IMM1
//
//  Created by Ｍac on 2024/4/12.
//

import Foundation

class BMI: ObservableObject {
    @Published var height: Double
    @Published var weight: Double
    
    init(height: Double, weight: Double) {
        self.height=height
        self.weight=weight
    }
}
