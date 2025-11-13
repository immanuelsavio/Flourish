//
//  SavingsBudget.swift
//  FinanceApp
//
//  Model for tracking savings goals (401k, stocks, cash savings, etc.)
//

import Foundation

enum SavingsType: String, Codable, CaseIterable {
    case retirement401k = "401(k)"
    case retirementIRA = "IRA"
    case stocks = "Stocks/Investments"
    case emergencyFund = "Emergency Fund"
    case cashSavings = "Cash Savings"
    case other = "Other"
}

struct SavingsBudget: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var name: String
    var type: SavingsType
    var targetAmount: Double
    var currentAmount: Double
    var monthlyContribution: Double
    var createdAt: Date
    
    init(id: UUID = UUID(), userId: UUID, name: String, type: SavingsType, targetAmount: Double, currentAmount: Double = 0, monthlyContribution: Double, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.type = type
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.monthlyContribution = monthlyContribution
        self.createdAt = createdAt
    }
    
    var percentComplete: Double {
        guard targetAmount > 0 else { return 0 }
        return (currentAmount / targetAmount) * 100
    }
    
    var remaining: Double {
        targetAmount - currentAmount
    }
}
