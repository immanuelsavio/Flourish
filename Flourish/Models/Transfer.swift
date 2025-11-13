//
//  Transfer.swift
//  Flourish
//

import Foundation

struct Transfer: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var fromAccountId: UUID
    var toAccountId: UUID
    var amount: Double
    var date: Date
    var notes: String
    var isPending: Bool = false
    
    init(id: UUID = UUID(), userId: UUID, fromAccountId: UUID, toAccountId: UUID, amount: Double, date: Date = Date(), notes: String = "", isPending: Bool = false) {
        self.id = id
        self.userId = userId
        self.fromAccountId = fromAccountId
        self.toAccountId = toAccountId
        self.amount = amount
        self.date = date
        self.notes = notes
        self.isPending = isPending
    }
}
