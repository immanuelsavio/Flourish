//
//  IncomeTransaction.swift
//  Flourish
//

import Foundation

struct IncomeTransaction: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var salaryId: UUID
    var amount: Double
    var accountId: UUID
    var date: Date
    var notes: String?
    
    init(id: UUID = UUID(), userId: UUID, salaryId: UUID, amount: Double, accountId: UUID, date: Date = Date(), notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.salaryId = salaryId
        self.amount = amount
        self.accountId = accountId
        self.date = date
        self.notes = notes
    }
}

