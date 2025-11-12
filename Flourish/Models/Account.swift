//
//  Account.swift
//  FinanceApp
//
//  Model representing a bank account or credit card
//

import Foundation

enum AccountType: String, Codable, CaseIterable {
    case checking = "Checking"
    case savings = "Savings"
    case creditCard = "Credit Card"
}

struct Account: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var name: String
    var type: AccountType
    var balance: Double
    var createdAt: Date
    var creditLimit: Double? // For credit cards only
    var creditUsageWarning: Double? // Percentage (e.g., 80 means warn at 80% usage)
    
    init(id: UUID = UUID(), userId: UUID, name: String, type: AccountType, balance: Double, createdAt: Date = Date(), creditLimit: Double? = nil, creditUsageWarning: Double? = nil) {
        self.id = id
        self.userId = userId
        self.name = name
        self.type = type
        self.balance = balance
        self.createdAt = createdAt
        self.creditLimit = creditLimit
        self.creditUsageWarning = creditUsageWarning
    }
    
    var isCreditCard: Bool {
        type == .creditCard
    }
    
    // For credit cards: how much has been used (negative balance means usage)
    var creditUsed: Double {
        guard isCreditCard else { return 0 }
        return abs(balance)
    }
    
    // For credit cards: remaining available credit
    var creditAvailable: Double {
        guard isCreditCard, let limit = creditLimit else { return 0 }
        return limit - creditUsed
    }
    
    // For credit cards: usage percentage
    var creditUsagePercent: Double {
        guard isCreditCard, let limit = creditLimit, limit > 0 else { return 0 }
        return (creditUsed / limit) * 100
    }
    
    // Check if credit usage is above warning threshold
    var isOverCreditWarning: Bool {
        guard isCreditCard, let warning = creditUsageWarning else { return false }
        return creditUsagePercent >= warning
    }
}
