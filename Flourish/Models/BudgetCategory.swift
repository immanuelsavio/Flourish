//
//  BudgetCategory.swift
//  FinanceApp
//
//  Model for monthly budget categories with spending limits
//

import Foundation

struct BudgetCategory: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var name: String
    var monthlyLimit: Double
    var month: Int // 1-12
    var year: Int
    var spent: Double // Current spending in this category for the month
    
    init(id: UUID = UUID(), userId: UUID, name: String, monthlyLimit: Double, month: Int, year: Int, spent: Double = 0) {
        self.id = id
        self.userId = userId
        self.name = name
        self.monthlyLimit = monthlyLimit
        self.month = month
        self.year = year
        self.spent = spent
    }
    
    var remaining: Double {
        monthlyLimit - spent
    }
    
    var percentUsed: Double {
        guard monthlyLimit > 0 else { return 0 }
        return (spent / monthlyLimit) * 100
    }
}
