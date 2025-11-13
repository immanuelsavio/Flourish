//
//  FriendIOU.swift
//  FinanceApp
//
//  Model for tracking IOUs with friends
//

import Foundation

enum IOUDirection: String, Codable, CaseIterable, Hashable {
    case owedToYou = "They owe you"
    case youOwe = "You owe"
}

struct FriendIOU: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var personName: String
    var amount: Double
    var direction: IOUDirection
    var notes: String
    var date: Date
    var isSettled: Bool
    var settledDate: Date?
    
    init(id: UUID = UUID(), userId: UUID, personName: String, amount: Double, direction: IOUDirection, notes: String = "", date: Date = Date(), isSettled: Bool = false, settledDate: Date? = nil) {
        self.id = id
        self.userId = userId
        self.personName = personName
        self.amount = amount
        self.direction = direction
        self.notes = notes
        self.date = date
        self.isSettled = isSettled
        self.settledDate = settledDate
    }
}
