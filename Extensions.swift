//
//  Extensions.swift
//  Flourish
//
//  Helper extensions for consistent formatting across the app
//

import Foundation

// MARK: - Double Extensions

extension Double {
    /// Formats a Double as currency with proper locale formatting
    func formatAsCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    
    /// Formats a Double as a percentage
    func formatAsPercentage() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: self / 100)) ?? "0%"
    }
}

// MARK: - Date Extensions

extension Date {
    /// Returns the start of the current month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    /// Returns the end of the current month
    var endOfMonth: Date {
        let calendar = Calendar.current
        guard let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return self
        }
        return calendar.date(byAdding: .day, value: -1, to: startOfNextMonth) ?? self
    }
    
    /// Checks if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Checks if date is in the current month
    var isInCurrentMonth: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month)
    }
    
    /// Returns a formatted string for display
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Returns a short formatted string (e.g., "Jan 15")
    func shortFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
    
    /// Returns month name (e.g., "January")
    func monthName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }
    
    /// Returns year as string
    func yearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions

extension String {
    /// Validates if string is a valid email
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Converts string to Double safely
    var toDouble: Double? {
        Double(self)
    }
    
    /// Converts string to Int safely
    var toInt: Int? {
        Int(self)
    }
    
    /// Trims whitespace and newlines
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Color Extensions

import SwiftUI

extension Color {
    /// Custom app colors
    static let flourishGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let flourishBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    
    /// Income/positive balance color
    static let incomeGreen = Color.green
    
    /// Expense/negative balance color
    static let expenseRed = Color.red
    
    /// Warning color
    static let warningOrange = Color.orange
    
    /// Budget tracking colors
    static func budgetColor(spent: Double, limit: Double) -> Color {
        let percentage = spent / limit
        if percentage >= 1.0 {
            return .red
        } else if percentage >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Array Extensions

extension Array where Element == Double {
    /// Sum of all elements
    var sum: Double {
        reduce(0, +)
    }
    
    /// Average of all elements
    var average: Double {
        isEmpty ? 0 : sum / Double(count)
    }
}

// MARK: - Subscription Extensions

extension Subscription {
    /// Check if subscription is due within the next 7 days
    var isDueSoon: Bool {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate).day ?? 0
        return daysUntilDue >= 0 && daysUntilDue <= 7
    }
    
    /// Calculate next due date based on frequency
    func calculateNextDueDate() -> Date {
        let calendar = Calendar.current
        
        switch frequency {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: nextDueDate) ?? nextDueDate
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: nextDueDate) ?? nextDueDate
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: nextDueDate) ?? nextDueDate
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let dataDidUpdate = Notification.Name("dataDidUpdate")
    static let actionItemsUpdated = Notification.Name("actionItemsUpdated")
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    /// Keys for storing data
    enum Keys {
        static let currentUserId = "currentUserId"
        static let users = "users"
        static let accounts = "accounts"
        static let budgetCategories = "budgetCategories"
        static let expenses = "expenses"
        static let subscriptions = "subscriptions"
        static let balancesOwed = "balancesOwed"
        static let repayments = "repayments"
        static let transfers = "transfers"
        static let savingsBudgets = "savingsBudgets"
        static let salaryIncomes = "salaryIncomes"
        static let incomeTransactions = "incomeTransactions"
        static let actionItems = "actionItems"
        static let friendIOUs = "friendIOUs"
    }
}

// MARK: - View Extensions

extension View {
    /// Apply conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Card style modifier
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}

// MARK: - TextField Formatters

class CurrencyFormatter: NumberFormatter {
    override init() {
        super.init()
        self.numberStyle = .currency
        self.locale = Locale.current
        self.minimumFractionDigits = 2
        self.maximumFractionDigits = 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PercentageFormatter: NumberFormatter {
    override init() {
        super.init()
        self.numberStyle = .percent
        self.minimumFractionDigits = 0
        self.maximumFractionDigits = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
