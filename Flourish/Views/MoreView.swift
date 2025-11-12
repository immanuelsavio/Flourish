//
//  MoreView.swift
//  FinanceApp
//
//  View for accounts, subscriptions, and settings
//

import SwiftUI

struct MoreView: View {
    @Environment(\.showProfileMenu) var showProfileMenu
    @StateObject private var authService = AuthenticationService.shared
    
    var body: some View {
        List {
            Section(header: Text("Income & Expenses")) {
                NavigationLink(destination: SalaryManagementView()) {
                    Label("Salary & Income", systemImage: "banknote.fill")
                }
            }
            
            Section(header: Text("Manage")) {
                NavigationLink(destination: AccountsListView()) {
                    Label("Manage Accounts", systemImage: "creditcard.fill")
                }
                
                NavigationLink(destination: SubscriptionsListView()) {
                    Label("Manage Subscriptions", systemImage: "arrow.clockwise")
                }
                
                NavigationLink(destination: TransferListView()) {
                    Label("Account Transfers", systemImage: "arrow.left.arrow.right")
                }
                
                NavigationLink(destination: SavingsBudgetView()) {
                    Label("Savings Goals", systemImage: "chart.line.uptrend.xyaxis")
                }
                
                NavigationLink(destination: MonthlyReportView()) {
                    Label("Monthly Reports", systemImage: "chart.bar.fill")
                }
            }
        }
        .navigationTitle("More")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showProfileMenu.wrappedValue = true }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                }
            }
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
                            NavigationLink(destination: EditAccountView(account: account)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(account.name)
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        if account.isCreditCard {
                                            Text(formatCurrency(abs(account.balance)))
                                                .font(.headline)
                                                .foregroundColor(.red)
                                        } else {
                                            Text(formatCurrency(account.balance))
                                                .font(.headline)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    
                                    HStack {
                                        Text(account.type.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        if account.isCreditCard, let limit = account.creditLimit {
                                            Spacer()
                                            let used = abs(account.balance)
                                            let percent = (used / limit) * 100
                                            let available = limit - used
                                            
                                            HStack(spacing: 4) {
                                                Text("Available: \(available.formatAsCurrency())")
                                                Text("(\(String(format: "%.0f%%", percent)) used)")
                                            }
                                            .font(.caption)
                                            .foregroundColor(account.isOverCreditWarning ? .orange : .gray)
                                        }
                                    }
                                }
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
        amount.formatAsCurrency()
    }
}

struct AddAccountView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var name = ""
    @State private var type: AccountType = .checking
    @State private var balance = ""
    @State private var creditLimit = ""
    @State private var creditWarningPercent = ""
    
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
                    
                    TextField(type == .creditCard ? "Starting Balance (0 for new card)" : "Starting Balance", text: $balance)
                        .keyboardType(.decimalPad)
                }
                
                if type == .creditCard {
                    Section(header: Text("Credit Card Settings")) {
                        TextField("Credit Limit ($)", text: $creditLimit)
                            .keyboardType(.decimalPad)
                        
                        TextField("Warning at % Usage (Optional)", text: $creditWarningPercent)
                            .keyboardType(.numberPad)
                        
                        Text("Enter the percentage at which you want to be warned (e.g., 80 for 80%)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        if name.isEmpty || balance.isEmpty {
            return false
        }
        
        if type == .creditCard && creditLimit.isEmpty {
            return false
        }
        
        return true
    }
    
    private func saveAccount() {
        guard let userId = authService.currentUser?.id,
              let accountBalance = Double(balance) else { return }
        
        let account = Account(
            userId: userId,
            name: name,
            type: type,
            balance: accountBalance,
            creditLimit: type == .creditCard ? Double(creditLimit) : nil,
            creditUsageWarning: type == .creditCard ? Double(creditWarningPercent) : nil
        )
        
        dataService.saveAccount(account)
        dismiss()
    }
}

// MARK: - Edit Account View

struct EditAccountView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    
    let account: Account
    
    @State private var name = ""
    @State private var balance = ""
    @State private var creditLimit = ""
    @State private var creditWarningPercent = ""
    
    var body: some View {
        Form {
            Section(header: Text("Account Details")) {
                TextField("Account Name", text: $name)
                
                Text(account.type.rawValue)
                    .foregroundColor(.gray)
                
                TextField(account.isCreditCard ? "Current Balance (Negative = Used)" : "Current Balance", text: $balance)
                    .keyboardType(.decimalPad)
            }
            
            if account.isCreditCard {
                Section(header: Text("Credit Card Settings")) {
                    TextField("Credit Limit ($)", text: $creditLimit)
                        .keyboardType(.decimalPad)
                    
                    TextField("Warning at % Usage (Optional)", text: $creditWarningPercent)
                        .keyboardType(.numberPad)
                    
                    if let limit = Double(creditLimit), limit > 0 {
                        if let bal = Double(balance) {
                            let used = abs(bal)
                            let available = limit - used
                            let percent = (used / limit) * 100
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Used:")
                                    Spacer()
                                    Text(used.formatAsCurrency())
                                }
                                HStack {
                                    Text("Available:")
                                    Spacer()
                                    Text(available.formatAsCurrency())
                                        .foregroundColor(available < 0 ? .red : .green)
                                }
                                HStack {
                                    Text("Usage:")
                                    Spacer()
                                    Text(String(format: "%.1f%%", percent))
                                        .foregroundColor(percent > 80 ? .red : percent > 60 ? .orange : .green)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(name.isEmpty || balance.isEmpty)
            }
        }
        .onAppear {
            name = account.name
            balance = String(account.balance)
            if let limit = account.creditLimit {
                creditLimit = String(limit)
            }
            if let warning = account.creditUsageWarning {
                creditWarningPercent = String(Int(warning))
            }
        }
    }
    
    private func saveChanges() {
        guard let accountBalance = Double(balance) else { return }
        
        var updatedAccount = account
        updatedAccount.name = name
        updatedAccount.balance = accountBalance
        
        if account.isCreditCard {
            updatedAccount.creditLimit = Double(creditLimit)
            updatedAccount.creditUsageWarning = Double(creditWarningPercent)
        }
        
        dataService.saveAccount(updatedAccount)
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
        amount.formatAsCurrency()
    }
    
    private func formatDate(_ date: Date) -> String {
        date.formatted()
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
        amount.formatAsCurrency()
    }
}

