//
//  SalaryIncome.swift
//  Flourish
//

import Foundation

enum IncomeFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case semimonthly = "Semi-monthly"
    case custom = "Custom"
}

struct SalaryIncome: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var name: String
    var amount: Double
    var frequency: IncomeFrequency
    var nextExpectedDate: Date
    var accountId: UUID
    var customDayInterval: Int?
    var isActive: Bool
    
    init(id: UUID = UUID(), userId: UUID, name: String, amount: Double, frequency: IncomeFrequency, nextExpectedDate: Date, accountId: UUID, customDayInterval: Int? = nil, isActive: Bool = true) {
        self.id = id
        self.userId = userId
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.nextExpectedDate = nextExpectedDate
        self.accountId = accountId
        self.customDayInterval = customDayInterval
        self.isActive = isActive
    }
    
    func calculateNextDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .semimonthly:
            return calendar.date(byAdding: .day, value: 15, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .custom:
            let days = customDayInterval ?? 30
            return calendar.date(byAdding: .day, value: days, to: date) ?? date
        }
    }
    
    var isDueSoon: Bool {
        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: nextExpectedDate).day ?? 0
        return daysUntil <= 3 && daysUntil >= 0
    }
    
    var isOverdue: Bool {
        nextExpectedDate < Date()
    }
}
