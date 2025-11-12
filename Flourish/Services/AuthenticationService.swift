//
//  AuthenticationService.swift
//  FinanceApp
//
//  Service for handling user authentication
//

import Foundation
import CryptoKit
import Combine

class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let userDefaultsKey = "currentUserId"
    
    private init() {
        loadSession()
    }
    
    // Register a new user
    func register(email: String, name: String, password: String) -> Result<User, AuthError> {
        // Validate email format
        guard isValidEmail(email) else {
            return .failure(.invalidEmail)
        }
        
        // Check if user already exists
        if DataService.shared.getUser(by: email) != nil {
            return .failure(.userAlreadyExists)
        }
        
        // Hash the password
        let passwordHash = hashPassword(password)
        
        // Create new user
        let user = User(email: email, name: name, passwordHash: passwordHash)
        
        // Save user
        DataService.shared.saveUser(user)
        
        // Set as current user
        currentUser = user
        isAuthenticated = true
        saveSession(userId: user.id)
        
        return .success(user)
    }
    
    // Login existing user
    func login(email: String, password: String) -> Result<User, AuthError> {
        guard let user = DataService.shared.getUser(by: email) else {
            return .failure(.userNotFound)
        }
        
        // Verify password
        let passwordHash = hashPassword(password)
        guard user.passwordHash == passwordHash else {
            return .failure(.invalidPassword)
        }
        
        // Set as current user
        currentUser = user
        isAuthenticated = true
        saveSession(userId: user.id)
        
        return .success(user)
    }
    
    // Logout
    func logout() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // Save session
    private func saveSession(userId: UUID) {
        UserDefaults.standard.set(userId.uuidString, forKey: userDefaultsKey)
    }
    
    // Load session on app launch
    private func loadSession() {
        guard let userIdString = UserDefaults.standard.string(forKey: userDefaultsKey),
              let userId = UUID(uuidString: userIdString),
              let user = DataService.shared.getUser(by: userId) else {
            return
        }
        
        currentUser = user
        isAuthenticated = true
    }
    
    // Simple password hashing (use proper encryption in production)
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // Email validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

enum AuthError: Error, LocalizedError {
    case invalidEmail
    case userAlreadyExists
    case userNotFound
    case invalidPassword
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Invalid email format"
        case .userAlreadyExists:
            return "User with this email already exists"
        case .userNotFound:
            return "User not found"
        case .invalidPassword:
            return "Invalid password"
        }
    }
}
