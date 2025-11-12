//
//  DateFormatters.swift
//  FinanceApp
//
//  Centralized date formatting utilities
//

import Foundation

extension Date {
    /// Format date as "MMM d, yyyy" (e.g., "Nov 2, 2025")
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }
    
    /// Format date as short style (e.g., "11/2/25")
    func formattedShort() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
    
    /// Format date as medium style (e.g., "Nov 2, 2025")
    func formattedMedium() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }
    
    /// Format date as long style with time (e.g., "November 2, 2025 at 3:30 PM")
    func formattedLong() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        return formatter.string(from: self)
    }
}

extension Double {
    /// Format as currency (e.g., "$123.45")
    func formatAsCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}
