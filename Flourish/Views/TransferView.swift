//
//  TransferView.swift
//  FinanceApp
//
//  View for scheduling transfers between accounts (all transfers require approval)
//

import SwiftUI

struct TransferView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var fromAccountId: UUID?
    @State private var toAccountId: UUID?
    @State private var amount = ""
    @State private var scheduledDate = Date()
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurrenceInterval = "7" // Default to weekly
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transfer Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Scheduled Date", selection: $scheduledDate, displayedComponents: .date)
                    
                    TextField("Notes (optional)", text: $notes)
                }
                
                Section(header: Text("Recurrence (Optional)")) {
                    Toggle("Recurring Transfer", isOn: $isRecurring)
                    
                    if isRecurring {
                        HStack {
                            Text("Repeat every")
                            TextField("Days", text: $recurrenceInterval)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 50)
                            Text("days")
                        }
                        
                        Text("Examples: 7 for weekly, 14 for biweekly, 30 for monthly")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("All transfers require approval")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Text("After scheduling, you'll need to approve this transfer in the Action Center before it executes.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Schedule Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schedule") {
                        saveScheduledTransfer()
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
        
        if isRecurring {
            guard let interval = Int(recurrenceInterval), interval > 0 else {
                return false
            }
        }
        
        return true
    }
    
    private func saveScheduledTransfer() {
        guard let userId = authService.currentUser?.id,
              let fromId = fromAccountId,
              let toId = toAccountId,
              let transferAmount = Double(amount) else { return }
        
        let recurrence = isRecurring ? Int(recurrenceInterval) : nil
        
        let scheduledTransfer = ScheduledTransfer(
            userId: userId,
            fromAccountId: fromId,
            toAccountId: toId,
            amount: transferAmount,
            scheduledDate: scheduledDate,
            recurrenceDays: recurrence,
            notes: notes.isEmpty ? nil : notes,
            isCompleted: false
        )
        
        dataService.saveScheduledTransfer(scheduledTransfer)
        dismiss()
    }
}
