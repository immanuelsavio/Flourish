//
//  MoreView.swift
//  FinanceApp
//
//  View for accounts, subscriptions, and settings
//

import SwiftUI

struct MoreView: View {
    @StateObject private var authService = AuthenticationService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Accounts")) {
                    NavigationLink(destination: AccountsListView()) {
                        Label("Manage Accounts", systemImage: "creditcard.fill")
                    }
                }
                
                Section(header: Text("Subscriptions")) {
                    NavigationLink(destination: SubscriptionsListView()) {
                        Label("Manage Subscriptions", systemImage: "arrow.clockwise")
                    }
                }
                
                Section(header: Text("Reports")) {
                    NavigationLink(destination: MonthlyReportView()) {
                        Label("Monthly Reports", systemImage: "chart.bar.fill")
                    }
                }
                
                Section(header: Text("Account")) {
                    if let user = authService.currentUser {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.headline)
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        authService.logout()
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("More")
        }
    }
}

// MARK: - Accounts List View

struct AccountsListView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddAccount = false
    
    var body: some View {
        VStack {
            if let userId = authService.currentUser?.id {
                let accounts = dataService.getAccounts(for: userId)
                
                if accounts.isEmpty {
                    VStack {
                        Text("No accounts yet")
                            .foregroundColor(.gray)
                        Text("Tap + to add your first account")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(accounts) { account in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(account.name)
                                        .font(.headline)
                                    Text(account.type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text(formatCurrency(account.balance))
                                    .font(.headline)
                                    .foregroundColor(account.isCreditCard ? .red : .green)
                            }
                        }
                        .onDelete(perform: deleteAccounts)
                    }
                }
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddAccount = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddAccount) {
            AddAccountView()
        }
    }
    
    private func deleteAccounts(at offsets: IndexSet) {
        guard let userId = authService.currentUser?.id else { return }
        let accounts = dataService.getAccounts(for: userId)
        
        for index in offsets {
            dataService.deleteAccount(accounts[index])
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct AddAccountView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var name = ""
    @State private var type: AccountType = .checking
    @State private var balance = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Details")) {
                    TextField("Account Name", text: $name)
                    
                    Picker("Type", selection: $type) {
                        ForEach(AccountType.allCases, id: \.self) { accountType in
                            Text(accountType.rawValue).tag(accountType)
                        }
                    }
                    
                    TextField("Starting Balance", text: $balance)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAccount()
                    }
                    .disabled(name.isEmpty || balance.isEmpty)
                }
            }
        }
    }
    
    private func saveAccount() {
        guard let userId = authService.currentUser?.id,
              let accountBalance = Double(balance) else { return }
        
        let account = Account(
            userId: userId,
            name: name,
            type: type,
            balance: accountBalance
        )
        
        dataService.saveAccount(account)
        dismiss()
    }
}

// MARK: - Subscriptions List View

