//
//  SavingsBudgetView.swift
//  FinanceApp
//
//  View for managing savings goals and investments
//

import SwiftUI

struct SavingsBudgetView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddGoal = false
    
    var body: some View {
        VStack {
            if let userId = authService.currentUser?.id {
                let goals = dataService.getSavingsBudgets(for: userId)
                
                if goals.isEmpty {
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No savings goals yet")
                            .foregroundColor(.gray)
                        Text("Tap + to add your first goal")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(goals) { goal in
                            SavingsGoalRow(goal: goal)
                        }
                        .onDelete(perform: deleteGoals)
                    }
                }
            }
        }
        .navigationTitle("Savings Goals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddGoal = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            AddSavingsGoalView()
        }
    }
    
    private func deleteGoals(at offsets: IndexSet) {
        guard let userId = authService.currentUser?.id else { return }
        let goals = dataService.getSavingsBudgets(for: userId)
        
        for index in offsets {
            dataService.deleteSavingsBudget(goals[index])
        }
    }
}

struct SavingsGoalRow: View {
    let goal: SavingsBudget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name)
                    .font(.headline)
                Spacer()
                Text(formatCurrency(goal.currentAmount))
                    .font(.headline)
                    .foregroundColor(.green)
            }
            
            Text(goal.type.rawValue)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Text("Goal: \(formatCurrency(goal.targetAmount))")
                    .font(.caption)
                Spacer()
                Text("\(Int(goal.percentComplete))% complete")
                    .font(.caption)
                    .foregroundColor(goal.percentComplete >= 100 ? .green : .blue)
            }
            
            ProgressView(value: min(goal.currentAmount, goal.targetAmount), total: goal.targetAmount)
                .tint(goal.percentComplete >= 100 ? .green : .blue)
            
            Text("Monthly: \(formatCurrency(goal.monthlyContribution))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct AddSavingsGoalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var name = ""
    @State private var type: SavingsType = .cashSavings
    @State private var targetAmount = ""
    @State private var currentAmount = ""
    @State private var monthlyContribution = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Goal Details")) {
                    TextField("Goal Name", text: $name)
                    
                    Picker("Type", selection: $type) {
                        ForEach(SavingsType.allCases, id: \.self) { savingsType in
                            Text(savingsType.rawValue).tag(savingsType)
                        }
                    }
                }
                
                Section(header: Text("Amounts")) {
                    TextField("Target Amount", text: $targetAmount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Current Amount", text: $currentAmount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Monthly Contribution", text: $monthlyContribution)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Savings Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !targetAmount.isEmpty && !monthlyContribution.isEmpty
    }
    
    private func saveGoal() {
        guard let userId = authService.currentUser?.id,
              let target = Double(targetAmount),
              let current = Double(currentAmount.isEmpty ? "0" : currentAmount),
              let monthly = Double(monthlyContribution) else { return }
        
        let goal = SavingsBudget(
            userId: userId,
            name: name,
            type: type,
            targetAmount: target,
            currentAmount: current,
            monthlyContribution: monthly
        )
        
        dataService.saveSavingsBudget(goal)
        dismiss()
    }
}
