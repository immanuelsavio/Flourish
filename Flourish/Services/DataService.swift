//
//  DataService.swift
//  FinanceApp
//
//  Service for data persistence using local storage (with remote DB pipeline)
//

import Foundation
import Combine

class DataService: ObservableObject {
    static let shared = DataService()
    
    @Published var users: [User] = []
    @Published var accounts: [Account] = []
    @Published var budgetCategories: [BudgetCategory] = []
    @Published var expenses: [Expense] = []
    @Published var subscriptions: [Subscription] = []
    @Published var balancesOwed: [BalanceOwed] = []
    @Published var repayments: [Repayment] = []
    @Published var transfers: [Transfer] = []
    @Published var savingsBudgets: [SavingsBudget] = []
    
    private let useRemoteDB: Bool
    private var remoteDBConfig: RemoteDBConfig?
    
    private init() {
        // Check for remote database configuration
        useRemoteDB = ProcessInfo.processInfo.environment["USE_REMOTE_DB"] == "true"
        
        if useRemoteDB {
            remoteDBConfig = RemoteDBConfig(
                host: ProcessInfo.processInfo.environment["DB_HOST"] ?? "",
                port: ProcessInfo.processInfo.environment["DB_PORT"] ?? "",
                database: ProcessInfo.processInfo.environment["DB_NAME"] ?? "",
                username: ProcessInfo.processInfo.environment["DB_USERNAME"] ?? "",
                password: ProcessInfo.processInfo.environment["DB_PASSWORD"] ?? ""
            )
        }
        
        loadLocalData()
    }
    
    // MARK: - User Operations
    
