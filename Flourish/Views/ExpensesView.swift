//
//  ExpensesView.swift
//  FinanceApp
//
//  View for managing expenses with split functionality
//

import SwiftUI

struct ExpensesView: View {
    @Environment(\.showProfileMenu) var showProfileMenu
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddExpense = false
    @State private var showFilterSheet = false
    @State private var selectedCategories: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack {
                if let userId = authService.currentUser?.id {
                    let allExpenses = dataService.getExpenses(for: userId).sorted { $0.date > $1.date }
                    let expenses = selectedCategories.isEmpty ? allExpenses : allExpenses.filter { selectedCategories.contains($0.categoryName) }
                    
                    if expenses.isEmpty {
                        VStack {
                            Text(selectedCategories.isEmpty ? "No expenses yet" : "No expenses in selected categories")
                                .foregroundColor(.gray)
                            Text(selectedCategories.isEmpty ? "Tap + to add your first expense" : "Try adjusting your filters")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        List {
                            ForEach(expenses) { expense in
                                NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                                    ExpenseRow(expense: expense)
                                }
                            }
                            .onDelete { offsets in
                                deleteExpenses(at: offsets, from: expenses)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showProfileMenu.wrappedValue = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showFilterSheet = true }) {
                            Image(systemName: selectedCategories.isEmpty ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        }
                        
                        Button(action: { showAddExpense = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView()
            }
            .sheet(isPresented: $showFilterSheet) {
                ExpenseFilterView(selectedCategories: $selectedCategories)
            }
        }
    }
    
    private func deleteExpenses(at offsets: IndexSet, from expenses: [Expense]) {
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
        amount.formatAsCurrency()
    }
    
    private func formatDate(_ date: Date) -> String {
        date.formatted()
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
                        let budgetCategories = dataService.getBudgetCategories(for: userId, month: month, year: year)
                        let budgetCategoryNames = Set(budgetCategories.map { $0.name })
                        
                        // Combine default categories with budget categories
                        let allCategories = DefaultCategories.all + budgetCategories.filter { !DefaultCategories.isDefault($0.name) }.map { $0.name }
                        
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select Category").tag("")
                            ForEach(allCategories, id: \.self) { categoryName in
                                if budgetCategoryNames.contains(categoryName) {
                                    // Show with checkmark if in budget
                                    Label(categoryName, systemImage: "checkmark.circle.fill")
                                        .tag(categoryName)
                                } else {
                                    Text(categoryName).tag(categoryName)
                                }
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

// MARK: - Edit Expense View

struct EditExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    let expense: Expense
    
    @State private var amount = ""
    @State private var description = ""
    @State private var selectedCategory = ""
    @State private var selectedAccountId: UUID?
    @State private var date = Date()
    @State private var splitParticipants: [SplitParticipant] = []
    @State private var showAddParticipant = false
    
    var body: some View {
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
                    let budgetCategories = dataService.getBudgetCategories(for: userId, month: month, year: year)
                    let budgetCategoryNames = Set(budgetCategories.map { $0.name })
                    
                    // Combine default categories with budget categories
                    let allCategories = DefaultCategories.all + budgetCategories.filter { !DefaultCategories.isDefault($0.name) }.map { $0.name }
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select Category").tag("")
                        ForEach(allCategories, id: \.self) { categoryName in
                            if budgetCategoryNames.contains(categoryName) {
                                // Show with checkmark if in budget
                                Label(categoryName, systemImage: "checkmark.circle.fill")
                                    .tag(categoryName)
                            } else {
                                Text(categoryName).tag(categoryName)
                            }
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
        .navigationTitle("Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .onAppear {
            // Populate fields with existing expense data
            amount = String(expense.amount)
            description = expense.description
            selectedCategory = expense.categoryName
            selectedAccountId = expense.accountId
            date = expense.date
            splitParticipants = expense.splitParticipants
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
        
        // Create updated expense with same ID
        let updatedExpense = Expense(
            id: expense.id,
            userId: userId,
            amount: expenseAmount,
            date: date,
            description: description,
            categoryName: selectedCategory,
            accountId: accountId,
            splitParticipants: finalParticipants
        )
        
        dataService.updateExpense(updatedExpense)
        dismiss()
    }
    
    private func deleteParticipant(at offsets: IndexSet) {
        splitParticipants.remove(atOffsets: offsets)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        amount.formatAsCurrency()
    }
}

// MARK: - Expense Filter View

struct ExpenseFilterView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @Binding var selectedCategories: Set<String>
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Filter by Category")) {
                    if let userId = authService.currentUser?.id {
                        let expenses = dataService.getExpenses(for: userId)
                        let uniqueCategories = Set(expenses.map { $0.categoryName }).sorted()
                        
                        ForEach(uniqueCategories, id: \.self) { category in
                            Button(action: {
                                if selectedCategories.contains(category) {
                                    selectedCategories.remove(category)
                                } else {
                                    selectedCategories.insert(category)
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedCategories.contains(category) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedCategories.contains(category) ? .blue : .gray)
                                    Text(category)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button("Clear All Filters") {
                        selectedCategories.removeAll()
                    }
                    .disabled(selectedCategories.isEmpty)
                }
            }
            .navigationTitle("Filter Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Expense Detail View

struct ExpenseDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    let expense: Expense
    
    var body: some View {
        List {
            Section(header: Text("Details")) {
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(expense.amount.formatAsCurrency())
                        .font(.headline)
                }
                
                HStack {
                    Text("Your Share")
                    Spacer()
                    Text(expense.userShare.formatAsCurrency())
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Description")
                    Spacer()
                    Text(expense.description)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Category")
                    Spacer()
                    Text(expense.categoryName)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Date")
                    Spacer()
                    Text(expense.date.formatted())
                        .foregroundColor(.gray)
                }
            }
            
            if !expense.splitParticipants.isEmpty {
                Section(header: Text("Split Details")) {
                    ForEach(expense.splitParticipants) { participant in
                        HStack {
                            Text(participant.name)
                            if participant.isCurrentUser {
                                Text("(You)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text(participant.amount.formatAsCurrency())
                                .foregroundColor(participant.isCurrentUser ? .blue : .primary)
                        }
                    }
                }
            }
            
            if expense.isSubscription {
                Section {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.orange)
                        Text("This is a recurring subscription")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Section {
                Button(action: { showEditSheet = true }) {
                    Label("Edit Expense", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: { showDeleteAlert = true }) {
                    Label("Delete Expense", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            NavigationView {
                EditExpenseView(expense: expense)
            }
        }
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dataService.deleteExpense(expense)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
    }
}

