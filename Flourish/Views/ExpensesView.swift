//
//  ExpensesView.swift
//  FinanceApp
//
//  View for managing expenses with split functionality
//

import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddExpense = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let userId = authService.currentUser?.id {
                    let expenses = dataService.getExpenses(for: userId).sorted { $0.date > $1.date }
                    
                    if expenses.isEmpty {
                        VStack {
                            Text("No expenses yet")
                                .foregroundColor(.gray)
                            Text("Tap + to add your first expense")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        List {
                            ForEach(expenses) { expense in
                                ExpenseRow(expense: expense)
                            }
                            .onDelete(perform: deleteExpenses)
                        }
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddExpense = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
            }
        }
    }
    
    private func deleteExpenses(at offsets: IndexSet) {
        guard let userId = authService.currentUser?.id else { return }
        let expenses = dataService.getExpenses(for: userId).sorted { $0.date > $1.date }
        
        for index in offsets {
            dataService.deleteExpense(expenses[index])
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(expense.description)
                    .font(.headline)
                
                Spacer()
                
                Text(formatCurrency(expense.userShare))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text(expense.categoryName)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(formatDate(expense.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if !expense.splitParticipants.isEmpty {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("Split with \(expense.splitParticipants.filter { !$0.isCurrentUser }.count) people")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if expense.isSubscription {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Subscription")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
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

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedCategory = ""
    @State private var selectedAccountId: UUID?
    @State private var date = Date()
    @State private var splitParticipants: [SplitParticipant] = []
    @State private var showAddParticipant = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Description", text: $description)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("Category")) {
                    if let userId = authService.currentUser?.id {
                        let now = Date()
                        let month = Calendar.current.component(.month, from: now)
                        let year = Calendar.current.component(.year, from: now)
                        let categories = dataService.getBudgetCategories(for: userId, month: month, year: year)
                        
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select Category").tag("")
                            ForEach(categories, id: \.name) { category in
                                Text(category.name).tag(category.name)
                            }
                        }
                    }
                }
                
                Section(header: Text("Payment Account")) {
                    if let userId = authService.currentUser?.id {
                        let accounts = dataService.getAccounts(for: userId)
                        
                        Picker("Account", selection: $selectedAccountId) {
                            Text("Select Account").tag(nil as UUID?)
                            ForEach(accounts) { account in
                                Text(account.name).tag(account.id as UUID?)
                            }
                        }
                    }
                }
                
                Section(header: HStack {
                    Text("Split With")
                    Spacer()
                    Button("Add Person") {
                        showAddParticipant = true
                    }
                    .font(.caption)
                }) {
                    if splitParticipants.isEmpty {
                        Text("Not split")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(splitParticipants) { participant in
                            HStack {
                                Text(participant.name)
                                Spacer()
                                Text(formatCurrency(participant.amount))
                            }
                        }
                        .onDelete(perform: deleteParticipant)
                    }
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showAddParticipant) {
                AddSplitParticipantView(
                    totalAmount: Double(amount) ?? 0,
                    existingParticipants: splitParticipants
                ) { participant in
                    splitParticipants.append(participant)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !amount.isEmpty && !description.isEmpty && !selectedCategory.isEmpty && selectedAccountId != nil
    }
    
    private func saveExpense() {
        guard let userId = authService.currentUser?.id,
              let accountId = selectedAccountId,
              let expenseAmount = Double(amount) else { return }
        
        // If there are split participants, add the current user as a participant
        var finalParticipants = splitParticipants
        if !splitParticipants.isEmpty {
            let othersTotal = splitParticipants.reduce(0) { $0 + $1.amount }
            let userShare = expenseAmount - othersTotal
            
            let currentUserParticipant = SplitParticipant(
                name: authService.currentUser?.name ?? "You",
                amount: userShare,
                isCurrentUser: true
            )
            finalParticipants.insert(currentUserParticipant, at: 0)
        }
        
        let expense = Expense(
            userId: userId,
            amount: expenseAmount,
            date: date,
            description: description,
            categoryName: selectedCategory,
            accountId: accountId,
            splitParticipants: finalParticipants
        )
        
        dataService.saveExpense(expense)
        dismiss()
    }
    
    private func deleteParticipant(at offsets: IndexSet) {
        splitParticipants.remove(atOffsets: offsets)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct AddSplitParticipantView: View {
    @Environment(\.dismiss) var dismiss
    
    let totalAmount: Double
    let existingParticipants: [SplitParticipant]
    let onAdd: (SplitParticipant) -> Void
    
    @State private var name = ""
    @State private var amount = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Participant Details")) {
                    TextField("Name", text: $name)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    let existingTotal = existingParticipants.reduce(0) { $0 + $1.amount }
                    let remainingAmount = totalAmount - existingTotal
                    
                    Text("Total expense: \(formatCurrency(totalAmount))")
                    Text("Already allocated: \(formatCurrency(existingTotal))")
                    Text("Remaining: \(formatCurrency(remainingAmount))")
                        .foregroundColor(remainingAmount < 0 ? .red : .green)
                }
            }
            .navigationTitle("Add Split Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addParticipant()
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
    }
    
    private func addParticipant() {
        guard let participantAmount = Double(amount) else { return }
        
        let participant = SplitParticipant(
            name: name,
            amount: participantAmount,
            isCurrentUser: false
        )
        
        onAdd(participant)
        dismiss()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
