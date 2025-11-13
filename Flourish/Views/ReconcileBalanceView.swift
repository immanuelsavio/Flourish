//
//  ReconcileBalanceView.swift
//  Flourish
//
//  View for reconciling account balance with actual bank balance
//

import SwiftUI

struct ReconcileBalanceView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    let account: Account
    
    @State private var actualBalance = ""
    @State private var notes = ""
    @State private var showConfirmation = false
    
    var body: some View {
        Form {
            Section(header: Text("Current Information")) {
                HStack {
                    Text("Account")
                    Spacer()
                    Text(account.name)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Current Balance in App")
                    Spacer()
                    Text(account.balance.formatAsCurrency())
                        .fontWeight(.semibold)
                }
            }
            
            Section(header: Text("Actual Balance"), footer: Text("Enter the current balance shown in your bank account or statement")) {
                TextField("Actual Balance", text: $actualBalance)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .multilineTextAlignment(.trailing)
            }
            
            if let actual = Double(actualBalance) {
                Section(header: Text("Reconciliation")) {
                    let difference = actual - account.balance
                    
                    HStack {
                        Text("Difference")
                        Spacer()
                        Text(abs(difference).formatAsCurrency())
                            .fontWeight(.bold)
                            .foregroundColor(abs(difference) > 0.01 ? .orange : .green)
                    }
                    
                    if abs(difference) > 0.01 {
                        VStack(alignment: .leading, spacing: 8) {
                            if difference > 0 {
                                Text("Your account has \(difference.formatAsCurrency()) more than recorded")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("Your account has \(abs(difference).formatAsCurrency()) less than recorded")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            Text("A reconciliation transaction will be created to adjust the balance")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        TextField("Notes (optional)", text: $notes)
                            .font(.subheadline)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Balance matches!")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                HStack {
                    Text("Balance After Reconciliation")
                    Spacer()
                    Text(actual.formatAsCurrency())
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            if !actualBalance.isEmpty, let actual = Double(actualBalance) {
                Section {
                    Button(action: {
                        showConfirmation = true
                    }) {
                        Text("Reconcile Balance")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Reconcile Balance")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Confirm Reconciliation", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reconcile") {
                reconcileBalance()
            }
        } message: {
            if let actual = Double(actualBalance) {
                let difference = actual - account.balance
                Text("This will adjust your balance by \(abs(difference).formatAsCurrency()) and create a reconciliation transaction.")
            }
        }
    }
    
    private func reconcileBalance() {
        guard let actual = Double(actualBalance) else { return }
        
        dataService.reconcileAccount(account, actualBalance: actual, notes: notes)
        dismiss()
    }
}

#Preview {
    NavigationView {
        ReconcileBalanceView(account: Account(
            userId: UUID(),
            name: "Checking",
            type: .checking,
            balance: 4958.32
        ))
        .environmentObject(DataService.shared)
    }
}
