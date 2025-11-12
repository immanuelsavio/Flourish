//
//  BalancesView.swift
//  FinanceApp
//
//  View for tracking balances owed by others (Splitwise-style)
//

import SwiftUI

struct BalancesView: View {
    @Environment(\.showProfileMenu) var showProfileMenu
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddRepayment = false
    @State private var selectedPerson: String?
    @State private var showSettleUp = false
    @State private var settleUpPerson: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if let userId = authService.currentUser?.id {
                    let balances = dataService.getBalancesOwed(for: userId).sorted { $0.amount > $1.amount }
                    let ious = dataService.getActiveFriendIOUs(for: userId)
                    
                    if balances.isEmpty && ious.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No outstanding balances")
                                .foregroundColor(.gray)
                            Text("Split expenses and IOUs will appear here")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        List {
                            if !balances.isEmpty {
                                Section(header: Text("From Expense Splits")) {
                                    ForEach(balances) { balance in
                                        BalanceRow(
                                            personName: balance.personName,
                                            amount: balance.amount,
                                            lastUpdated: balance.lastUpdated,
                                            onRepayment: {
                                                selectedPerson = balance.personName
                                                showAddRepayment = true
                                            },
                                            onSettleUp: {
                                                settleUpPerson = balance.personName
                                                showSettleUp = true
                                            }
                                        )
                                    }
                                }
                            }
                            
                            if !ious.isEmpty {
                                Section(header: Text("Personal IOUs")) {
                                    NavigationLink(destination: FriendIOUView()) {
                                        HStack {
                                            Image(systemName: "hand.raised.fill")
                                                .foregroundColor(.blue)
                                            Text("\(ious.count) active IOUs")
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Balances")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showProfileMenu.wrappedValue = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FriendIOUView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddRepayment) {
                if let person = selectedPerson {
                    AddRepaymentView(personName: person)
                }
            }
            .sheet(isPresented: $showSettleUp) {
                if let person = settleUpPerson {
                    SettleUpView(personName: person)
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

struct BalanceRow: View {
    let personName: String
    let amount: Double
    let lastUpdated: Date
    let onRepayment: () -> Void
    let onSettleUp: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(personName)
                        .font(.headline)
                    Text("Last updated: \(lastUpdated.formatted())")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(amount.formatAsCurrency())
                    .font(.headline)
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 12) {
                Button(action: onRepayment) {
                    Label("Record Payment", systemImage: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: onSettleUp) {
                    Label("Settle Up", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettleUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    let personName: String
    
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Settle Up with \(personName)")) {
                    if let userId = authService.currentUser?.id,
                       let balance = dataService.getBalancesOwed(for: userId).first(where: { $0.personName == personName }) {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Total Amount:")
                                Spacer()
                                Text(balance.amount.formatAsCurrency())
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            .font(.title3)
                            
                            Text("This will mark the entire balance as paid and reset to zero.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    TextField("Payment method or notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section {
                    Button(action: settleUp) {
                        Text("Confirm Settlement")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settle Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func settleUp() {
        guard let userId = authService.currentUser?.id else { return }
        dataService.settleUpBalance(userId: userId, personName: personName, notes: notes)
        dismiss()
    }
}

struct AddRepaymentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    let personName: String
    
    @State private var amount = ""
    @State private var notes = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Repayment from \(personName)")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Notes (optional)", text: $notes)
                }
                
                if let userId = authService.currentUser?.id,
                   let balance = dataService.getBalancesOwed(for: userId).first(where: { $0.personName == personName }) {
                    Section {
                        HStack {
                            Text("Current balance:")
                            Spacer()
                            Text(formatCurrency(balance.amount))
                                .fontWeight(.bold)
                        }
                        
                        if let repaymentAmount = Double(amount), repaymentAmount > 0 {
                            HStack {
                                Text("After repayment:")
                                Spacer()
                                Text(formatCurrency(balance.amount - repaymentAmount))
                                    .fontWeight(.bold)
                                    .foregroundColor(balance.amount - repaymentAmount <= 0 ? .green : .primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Record Repayment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRepayment()
                    }
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
    
    private func saveRepayment() {
        guard let userId = authService.currentUser?.id,
              let repaymentAmount = Double(amount) else { return }
        
        let repayment = Repayment(
            userId: userId,
            personName: personName,
            amount: repaymentAmount,
            date: date,
            notes: notes
        )
        
        dataService.recordRepayment(repayment)
        dismiss()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        amount.formatAsCurrency()
    }
}
