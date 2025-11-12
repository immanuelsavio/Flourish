//
//  TransferListView.swift
//  FinanceApp
//
//  View for displaying transfer history
//

import SwiftUI

struct TransferListView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddTransfer = false
    
    var body: some View {
        VStack {
            if let userId = authService.currentUser?.id {
                let transfers = dataService.getTransfers(for: userId).sorted { $0.date > $1.date }
                
                if transfers.isEmpty {
                    VStack {
                        Text("No transfers yet")
                            .foregroundColor(.gray)
                        Text("Tap + to transfer money between accounts")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(transfers) { transfer in
                            TransferRow(transfer: transfer)
                        }
                    }
                }
            }
        }
        .navigationTitle("Transfers")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddTransfer = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTransfer) {
            TransferView()
        }
    }
}

struct TransferRow: View {
    let transfer: Transfer
    @EnvironmentObject var dataService: DataService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(formatCurrency(transfer.amount))
                    .font(.headline)
                Spacer()
                Text(formatDate(transfer.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if let fromAccount = dataService.getAccount(by: transfer.fromAccountId),
               let toAccount = dataService.getAccount(by: transfer.toAccountId) {
                HStack {
                    Text(fromAccount.name)
                        .font(.subheadline)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(toAccount.name)
                        .font(.subheadline)
                }
                .foregroundColor(.gray)
            }
            
            if !transfer.notes.isEmpty {
                Text(transfer.notes)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
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
