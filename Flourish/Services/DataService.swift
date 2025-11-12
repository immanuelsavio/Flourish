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
    @Published var salaryIncomes: [SalaryIncome] = []
    @Published var incomeTransactions: [IncomeTransaction] = []
    @Published var actionItems: [ActionItem] = []
    @Published var friendIOUs: [FriendIOU] = []
    
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
            let account = accounts[index]
            
            if account.isCreditCard {
                // For credit cards: spending increases usage (makes balance more negative)
                // Payments decrease usage (makes balance less negative or positive)
                // Amount is negative for expenses, positive for payments
                accounts[index].balance += amount
            } else {
                // For regular accounts: normal balance adjustment
                accounts[index].balance += amount
            }
            
            saveToLocalStorage()
        }
    }
    
    // MARK: - Budget Category Operations
    
    func saveBudgetCategory(_ category: BudgetCategory) {
        if let index = budgetCategories.firstIndex(where: { $0.id == category.id }) {
            budgetCategories[index] = category
        } else {
            // Calculate existing spending for this category/month/year
            let existingExpenses = expenses.filter {
                $0.userId == category.userId &&
                $0.categoryName == category.name &&
                Calendar.current.component(.month, from: $0.date) == category.month &&
                Calendar.current.component(.year, from: $0.date) == category.year
            }
            let existingSpent = existingExpenses.reduce(0) { $0 + $1.userShare }
            
            // Create new category with existing spending
            var newCategory = category
            newCategory.spent = existingSpent
            budgetCategories.append(newCategory)
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
    
    func updateExpense(_ updatedExpense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == updatedExpense.id }) else {
            // If expense doesn't exist, treat as new
            saveExpense(updatedExpense)
            return
        }
        
        let oldExpense = expenses[index]
        
        // Reverse old expense effects
        updateAccountBalance(oldExpense.accountId, by: oldExpense.userShare)
        updateBudgetSpending(for: oldExpense.userId, category: oldExpense.categoryName, amount: -oldExpense.userShare, date: oldExpense.date)
        reverseBalancesOwed(from: oldExpense)
        
        // Apply new expense effects
        updateAccountBalance(updatedExpense.accountId, by: -updatedExpense.userShare)
        updateBudgetSpending(for: updatedExpense.userId, category: updatedExpense.categoryName, amount: updatedExpense.userShare, date: updatedExpense.date)
        updateBalancesOwed(from: updatedExpense)
        
        // Update the expense
        expenses[index] = updatedExpense
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
    
    func reverseBalancesOwed(from expense: Expense) {
        for participant in expense.splitParticipants where !participant.isCurrentUser {
            if let index = balancesOwed.firstIndex(where: { $0.userId == expense.userId && $0.personName == participant.name }) {
                balancesOwed[index].amount -= participant.amount
                balancesOwed[index].lastUpdated = Date()
                
                // Remove if balance is zero or negative
                if balancesOwed[index].amount <= 0 {
                    balancesOwed.remove(at: index)
                }
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
    
    // MARK: - Salary Income Operations
    
    func saveSalaryIncome(_ salary: SalaryIncome) {
        if let index = salaryIncomes.firstIndex(where: { $0.id == salary.id }) {
            salaryIncomes[index] = salary
        } else {
            salaryIncomes.append(salary)
        }
        saveToLocalStorage()
    }
    
    func getSalaryIncomes(for userId: UUID) -> [SalaryIncome] {
        salaryIncomes.filter { $0.userId == userId && $0.isActive }
    }
    
    func deleteSalaryIncome(_ salary: SalaryIncome) {
        salaryIncomes.removeAll { $0.id == salary.id }
        saveToLocalStorage()
    }
    
    func confirmSalaryDeposit(_ salary: SalaryIncome, amount: Double? = nil, date: Date = Date()) {
        let depositAmount = amount ?? salary.amount
        
        // Create income transaction as an Expense with positive amount
        let expense = Expense(
            userId: salary.userId,
            amount: depositAmount,
            date: date,
            description: "Salary Deposit",
            categoryName: "Income",
            accountId: salary.accountId,
            isSubscription: false
        )
        
        // Update account balance (add money)
        updateAccountBalance(salary.accountId, by: depositAmount)
        
        // Save expense record
        expenses.append(expense)
        
        // Create income transaction record
        let incomeTransaction = IncomeTransaction(
            userId: salary.userId,
            salaryId: salary.id,
            amount: depositAmount,
            accountId: salary.accountId,
            date: date
        )
        incomeTransactions.append(incomeTransaction)
        
        // Update next expected date
        if let index = salaryIncomes.firstIndex(where: { $0.id == salary.id }) {
            salaryIncomes[index].nextExpectedDate = salary.calculateNextDate(from: date)
        }
        
        // Remove salary action item
        actionItems.removeAll { $0.type == .salaryPending && $0.relatedEntityId == salary.id }
        
        saveToLocalStorage()
    }
    
    func getIncomeTransactions(for userId: UUID) -> [IncomeTransaction] {
        incomeTransactions.filter { $0.userId == userId }
    }
    
    // MARK: - Action Item Operations
    
    func createActionItem(_ item: ActionItem) {
        // Check if similar item already exists
        let exists = actionItems.contains { existingItem in
            existingItem.userId == item.userId &&
            existingItem.type == item.type &&
            existingItem.relatedEntityId == item.relatedEntityId &&
            !existingItem.isDismissed
        }
        
        if !exists {
            actionItems.append(item)
            saveToLocalStorage()
        }
    }
    
    func getActionItems(for userId: UUID) -> [ActionItem] {
        actionItems.filter { $0.userId == userId && !$0.isDismissed }
            .sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    func dismissActionItem(_ item: ActionItem) {
        if let index = actionItems.firstIndex(where: { $0.id == item.id }) {
            actionItems[index].isDismissed = true
            saveToLocalStorage()
        }
    }
    
    func generateActionItems(for userId: UUID) {
        // Check for pending salaries
        let salaries = getSalaryIncomes(for: userId)
        for salary in salaries where salary.isDueSoon || salary.isOverdue {
            let priority: ActionItemPriority = salary.isOverdue ? .high : .medium
            let message = salary.isOverdue 
                ? "Your salary was expected on \(salary.nextExpectedDate.formatted(date: .abbreviated, time: .omitted)). Confirm deposit?"
                : "Salary expected on \(salary.nextExpectedDate.formatted(date: .abbreviated, time: .omitted))"
            
            let item = ActionItem(
                userId: userId,
                type: .salaryPending,
                priority: priority,
                title: "Salary Confirmation",
                message: message,
                relatedEntityId: salary.id
            )
            createActionItem(item)
        }
        
        // Check for upcoming subscriptions
        let subscriptions = getSubscriptions(for: userId)
        for subscription in subscriptions where subscription.isDueSoon {
            let item = ActionItem(
                userId: userId,
                type: .subscriptionDue,
                priority: .medium,
                title: "Subscription Due",
                message: "\(subscription.name) - \(subscription.amount.formatAsCurrency()) due on \(subscription.nextDueDate.formatted(date: .abbreviated, time: .omitted))",
                relatedEntityId: subscription.id
            )
            createActionItem(item)
        }
        
        // Check for overspending
        let now = Date()
        let month = Calendar.current.component(.month, from: now)
        let year = Calendar.current.component(.year, from: now)
        let categories = getBudgetCategories(for: userId, month: month, year: year)
        
        for category in categories where category.spent > category.monthlyLimit {
            let overage = category.spent - category.monthlyLimit
            let item = ActionItem(
                userId: userId,
                type: .overspending,
                priority: .high,
                title: "Budget Exceeded",
                message: "You're over budget in \(category.name) by \(overage.formatAsCurrency())",
                relatedEntityId: category.id
            )
            createActionItem(item)
        }
        
        // Check for friend balances
        let balances = getBalancesOwed(for: userId)
        for balance in balances where balance.amount > 50 { // Only show significant balances
            let item = ActionItem(
                userId: userId,
                type: .friendBalance,
                priority: .low,
                title: "Outstanding Balance",
                message: "\(balance.personName) owes you \(balance.amount.formatAsCurrency())",
                relatedEntityId: balance.id
            )
            createActionItem(item)
        }
        
        // Check for unsettled IOUs
        let ious = getFriendIOUs(for: userId)
        for iou in ious where !iou.isSettled && iou.amount > 20 {
            let message = iou.direction == .owedToYou
                ? "\(iou.personName) owes you \(iou.amount.formatAsCurrency())"
                : "You owe \(iou.personName) \(iou.amount.formatAsCurrency())"
            
            let item = ActionItem(
                userId: userId,
                type: .friendBalance,
                priority: .low,
                title: "IOU Reminder",
                message: message,
                relatedEntityId: iou.id
            )
            createActionItem(item)
        }
    }
    
    // MARK: - Friend IOU Operations
    
    func saveFriendIOU(_ iou: FriendIOU) {
        if let index = friendIOUs.firstIndex(where: { $0.id == iou.id }) {
            friendIOUs[index] = iou
        } else {
            friendIOUs.append(iou)
        }
        saveToLocalStorage()
    }
    
    func getFriendIOUs(for userId: UUID) -> [FriendIOU] {
        friendIOUs.filter { $0.userId == userId }
    }
    
    func getActiveFriendIOUs(for userId: UUID) -> [FriendIOU] {
        friendIOUs.filter { $0.userId == userId && !$0.isSettled }
    }
    
    func settleFriendIOU(_ iou: FriendIOU) {
        if let index = friendIOUs.firstIndex(where: { $0.id == iou.id }) {
            friendIOUs[index].isSettled = true
            friendIOUs[index].settledDate = Date()
            saveToLocalStorage()
        }
    }
    
    func deleteFriendIOU(_ iou: FriendIOU) {
        friendIOUs.removeAll { $0.id == iou.id }
        saveToLocalStorage()
    }
    
    // MARK: - Balance Reconciliation
    
    func reconcileAccount(_ account: Account, actualBalance: Double, notes: String = "") {
        let difference = actualBalance - account.balance
        
        guard abs(difference) > 0.01 else { return } // Ignore tiny differences
        
        // Create reconciliation adjustment expense
        let expense = Expense(
            userId: account.userId,
            amount: abs(difference),
            date: Date(),
            description: "Balance Reconciliation: \(notes.isEmpty ? "Adjustment" : notes)",
            categoryName: "Reconciliation",
            accountId: account.id,
            isSubscription: false
        )
        
        expenses.append(expense)
        
        // Update account balance to match actual
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index].balance = actualBalance
        }
        
        saveToLocalStorage()
    }
    
    // MARK: - Settle Up Function
    
    func settleUpBalance(userId: UUID, personName: String, notes: String = "") {
        // Find balance for this person
        if let index = balancesOwed.firstIndex(where: { $0.userId == userId && $0.personName == personName }) {
            let balance = balancesOwed[index]
            
            // Create repayment record for the full amount
            let repayment = Repayment(
                userId: userId,
                personName: personName,
                amount: balance.amount,
                date: Date(),
                notes: notes.isEmpty ? "Settled up" : notes
            )
            repayments.append(repayment)
            
            // Remove the balance
            balancesOwed.remove(at: index)
            
            // Remove related action items
            actionItems.removeAll { $0.userId == userId && $0.type == .friendBalance }
            
            saveToLocalStorage()
        }
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
        saveData(salaryIncomes, forKey: "salaryIncomes")
        saveData(incomeTransactions, forKey: "incomeTransactions")
        saveData(actionItems, forKey: "actionItems")
        saveData(friendIOUs, forKey: "friendIOUs")
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
        salaryIncomes = loadData(forKey: "salaryIncomes") ?? []
        incomeTransactions = loadData(forKey: "incomeTransactions") ?? []
        actionItems = loadData(forKey: "actionItems") ?? []
        friendIOUs = loadData(forKey: "friendIOUs") ?? []
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

