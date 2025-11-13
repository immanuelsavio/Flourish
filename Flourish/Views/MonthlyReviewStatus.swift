//
//  MonthlyReviewStatus.swift
//  Flourish
//
//  Model for tracking monthly finance review completion
//

import Foundation

struct MonthlyReviewStatus: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var userId: UUID
    var month: Int
    var year: Int
    var isCompleted: Bool = false
    var completedAt: Date?
    
    init(id: UUID = UUID(), userId: UUID, month: Int, year: Int, isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.month = month
        self.year = year
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
    
    /// Returns true if this review is for the current month
    var isCurrentMonth: Bool {
        let now = Date()
        let currentMonth = Calendar.current.component(.month, from: now)
        let currentYear = Calendar.current.component(.year, from: now)
        return month == currentMonth && year == currentYear
    }
    
    /// Returns a formatted string like "October 2025"
    var monthYearString: String {
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        guard let date = Calendar.current.date(from: dateComponents) else {
            return "\(month)/\(year)"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}
