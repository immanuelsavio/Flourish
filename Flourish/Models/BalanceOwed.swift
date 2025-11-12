//
//  BalanceOwed.swift
//  FinanceApp
//
//  Model to track money owed by others (receivables)
//

import Foundation

struct BalanceOwed: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var personName: String
    var amount: Double
    var lastUpdated: Date
    
    init(id: UUID = UUID(), userId: UUID, personName: String, amount: Double, lastUpdated: Date = Date()) {
        self.id = id
        self.userId = userId
        self.personName = personName
        self.amount = amount
        self.lastUpdated = lastUpdated
    }
}

struct Repayment: Identifiable, Codable {
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
