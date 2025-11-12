//
//  AuthenticationService.swift
//  FinanceApp
//
//  Service for managing user authentication and profile updates
//

import Foundation
import Combine

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private let userDefaultsKey = "currentUserId"
    private let usersKey = "registeredUsers"
    
    private init() {
        loadCurrentUser()
    }
    
    // MARK: - Authentication
    
    func login(email: String, password: String) -> Bool {
        guard let users = loadUsers(),
              let user = users.first(where: { $0.email.lowercased() == email.lowercased() && $0.passwordHash == hashPassword(password) }) else {
            return false
        }
        
        currentUser = user
        isAuthenticated = true
        saveCurrentUserId(user.id)
        return true
    }
    
    func register(name: String, email: String, password: String) -> Bool {
        var users = loadUsers() ?? []
        
        // Check if email already exists
        if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
            return false
        }
        
        let newUser = User(
            email: email,
            name: name,
            passwordHash: hashPassword(password)
        )
        
        users.append(newUser)
        saveUsers(users)
        
        // Auto-login after registration
        currentUser = newUser
        isAuthenticated = true
        saveCurrentUserId(newUser.id)
        
        return true
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Profile Management
    
    func updateCurrentUser(name: String, email: String) {
        guard var user = currentUser else { return }
        
        // Update user properties
        user.name = name
        user.email = email
        
        // Update in memory
        currentUser = user
        
        // Update in persistent storage
        var users = loadUsers() ?? []
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveUsers(users)
        }
    }
    
    // MARK: - Private Helpers
    
    private func loadCurrentUser() {
        guard let userIdString = UserDefaults.standard.string(forKey: userDefaultsKey),
              let userId = UUID(uuidString: userIdString),
              let users = loadUsers(),
              let user = users.first(where: { $0.id == userId }) else {
            return
        }
        
        currentUser = user
        isAuthenticated = true
    }
    
    private func saveCurrentUserId(_ userId: UUID) {
        UserDefaults.standard.set(userId.uuidString, forKey: userDefaultsKey)
    }
    
    private func loadUsers() -> [User]? {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return nil
        }
        return users
    }
    
    private func saveUsers(_ users: [User]) {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        // In production, use proper password hashing (bcrypt, Argon2, etc.)
        // This is just for demonstration
        return password.data(using: .utf8)?.base64EncodedString() ?? password
    }
}
