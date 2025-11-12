//
//  QuickAddExpenseView.swift
//  FinanceApp
//
//  Quick add expense with pre-selected category
//

import SwiftUI

struct QuickAddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    let preselectedCategory: String
    
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedAccountId: UUID?
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Quick Expense")) {
                    Text("Category: \(preselectedCategory)")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Description", text: $description)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("Payment Account")) {
                    if let userId = authService.currentUser?.id {
                        let accounts = dataService.getAccounts(for: userId)
                        
                        Picker("Account", selection: $selectedAccountId) {
                            Text("Select Account").tag(nil as UUID?)
                            
                            // Group by account type
                            ForEach(accounts.filter { $0.type == .checking || $0.type == .savings }) { account in
                                Label(account.name, systemImage: "building.columns")
                                    .tag(account.id as UUID?)
                            }
                            
                            ForEach(accounts.filter { $0.type == .creditCard }) { account in
                                Label(account.name, systemImage: "creditcard")
                                    .tag(account.id as UUID?)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to \(preselectedCategory)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !amount.isEmpty && !description.isEmpty && selectedAccountId != nil
    }
    
    private func saveExpense() {
        guard let userId = authService.currentUser?.id,
              let accountId = selectedAccountId,
              let expenseAmount = Double(amount) else { return }
        
        let expense = Expense(
            userId: userId,
            amount: expenseAmount,
            date: date,
            description: description,
            categoryName: preselectedCategory,
            accountId: accountId
        )
        
        dataService.saveExpense(expense)
        dismiss()
    }
}
