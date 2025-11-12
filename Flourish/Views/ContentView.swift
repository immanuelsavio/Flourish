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
            
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
    }
}