struct SubscriptionsListView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddSubscription = false
    
    var body: some View {
        VStack {
            if let userId = authService.currentUser?.id {
                let subscriptions = dataService.getSubscriptions(for: userId)
                
                if subscriptions.isEmpty {
                    VStack {
                        Text("No subscriptions yet")
                            .foregroundColor(.gray)
                        Text("Tap + to add your first subscription")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(subscriptions) { subscription in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(subscription.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text(formatCurrency(subscription.amount))
                                        .font(.headline)
                                }
                                
                                Text("Next due: \(formatDate(subscription.nextDueDate))")
                                    .font(.caption)
                                    .foregroundColor(subscription.isDueSoon ? .orange : .gray)
                                
                                Text(subscription.categoryName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onDelete(perform: deleteSubscriptions)
                    }
                }
            }
        }
        .navigationTitle("Subscriptions")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSubscription = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSubscription) {
            AddSubscriptionView()
        }
    }
    
    private func deleteSubscriptions(at offsets: IndexSet) {
        guard let userId = authService.currentUser?.id else { return }
        let subscriptions = dataService.getSubscriptions(for: userId)
        
        for index in offsets {
            dataService.deleteSubscription(subscriptions[index])
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

struct AddSubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var name = ""
    @State private var amount = ""
    @State private var selectedCategory = ""
    @State private var selectedAccountId: UUID?
    @State private var nextDueDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Subscription Details")) {
                    TextField("Name", text: $name)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Next Due Date", selection: $nextDueDate, displayedComponents: .date)
                }
                
                Section(header: Text("Transfers")) {
                    NavigationLink(destination: TransferListView()) {
                        Label("Account Transfers", systemImage: "arrow.left.arrow.right")
                    }
                }

                Section(header: Text("Savings & Investments")) {
                    NavigationLink(destination: SavingsBudgetView()) {
                        Label("Savings Goals", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
                
                Section(header: Text("Category")) {
                    if let userId = authService.currentUser?.id {
                        let now = Date()
                        let month = Calendar.current.component(.month, from: now)
                        let year = Calendar.current.component(.year, from: now)
                        let categories = dataService.getBudgetCategories(for: userId, month: month, year: year)
                        
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select Category").tag("")
                            ForEach(categories, id: \.name) { category in
                                Text(category.name).tag(category.name)
                            }
                        }
                    }
                }
                
                Section(header: Text("Payment Account")) {
                    if let userId = authService.currentUser?.id {
                        let accounts = dataService.getAccounts(for: userId)
                        
                        Picker("Account", selection: $selectedAccountId) {
                            Text("Select Account").tag(nil as UUID?)
                            ForEach(accounts) { account in
                                Text(account.name).tag(account.id as UUID?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSubscription()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !amount.isEmpty && !selectedCategory.isEmpty && selectedAccountId != nil
    }
    
    private func saveSubscription() {
        guard let userId = authService.currentUser?.id,
              let accountId = selectedAccountId,
              let subscriptionAmount = Double(amount) else { return }
        
        let subscription = Subscription(
            userId: userId,
            name: name,
            amount: subscriptionAmount,
            categoryName: selectedCategory,
            accountId: accountId,
            nextDueDate: nextDueDate
        )
        
        dataService.saveSubscription(subscription)
        dismiss()
    }
}

// MARK: - Monthly Report View

struct MonthlyReportView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    
    init() {
        let now = Date()
        _selectedMonth = State(initialValue: Calendar.current.component(.month, from: now))
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: now))
    }
    
    var body: some View {
        VStack {
            // Month selector
            monthSelector
            
            if let userId = authService.currentUser?.id {
                List {
                    // Budget Summary
                    Section(header: Text("Budget Summary")) {
                        let categories = dataService.getBudgetCategories(for: userId, month: selectedMonth, year: selectedYear)
                        
                        if categories.isEmpty {
                            Text("No budget for this month")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(categories) { category in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(category.name)
                                        .font(.headline)
                                    HStack {
                                        Text("Spent: \(formatCurrency(category.spent))")
                                        Text("Budget: \(formatCurrency(category.monthlyLimit))")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                }
                            }
                            
                            let totalBudget = categories.reduce(0) { $0 + $1.monthlyLimit }
                            let totalSpent = categories.reduce(0) { $0 + $1.spent }
                            
                            HStack {
                                Text("Total")
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(formatCurrency(totalSpent)) / \(formatCurrency(totalBudget))")
                                    .fontWeight(.bold)
                                    .foregroundColor(totalSpent > totalBudget ? .red : .green)
                            }
                        }
                    }
                    
                    // Expenses Summary
                    Section(header: Text("Expenses This Month")) {
                        let expenses = dataService.getExpenses(for: userId, month: selectedMonth, year: selectedYear)
                        
                        if expenses.isEmpty {
                            Text("No expenses this month")
                                .foregroundColor(.gray)
                        } else {
                            Text("Total expenses: \(expenses.count)")
                            Text("Total amount: \(formatCurrency(expenses.reduce(0) { $0 + $1.userShare }))")
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Monthly Report")
    }
    
    private var monthSelector: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            
            Text("\(monthName(selectedMonth)) \(selectedYear)")
                .font(.headline)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }
    
    private func previousMonth() {
        selectedMonth -= 1
        if selectedMonth < 1 {
            selectedMonth = 12
            selectedYear -= 1
        }
    }
    
    private func nextMonth() {
        selectedMonth += 1
        if selectedMonth > 12 {
            selectedMonth = 1
            selectedYear += 1
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: 2000, month: month, day: 1))!
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
