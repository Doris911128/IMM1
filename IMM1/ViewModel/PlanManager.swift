//
//  PlanManager.swift
//  IMM1
//
//  Created by Ｍac on 2024/3/24.
//

import Foundation

class PlanManager {
    static let shared = PlanManager()

    private let userDefaults = UserDefaults.standard
    private let plansKey = "plans"

    func savePlans(_ plans: [String: [String]]) {
        do {
            let encodedData = try JSONEncoder().encode(plans)
            userDefaults.set(encodedData, forKey: plansKey)
        } catch {
            print("Error encoding plans: (error)")
        }
    }

    func loadPlans() -> [String: [String]] {
        guard let encodedData = userDefaults.data(forKey: plansKey) else {
            return [:]
        }

        do {
            let plans = try JSONDecoder().decode([String: [String]].self, from: encodedData)
            return plans
        } catch {
            print("Error decoding plans: (error)")
            return [:]
        }
    }
}