    func saveUser(_ user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        } else {
            users.append(user)
        }
        saveToLocalStorage()
    }
    
    func getUser(by email: String) -> User? {
        users.first { $0.email == email }
    }
    
    func getUser(by id: UUID) -> User? {
        users.first { $0.id == id }
    }
    
    // MARK: - Account Operations
    
    func saveAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }
        saveToLocalStorage()
    }
    
    func getAccounts(for userId: UUID) -> [Account] {
        accounts.filter { $0.userId == userId }
    }
    
    func getAccount(by id: UUID) -> Account? {
        accounts.first { $0.id == id }
    }
    
    func deleteAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        saveToLocalStorage()
    }
    
    func updateAccountBalance(_ accountId: UUID, by amount: Double) {
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[index].balance += amount
            saveToLocalStorage()
        }
    }
    
    // MARK: - Budget Category Operations
    
    func saveBudgetCategory(_ category: BudgetCategory) {
        if let index = budgetCategories.firstIndex(where: { $0.id == category.id }) {
            budgetCategories[index] = category
        } else {
            budgetCategories.append(category)
        }
        saveToLocalStorage()
    }
    
    func getBudgetCategories(for userId: UUID, month: Int, year: Int) -> [BudgetCategory] {
        budgetCategories.filter { $0.userId == userId && $0.month == month && $0.year == year }
    }
    
    func deleteBudgetCategory(_ category: BudgetCategory) {
        budgetCategories.removeAll { $0.id == category.id }
        saveToLocalStorage()
    }
    
    func copyBudgetToNextMonth(userId: UUID, fromMonth: Int, fromYear: Int) {
        let currentCategories = getBudgetCategories(for: userId, month: fromMonth, year: fromYear)
        
        // Calculate next month and year
        var nextMonth = fromMonth + 1
        var nextYear = fromYear
        if nextMonth > 12 {
            nextMonth = 1
            nextYear += 1
        }
        
        // Check if budget already exists for next month
        let existingCategories = getBudgetCategories(for: userId, month: nextMonth, year: nextYear)
        guard existingCategories.isEmpty else { return }
        
        // Copy categories
        for category in currentCategories {
            let newCategory = BudgetCategory(
                userId: userId,
                name: category.name,
                monthlyLimit: category.monthlyLimit,
                month: nextMonth,
                year: nextYear,
                spent: 0
            )
            saveBudgetCategory(newCategory)
        }
    }
    
    // MARK: - Expense Operations
    
    func saveExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
        } else {
            expenses.append(expense)
            
            // Update account balance
            updateAccountBalance(expense.accountId, by: -expense.userShare)
            
            // Update budget category spent amount
            updateBudgetSpending(for: expense.userId, category: expense.categoryName, amount: expense.userShare, date: expense.date)
            
            // Update balances owed
            updateBalancesOwed(from: expense)
        }
        saveToLocalStorage()
    }
    
    func getExpenses(for userId: UUID) -> [Expense] {
        expenses.filter { $0.userId == userId }
    }
    
    func getExpenses(for userId: UUID, month: Int, year: Int) -> [Expense] {
        expenses.filter {
            $0.userId == userId &&
            Calendar.current.component(.month, from: $0.date) == month &&
            Calendar.current.component(.year, from: $0.date) == year
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        // Reverse account balance update
        updateAccountBalance(expense.accountId, by: expense.userShare)
        
        // Reverse budget spending
        updateBudgetSpending(for: expense.userId, category: expense.categoryName, amount: -expense.userShare, date: expense.date)
        
        // Remove expense
        expenses.removeAll { $0.id == expense.id }
        saveToLocalStorage()
    }
    
    private func updateBudgetSpending(for userId: UUID, category: String, amount: Double, date: Date) {
        let month = Calendar.current.component(.month, from: date)
        let year = Calendar.current.component(.year, from: date)
        
        if let index = budgetCategories.firstIndex(where: {
            $0.userId == userId && $0.name == category && $0.month == month && $0.year == year
        }) {
            budgetCategories[index].spent += amount
            saveToLocalStorage()
        }
    }
    
    // MARK: - Subscription Operations
    
    func saveSubscription(_ subscription: Subscription) {
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
        } else {
            subscriptions.append(subscription)
        }
        saveToLocalStorage()
    }
    
    func getSubscriptions(for userId: UUID) -> [Subscription] {
        subscriptions.filter { $0.userId == userId && $0.isActive }
    }
    
    func deleteSubscription(_ subscription: Subscription) {
        subscriptions.removeAll { $0.id == subscription.id }
        saveToLocalStorage()
    }
    
    func processSubscriptions(for userId: UUID) {
        let userSubscriptions = getSubscriptions(for: userId)
        let today = Date()
        
        for subscription in userSubscriptions {
            if subscription.nextDueDate <= today {
                // Create expense for subscription
                let expense = Expense(
                    userId: userId,
                    amount: subscription.amount,
                    date: subscription.nextDueDate,
                    description: subscription.name,
                    categoryName: subscription.categoryName,
                    accountId: subscription.accountId,
                    isSubscription: true,
                    subscriptionId: subscription.id
                )
                saveExpense(expense)
                
                // Update next due date
                var updatedSubscription = subscription
                updatedSubscription.nextDueDate = subscription.calculateNextDueDate()
                saveSubscription(updatedSubscription)
            }
        }
    }
    
    // MARK: - Balance Owed Operations
    
    func saveBalanceOwed(_ balance: BalanceOwed) {
        if let index = balancesOwed.firstIndex(where: { $0.id == balance.id }) {
            balancesOwed[index] = balance
        } else {
            balancesOwed.append(balance)
        }
        saveToLocalStorage()
    }
    
    func getBalancesOwed(for userId: UUID) -> [BalanceOwed] {
        balancesOwed.filter { $0.userId == userId }
    }
    
    func updateBalancesOwed(from expense: Expense) {
        for participant in expense.splitParticipants where !participant.isCurrentUser {
            if let index = balancesOwed.firstIndex(where: { $0.userId == expense.userId && $0.personName == participant.name }) {
                balancesOwed[index].amount += participant.amount
                balancesOwed[index].lastUpdated = Date()
            } else {
                let balance = BalanceOwed(
                    userId: expense.userId,
                    personName: participant.name,
                    amount: participant.amount
                )
                balancesOwed.append(balance)
            }
        }
        saveToLocalStorage()
    }
    
    func recordRepayment(_ repayment: Repayment) {
        repayments.append(repayment)
        
        // Update balance owed
        if let index = balancesOwed.firstIndex(where: { $0.userId == repayment.userId && $0.personName == repayment.personName }) {
            balancesOwed[index].amount -= repayment.amount
            balancesOwed[index].lastUpdated = Date()
            
            // Remove if fully paid
            if balancesOwed[index].amount <= 0 {
                balancesOwed.remove(at: index)
            }
        }
        
        saveToLocalStorage()
    }
    
    // MARK: - Savings Budget Operations

    func saveSavingsBudget(_ budget: SavingsBudget) {
        if let index = savingsBudgets.firstIndex(where: { $0.id == budget.id }) {
            savingsBudgets[index] = budget
        } else {
            savingsBudgets.append(budget)
        }
        saveToLocalStorage()
    }

    func getSavingsBudgets(for userId: UUID) -> [SavingsBudget] {
        savingsBudgets.filter { $0.userId == userId }
    }

    func deleteSavingsBudget(_ budget: SavingsBudget) {
        savingsBudgets.removeAll { $0.id == budget.id }
        saveToLocalStorage()
    }
    
    // MARK: - Transfer Operations

    func saveTransfer(_ transfer: Transfer) {
        transfers.append(transfer)
        
        // Update account balances
        updateAccountBalance(transfer.fromAccountId, by: -transfer.amount)
        updateAccountBalance(transfer.toAccountId, by: transfer.amount)
        
        saveToLocalStorage()
    }

    func getTransfers(for userId: UUID) -> [Transfer] {
        transfers.filter { $0.userId == userId }
    }
    
    // MARK: - Local Storage
    
    private func saveToLocalStorage() {
        saveData(users, forKey: "users")
        saveData(accounts, forKey: "accounts")
        saveData(budgetCategories, forKey: "budgetCategories")
        saveData(expenses, forKey: "expenses")
        saveData(subscriptions, forKey: "subscriptions")
        saveData(balancesOwed, forKey: "balancesOwed")
        saveData(repayments, forKey: "repayments")
        saveData(transfers, forKey: "transfers")
        saveData(savingsBudgets, forKey: "savingsBudgets")
    }
    
    private func loadLocalData() {
        users = loadData(forKey: "users") ?? []
        accounts = loadData(forKey: "accounts") ?? []
        budgetCategories = loadData(forKey: "budgetCategories") ?? []
        expenses = loadData(forKey: "expenses") ?? []
        subscriptions = loadData(forKey: "subscriptions") ?? []
        balancesOwed = loadData(forKey: "balancesOwed") ?? []
        repayments = loadData(forKey: "repayments") ?? []
        transfers = loadData(forKey: "transfers") ?? []
        savingsBudgets = loadData(forKey: "savingsBudgets") ?? []
    }
    
    private func saveData<T: Codable>(_ data: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    private func loadData<T: Codable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Remote Database Placeholder
    
    // Placeholder for remote database connection
    private func connectToRemoteDB() -> Bool {
        guard let config = remoteDBConfig else { return false }
        
        // TODO: Implement PostgreSQL or MongoDB connection
        print("Connecting to remote DB at \(config.host):\(config.port)")
        print("Database: \(config.database), Username: \(config.username)")
        
        // For now, return false to use local storage
        return false
    }
}

struct RemoteDBConfig {
    let host: String
    let port: String
    let database: String
    let username: String
    let password: String
}

