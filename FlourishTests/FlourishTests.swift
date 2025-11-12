//
//  FinanceAppTests.swift
//  FinanceAppTests
//
//  Unit tests for FinanceApp
//

import XCTest
@testable import Flourish

class FlourishTests: XCTestCase {
    
    var dataService: DataService!
    var authService: AuthenticationService!
    var testUserId: UUID!
    
    override func setUp() {
        super.setUp()
        dataService = DataService.shared
        authService = AuthenticationService.shared
        testUserId = UUID()
    }
    
    override func tearDown() {
        // Clean up test data
        dataService.users.removeAll()
        dataService.accounts.removeAll()
        dataService.budgetCategories.removeAll()
        dataService.expenses.removeAll()
        dataService.subscriptions.removeAll()
        dataService.balancesOwed.removeAll()
        super.tearDown()
    }
    
    // MARK: - Authentication Tests
    
    func testUserRegistration() {
        let result = authService.register(email: "test@example.com", name: "Test User", password: "password123")
        
        switch result {
        case .success(let user):
            XCTAssertEqual(user.email, "test@example.com")
            XCTAssertEqual(user.name, "Test User")
            XCTAssertTrue(authService.isAuthenticated)
        case .failure:
            XCTFail("Registration should succeed")
        }
    }
    
    func testUserLogin() {
        // First register
        _ = authService.register(email: "test@example.com", name: "Test User", password: "password123")
        authService.logout()
        
        // Then login
        let result = authService.login(email: "test@example.com", password: "password123")
        
        switch result {
        case .success:
            XCTAssertTrue(authService.isAuthenticated)
        case .failure:
            XCTFail("Login should succeed")
        }
    }
    
    func testInvalidLogin() {
        let result = authService.login(email: "nonexistent@example.com", password: "password")
        
        switch result {
        case .success:
            XCTFail("Login should fail for nonexistent user")
        case .failure(let error):
            XCTAssertEqual(error, .userNotFound)
        }
    }
    
    // MARK: - Budget Category Tests
    
