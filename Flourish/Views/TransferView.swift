//
//  TransferView.swift
//  FinanceApp
//
//  View for transferring money between accounts
//

import SwiftUI

struct TransferView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var fromAccountId: UUID?
    @State private var toAccountId: UUID?
    @State private var amount = ""
    @State private var date = Date()
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transfer Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Notes (optional)", text: $notes)
                }
                
                Section(header: Text("From Account")) {
                    if let userId = authService.currentUser?.id {
                        let accounts = dataService.getAccounts(for: userId)
                        
                        Picker("From", selection: $fromAccountId) {
                            Text("Select Account").tag(nil as UUID?)
                            ForEach(accounts) { account in
                                Text("\(account.name) (\(account.type.rawValue))")
                                    .tag(account.id as UUID?)
                            }
                        }
                    }
                }
                
                Section(header: Text("To Account")) {
                    if let userId = authService.currentUser?.id {
                        let accounts = dataService.getAccounts(for: userId)
                        
                        Picker("To", selection: $toAccountId) {
                            Text("Select Account").tag(nil as UUID?)
                            ForEach(accounts) { account in
                                Text("\(account.name) (\(account.type.rawValue))")
                                    .tag(account.id as UUID?)
                            }
                        }
                    }
                }
                
                if let fromId = fromAccountId, let toId = toAccountId, fromId == toId {
                    Section {
                        Text("Cannot transfer to the same account")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Transfer Money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Transfer") {
                        saveTransfer()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        guard !amount.isEmpty,
              let fromId = fromAccountId,
              let toId = toAccountId,
              fromId != toId else {
            return false
        }
        return true
    }
    
    private func saveTransfer() {
        guard let userId = authService.currentUser?.id,
              let fromId = fromAccountId,
              let toId = toAccountId,
              let transferAmount = Double(amount) else { return }
        
        let transfer = Transfer(
            userId: userId,
            fromAccountId: fromId,
            toAccountId: toId,
            amount: transferAmount,
            date: date,
            notes: notes
        )
        
        dataService.saveTransfer(transfer)
        dismiss()
    }
}
