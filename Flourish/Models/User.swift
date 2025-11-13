//
//  User.swift
//  FinanceApp
//
//  User model representing a registered user
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    var id: UUID
    var email: String
    var name: String
    var passwordHash: String // In production, use proper encryption
    var createdAt: Date
    
    init(id: UUID = UUID(), email: String, name: String, passwordHash: String, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.passwordHash = passwordHash
        self.createdAt = createdAt
    }
}
