//
//  BalanceOwed.swift
//  FinanceApp
//
//  Model to track money owed by others (receivables)
//

import Foundation

struct BalanceOwed: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var personName: String
    var amount: Double
    var lastUpdated: Date
    var isOwedToMe: Bool // true = they owe me, false = I owe them
    
    init(id: UUID = UUID(), userId: UUID, personName: String, amount: Double, lastUpdated: Date = Date(), isOwedToMe: Bool = true) {
        self.id = id
        self.userId = userId
        self.personName = personName
        self.amount = amount
        self.lastUpdated = lastUpdated
        self.isOwedToMe = isOwedToMe
    }
}

struct Repayment: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var personName: String
    var amount: Double
    var date: Date
    var notes: String
    
    init(id: UUID = UUID(), userId: UUID, personName: String, amount: Double, date: Date = Date(), notes: String = "") {
        self.id = id
        self.userId = userId
        self.personName = personName
        self.amount = amount
        self.date = date
        self.notes = notes
    }
}
