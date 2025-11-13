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
    @State private var showSettleAlert = false
    @State private var showPartialSettleSheet = false
    @State private var settleUpBalance: BalanceOwed?
    @State private var showAddBalance = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let userId = authService.currentUser?.id {
                    let balances = dataService.getBalancesOwed(for: userId).sorted { $0.amount > $1.amount }
                    
                    if balances.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No outstanding balances")
                                .foregroundColor(.gray)
                            Text("Split expenses will appear here")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        List {
                            ForEach(balances) { balance in
                                BalanceRow(
                                    personName: balance.personName,
                                    amount: balance.amount,
                                    lastUpdated: balance.lastUpdated,
                                    isOwedToMe: balance.isOwedToMe,
                                    onSettleUp: {
                                        settleUpBalance = balance
                                        showSettleAlert = true
                                    }
                                )
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
                    Button(action: { showAddBalance = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Settle Up", isPresented: $showSettleAlert, presenting: settleUpBalance) { balance in
                Button("Cancel", role: .cancel) { }
                Button("Settle Full Amount") {
                    settleUpBalanceAction(balance, amount: balance.amount)
                }
                Button("Settle Partial Amount") {
                    showPartialSettleSheet = true
                }
            } message: { balance in
                Text("Settle balance of \(balance.amount.formatAsCurrency()) with \(balance.personName)")
            }
            .sheet(isPresented: $showPartialSettleSheet) {
                if let balance = settleUpBalance {
                    PartialSettleView(dataService: dataService, balance: balance)
                }
            }
            .sheet(isPresented: $showAddBalance) {
                AddBalanceView(dataService: dataService)
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        amount.formatAsCurrency()
    }
    
    private func formatDate(_ date: Date) -> String {
        date.formatted()
    }
    
    private func settleUpBalanceAction(_ balance: BalanceOwed, amount: Double) {
        guard let userId = authService.currentUser?.id else { return }
        
        if amount >= balance.amount {
            // Full settlement
            dataService.settleUpBalance(userId: userId, personName: balance.personName, notes: "Settled up")
        } else {
            // Partial settlement - reduce the balance
            let repayment = Repayment(
                userId: userId,
                personName: balance.personName,
                amount: amount,
                date: Date(),
                notes: "Partial settlement"
            )
            dataService.recordRepayment(repayment)
        }
    }
}

struct BalanceRow: View {
    let personName: String
    let amount: Double
    let lastUpdated: Date
    let isOwedToMe: Bool
    let onSettleUp: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(personName)
                        .font(.headline)
                    Text(isOwedToMe ? "owes you" : "you owe")
                        .font(.caption)
                        .foregroundColor(isOwedToMe ? .green : .red)
                    Text("Last updated: \(lastUpdated.formatted())")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(amount.formatAsCurrency())
                    .font(.headline)
                    .foregroundColor(isOwedToMe ? .green : .red)
            }
            
            HStack {
                Spacer()
                
                Button(action: onSettleUp) {
                    Label("Settle Up", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Partial Settle View

struct PartialSettleView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    let balance: BalanceOwed
    
    @State private var amount = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Settle with \(balance.personName)")) {
                    HStack {
                        Text("Current Balance:")
                        Spacer()
                        Text(balance.amount.formatAsCurrency())
                            .fontWeight(.bold)
                            .foregroundColor(balance.isOwedToMe ? .green : .red)
                    }
                }
                
                Section(header: Text("Settlement Amount")) {
                    TextField("Amount to settle", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    if let settleAmount = Double(amount), settleAmount > 0 {
                        HStack {
                            Text("Remaining Balance:")
                            Spacer()
                            Text((balance.amount - settleAmount).formatAsCurrency())
                                .fontWeight(.bold)
                                .foregroundColor(balance.amount - settleAmount <= 0 ? .gray : (balance.isOwedToMe ? .green : .red))
                        }
                    }
                }
                
                Section {
                    Button(action: settlePartial) {
                        Text("Settle")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(isValid ? Color.green : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isValid)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Partial Settlement")
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
    
    private var isValid: Bool {
        guard let settleAmount = Double(amount) else { return false }
        return settleAmount > 0 && settleAmount <= balance.amount
    }
    
    private func settlePartial() {
        guard let userId = authService.currentUser?.id,
              let settleAmount = Double(amount), settleAmount > 0 else { return }
        
        if settleAmount >= balance.amount {
            // Full settlement
            dataService.settleUpBalance(userId: userId, personName: balance.personName, notes: "Settled up")
        } else {
            // Partial settlement
            let repayment = Repayment(
                userId: userId,
                personName: balance.personName,
                amount: settleAmount,
                date: Date(),
                notes: "Partial settlement"
            )
            dataService.recordRepayment(repayment)
        }
        
        dismiss()
    }
}

// MARK: - Add Balance View

struct AddBalanceView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var personName = ""
    @State private var amount = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var isOwedToMe = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Balance Details")) {
                    TextField("Person Name", text: $personName)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Direction", selection: $isOwedToMe) {
                        Text("They owe me").tag(true)
                        Text("I owe them").tag(false)
                    }
                    .pickerStyle(.segmented)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section {
                    Text(isOwedToMe ? "Record money someone owes you." : "Record money you owe someone.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Add Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBalance()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !personName.isEmpty && !amount.isEmpty && Double(amount) != nil
    }
    
    private func saveBalance() {
        guard let userId = authService.currentUser?.id,
              let balanceAmount = Double(amount), balanceAmount > 0 else { return }
        
        // Create or update a balance entry for this person
        dataService.addManualBalance(userId: userId, personName: personName, amount: balanceAmount, isOwedToMe: isOwedToMe)
        dismiss()
    }
}
