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
            .onAppear {
                refreshActionItems()
            }
        }
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

#Preview {
    ActionCenterView()
        .environmentObject(DataService.shared)
}
