//
//  Subscription.swift
//  Flourish
//
//  Model for recurring subscription tracking
//

import Foundation

enum SubscriptionFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

struct Subscription: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var name: String
    var amount: Double
    var frequency: SubscriptionFrequency
    var nextDueDate: Date
    var categoryName: String
    var accountId: UUID
    var isActive: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), userId: UUID, name: String, amount: Double, frequency: SubscriptionFrequency, nextDueDate: Date, categoryName: String, accountId: UUID, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.nextDueDate = nextDueDate
        self.categoryName = categoryName
        self.accountId = accountId
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
