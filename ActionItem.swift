//
//  ActionItem.swift
//  Flourish
//
//  Model for Action Center notifications and alerts
//

import Foundation

enum ActionItemType: String, Codable {
    case salaryPending = "Salary Pending"
    case reconciliationNeeded = "Reconciliation Needed"
    case subscriptionDue = "Subscription Due"
    case overspending = "Overspending Alert"
    case friendBalance = "Friend Balance"
    case missedExpense = "Missed Expense"
}

enum ActionItemPriority: Int, Codable {
    case low = 0
    case medium = 1
    case high = 2
}

struct ActionItem: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var type: ActionItemType
    var priority: ActionItemPriority
    var title: String
    var message: String
    var createdAt: Date
    var isDismissed: Bool
    var relatedEntityId: UUID? // Could be salaryId, subscriptionId, personName hash, etc.
    
    init(id: UUID = UUID(), userId: UUID, type: ActionItemType, priority: ActionItemPriority = .medium, title: String, message: String, createdAt: Date = Date(), isDismissed: Bool = false, relatedEntityId: UUID? = nil) {
        self.id = id
        self.userId = userId
        self.type = type
        self.priority = priority
        self.title = title
        self.message = message
        self.createdAt = createdAt
        self.isDismissed = isDismissed
        self.relatedEntityId = relatedEntityId
    }
}

// IOU (I Owe You / You Owe Me) for friend debt tracking not tied to expenses
struct FriendIOU: Identifiable, Codable {
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

enum IOUDirection: String, Codable {
    case owedToYou = "They owe you"
    case youOwe = "You owe them"
}
