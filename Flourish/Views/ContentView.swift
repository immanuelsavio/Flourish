//
//  ContentView.swift
//  FinanceApp
//
//  Main content view with authentication check and tab navigation
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService.shared
    
    var body: some View {
        if authService.isAuthenticated {
            MainTabView()
        } else {
            AuthenticationView()
        }
    }
}

struct MainTabView: View {
    @State private var showProfileMenu = false
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie.fill")
                }
            
            ExpensesView()
                .tabItem {
                    Label("Expenses", systemImage: "dollarsign.circle.fill")
                }
            
            BalancesView()
                .tabItem {
                    Label("Balances", systemImage: "person.2.fill")
                }
            
            NavigationView {
                MoreView()
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle.fill")
            }
        }
        .sheet(isPresented: $showProfileMenu) {
            ProfileMenuView()
        }
        .environment(\.showProfileMenu, $showProfileMenu)
    }
}

// Environment key for profile menu
struct ShowProfileMenuKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var showProfileMenu: Binding<Bool> {
        get { self[ShowProfileMenuKey.self] }
        set { self[ShowProfileMenuKey.self] = newValue }
    }
}

// Profile Menu View
struct ProfileMenuView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthenticationService.shared
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Profile")) {
                    if let user = authService.currentUser {
                        Button(action: { showEditProfile = true }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(user.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                HStack {
                                    Spacer()
                                    Text("Tap to edit")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                Section(header: Text("App Info")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.gray)
                    }
                }
                
                Section {
                    Button(action: {
                        authService.logout()
                        dismiss()
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var name = ""
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
            .onAppear {
                if let user = authService.currentUser {
                    name = user.name
                    email = user.email
                }
            }
        }
    }
    
    private func saveProfile() {
        authService.updateCurrentUser(name: name, email: email)
        dismiss()
    }
}

