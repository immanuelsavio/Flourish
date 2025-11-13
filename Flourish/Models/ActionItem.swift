//
//  ActionItem.swift
//  Flourish
//

import Foundation

enum ActionItemType: String, Codable {
    case salaryPending = "Salary Pending"
    case subscriptionDue = "Subscription Due"
    case budgetWarning = "Budget Warning"
    case creditWarning = "Credit Warning"
    case friendBalance = "Friend Balance"
    case overspending = "Overspending"
    case reconciliationNeeded = "Reconciliation Needed"
    case missedExpense = "Missed Expense"
    case scheduledTransferDueToday = "Scheduled Transfer Due Today"
    case pendingExpense = "Pending Expense"
    case pendingTransfer = "Pending Transfer"
    case monthlyFinanceReview = "Monthly Finance Review"
}

enum ActionItemPriority: Int, Codable {
    case low = 1
    case medium = 2
    case high = 3
}

struct ActionItem: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var type: ActionItemType
    var title: String
    var message: String
    var priority: ActionItemPriority
    var createdAt: Date
    var isDismissed: Bool
    var relatedEntityId: UUID?
    
    init(id: UUID = UUID(), userId: UUID, type: ActionItemType, title: String, message: String, priority: ActionItemPriority, createdAt: Date = Date(), isDismissed: Bool = false, relatedEntityId: UUID? = nil) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.priority = priority
        self.createdAt = createdAt
        self.isDismissed = isDismissed
        self.relatedEntityId = relatedEntityId
    }
}

