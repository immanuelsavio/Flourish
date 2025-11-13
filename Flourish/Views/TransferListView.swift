//
//  TransferListView.swift
//  FinanceApp
//
//  View for displaying transfer history and scheduled transfers
//

import SwiftUI

struct TransferListView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddTransfer = false
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("View", selection: $selectedTab) {
                Text("Scheduled").tag(0)
                Text("Completed").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            if selectedTab == 0 {
                scheduledTransfersView
            } else {
                completedTransfersView
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
    
    private var scheduledTransfersView: some View {
        VStack {
            if let userId = authService.currentUser?.id {
                let scheduled = dataService.getScheduledTransfers(for: userId)
                    .filter { !$0.isCompleted }
                    .sorted { $0.scheduledDate < $1.scheduledDate }
                
                if scheduled.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No scheduled transfers")
                            .foregroundColor(.gray)
                        Text("Tap + to schedule a transfer")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(scheduled) { transfer in
                            ScheduledTransferRow(transfer: transfer)
                        }
                        .onDelete(perform: deleteScheduledTransfers)
                    }
                }
            }
        }
    }
    
    private var completedTransfersView: some View {
        VStack {
            if let userId = authService.currentUser?.id {
                let completed = dataService.getTransfers(for: userId)
                    .sorted { $0.date > $1.date }
                
                if completed.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No completed transfers yet")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(completed) { transfer in
                            CompletedTransferRow(transfer: transfer)
                        }
                    }
                }
            }
        }
    }
    
    private func deleteScheduledTransfers(at offsets: IndexSet) {
        guard let userId = authService.currentUser?.id else { return }
        let scheduled = dataService.getScheduledTransfers(for: userId)
            .filter { !$0.isCompleted }
            .sorted { $0.scheduledDate < $1.scheduledDate }
        
        for index in offsets {
            let transfer = scheduled[index]
            // Mark as completed to "delete" it
            dataService.markScheduledTransferCompleted(transfer.id)
        }
    }
}

struct ScheduledTransferRow: View {
    let transfer: ScheduledTransfer
    @EnvironmentObject var dataService: DataService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formatCurrency(transfer.amount))
                    .font(.headline)
                Spacer()
                
                // Status badge
                let today = Calendar.current.startOfDay(for: Date())
                let scheduledDay = Calendar.current.startOfDay(for: transfer.scheduledDate)
                
                if scheduledDay <= today {
                    Text("Pending Approval")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .cornerRadius(8)
                } else {
                    Text(formatDate(transfer.scheduledDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
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
            
            HStack {
                if let recurrence = transfer.recurrenceDays {
                    Label("Every \(recurrence) days", systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                if let notes = transfer.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        amount.formatAsCurrency()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct CompletedTransferRow: View {
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
        amount.formatAsCurrency()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