    func testCreateBudgetCategory() {
        let category = BudgetCategory(
            userId: testUserId,
            name: "Groceries",
            monthlyLimit: 500,
            month: 11,
            year: 2025
        )
        
        dataService.saveBudgetCategory(category)
        
        let categories = dataService.getBudgetCategories(for: testUserId, month: 11, year: 2025)
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories[0].name, "Groceries")
    }
    
    func testBudgetCategoryCalculations() {
        let category = BudgetCategory(
            userId: testUserId,
            name: "Dining",
            monthlyLimit: 300,
            month: 11,
            year: 2025,
            spent: 150
        )
        
        XCTAssertEqual(category.remaining, 150)
        XCTAssertEqual(category.percentUsed, 50)
    }
    
    func testCopyBudgetToNextMonth() {
        // Create categories for November
        let category1 = BudgetCategory(userId: testUserId, name: "Groceries", monthlyLimit: 500, month: 11, year: 2025)
        let category2 = BudgetCategory(userId: testUserId, name: "Dining", monthlyLimit: 300, month: 11, year: 2025)
        
        dataService.saveBudgetCategory(category1)
        dataService.saveBudgetCategory(category2)
        
        // Copy to December
        dataService.copyBudgetToNextMonth(userId: testUserId, fromMonth: 11, fromYear: 2025)
        
        let decemberCategories = dataService.getBudgetCategories(for: testUserId, month: 12, year: 2025)
        XCTAssertEqual(decemberCategories.count, 2)
        XCTAssertEqual(decemberCategories[0].spent, 0) // Spent should reset
    }
    
    // MARK: - Account Tests
    
    func testCreateAccount() {
        let account = Account(
            userId: testUserId,
            name: "Checking",
            type: .checking,
            balance: 1000
        )
        
        dataService.saveAccount(account)
        
        let accounts = dataService.getAccounts(for: testUserId)
        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0].balance, 1000)
    }
    
    func testUpdateAccountBalance() {
        let account = Account(userId: testUserId, name: "Checking", type: .checking, balance: 1000)
        dataService.saveAccount(account)
        
        // Deduct 50
        dataService.updateAccountBalance(account.id, by: -50)
        
        let updatedAccount = dataService.getAccount(by: account.id)
        XCTAssertEqual(updatedAccount?.balance, 950)
    }
    
    // MARK: - Expense Tests
    
    func testCreateExpense() {
        let account = Account(userId: testUserId, name: "Checking", type: .checking, balance: 1000)
        dataService.saveAccount(account)
        
        let category = BudgetCategory(userId: testUserId, name: "Groceries", monthlyLimit: 500, month: 11, year: 2025)
        dataService.saveBudgetCategory(category)
        
        let expense = Expense(
            userId: testUserId,
            amount: 50,
            date: Date(),
            description: "Grocery shopping",
            categoryName: "Groceries",
            accountId: account.id
        )
        
        dataService.saveExpense(expense)
        
        let expenses = dataService.getExpenses(for: testUserId)
        XCTAssertEqual(expenses.count, 1)
        
        // Check account balance updated
        let updatedAccount = dataService.getAccount(by: account.id)
        XCTAssertEqual(updatedAccount?.balance, 950)
    }
    
    func testExpenseSplitting() {
        let account = Account(userId: testUserId, name: "Checking", type: .checking, balance: 1000)
        dataService.saveAccount(account)
        
        let category = BudgetCategory(userId: testUserId, name: "Dining", monthlyLimit: 300, month: 11, year: 2025)
        dataService.saveBudgetCategory(category)
        
        // Create a split expense
        let participant1 = SplitParticipant(name: "You", amount: 30, isCurrentUser: true)
        let participant2 = SplitParticipant(name: "Friend", amount: 20, isCurrentUser: false)
        
        let expense = Expense(
            userId: testUserId,
            amount: 50,
            date: Date(),
            description: "Dinner",
            categoryName: "Dining",
            accountId: account.id,
            splitParticipants: [participant1, participant2]
        )
        
        dataService.saveExpense(expense)
        
        // Check user share
        XCTAssertEqual(expense.userShare, 30)
        XCTAssertEqual(expense.totalOwedByOthers, 20)
        
        // Check balance owed created
        let balances = dataService.getBalancesOwed(for: testUserId)
        XCTAssertEqual(balances.count, 1)
        XCTAssertEqual(balances[0].personName, "Friend")
        XCTAssertEqual(balances[0].amount, 20)
        
        // Check only user share deducted from account
        let updatedAccount = dataService.getAccount(by: account.id)
        XCTAssertEqual(updatedAccount?.balance, 970) // 1000 - 30
    }
    
    // MARK: - Subscription Tests
    
    func testCreateSubscription() {
        let account = Account(userId: testUserId, name: "Credit Card", type: .creditCard, balance: 0)
        dataService.saveAccount(account)
        
        let category = BudgetCategory(userId: testUserId, name: "Entertainment", monthlyLimit: 100, month: 11, year: 2025)
        dataService.saveBudgetCategory(category)
        
        let subscription = Subscription(
            userId: testUserId,
            name: "Netflix",
            amount: 15.99,
            categoryName: "Entertainment",
            accountId: account.id,
            nextDueDate: Date()
        )
        
        dataService.saveSubscription(subscription)
        
        let subscriptions = dataService.getSubscriptions(for: testUserId)
        XCTAssertEqual(subscriptions.count, 1)
    }
    
    func testSubscriptionProcessing() {
        let account = Account(userId: testUserId, name: "Credit Card", type: .creditCard, balance: 0)
        dataService.saveAccount(account)
        
        let category = BudgetCategory(userId: testUserId, name: "Entertainment", monthlyLimit: 100, month: 11, year: 2025)
        dataService.saveBudgetCategory(category)
        
        // Create subscription due today
        let subscription = Subscription(
            userId: testUserId,
            name: "Spotify",
            amount: 9.99,
            categoryName: "Entertainment",
            accountId: account.id,
            nextDueDate: Date() // Due today
        )
        
        dataService.saveSubscription(subscription)
        
        // Process subscriptions
        dataService.processSubscriptions(for: testUserId)
        
        // Check expense created
        let expenses = dataService.getExpenses(for: testUserId)
        XCTAssertEqual(expenses.count, 1)
        XCTAssertEqual(expenses[0].amount, 9.99)
        XCTAssertTrue(expenses[0].isSubscription)
    }
    
    // MARK: - Balance Owed Tests
    
    func testRecordRepayment() {
        // Create initial balance owed
        let balance = BalanceOwed(userId: testUserId, personName: "Friend", amount: 100)
        dataService.saveBalanceOwed(balance)
        
        // Record repayment
        let repayment = Repayment(userId: testUserId, personName: "Friend", amount: 50)
        dataService.recordRepayment(repayment)
        
        // Check balance updated
        let balances = dataService.getBalancesOwed(for: testUserId)
        XCTAssertEqual(balances.count, 1)
        XCTAssertEqual(balances[0].amount, 50)
    }
    
    func testFullRepayment() {
        // Create initial balance owed
        let balance = BalanceOwed(userId: testUserId, personName: "Friend", amount: 100)
        dataService.saveBalanceOwed(balance)
        
        // Record full repayment
        let repayment = Repayment(userId: testUserId, personName: "Friend", amount: 100)
        dataService.recordRepayment(repayment)
        
        // Check balance removed
        let balances = dataService.getBalancesOwed(for: testUserId)
        XCTAssertEqual(balances.count, 0)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteExpenseFlow() {
        // Setup: Create account and budget
        let account = Account(userId: testUserId, name: "Checking", type: .checking, balance: 1000)
        dataService.saveAccount(account)
        
        let category = BudgetCategory(userId: testUserId, name: "Groceries", monthlyLimit: 500, month: 11, year: 2025)
        dataService.saveBudgetCategory(category)
        
        // Create expense
        let expense = Expense(
            userId: testUserId,
            amount: 75,
            date: Date(),
            description: "Weekly groceries",
            categoryName: "Groceries",
            accountId: account.id
        )
        
        dataService.saveExpense(expense)
        
        // Verify account balance
        let updatedAccount = dataService.getAccount(by: account.id)
        XCTAssertEqual(updatedAccount?.balance, 925)
        
        // Verify budget updated
        let updatedCategories = dataService.getBudgetCategories(for: testUserId, month: 11, year: 2025)
        XCTAssertEqual(updatedCategories[0].spent, 75)
        XCTAssertEqual(updatedCategories[0].remaining, 425)
    }
}
