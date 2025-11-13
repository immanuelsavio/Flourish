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
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var filterByDate = true // Default to current month
    
    var body: some View {
        NavigationView {
            VStack {
                // Month Scroller
                monthScroller
                
                if let userId = authService.currentUser?.id {
                    expensesList(for: userId)
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
                            Image(systemName: (selectedCategories.isEmpty && !filterByDate) ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
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
                ExpenseFilterView(
                    selectedCategories: $selectedCategories,
                    filterByDate: $filterByDate
                )
            }
        }
    }
    
    private var filteredExpenses: [Expense] {
        guard let userId = authService.currentUser?.id else { return [] }
        
        let allExpenses: [Expense]
        if filterByDate {
            allExpenses = dataService.getExpenses(for: userId, month: selectedMonth, year: selectedYear).sorted { $0.date > $1.date }
        } else {
            allExpenses = dataService.getExpenses(for: userId).sorted { $0.date > $1.date }
        }
        
        return selectedCategories.isEmpty ? allExpenses : allExpenses.filter { selectedCategories.contains($0.categoryName) }
    }
    
    @ViewBuilder
    private func expensesList(for userId: UUID) -> some View {
        let expenses = filteredExpenses
        
        // Summary
        if !expenses.isEmpty {
            VStack(spacing: 4) {
                HStack {
                    Text("Total: \(expenses.count) expenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(expenses.reduce(0) { $0 + $1.userShare }.formatAsCurrency())
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }
        }
        
        if expenses.isEmpty {
            VStack {
                Text(selectedCategories.isEmpty ? "No expenses yet" : "No expenses match filters")
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
    
    private var monthScroller: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
            }
            .disabled(!filterByDate)
            
            Spacer()
            
            Toggle(isOn: $filterByDate) {
                Text(filterByDate ? monthName(selectedMonth) + " \(selectedYear)" : "All Time")
                    .font(.headline)
            }
            .toggleStyle(.button)
            .tint(.blue)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
            }
            .disabled(!filterByDate)
        }
        .padding()
    }
    
    private func previousMonth() {
        selectedMonth -= 1
        if selectedMonth < 1 {
            selectedMonth = 12
            selectedYear -= 1
        }
    }
    
    private func nextMonth() {
        selectedMonth += 1
        if selectedMonth > 12 {
            selectedMonth = 1
            selectedYear += 1
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: 2000, month: month, day: 1))!
        return formatter.string(from: date)
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
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    let totalAmount: Double
    let existingParticipants: [SplitParticipant]
    let onAdd: (SplitParticipant) -> Void
    
    @State private var name = ""
    @State private var amount = ""
    @State private var showingExistingPeople = false
    @State private var useExistingPerson = false
    @State private var selectedExistingPerson: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Person")) {
                    // Get existing people from balances
                    if let userId = authService.currentUser?.id {
                        let existingPeople = dataService.getBalancesOwed(for: userId).map { $0.personName }
                        
                        if !existingPeople.isEmpty {
                            Toggle("Use existing person", isOn: $useExistingPerson)
                            
                            if useExistingPerson {
                                Picker("Person", selection: $selectedExistingPerson) {
                                    Text("Select person").tag(nil as String?)
                                    ForEach(existingPeople, id: \.self) { person in
                                        Text(person).tag(person as String?)
                                    }
                                }
                            }
                        }
                    }
                    
                    if !useExistingPerson {
                        TextField("Name", text: $name)
                    }
                }
                
                Section(header: Text("Amount")) {
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
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        let hasName = useExistingPerson ? selectedExistingPerson != nil : !name.isEmpty
        return hasName && !amount.isEmpty
    }
    
    private func addParticipant() {
        guard let participantAmount = Double(amount) else { return }
        
        let participantName = useExistingPerson ? (selectedExistingPerson ?? "") : name
        
        let participant = SplitParticipant(
            name: participantName,
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
            .navigationTitle("Edit Expense")
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
            .onAppear {
                // Populate fields with existing expense data
                amount = String(expense.amount)
                description = expense.description
                selectedCategory = expense.categoryName
                selectedAccountId = expense.accountId
                date = expense.date
                // Remove current user from participants list for editing
                splitParticipants = expense.splitParticipants.filter { !$0.isCurrentUser }
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
    @Binding var filterByDate: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Date Filter")) {
                    Toggle("Filter by Month", isOn: $filterByDate)
                }
                
                Section(header: Text("Category Filter")) {
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
                        filterByDate = false
                    }
                    .disabled(selectedCategories.isEmpty && !filterByDate)
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
