//
//  BalancesView.swift
//  FinanceApp
//
//  View for tracking balances owed by others (Splitwise-style)
//

import SwiftUI

struct BalancesView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddRepayment = false
    @State private var selectedPerson: String?
    
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
                            Section(header: Text("People who owe you")) {
                                ForEach(balances) { balance in
                                    Button(action: {
                                        selectedPerson = balance.personName
                                        showAddRepayment = true
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(balance.personName)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                Text("Last updated: \(formatDate(balance.lastUpdated))")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(formatCurrency(balance.amount))
                                                .font(.headline)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Balances")
            .sheet(isPresented: $showAddRepayment) {
                if let person = selectedPerson {
                    AddRepaymentView(personName: person)
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
