//
//  ActionCenterView.swift
//  Flourish
//
//  Central hub for notifications, alerts, and reminders
//

import SwiftUI

struct ActionCenterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var showingSalaryConfirmation: SalaryIncome?
    @State private var showingScheduledTransfer: ScheduledTransfer?
    @State private var showingMonthlyReview: (month: Int, year: Int)?
    
    var body: some View {
        NavigationView {
            VStack {
                if let userId = authService.currentUser?.id {
                    let actionItems = dataService.getActionItems(for: userId)
                    
                    if actionItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("All Caught Up!")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("No pending actions at this time")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(actionItems) { item in
                                ActionItemRow(
                                    item: item,
                                    onTap: { handleActionItem(item) },
                                    onDismiss: { dataService.dismissActionItem(item) }
                                )
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                } else {
                    Text("Please log in to view actions")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Action Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshActionItems) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(item: $showingSalaryConfirmation) { salary in
                ConfirmSalaryDepositView(salary: salary)
            }
            .sheet(item: $showingScheduledTransfer) { scheduled in
                ConfirmScheduledTransferView(scheduled: scheduled)
            }
            .sheet(item: Binding(
                get: {
                    showingMonthlyReview.map { MonthlyReviewIdentifier(month: $0.month, year: $0.year) }
                },
                set: { newValue in
                    showingMonthlyReview = newValue.map { ($0.month, $0.year) }
                }
            )) { identifier in
                MonthlyReviewView(month: identifier.month, year: identifier.year)
            }
            .onAppear {
                refreshActionItems()
            }
        }
    }
    
    private struct MonthlyReviewIdentifier: Identifiable {
        let id = UUID()
        let month: Int
        let year: Int
    }
    
    private func refreshActionItems() {
        guard let userId = authService.currentUser?.id else { return }
        dataService.generateActionItems(for: userId)
    }
    
    private func handleActionItem(_ item: ActionItem) {
        guard let userId = authService.currentUser?.id else { return }
        
        switch item.type {
        case .salaryPending:
            // Find the salary and show confirmation sheet
            if let relatedId = item.relatedEntityId,
               let salary = dataService.getSalaryIncomes(for: userId).first(where: { $0.id == relatedId }) {
                showingSalaryConfirmation = salary
            }
            
        case .subscriptionDue:
            // Navigate to subscriptions view or show details
            break
            
        case .overspending:
            // Navigate to budget view
            break
            
        case .friendBalance:
            // Navigate to balances view
            break
            
        case .reconciliationNeeded:
            // Navigate to accounts
            break
            
        case .missedExpense:
            // Navigate to add expense
            break
            
        case .budgetWarning:
            // Navigate to budget view or show details
            break
        case .creditWarning:
            // Navigate to accounts/credit view or show details
            break
        case .scheduledTransferDueToday:
            if let relatedId = item.relatedEntityId,
               let scheduled = dataService.getScheduledTransfers(for: userId).first(where: { $0.id == relatedId }) {
                showingScheduledTransfer = scheduled
            }
        case .pendingExpense:
            // Navigate to pending expense details
            break
        case .pendingTransfer:
            // Show pending transfer confirmation - requires user approval
            if let relatedId = item.relatedEntityId,
               let scheduled = dataService.getScheduledTransfers(for: userId).first(where: { $0.id == relatedId }) {
                showingScheduledTransfer = scheduled
            }
        case .monthlyFinanceReview:
            // Show monthly review flow
            let now = Date()
            let currentMonth = Calendar.current.component(.month, from: now)
            let currentYear = Calendar.current.component(.year, from: now)
            
            // Try to determine which month to review
            if let status = dataService.monthlyReviewStatuses.first(where: { $0.id == item.relatedEntityId }) {
                showingMonthlyReview = (status.month, status.year)
            } else {
                // Default to current month
                showingMonthlyReview = (currentMonth, currentYear)
            }
        }
    }
}

struct ActionItemRow: View {
    let item: ActionItem
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            // Icon
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                
                Text(item.message)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Action buttons
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch item.priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var iconName: String {
        switch item.type {
        case .salaryPending: return "dollarsign.circle.fill"
        case .subscriptionDue: return "calendar.badge.clock"
        case .overspending: return "exclamationmark.triangle.fill"
        case .friendBalance: return "person.2.fill"
        case .reconciliationNeeded: return "checkmark.circle"
        case .missedExpense: return "questionmark.circle"
        case .budgetWarning: return "chart.pie.fill"
        case .creditWarning: return "creditcard.fill"
        case .scheduledTransferDueToday: return "arrow.left.arrow.right.circle.fill"
        case .pendingExpense: return "cart.fill.badge.questionmark"
        case .pendingTransfer: return "clock.arrow.2.circlepath"
        case .monthlyFinanceReview: return "calendar.badge.checkmark"
        }
    }
    
    private var iconColor: Color {
        switch item.type {
        case .salaryPending: return .green
        case .subscriptionDue: return .orange
        case .overspending: return .red
        case .friendBalance: return .blue
        case .reconciliationNeeded: return .purple
        case .missedExpense: return .gray
        case .budgetWarning: return .orange
        case .creditWarning: return .red
        case .scheduledTransferDueToday: return .blue
        case .pendingExpense: return .orange
        case .pendingTransfer: return .blue
        case .monthlyFinanceReview: return .blue
        }
    }
}

struct ConfirmSalaryDepositView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    let salary: SalaryIncome
    
    @State private var amount: String
    @State private var date = Date()
    @State private var useCustomAmount = false
    
    init(salary: SalaryIncome) {
        self.salary = salary
        _amount = State(initialValue: String(format: "%.2f", salary.amount))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Salary Details")) {
                    HStack {
                        Text("Expected Amount")
                        Spacer()
                        Text(salary.amount.formatAsCurrency())
                            .foregroundColor(.gray)
                    }
                    
                    if let account = dataService.getAccount(by: salary.accountId) {
                        HStack {
                            Text("Deposit To")
                            Spacer()
                            Text(account.name)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Confirmation")) {
                    Toggle("Use Different Amount", isOn: $useCustomAmount)
                    
                    if useCustomAmount {
                        TextField("Actual Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    DatePicker("Deposit Date", selection: $date, displayedComponents: .date)
                }
                
                Section {
                    Button(action: confirmDeposit) {
                        Text("Confirm Salary Deposit")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Confirm Salary")
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
    
    private func confirmDeposit() {
        let depositAmount = useCustomAmount ? (Double(amount) ?? salary.amount) : salary.amount
        dataService.confirmSalaryDeposit(salary, amount: depositAmount, date: date)
        dismiss()
    }
}

struct ConfirmScheduledTransferView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    let scheduled: ScheduledTransfer

    @State private var date = Date()
    @State private var notes: String
    @State private var showDeclineAlert = false

    init(scheduled: ScheduledTransfer) {
        self.scheduled = scheduled
        _notes = State(initialValue: scheduled.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transfer Details")) {
                    if let from = dataService.getAccount(by: scheduled.fromAccountId) {
                        HStack {
                            Text("From")
                            Spacer()
                            Text(from.name).foregroundColor(.gray)
                        }
                    }
                    if let to = dataService.getAccount(by: scheduled.toAccountId) {
                        HStack {
                            Text("To")
                            Spacer()
                            Text(to.name).foregroundColor(.gray)
                        }
                    }
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text(scheduled.amount.formatAsCurrency()).foregroundColor(.gray)
                    }
                    
                    if let recurrence = scheduled.recurrenceDays {
                        HStack {
                            Text("Recurrence")
                            Spacer()
                            Text("Every \(recurrence) days")
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section(header: Text("Confirmation")) {
                    DatePicker("Transfer Date", selection: $date, displayedComponents: .date)
                    TextField("Notes (optional)", text: $notes)
                }

                Section {
                    Button(action: confirmTransfer) {
                        Text("Mark Transfer as Completed")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .listRowBackground(Color.clear)
                    
                    Button(action: { showDeclineAlert = true }) {
                        Text("Decline Transfer")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Confirm Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Decline Transfer?", isPresented: $showDeclineAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Decline", role: .destructive) {
                    declineTransfer()
                }
            } message: {
                if scheduled.recurrenceDays != nil {
                    Text("This is a recurring transfer. Declining will cancel this occurrence only. The next scheduled transfer will still appear.")
                } else {
                    Text("This will permanently cancel this scheduled transfer. This action cannot be undone.")
                }
            }
        }
    }

    private func confirmTransfer() {
        // Only update balances upon explicit confirmation
        var updated = scheduled
        if !notes.isEmpty { updated.notes = notes }
        dataService.confirmScheduledTransfer(updated)
        dismiss()
    }
    
    private func declineTransfer() {
        dataService.declineScheduledTransfer(scheduled)
        dismiss()
    }
}

#Preview {
    ActionCenterView()
        .environmentObject(DataService.shared)
}

