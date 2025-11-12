//
//  BudgetView.swift
//  FinanceApp
//
//  View for managing monthly budgets
//

import SwiftUI

struct BudgetView: View {
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
                                BudgetCategoryRow(category: category)
                            }
                            .onDelete(perform: deleteCategories)
                        }
                    }
                }
            }
            .navigationTitle("Budget")
            .toolbar {
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
            
            Text("\(monthName(selectedMonth)) \(selectedYear)")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(category.name)
                    .font(.headline)
                
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
            
            ProgressView(value: min(category.spent, category.monthlyLimit), total: category.monthlyLimit)
                .tint(category.spent > category.monthlyLimit ? .red : .blue)
            
            Text("\(Int(category.percentUsed))% used")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showAddExpense) {
            QuickAddExpenseView(preselectedCategory: category.name)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
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
                    HStack {
                        TextField("Category Name", text: $categoryName)
                        
                        Button(action: { showTemplates = true }) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.blue)
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
