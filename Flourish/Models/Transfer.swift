//
//  Transfer.swift
//  FinanceApp
//
//  Model for transfers between accounts (not counted as expenses)
//

import Foundation

struct Transfer: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var fromAccountId: UUID
    var toAccountId: UUID
    var amount: Double
    var date: Date
    var notes: String
    
    init(id: UUID = UUID(), userId: UUID, fromAccountId: UUID, toAccountId: UUID, amount: Double, date: Date = Date(), notes: String = "") {
        self.id = id
        self.userId = userId
        self.fromAccountId = fromAccountId
        self.toAccountId = toAccountId
        self.amount = amount
        self.date = date
        self.notes = notes
    }
}
