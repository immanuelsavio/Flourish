//
//  DashboardView.swift
//  FinanceApp
//
//  Dashboard showing account balances, budget summary, and recent expenses
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Account Summary
                    accountSummarySection
                    
                    // Budget Summary
                    budgetSummarySection
                    
                    // Recent Expenses
                    recentExpensesSection
                    
                    // Upcoming Subscriptions
                    upcomingSubscriptionsSection
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .onAppear {
                // Process any due subscriptions
                if let userId = authService.currentUser?.id {
                    dataService.processSubscriptions(for: userId)
                }
            }
        }
    }
    
    private var accountSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accounts")
                .font(.headline)
            
            if let userId = authService.currentUser?.id {
                let accounts = dataService.getAccounts(for: userId)
                
                if accounts.isEmpty {
                    Text("No accounts yet. Add one in the More tab.")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(accounts) { account in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(account.name)
                                    .font(.subheadline)
                                Text(account.type.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text(formatCurrency(account.balance))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(account.isCreditCard ? .red : .green)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private var budgetSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This Month's Budget")
                .font(.headline)
            
            if let userId = authService.currentUser?.id {
                let now = Date()
                let month = Calendar.current.component(.month, from: now)
                let year = Calendar.current.component(.year, from: now)
                let categories = dataService.getBudgetCategories(for: userId, month: month, year: year)
                
                if categories.isEmpty {
                    Text("No budget set. Create one in the Budget tab.")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    let totalBudget = categories.reduce(0) { $0 + $1.monthlyLimit }
                    let totalSpent = categories.reduce(0) { $0 + $1.spent }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total Budget:")
                            Spacer()
                            Text(formatCurrency(totalBudget))
                        }
                        
                        HStack {
                            Text("Total Spent:")
                            Spacer()
                            Text(formatCurrency(totalSpent))
                                .foregroundColor(totalSpent > totalBudget ? .red : .primary)
                        }
                        
                        HStack {
                            Text("Remaining:")
                            Spacer()
                            Text(formatCurrency(totalBudget - totalSpent))
                                .fontWeight(.bold)
                                .foregroundColor(totalBudget - totalSpent < 0 ? .red : .green)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Expenses")
                .font(.headline)
            
            if let userId = authService.currentUser?.id {
                let expenses = dataService.getExpenses(for: userId)
                    .sorted { $0.date > $1.date }
                    .prefix(5)
                
                if expenses.isEmpty {
                    Text("No expenses yet.")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(Array(expenses)) { expense in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.description)
                                    .font(.subheadline)
                                Text(expense.categoryName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text(formatCurrency(expense.userShare))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private var upcomingSubscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Subscriptions")
                .font(.headline)
            
            if let userId = authService.currentUser?.id {
                let subscriptions = dataService.getSubscriptions(for: userId)
                    .filter { $0.isDueSoon }
                    .sorted { $0.nextDueDate < $1.nextDueDate }
                
                if subscriptions.isEmpty {
                    Text("No subscriptions due soon.")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(subscriptions) { subscription in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(subscription.name)
                                    .font(.subheadline)
                                Text("Due: \(formatDate(subscription.nextDueDate))")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            
                            Spacer()
                            
                            Text(formatCurrency(subscription.amount))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
