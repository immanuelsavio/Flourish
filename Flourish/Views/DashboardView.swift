//
//  DashboardView.swift
//  FinanceApp
//
//  Dashboard showing account balances, budget summary, and recent expenses
//

import SwiftUI

struct DashboardView: View {
    @Environment(\.showProfileMenu) var showProfileMenu
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showActionCenter = false
    @State private var showAddAccount = false
    @State private var showAddBudget = false
    @State private var showAddSubscription = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    heroHeader
                    // Action Center Alert Badge
                    if let userId = authService.currentUser?.id {
                        let actionCount = dataService.getActionItems(for: userId).count
                        if actionCount > 0 {
                            actionCenterBanner(count: actionCount)
                        }
                    }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showProfileMenu.wrappedValue = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showActionCenter = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.title3)
                            
                            if let userId = authService.currentUser?.id {
                                let actionCount = dataService.getActionItems(for: userId).count
                                if actionCount > 0 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showActionCenter) {
                ActionCenterView()
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountView()
            }
            .sheet(isPresented: $showAddBudget) {
                AddBudgetCategoryView(month: Calendar.current.component(.month, from: Date()), year: Calendar.current.component(.year, from: Date()))
            }
            .sheet(isPresented: $showAddSubscription) {
                AddSubscriptionView()
            }
            .onAppear {
                // Process any due subscriptions
                if let userId = authService.currentUser?.id {
                    dataService.processSubscriptions(for: userId)
                    dataService.generateActionItems(for: userId)
                }
            }
        }
    }
    
    private func actionCenterBanner(count: Int) -> some View {
        Button(action: { showActionCenter = true }) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) Action\(count > 1 ? "s" : "") Needed")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Tap to review")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var heroHeader: some View {
        let totalBalance: Double = {
            if let userId = authService.currentUser?.id {
                return dataService.getAccounts(for: userId).reduce(0) { $0 + $1.balance }
            }
            return 0
        }()
        return ZStack(alignment: .leading) {
            LinearGradient(colors: [Color.teal, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(maxWidth: .infinity)
                .cornerRadius(16)
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome back")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                Text(totalBalance.formatAsCurrency())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("Total Balance")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        }
        .frame(height: 120)
    }
    
    private var accountSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accounts")
                .font(.headline)
            
            if let userId = authService.currentUser?.id {
                let accounts = dataService.getAccounts(for: userId)
                
                if accounts.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.blue)
                            Text("No accounts yet")
                                .font(.headline)
                            Spacer()
                        }
                        Text("Add a checking or savings account to get started.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button(action: { showAddAccount = true }) {
                            Label("Add Account", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.teal)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.teal.opacity(0.08))
                    .cornerRadius(12)
                } else {
                    ForEach(accounts) { account in
                        NavigationLink(destination: AccountTransactionsView(account: account)) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(account.name)
                                        .font(.subheadline)
                                    Text(account.type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(formatCurrency(account.balance))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(account.isCreditCard ? .red : .green)
                                    
                                    if account.isCreditCard {
                                        Text("Available: \(formatCurrency(account.creditAvailable))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
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
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "chart.pie.fill")
                                .foregroundColor(.indigo)
                            Text("No budget yet")
                                .font(.headline)
                            Spacer()
                        }
                        Text("Create your first monthly budget to track spending.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button(action: { showAddBudget = true }) {
                            Label("Create Budget", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.indigo)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.indigo.opacity(0.08))
                    .cornerRadius(12)
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
                    EmptyView()
                } else {
                    ForEach(Array(expenses)) { expense in
                        NavigationLink(destination: ExpenseDetailView(expense: expense)) {
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
                        .buttonStyle(PlainButtonStyle())
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
                let allSubs = dataService.getSubscriptions(for: userId)
                let dueSoon = allSubs.filter { $0.isDueSoon }.sorted { $0.nextDueDate < $1.nextDueDate }
                
                if allSubs.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                            Text("No subscriptions yet")
                                .font(.headline)
                            Spacer()
                        }
                        Text("Add recurring subscriptions to never miss a payment.")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button(action: { showAddSubscription = true }) {
                            Label("Add Subscription", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.orange.opacity(0.9))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.07))
                    .cornerRadius(12)
                } else if dueSoon.isEmpty {
                    EmptyView()
                } else {
                    ForEach(dueSoon) { subscription in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(subscription.name)
                                    .font(.subheadline)
                                Text("Due: \(subscription.nextDueDate.formatted())")
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
        amount.formatAsCurrency()
    }
    
    private func formatDate(_ date: Date) -> String {
        date.formatted()
    }
}

