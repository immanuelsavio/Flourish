//
//  Expense.swift
//  FinanceApp
//
//  Model for transaction/expense tracking
//

import Foundation

struct Expense: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var amount: Double
    var date: Date
    var description: String
    var categoryName: String
    var accountId: UUID
    var isSubscription: Bool
    var subscriptionId: UUID?
    var splitParticipants: [SplitParticipant]
    var isPending: Bool
    
    init(id: UUID = UUID(), userId: UUID, amount: Double, date: Date = Date(), description: String, categoryName: String, accountId: UUID, isSubscription: Bool = false, subscriptionId: UUID? = nil, splitParticipants: [SplitParticipant] = [], isPending: Bool = false) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.date = date
        self.description = description
        self.categoryName = categoryName
        self.accountId = accountId
        self.isSubscription = isSubscription
        self.subscriptionId = subscriptionId
        self.splitParticipants = splitParticipants
        self.isPending = isPending
    }
    
    // Calculate the user's share of the expense
    var userShare: Double {
        if splitParticipants.isEmpty {
            return amount
        }
        
        if let userParticipant = splitParticipants.first(where: { $0.isCurrentUser }) {
            return userParticipant.amount
        }
        
        return amount
    }
    
    // Calculate total amount owed by others
    var totalOwedByOthers: Double {
        splitParticipants.filter { !$0.isCurrentUser }.reduce(0) { $0 + $1.amount }
    }
}

struct SplitParticipant: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var amount: Double
    var isCurrentUser: Bool
    
    init(id: UUID = UUID(), name: String, amount: Double, isCurrentUser: Bool = false) {
        self.id = id
        self.name = name
        self.amount = amount
        self.isCurrentUser = isCurrentUser
    }
}
