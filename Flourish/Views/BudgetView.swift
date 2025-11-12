//
//  BudgetView.swift
//  FinanceApp
//
//  View for managing monthly budgets
//

import SwiftUI

struct BudgetView: View {
    @Environment(\.showProfileMenu) var showProfileMenu
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    @State private var showAddCategory = false
    
    init() {
        let now = Date()
        _selectedMonth = State(initialValue: Calendar.current.component(.month, from: now))
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: now))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Month selector
                monthSelector
                
                // Budget categories
                if let userId = authService.currentUser?.id {
                    let categories = dataService.getBudgetCategories(for: userId, month: selectedMonth, year: selectedYear)
                    
                    if categories.isEmpty {
                        VStack(spacing: 20) {
                            Text("No budget for this month")
                                .foregroundColor(.gray)
                            
                            Button("Copy from Previous Month") {
                                copyFromPreviousMonth()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(categories) { category in
                                NavigationLink(destination: EditBudgetCategoryView(category: category)) {
                                    BudgetCategoryRow(category: category)
                                }
                            }
                            .onDelete(perform: deleteCategories)
                        }
                    }
                }
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showProfileMenu.wrappedValue = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddCategory = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCategory) {
                AddBudgetCategoryView(month: selectedMonth, year: selectedYear)
            }
        }
    }
    
    private var monthSelector: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            
            Text("\(monthName(selectedMonth)), \(selectedYear)")
                .font(.headline)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
            }
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
    
    private func copyFromPreviousMonth() {
        guard let userId = authService.currentUser?.id else { return }
        
        var prevMonth = selectedMonth - 1
        var prevYear = selectedYear
        if prevMonth < 1 {
            prevMonth = 12
            prevYear -= 1
        }
        
        dataService.copyBudgetToNextMonth(userId: userId, fromMonth: prevMonth, fromYear: prevYear)
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        guard let userId = authService.currentUser?.id else { return }
        let categories = dataService.getBudgetCategories(for: userId, month: selectedMonth, year: selectedYear)
        
        for index in offsets {
            dataService.deleteBudgetCategory(categories[index])
        }
    }
}

struct BudgetCategoryRow: View {
    let category: BudgetCategory
    @State private var showAddExpense = false
    @State private var showCategoryExpenses = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: { showCategoryExpenses = true }) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Quick Add Expense Button
                Button(action: { showAddExpense = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .trailing) {
                    Text("\(formatCurrency(category.spent)) / \(formatCurrency(category.monthlyLimit))")
                        .font(.subheadline)
                    Text("\(formatCurrency(category.remaining)) remaining")
                        .font(.caption)
                        .foregroundColor(category.remaining < 0 ? .red : .green)
                }
            }
            
            Button(action: { showCategoryExpenses = true }) {
                VStack(spacing: 4) {
                    ProgressView(value: min(category.spent, category.monthlyLimit), total: category.monthlyLimit)
                        .tint(category.spent > category.monthlyLimit ? .red : .blue)
                    
                    Text("\(Int(category.percentUsed))% used")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showAddExpense) {
            QuickAddExpenseView(preselectedCategory: category.name)
        }
        .sheet(isPresented: $showCategoryExpenses) {
            CategoryExpensesView(category: category)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        amount.formatAsCurrency()
    }
}

