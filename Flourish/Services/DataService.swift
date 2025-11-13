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
    @Published var scheduledTransfers: [ScheduledTransfer] = []
    @Published var savingsBudgets: [SavingsBudget] = []
    @Published var salaryIncomes: [SalaryIncome] = []
    @Published var incomeTransactions: [IncomeTransaction] = []
    @Published var actionItems: [ActionItem] = []
    @Published var friendIOUs: [FriendIOU] = []
    @Published var monthlyReviewStatuses: [MonthlyReviewStatus] = []
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "USD"
    
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
    
    func hasDepositAccount(for userId: UUID) -> Bool {
        accounts.contains { $0.userId == userId && ($0.type == .checking || $0.type == .savings) }
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
    
    func addManualBalance(userId: UUID, personName: String, amount: Double, isOwedToMe: Bool = true) {
        // Check if balance already exists for this person
        if let index = balancesOwed.firstIndex(where: { $0.userId == userId && $0.personName == personName }) {
            // Add to existing balance
            balancesOwed[index].amount += amount
            balancesOwed[index].lastUpdated = Date()
        } else {
            // Create new balance
            let balance = BalanceOwed(
                userId: userId,
                personName: personName,
                amount: amount,
                lastUpdated: Date(),
                isOwedToMe: isOwedToMe
            )
            balancesOwed.append(balance)
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
    
    // MARK: - Scheduled Transfer Operations

    func saveScheduledTransfer(_ scheduled: ScheduledTransfer) {
        let isNewTransfer = !scheduledTransfers.contains(where: { $0.id == scheduled.id })
        
        if let index = scheduledTransfers.firstIndex(where: { $0.id == scheduled.id }) {
            scheduledTransfers[index] = scheduled
        } else {
            scheduledTransfers.append(scheduled)
        }
        
        // If this is a new scheduled transfer and it's due today or in the past, create action item immediately
        if isNewTransfer && !scheduled.isCompleted {
            let today = Calendar.current.startOfDay(for: Date())
            let scheduledDay = Calendar.current.startOfDay(for: scheduled.scheduledDate)
            
            if scheduledDay <= today {
                let fromName = getAccount(by: scheduled.fromAccountId)?.name ?? "From"
                let toName = getAccount(by: scheduled.toAccountId)?.name ?? "To"
                let msg = "Scheduled transfer of \(scheduled.amount.formatAsCurrency()) from \(fromName) → \(toName) requires approval to complete."
                
                let item = ActionItem(
                    userId: scheduled.userId,
                    type: .pendingTransfer,
                    title: "Pending Transfer Approval",
                    message: msg,
                    priority: .medium,
                    relatedEntityId: scheduled.id
                )
                createActionItem(item)
            }
        }
        
        saveToLocalStorage()
    }

    func getScheduledTransfers(for userId: UUID) -> [ScheduledTransfer] {
        scheduledTransfers.filter { $0.userId == userId }
    }

    func markScheduledTransferCompleted(_ id: UUID, completedDate: Date = Date()) {
        if let index = scheduledTransfers.firstIndex(where: { $0.id == id }) {
            scheduledTransfers[index].isCompleted = true
            scheduledTransfers[index].completedDate = completedDate
            saveToLocalStorage()
        }
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
    
    // MARK: - Confirm Scheduled Transfer

    func confirmScheduledTransfer(_ scheduled: ScheduledTransfer) {
        // Create a normal transfer and update balances
        let transfer = Transfer(
            userId: scheduled.userId,
            fromAccountId: scheduled.fromAccountId,
            toAccountId: scheduled.toAccountId,
            amount: scheduled.amount,
            date: Date(),
            notes: scheduled.notes ?? "Scheduled transfer completed"
        )
        saveTransfer(transfer)
        // If recurring, advance scheduledDate; else mark completed
        if let interval = scheduled.recurrenceDays, interval > 0 {
            if let idx = scheduledTransfers.firstIndex(where: { $0.id == scheduled.id }) {
                scheduledTransfers[idx].scheduledDate = Calendar.current.date(byAdding: .day, value: interval, to: scheduled.scheduledDate) ?? scheduled.scheduledDate
                saveToLocalStorage()
            }
        } else {
            markScheduledTransferCompleted(scheduled.id, completedDate: Date())
        }
        // Remove related action items
        actionItems.removeAll { $0.type == .pendingTransfer && $0.relatedEntityId == scheduled.id }
        saveToLocalStorage()
    }
    
    func declineScheduledTransfer(_ scheduled: ScheduledTransfer) {
        // If recurring, advance to next occurrence without executing current one
        if let interval = scheduled.recurrenceDays, interval > 0 {
            if let idx = scheduledTransfers.firstIndex(where: { $0.id == scheduled.id }) {
                scheduledTransfers[idx].scheduledDate = Calendar.current.date(byAdding: .day, value: interval, to: scheduled.scheduledDate) ?? scheduled.scheduledDate
                saveToLocalStorage()
            }
        } else {
            // If one-time, mark as completed (effectively canceling it)
            markScheduledTransferCompleted(scheduled.id, completedDate: Date())
        }
        // Remove related action items
        actionItems.removeAll { $0.type == .pendingTransfer && $0.relatedEntityId == scheduled.id }
        saveToLocalStorage()
    }
    
    // MARK: - Action Item Operations
    
    func createActionItem(_ item: ActionItem) {
        // For monthly review items, remove any existing ones for the same month/year first
        // This ensures only ONE reminder exists at a time (replaces 7-day with 3-day, etc.)
        if item.type == .monthlyFinanceReview {
            actionItems.removeAll { existingItem in
                existingItem.userId == item.userId &&
                existingItem.type == .monthlyFinanceReview &&
                existingItem.relatedEntityId == item.relatedEntityId
            }
        }
        
        // Check if similar item already exists (for other types)
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
                title: "Salary Confirmation",
                message: message,
                priority: priority,
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
                title: "Subscription Due",
                message: "\(subscription.name) - \(subscription.amount.formatAsCurrency()) due on \(subscription.nextDueDate.formatted(date: .abbreviated, time: .omitted))",
                priority: .medium,
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
                title: "Budget Exceeded",
                message: "You're over budget in \(category.name) by \(overage.formatAsCurrency())",
                priority: .high,
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
                title: "Outstanding Balance",
                message: "\(balance.personName) owes you \(balance.amount.formatAsCurrency())",
                priority: .low,
                relatedEntityId: balance.id
            )
            createActionItem(item)
        }

        // Check for scheduled transfers due (one-time or recurring)
        let scheduled = getScheduledTransfers(for: userId)
        let today = Calendar.current.startOfDay(for: Date())
        for s in scheduled where !s.isCompleted {
            var due = false
            let scheduledDay = Calendar.current.startOfDay(for: s.scheduledDate)
            if let interval = s.recurrenceDays, interval > 0 {
                // Recurring: due if today is on/after first schedule and aligned to recurrence
                if scheduledDay <= today {
                    let days = Calendar.current.dateComponents([.day], from: scheduledDay, to: today).day ?? 0
                    if days % interval == 0 { due = true }
                }
            } else {
                // One-time: due on or after scheduled date until completed
                if scheduledDay <= today { due = true }
            }
            if due {
                let fromName = getAccount(by: s.fromAccountId)?.name ?? "From"
                let toName = getAccount(by: s.toAccountId)?.name ?? "To"
                let msg = "Scheduled transfer of \(s.amount.formatAsCurrency()) from \(fromName) → \(toName) requires approval to complete."
                let item = ActionItem(
                    userId: userId,
                    type: .pendingTransfer,
                    title: "Pending Transfer Approval",
                    message: msg,
                    priority: .medium,
                    relatedEntityId: s.id
                )
                createActionItem(item)
            }
        }
        
        // Check for monthly finance review (current month and previous month if not completed)
        let currentMonth = Calendar.current.component(.month, from: now)
        let currentYear = Calendar.current.component(.year, from: now)
        
        // Check current month review
        if shouldShowMonthlyReviewReminder(for: userId, month: currentMonth, year: currentYear) {
            // Get or create status to use as relatedEntityId
            var status = getMonthlyReviewStatus(for: userId, month: currentMonth, year: currentYear)
            if status == nil {
                status = MonthlyReviewStatus(userId: userId, month: currentMonth, year: currentYear)
                saveMonthlyReviewStatus(status!)
            }
            
            let item = ActionItem(
                userId: userId,
                type: .monthlyFinanceReview,
                title: "Monthly Finance Review",
                message: "Review your finances for \(status!.monthYearString). Verify that your app balances match your bank statements.",
                priority: .high,
                relatedEntityId: status!.id
            )
            createActionItem(item)
        }
        
        // Check ONLY the immediately previous month for carryover (not older months)
        var previousMonth = currentMonth - 1
        var previousYear = currentYear
        if previousMonth < 1 {
            previousMonth = 12
            previousYear -= 1
        }
        
        if shouldShowMonthlyReviewReminder(for: userId, month: previousMonth, year: previousYear) {
            // Get or create status
            var status = getMonthlyReviewStatus(for: userId, month: previousMonth, year: previousYear)
            if status == nil {
                status = MonthlyReviewStatus(userId: userId, month: previousMonth, year: previousYear)
                saveMonthlyReviewStatus(status!)
            }
            
            let item = ActionItem(
                userId: userId,
                type: .monthlyFinanceReview,
                title: "⚠️ Overdue: Monthly Finance Review",
                message: "You haven't completed your review for \(status!.monthYearString). Please review your finances to ensure accuracy.",
                priority: .high,
                relatedEntityId: status!.id
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
    
    // MARK: - Monthly Review Operations
    
    func getMonthlyReviewStatus(for userId: UUID, month: Int, year: Int) -> MonthlyReviewStatus? {
        monthlyReviewStatuses.first { $0.userId == userId && $0.month == month && $0.year == year }
    }
    
    func saveMonthlyReviewStatus(_ status: MonthlyReviewStatus) {
        if let index = monthlyReviewStatuses.firstIndex(where: { $0.userId == status.userId && $0.month == status.month && $0.year == status.year }) {
            monthlyReviewStatuses[index] = status
        } else {
            monthlyReviewStatuses.append(status)
        }
        saveToLocalStorage()
    }
    
    func completeMonthlyReview(for userId: UUID, month: Int, year: Int) {
        var status = getMonthlyReviewStatus(for: userId, month: month, year: year) ?? MonthlyReviewStatus(userId: userId, month: month, year: year)
        status.isCompleted = true
        status.completedAt = Date()
        saveMonthlyReviewStatus(status)
        
        // Remove related action items
        actionItems.removeAll { $0.type == .monthlyFinanceReview && $0.userId == userId }
        saveToLocalStorage()
    }
    
    func shouldShowMonthlyReviewReminder(for userId: UUID, month: Int, year: Int) -> Bool {
        // Check if review already completed
        if let status = getMonthlyReviewStatus(for: userId, month: month, year: year), status.isCompleted {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        let currentDay = calendar.component(.day, from: now)
        
        // If reviewing current month
        if month == currentMonth && year == currentYear {
            // Get last day of current month
            guard let lastDayDate = calendar.date(from: DateComponents(year: year, month: month + 1, day: 0)) else {
                return false
            }
            let lastDay = calendar.component(.day, from: lastDayDate)
            
            // Calculate days until end of month
            let daysUntilEnd = lastDay - currentDay
            
            // Show reminder ONLY on specific days: 7, 3, or 0 days before end
            return daysUntilEnd == 7 || daysUntilEnd == 3 || daysUntilEnd == 0
        }
        
        // If reviewing previous month (carryover if not completed)
        if (month == currentMonth - 1 && year == currentYear) ||
           (month == 12 && currentMonth == 1 && year == currentYear - 1) {
            // Show persistent reminder for previous month if not completed
            return true
        }
        
        return false
    }
    
    func reconcileAccountsForReview(userId: UUID, accountBalances: [UUID: Double]) {
        for (accountId, actualBalance) in accountBalances {
            guard let account = getAccount(by: accountId) else { continue }
            
            let difference = actualBalance - account.balance
            guard abs(difference) > 0.01 else { continue } // Skip tiny differences
            
            // Create reconciliation adjustment
            let expense = Expense(
                userId: userId,
                amount: abs(difference),
                date: Date(),
                description: "Monthly Review Reconciliation",
                categoryName: "Reconciliation",
                accountId: accountId,
                isSubscription: false
            )
            expenses.append(expense)
            
            // Update account balance to match actual
            if let index = accounts.firstIndex(where: { $0.id == accountId }) {
                accounts[index].balance = actualBalance
            }
        }
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
        saveData(scheduledTransfers, forKey: "scheduledTransfers")
        saveData(savingsBudgets, forKey: "savingsBudgets")
        saveData(salaryIncomes, forKey: "salaryIncomes")
        saveData(incomeTransactions, forKey: "incomeTransactions")
        saveData(actionItems, forKey: "actionItems")
        saveData(friendIOUs, forKey: "friendIOUs")
        saveData(monthlyReviewStatuses, forKey: "monthlyReviewStatuses")
        UserDefaults.standard.set(currencyCode, forKey: "currencyCode")
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
        scheduledTransfers = loadData(forKey: "scheduledTransfers") ?? []
        savingsBudgets = loadData(forKey: "savingsBudgets") ?? []
        salaryIncomes = loadData(forKey: "salaryIncomes") ?? []
        incomeTransactions = loadData(forKey: "incomeTransactions") ?? []
        actionItems = loadData(forKey: "actionItems") ?? []
        friendIOUs = loadData(forKey: "friendIOUs") ?? []
        monthlyReviewStatuses = loadData(forKey: "monthlyReviewStatuses") ?? []
        currencyCode = UserDefaults.standard.string(forKey: "currencyCode") ?? (Locale.current.currency?.identifier ?? "USD")
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

