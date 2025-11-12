//
//  AuthenticationView.swift
//  FinanceApp
//
//  View for user login and registration
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo or App Name
                    VStack(spacing: 8) {
                        // Try to use custom logo, fallback to SF Symbol
                        if let _ = UIImage(named: "FlourishLogo") {
                            Image("FlourishLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                        } else {
                            // Fallback to SF Symbol with Flourish styling
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green, Color.blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("Flourish")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Manage your finances")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Input Fields
                    VStack(spacing: 15) {
                        if isRegistering {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Name")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                TextField("Enter your name", text: $name)
                                    .textFieldStyle(.plain)
                                    .autocapitalization(.words)
                                    .textContentType(.name)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(.plain)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .font(.caption)
                                .foregroundColor(.gray)
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(.plain)
                                .textContentType(.none)
                                .autocorrectionDisabled(true)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Action Button
                    Button(action: handleAuthentication) {
                        Text(isRegistering ? "Create Account" : "Sign In")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    
                    // Toggle between login and registration
                    Button(action: {
                        withAnimation {
                            isRegistering.toggle()
                            errorMessage = ""
                            showError = false
                        }
                    }) {
                        Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Create Account")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                    
                    // Quick Test Login Button
                    if !isRegistering {
                        Button(action: quickTestLogin) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Quick Test Login")
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.top, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        if isRegistering {
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func quickTestLogin() {
        // Create test account if it doesn't exist
        let testEmail = "admin"
        let testPassword = "admin123"
        let testName = "Admin User"
        
        // Try to login first
        var success = authService.login(email: testEmail, password: testPassword)
        
        // If login fails, create the account
        if !success {
            success = authService.register(name: testName, email: testEmail, password: testPassword)
            if success {
                // Registration successful, user is automatically logged in
                return
            }
        }
        
        if !success {
            errorMessage = "Failed to create or login with test account."
            showError = true
        }
    }
    
    private func handleAuthentication() {
        if isRegistering {
            // Validate inputs
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                errorMessage = "Please enter your name."
                showError = true
                return
            }
            
            guard email.contains("@") && email.contains(".") else {
                errorMessage = "Please enter a valid email address."
                showError = true
                return
            }
            
            guard password.count >= 6 else {
                errorMessage = "Password must be at least 6 characters long."
                showError = true
                return
            }
            
            let success = authService.register(name: name, email: email, password: password)
            if !success {
                errorMessage = "Registration failed. Email may already be in use."
                showError = true
            }
        } else {
            let success = authService.login(email: email, password: password)
            if !success {
                errorMessage = "Invalid email or password."
                showError = true
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