struct AddBudgetCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    let month: Int
    let year: Int
    
    @State private var categoryName = ""
    @State private var monthlyLimit = ""
    @State private var showTemplates = false
    @State private var showCustomInput = false
    
    // Predefined category templates
    let categoryTemplates = [
        "Rent/Mortgage",
        "Utilities - Electric",
        "Utilities - Water",
        "Utilities - Gas",
        "Internet/Phone",
        "Groceries",
        "Dining Out",
        "Transportation",
        "Gas/Fuel",
        "Car Insurance",
        "Health Insurance",
        "Entertainment",
        "Subscriptions",
        "Shopping",
        "Personal Care",
        "Healthcare",
        "Debt Payments",
        "Savings",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    if showCustomInput {
                        // Allow custom text input
                        HStack {
                            TextField("Custom Category Name", text: $categoryName)
                            
                            Button(action: {
                                showCustomInput = false
                                showTemplates = true
                            }) {
                                Text("Templates")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        // Show selected category or prompt to select
                        HStack {
                            Text(categoryName.isEmpty ? "Select a category..." : categoryName)
                                .foregroundColor(categoryName.isEmpty ? .gray : .primary)
                            
                            Spacer()
                            
                            Button(action: { showTemplates = true }) {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    TextField("Monthly Limit", text: $monthlyLimit)
                        .keyboardType(.decimalPad)
                }
                
                if showTemplates {
                    Section(header: Text("Choose Template")) {
                        ForEach(categoryTemplates, id: \.self) { template in
                            Button(action: {
                                categoryName = template
                                showTemplates = false
                                showCustomInput = false
                            }) {
                                HStack {
                                    Text(template)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if categoryName == template {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        
                        // Add "Custom" option at the bottom
                        Button(action: {
                            categoryName = ""
                            showTemplates = false
                            showCustomInput = true
                        }) {
                            HStack {
                                Text("Custom Category...")
                                    .foregroundColor(.blue)
                                    .italic()
                                Spacer()
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Budget Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudgetCategory()
                    }
                    .disabled(categoryName.isEmpty || monthlyLimit.isEmpty)
                }
            }
        }
    }
    
    private func saveBudgetCategory() {
        guard let userId = authService.currentUser?.id,
              let limit = Double(monthlyLimit) else { return }
        
        let category = BudgetCategory(
            userId: userId,
            name: categoryName,
            monthlyLimit: limit,
            month: month,
            year: year
        )
        
        dataService.saveBudgetCategory(category)
        dismiss()
    }
}

// MARK: - Edit Budget Category View

struct EditBudgetCategoryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    
    let category: BudgetCategory
    
    @State private var categoryName = ""
    @State private var monthlyLimit = ""
    
    var body: some View {
        Form {
            Section(header: Text("Category Details")) {
                TextField("Category Name", text: $categoryName)
                
                TextField("Monthly Limit", text: $monthlyLimit)
                    .keyboardType(.decimalPad)
            }
            
            Section(header: Text("Current Spending")) {
                HStack {
                    Text("Spent")
                    Spacer()
                    Text(category.spent.formatAsCurrency())
                        .foregroundColor(.gray)
                }
                
                if let limit = Double(monthlyLimit) {
                    HStack {
                        Text("Remaining")
                        Spacer()
                        Text((limit - category.spent).formatAsCurrency())
                            .foregroundColor(limit - category.spent < 0 ? .red : .green)
                    }
                }
            }
        }
        .navigationTitle("Edit Budget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(categoryName.isEmpty || monthlyLimit.isEmpty)
            }
        }
        .onAppear {
            categoryName = category.name
            monthlyLimit = String(category.monthlyLimit)
        }
    }
    
    private func saveChanges() {
        guard let limit = Double(monthlyLimit) else { return }
        
        let updatedCategory = BudgetCategory(
            id: category.id,
            userId: category.userId,
            name: categoryName,
            monthlyLimit: limit,
            month: category.month,
            year: category.year,
            spent: category.spent
        )
        
        dataService.saveBudgetCategory(updatedCategory)
        dismiss()
    }
}

// MARK: - Category Expenses View

struct CategoryExpensesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    let category: BudgetCategory
    
    var body: some View {
        NavigationView {
            VStack {
                if let userId = authService.currentUser?.id {
                    let allExpenses = dataService.getExpenses(for: userId, month: category.month, year: category.year)
                    let categoryExpenses = allExpenses.filter { $0.categoryName == category.name }.sorted { $0.date > $1.date }
                    
                    if categoryExpenses.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No expenses in \(category.name)")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Text("Expenses in this category will appear here")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        List {
                            Section(header: HStack {
                                Text("Budget Summary")
                                Spacer()
                            }) {
                                HStack {
                                    Text("Spent")
                                    Spacer()
                                    Text(category.spent.formatAsCurrency())
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("Budget")
                                    Spacer()
                                    Text(category.monthlyLimit.formatAsCurrency())
                                        .foregroundColor(.gray)
                                }
                                
                                HStack {
                                    Text("Remaining")
                                    Spacer()
                                    Text(category.remaining.formatAsCurrency())
                                        .fontWeight(.bold)
                                        .foregroundColor(category.remaining < 0 ? .red : .green)
                                }
                            }
                            
                            Section(header: Text("Expenses (\(categoryExpenses.count))")) {
                                ForEach(categoryExpenses) { expense in
                                    NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(expense.description)
                                                    .font(.headline)
                                                Text(expense.date.formatted())
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(expense.userShare.formatAsCurrency())
                                                .font(.headline)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(category.name)
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
