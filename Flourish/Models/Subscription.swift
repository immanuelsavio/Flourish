//
//  Subscription.swift
//  FinanceApp
//
//  Model for recurring monthly subscriptions
//

import Foundation

struct Subscription: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var name: String
    var amount: Double
    var categoryName: String
    var accountId: UUID
    var nextDueDate: Date
    var isActive: Bool
    
    init(id: UUID = UUID(), userId: UUID, name: String, amount: Double, categoryName: String, accountId: UUID, nextDueDate: Date, isActive: Bool = true) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.categoryName = categoryName
        self.accountId = accountId
        self.nextDueDate = nextDueDate
        self.isActive = isActive
    }
    
    // Calculate next due date (add one month)
    func calculateNextDueDate() -> Date {
        Calendar.current.date(byAdding: .month, value: 1, to: nextDueDate) ?? nextDueDate
    }
    
    var isDueSoon: Bool {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0
        return daysUntilDue <= 7 && daysUntilDue >= 0
    }
}
