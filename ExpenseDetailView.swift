//
//  ExpenseDetailView.swift
//  Flourish
//
//  Detailed view for a single expense/transaction
//

import SwiftUI

struct ExpenseDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    let expense: Expense
    
    @State private var showEditView = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
            Section(header: Text("Transaction Details")) {
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(expense.amount.formatAsCurrency())
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Description")
                    Spacer()
                    Text(expense.description)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Category")
                    Spacer()
                    Text(expense.categoryName)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Date")
                    Spacer()
                    Text(expense.date.formatted(date: .long, time: .omitted))
                        .foregroundColor(.gray)
                }
                
                if let account = dataService.getAccount(by: expense.accountId) {
                    HStack {
                        Text("Account")
                        Spacer()
                        Text(account.name)
                            .foregroundColor(.gray)
                    }
                }
                
                if expense.isSubscription {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.orange)
                        Text("Recurring Subscription")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            if !expense.splitParticipants.isEmpty {
                Section(header: Text("Split Details")) {
                    ForEach(expense.splitParticipants) { participant in
                        HStack {
                            if participant.isCurrentUser {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                            }
                            Text(participant.name)
                            Spacer()
                            Text(participant.amount.formatAsCurrency())
                                .foregroundColor(participant.isCurrentUser ? .blue : .green)
                        }
                    }
                    
                    HStack {
                        Text("Your Share")
                            .fontWeight(.bold)
                        Spacer()
                        Text(expense.userShare.formatAsCurrency())
                            .fontWeight(.bold)
                    }
                }
            }
            
            Section {
                Button(action: { showEditView = true }) {
                    Label("Edit Transaction", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Label("Delete Transaction", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditView) {
            EditExpenseView(expense: expense)
        }
        .alert("Delete Transaction?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataService.deleteExpense(expense)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone. Account balance will be adjusted.")
        }
    }
}

struct EditExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    let expense: Expense
    
    @State private var amount: String
    @State private var description: String
    @State private var categoryName: String
    @State private var selectedAccount: Account?
    @State private var date: Date
    
    init(expense: Expense) {
        self.expense = expense
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _description = State(initialValue: expense.description)
        _categoryName = State(initialValue: expense.categoryName)
        _date = State(initialValue: expense.date)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Description", text: $description)
                    
                    TextField("Category", text: $categoryName)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                if let userId = authService.currentUser?.id {
                    let accounts = dataService.getAccounts(for: userId)
                    
                    Section(header: Text("Account")) {
                        Picker("Account", selection: $selectedAccount) {
                            ForEach(accounts) { account in
                                Text(account.name).tag(account as Account?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                selectedAccount = dataService.getAccount(by: expense.accountId)
            }
        }
    }
    
    private var isValid: Bool {
        guard let _ = Double(amount), !amount.isEmpty else { return false }
        guard !description.isEmpty else { return false }
        guard !categoryName.isEmpty else { return false }
        guard selectedAccount != nil else { return false }
        return true
    }
    
    private func saveChanges() {
        guard let amountValue = Double(amount),
              let account = selectedAccount else { return }
        
        var updatedExpense = expense
        updatedExpense.amount = amountValue
        updatedExpense.description = description
        updatedExpense.categoryName = categoryName
        updatedExpense.accountId = account.id
        updatedExpense.date = date
        
        dataService.updateExpense(updatedExpense)
        dismiss()
    }
}

#Preview {
    NavigationView {
        ExpenseDetailView(expense: Expense(
            userId: UUID(),
            amount: 45.99,
            description: "Grocery Shopping",
            categoryName: "Food",
            accountId: UUID()
        ))
        .environmentObject(DataService.shared)
    }
}
