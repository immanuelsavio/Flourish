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
    
    init(id: UUID = UUID(), userId: UUID, name: String, type: AccountType, balance: Double, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.type = type
        self.balance = balance
        self.createdAt = createdAt
    }
    
    var isCreditCard: Bool {
        type == .creditCard
    }
}
