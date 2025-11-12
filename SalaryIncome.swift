//
//  SalaryIncome.swift
//  Flourish
//
//  Model for recurring salary/income tracking
//

import Foundation

enum IncomeFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case custom = "Custom"
}

struct SalaryIncome: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var amount: Double
    var frequency: IncomeFrequency
    var accountId: UUID
    var nextExpectedDate: Date
    var customDayInterval: Int? // For custom frequency (in days)
    var isActive: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), userId: UUID, amount: Double, frequency: IncomeFrequency, accountId: UUID, nextExpectedDate: Date, customDayInterval: Int? = nil, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.frequency = frequency
        self.accountId = accountId
        self.nextExpectedDate = nextExpectedDate
        self.customDayInterval = customDayInterval
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    // Calculate next expected date based on frequency
    func calculateNextDate(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        
        switch frequency {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .custom:
            if let interval = customDayInterval {
                return calendar.date(byAdding: .day, value: interval, to: date) ?? date
            }
            return date
        }
    }
    
    // Check if salary is due soon (within 3 days)
    var isDueSoon: Bool {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: nextExpectedDate).day ?? 0
        return daysUntilDue >= -1 && daysUntilDue <= 3
    }
    
    // Check if salary is overdue
    var isOverdue: Bool {
        nextExpectedDate < Date()
    }
}

// Income transaction record
struct IncomeTransaction: Identifiable, Codable {
    var id: UUID
    var userId: UUID
    var salaryId: UUID
    var amount: Double
    var accountId: UUID
    var date: Date
    var notes: String
    var confirmedAt: Date
    
    init(id: UUID = UUID(), userId: UUID, salaryId: UUID, amount: Double, accountId: UUID, date: Date, notes: String = "", confirmedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.salaryId = salaryId
        self.amount = amount
        self.accountId = accountId
        self.date = date
        self.notes = notes
        self.confirmedAt = confirmedAt
    }
}
