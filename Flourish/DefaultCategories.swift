//
//  DefaultCategories.swift
//  FinanceApp
//
//  Default expense categories available for all users
//

import Foundation

struct DefaultCategories {
    static let all = [
        "Groceries",
        "Dining Out",
        "Transportation",
        "Utilities",
        "Rent/Mortgage",
        "Entertainment",
        "Shopping",
        "Health & Fitness",
        "Insurance",
        "Subscriptions",
        "Travel",
        "Education",
        "Personal Care",
        "Gifts & Donations",
        "Home Maintenance",
        "Pet Care",
        "Other"
    ]
    
    /// Check if a category is a default category
    static func isDefault(_ categoryName: String) -> Bool {
        all.contains(categoryName)
    }
}
