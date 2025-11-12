//
//  AccountTransactionsView.swift
//  Flourish
//
//  View showing all transactions for a specific account
//

import SwiftUI

struct AccountTransactionsView: View {
    @EnvironmentObject var dataService: DataService
    let account: Account
    
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedCategory: String = "All"
    @State private var showingFilters = false
    
    var body: some View {
        VStack {
            // Account Summary Header
            VStack(spacing: 8) {
                Text(account.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(account.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(account.balance.formatAsCurrency())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(account.isCreditCard ? (account.balance < 0 ? .red : .green) : (account.balance >= 0 ? .green : .red))
                
                if account.isCreditCard, let limit = account.creditLimit {
                    VStack(spacing: 4) {
                        Text("Available: \(account.creditAvailable.formatAsCurrency())")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        ProgressView(value: account.creditUsagePercent, total: 100)
                            .tint(account.isOverCreditWarning ? .red : .blue)
                    }
                    .padding(.horizontal)
                }
                
                Button(action: { showingFilters.toggle() }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filters")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Transactions List
            List {
                ForEach(filteredTransactions) { expense in
                    NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                        TransactionRow(expense: expense, account: account)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ReconcileBalanceView(account: account)) {
                    Label("Reconcile", systemImage: "checkmark.circle")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            TransactionFiltersView(
                selectedMonth: $selectedMonth,
                selectedYear: $selectedYear,
                selectedCategory: $selectedCategory,
                availableCategories: availableCategories
            )
        }
    }
    
    private var filteredTransactions: [Expense] {
        let transactions = dataService.expenses.filter { $0.accountId == account.id }
        
        var filtered = transactions
        
        // Filter by month/year if not "All"
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.categoryName == selectedCategory }
        }
        
        // Sort by newest first
        return filtered.sorted { $0.date > $1.date }
    }
    
    private var availableCategories: [String] {
        let categories = Set(dataService.expenses
            .filter { $0.accountId == account.id }
            .map { $0.categoryName })
        return ["All"] + categories.sorted()
    }
}

struct TransactionRow: View {
    let expense: Expense
    let account: Account
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.headline)
                
                HStack {
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text(expense.categoryName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Show amount based on account type and transaction direction
                let isIncome = expense.categoryName == "Income" || expense.categoryName == "Reconciliation"
                let displayAmount = isIncome ? expense.amount : expense.userShare
                
                Text(displayAmount.formatAsCurrency())
                    .font(.headline)
                    .foregroundColor(isIncome ? .green : .primary)
                
                if !expense.splitParticipants.isEmpty {
                    Text("Split")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TransactionFiltersView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    @Binding var selectedCategory: String
    let availableCategories: [String]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(availableCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Date Range")) {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthName(month)).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Year", selection: $selectedYear) {
                        ForEach(2020...2030, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Filter Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.monthSymbols[month - 1]
    }
}

#Preview {
    NavigationView {
        AccountTransactionsView(account: Account(
            userId: UUID(),
            name: "Checking",
            type: .checking,
            balance: 5000
        ))
        .environmentObject(DataService.shared)
    }
}
