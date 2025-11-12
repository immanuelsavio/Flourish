//
//  SalaryManagementView.swift
//  Flourish
//
//  View for managing recurring salary/income
//

import SwiftUI

struct SalaryManagementView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddSalary = false
    
    var body: some View {
        VStack {
            if let userId = authService.currentUser?.id {
                let salaries = dataService.getSalaryIncomes(for: userId)
                
                if salaries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "banknote")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Salary Configured")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Add your salary details to get automatic reminders")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showAddSalary = true }) {
                            Label("Add Salary", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .padding(.top)
                    }
                } else {
                    List {
                        Section(header: Text("Active Salaries")) {
                            ForEach(salaries) { salary in
                                NavigationLink(destination: EditSalaryView(salary: salary)) {
                                    SalaryRow(salary: salary)
                                }
                            }
                        }
                        
                        Section(header: Text("Income History")) {
                            let transactions = dataService.getIncomeTransactions(for: userId)
                                .sorted { $0.date > $1.date }
                                .prefix(10)
                            
                            if transactions.isEmpty {
                                Text("No income transactions yet")
                                    .foregroundColor(.gray)
                                    .italic()
                            } else {
                                ForEach(Array(transactions)) { transaction in
                                    IncomeTransactionRow(transaction: transaction)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Salary & Income")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddSalary = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSalary) {
            AddSalaryView()
        }
    }
}

struct SalaryRow: View {
    @EnvironmentObject var dataService: DataService
    let salary: SalaryIncome
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(salary.amount.formatAsCurrency())
                    .font(.headline)
                
                Spacer()
                
                Text(salary.frequency.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            if let account = dataService.getAccount(by: salary.accountId) {
                Text("Deposited to: \(account.name)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Next expected:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(salary.nextExpectedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(salary.isOverdue ? .red : (salary.isDueSoon ? .orange : .gray))
                
                if salary.isOverdue {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct IncomeTransactionRow: View {
    @EnvironmentObject var dataService: DataService
    let transaction: IncomeTransaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Salary Deposit")
                    .font(.headline)
                
                HStack {
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let account = dataService.getAccount(by: transaction.accountId) {
                        Text("•")
                            .foregroundColor(.gray)
                        Text(account.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Text(transaction.amount.formatAsCurrency())
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

struct AddSalaryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var amount = ""
    @State private var frequency: IncomeFrequency = .monthly
    @State private var selectedAccount: Account?
    @State private var nextExpectedDate = Date()
    @State private var customDayInterval = "30"
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Salary Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(IncomeFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    if frequency == .custom {
                        TextField("Days Between Payments", text: $customDayInterval)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(header: Text("Deposit Account")) {
                    if let userId = authService.currentUser?.id {
                        let accounts = dataService.getAccounts(for: userId)
                        
                        if accounts.isEmpty {
                            Text("No accounts available. Please add an account first.")
                                .foregroundColor(.orange)
                        } else {
                            Picker("Account", selection: $selectedAccount) {
                                Text("Select Account").tag(nil as Account?)
                                ForEach(accounts) { account in
                                    Text(account.name).tag(account as Account?)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Next Expected Date")) {
                    DatePicker("Expected On", selection: $nextExpectedDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add Salary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSalary()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isValid: Bool {
        guard let _ = Double(amount), !amount.isEmpty else { return false }
        guard selectedAccount != nil else { return false }
        if frequency == .custom {
            guard let _ = Int(customDayInterval), !customDayInterval.isEmpty else { return false }
        }
        return true
    }
    
    private func saveSalary() {
        guard let userId = authService.currentUser?.id,
              let amountValue = Double(amount),
              let account = selectedAccount else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return
        }
        
        let customInterval = frequency == .custom ? Int(customDayInterval) : nil
        
        let salary = SalaryIncome(
            userId: userId,
            amount: amountValue,
            frequency: frequency,
            accountId: account.id,
            nextExpectedDate: nextExpectedDate,
            customDayInterval: customInterval
        )
        
        dataService.saveSalaryIncome(salary)
        dismiss()
    }
}

struct EditSalaryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    let salary: SalaryIncome
    
    @State private var amount: String
    @State private var frequency: IncomeFrequency
    @State private var nextExpectedDate: Date
    @State private var showDeleteConfirmation = false
    
    init(salary: SalaryIncome) {
        self.salary = salary
        _amount = State(initialValue: String(format: "%.2f", salary.amount))
        _frequency = State(initialValue: salary.frequency)
        _nextExpectedDate = State(initialValue: salary.nextExpectedDate)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Salary Details")) {
                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                
                Picker("Frequency", selection: $frequency) {
                    ForEach(IncomeFrequency.allCases, id: \.self) { freq in
                        Text(freq.rawValue).tag(freq)
                    }
                }
                
                DatePicker("Next Expected Date", selection: $nextExpectedDate, displayedComponents: .date)
            }
            
            Section {
                Button(action: { showDeleteConfirmation = true }) {
                    Text("Delete Salary")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Edit Salary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveSalary()
                }
            }
        }
        .alert("Delete Salary?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataService.deleteSalaryIncome(salary)
                dismiss()
            }
        } message: {
            Text("This will remove the salary configuration. Past income transactions will not be affected.")
        }
    }
    
    private func saveSalary() {
        guard let amountValue = Double(amount) else { return }
        
        var updatedSalary = salary
        updatedSalary.amount = amountValue
        updatedSalary.frequency = frequency
        updatedSalary.nextExpectedDate = nextExpectedDate
        
        dataService.saveSalaryIncome(updatedSalary)
        dismiss()
    }
}

#Preview {
    NavigationView {
        SalaryManagementView()
            .environmentObject(DataService.shared)
    }
}
