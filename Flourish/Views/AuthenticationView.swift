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
            VStack(spacing: 20) {
                // Logo or App Name
                Text("FinanceApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Spacer()
                
                // Input Fields
                VStack(spacing: 15) {
                    if isRegistering {
                        TextField("Name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 30)
                
                // Action Button
                Button(action: handleAuthentication) {
                    Text(isRegistering ? "Register" : "Login")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
                // Toggle between login and registration
                Button(action: {
                    isRegistering.toggle()
                    errorMessage = ""
                    showError = false
                }) {
                    Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                        .foregroundColor(.blue)
                }
                .padding(.top, 10)
                
                Spacer()
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
    
    private func handleAuthentication() {
        if isRegistering {
            let result = authService.register(email: email, name: name, password: password)
            switch result {
            case .success:
                break // User is automatically logged in
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        } else {
            let result = authService.login(email: email, password: password)
            switch result {
            case .success:
                break // User is logged in
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
