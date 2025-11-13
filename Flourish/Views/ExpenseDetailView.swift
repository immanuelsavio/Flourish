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
