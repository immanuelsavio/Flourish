//
//  MonthlyReviewView.swift
//  Flourish
//
//  View for monthly finance review and reconciliation
//

import SwiftUI

struct MonthlyReviewView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    let month: Int
    let year: Int
    
    @State private var numbersMatch = true
    @State private var showingAdjustmentSheet = false
    @State private var showingConfirmation = false
    @State private var showingBudgetCopyPrompt = false
    @State private var accountAdjustments: [UUID: String] = [:]
    
    var monthYearString: String {
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        guard let date = Calendar.current.date(from: dateComponents) else {
            return "\(month)/\(year)"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Monthly Finance Review")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(monthYearString)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                    
                    if let userId = authService.currentUser?.id {
                        // Summary Section
                        summarySection(userId: userId)
                        
                        // Income Summary
                        incomeSection(userId: userId)
                        
                        // Expense Summary
                        expenseSection(userId: userId)
                        
                        // Budget Summary
                        budgetSection(userId: userId)
                        
                        // Action Buttons
                        actionButtons
                    }
                }
                .padding()
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAdjustmentSheet) {
                if let userId = authService.currentUser?.id {
                    AdjustBalancesView(
                        userId: userId,
                        month: month,
                        year: year,
                        accountAdjustments: $accountAdjustments,
                        onSave: handleAdjustments
                    )
                }
            }
            .alert("Confirm Review", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm") {
                    completeReview()
                }
            } message: {
                Text("Are you sure everything is correct for \(monthYearString)?")
            }
            .alert("Copy Budget?", isPresented: $showingBudgetCopyPrompt) {
                Button("No", role: .cancel) {
                    dismiss()
                }
                Button("Yes") {
                    copyBudgetToNextMonth()
                    dismiss()
                }
            } message: {
                Text("Do you want to copy this month's budget to next month?")
            }
        }
    }
    
    private func summarySection(userId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Balances")
                .font(.headline)
            
            let accounts = dataService.getAccounts(for: userId)
            
            if accounts.isEmpty {
                Text("No accounts to review")
                    .font(.subheadline)
                    .foregroundColor(.gray)
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
                        
                        Text(account.balance.formatAsCurrency())
                            .font(.headline)
                            .foregroundColor(account.isCreditCard ? .red : .green)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Total
                let totalBalance = accounts.reduce(0) { $0 + $1.balance }
                HStack {
                    Text("Total Balance")
                        .fontWeight(.bold)
                    Spacer()
                    Text(totalBalance.formatAsCurrency())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(totalBalance >= 0 ? .green : .red)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
    
    private func incomeSection(userId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income This Month")
                .font(.headline)
            
            let incomeTransactions = dataService.getIncomeTransactions(for: userId)
                .filter {
                    let transactionMonth = Calendar.current.component(.month, from: $0.date)
                    let transactionYear = Calendar.current.component(.year, from: $0.date)
                    return transactionMonth == month && transactionYear == year
                }
            
            if incomeTransactions.isEmpty {
                Text("No income recorded")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            } else {
                VStack(spacing: 8) {
                    ForEach(incomeTransactions) { transaction in
                        HStack {
                            Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                            Spacer()
                            Text(transaction.amount.formatAsCurrency())
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total Income")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(incomeTransactions.reduce(0) { $0 + $1.amount }.formatAsCurrency())
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.05))
                .cornerRadius(10)
            }
        }
    }
    
    private func expenseSection(userId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expenses This Month")
                .font(.headline)
            
            let expenses = dataService.getExpenses(for: userId, month: month, year: year)
            
            if expenses.isEmpty {
                Text("No expenses recorded")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Text("Total Expenses:")
                            .font(.subheadline)
                        Spacer()
                        Text("\(expenses.count) transactions")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Total Amount")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(expenses.reduce(0) { $0 + $1.userShare }.formatAsCurrency())
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.05))
                .cornerRadius(10)
            }
        }
    }
    
    private func budgetSection(userId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Performance")
                .font(.headline)
            
            let categories = dataService.getBudgetCategories(for: userId, month: month, year: year)
            
            if categories.isEmpty {
                Text("No budget set for this month")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            } else {
                let totalBudget = categories.reduce(0) { $0 + $1.monthlyLimit }
                let totalSpent = categories.reduce(0) { $0 + $1.spent }
                let remaining = totalBudget - totalSpent
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Total Budget:")
                        Spacer()
                        Text(totalBudget.formatAsCurrency())
                    }
                    
                    HStack {
                        Text("Total Spent:")
                        Spacer()
                        Text(totalSpent.formatAsCurrency())
                            .foregroundColor(totalSpent > totalBudget ? .red : .primary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Remaining:")
                            .fontWeight(.bold)
                        Spacer()
                        Text(remaining.formatAsCurrency())
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(remaining < 0 ? .red : .green)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(10)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Question
            Text("Do your app numbers match your bank statement?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            // Match Toggle
            Picker("", selection: $numbersMatch) {
                Text("Yes, they match").tag(true)
                Text("No, they don't match").tag(false)
            }
            .pickerStyle(.segmented)
            
            // Action Button
            if numbersMatch {
                Button(action: {
                    showingConfirmation = true
                }) {
                    Label("Complete Review", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            } else {
                Button(action: {
                    showingAdjustmentSheet = true
                }) {
                    Label("Adjust Balances", systemImage: "slider.horizontal.3")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                
                Text("Enter your actual account balances and we'll create adjustment entries to match.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func handleAdjustments() {
        guard let userId = authService.currentUser?.id else { return }
        
        var balances: [UUID: Double] = [:]
        for (accountId, amountString) in accountAdjustments {
            if let amount = Double(amountString) {
                balances[accountId] = amount
            }
        }
        
        dataService.reconcileAccountsForReview(userId: userId, accountBalances: balances)
        
        // Delay to allow adjustment sheet to dismiss first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completeReview()
        }
    }
    
    private func completeReview() {
        guard let userId = authService.currentUser?.id else { return }
        
        dataService.completeMonthlyReview(for: userId, month: month, year: year)
        
        // Show budget copy prompt
        showingBudgetCopyPrompt = true
    }
    
    private func copyBudgetToNextMonth() {
        guard let userId = authService.currentUser?.id else { return }
        dataService.copyBudgetToNextMonth(userId: userId, fromMonth: month, fromYear: year)
    }
}

struct AdjustBalancesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    
    let userId: UUID
    let month: Int
    let year: Int
    @Binding var accountAdjustments: [UUID: String]
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Enter Actual Balances")) {
                    Text("Enter the actual balance from your bank statement for each account.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Section {
                    let accounts = dataService.getAccounts(for: userId)
                    
                    ForEach(accounts) { account in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(account.name)
                                    .font(.headline)
                                Spacer()
                                Text("Current: \(account.balance.formatAsCurrency())")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Text("Actual Balance:")
                                    .font(.subheadline)
                                TextField("Amount", text: binding(for: account.id))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            if let amountStr = accountAdjustments[account.id],
                               let amount = Double(amountStr) {
                                let difference = amount - account.balance
                                if abs(difference) > 0.01 {
                                    Text("Adjustment: \(difference.formatAsCurrency())")
                                        .font(.caption)
                                        .foregroundColor(difference > 0 ? .green : .red)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Adjust Balances")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save & Complete") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func binding(for accountId: UUID) -> Binding<String> {
        Binding(
            get: {
                accountAdjustments[accountId] ?? ""
            },
            set: { newValue in
                accountAdjustments[accountId] = newValue
            }
        )
    }
}

#Preview {
    MonthlyReviewView(month: 11, year: 2025)
        .environmentObject(DataService.shared)
}
