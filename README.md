# Flourish Finance App

<p align="center">
   <img src="Assets.xcassets/AppIcon.appiconset/1024.png" alt="Flourish Logo" width="128" height="128" />
</p>

A comprehensive personal finance management application built with SwiftUI for iOS, designed to help users track expenses, manage budgets, handle split payments, and maintain financial health with intuitive visualizations and smart insights.

---

## 📋 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Getting Started](#-getting-started)
- [Navigation](#-navigation)
- [Project Structure](#-project-structure)
- [Core Components](#-core-components)
- [Data Models](#-data-models)
- [Requirements](#-requirements)

---

## ✨ Features

### 💰 Expense Tracking
- **Add Expenses** with categories, accounts, and dates
- **Split Expenses** with friends and family
- **Month-by-month view** with navigation (defaults to current month)
- **Category filtering** to view specific expense types
- **Swipe-to-delete** functionality
- Track split participants and automatically calculate balances

### 📊 Budget Management
- **Set monthly budgets** by category
- **Real-time spending tracking** with visual progress indicators
- **Budget alerts** for overspending
- **Custom categories** alongside default categories
- Month/year specific budget tracking

### 🏦 Account Management
- **Multiple account types**: Checking, Savings, Credit Card
- **Track balances** across all accounts
- **View transaction history** per account
- **Balance adjustments** with automatic expense reconciliation
- **Account summaries** on dashboard

### 🔄 Balance Tracking (Splitwise-style)
- **Track money owed** to you and money you owe others
- **Settle up** with full or partial payments
- **Quick settlement alerts** for easy confirmation
- **Person picker** when splitting expenses (choose from existing or add new)
- Automatic balance calculations from split expenses

### 📅 Subscriptions
- **Manage recurring subscriptions**
- **Track subscription costs** and due dates
- **Automatic renewal tracking**
- View all subscriptions in one place

### 💸 Transfers
- **Transfer between accounts**
- **Scheduled transfers** with recurring options
- **Transfer approval flow** for verification
- Track transfer history

### 🎯 Savings Goals
- **Set savings targets** with deadlines
- **Track progress** toward goals
- **Visual progress indicators**
- Monthly contribution tracking

### 📈 Dashboard & Reports
- **Financial overview** at a glance
- **Monthly reports** with insights
- **Action center** for important financial tasks
- **Visual charts** for spending analysis

### 🎨 Customization
- **Light/Dark mode** support
- **Senior mode** for enhanced accessibility
- **Customizable appearance** settings
- **Currency formatting** based on locale

---

## 📥 Installation

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- iOS 17.0+ deployment target

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flourish-finance-app.git
   cd flourish-finance-app
   ```

2. **Open in Xcode**
   ```bash
   open Flourish.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `⌘ + R` to build and run
   - The app will launch with the authentication screen

---

## 🚀 Getting Started

### First Launch

1. **Create an Account**
   - Enter your name, email, and password
   - Tap "Sign Up" to create your account

2. **Add Your First Account**
   - Navigate to the Accounts tab
   - Tap the "+" button
   - Enter account details (name, type, initial balance)
   - Save the account

3. **Set Up Budgets**
   - Go to the Budget tab
   - Tap "Add Budget"
   - Select a category and set a monthly limit
   - Save your budget

4. **Record an Expense**
   - Navigate to the Expenses tab
   - Tap the "+" button
   - Fill in amount, description, category, and payment account
   - Optionally split with others
   - Save the expense

---

## 🧭 Navigation

### Tab Bar Navigation

The app uses a tab-based navigation structure with five main tabs:

| Tab | Icon | Description |
|-----|------|-------------|
| **Dashboard** | 🏠 | Overview of your financial status, recent transactions, and quick actions |
| **Budget** | 📊 | Manage monthly budgets, view spending by category, track progress |
| **Expenses** | 💵 | Add, view, and manage expenses with filtering and splitting options |
| **Balances** | 👥 | Track money owed/owing, settle up with friends, manage IOUs |
| **Accounts** | 💳 | View and manage bank accounts, credit cards, and account balances |

### Hamburger Menu (☰)

Access additional features from any screen via the hamburger menu:

- **Manage Accounts** - Full account management
- **Manage Subscriptions** - Track recurring payments
- **Transfers** - Move money between accounts
- **Savings Goals** - Set and track savings targets
- **Monthly Reports** - Detailed financial reports
- **Settings** - Appearance, accessibility, and preferences
- **Logout** - Sign out of your account

---

## 📁 Project Structure

```
Flourish/
├── App Entry
│   ├── FlourishApp.swift              # App entry point, environment setup
│   └── ContentView.swift              # Root view with auth routing
│
├── Authentication
│   └── AuthenticationView.swift       # Login/signup screens
│
├── Main Views
│   ├── DashboardView.swift           # Financial overview dashboard
│   ├── BudgetView.swift              # Budget management interface
│   ├── ExpensesView.swift            # Expense tracking and management
│   ├── BalancesView.swift            # Friend balance tracking (Splitwise-style)
│   └── AccountsListView.swift        # Account management
│
├── Supporting Views
│   ├── ActionCenterView.swift        # Important financial alerts/tasks
│   ├── MonthlyReviewView.swift       # Monthly financial review
│   ├── TransferListView.swift        # Account transfer management
│   ├── MoreView.swift                # Additional features and settings
│   └── FriendIOUView.swift          # IOU tracking (legacy)
│
├── Data Layer
│   ├── DataService.swift             # Central data management service
│   ├── Models/
│   │   ├── User.swift                # User account model
│   │   ├── Account.swift             # Bank account model
│   │   ├── Expense.swift             # Expense transaction model
│   │   ├── BudgetCategory.swift      # Budget category model
│   │   ├── BalanceOwed.swift         # Balance tracking model
│   │   ├── Subscription.swift        # Recurring subscription model
│   │   └── Transfer.swift            # Account transfer model
│
├── Utilities & Modifiers
│   ├── SeniorModeModifier.swift     # Accessibility enhancements
│   └── Extensions/
│       ├── Double+Currency.swift     # Currency formatting
│       └── Date+Extensions.swift     # Date helpers
│
└── Resources
    ├── Assets.xcassets               # App icons, images, colors
    └── Info.plist                    # App configuration
```

---

## 🔧 Core Components

### FlourishApp.swift
**Purpose:** App entry point and environment configuration
- Initializes `DataService` for data persistence
- Sets up `AppSettings` for user preferences
- Configures color scheme (light/dark mode)
- Injects environment objects throughout app

### ContentView.swift
**Purpose:** Root navigation and authentication routing
- Checks authentication status
- Routes to `AuthenticationView` or `MainTabView`
- Contains `MainTabView` with five tabs
- Provides hamburger menu with additional features
- Manages profile editing and logout functionality

### AuthenticationView.swift
**Purpose:** User authentication interface
- Login screen with email/password
- Signup flow for new users
- Form validation
- Password confirmation
- Connects to `AuthenticationService`

### DashboardView.swift
**Purpose:** Financial overview and quick insights
- Display total balance across all accounts
- Recent transactions list
- Quick action buttons
- Monthly spending summary
- Budget progress indicators
- Action items and alerts

### BudgetView.swift
**Purpose:** Budget creation and monitoring
- Add/edit monthly budgets by category
- Visual spending progress (progress bars)
- Category-wise breakdown
- Overspending alerts
- Month/year navigation
- Spent vs. limit comparison

### ExpensesView.swift
**Purpose:** Expense tracking and management
- Add new expenses with all details
- Split expenses with friends/family
- Month-by-month expense view (defaults to current month)
- Category filtering
- Edit/delete expenses
- Expense summary with total calculations
- Person picker for splits (existing or new)

### BalancesView.swift
**Purpose:** Track IOUs and split payment balances
- View all outstanding balances (owed to you / you owe)
- Color-coded balances (green = owed to you, red = you owe)
- Settle up with full or partial amounts
- Quick settlement alerts
- Automatic balance updates from split expenses
- Person management for recurring splits

### AccountsListView.swift
**Purpose:** Bank account management
- Add checking, savings, or credit card accounts
- View current balances
- Transaction history per account
- Balance adjustments
- Account editing and deletion
- Account type indicators

### TransferListView.swift
**Purpose:** Inter-account transfers
- Transfer money between accounts
- Schedule recurring transfers
- View transfer history
- Approval workflow for large transfers
- Automatic balance updates

### MonthlyReviewView.swift
**Purpose:** Comprehensive monthly financial report
- Income vs. expenses comparison
- Category-wise spending breakdown
- Budget performance review
- Savings rate calculation
- Month-over-month trends
- Actionable insights

### ActionCenterView.swift
**Purpose:** Financial alerts and recommended actions
- Overspending notifications
- Upcoming bill reminders
- Low balance alerts
- Savings goal progress
- Transfer approvals needed
- Friend balance reminders

---

## 📊 Data Models

### User
- `id`: UUID
- `name`: String
- `email`: String
- `password`: String (hashed)

### Account
- `id`: UUID
- `userId`: UUID
- `name`: String
- `type`: AccountType (checking/savings/credit)
- `balance`: Double

### Expense
- `id`: UUID
- `userId`: UUID
- `amount`: Double
- `date`: Date
- `description`: String
- `categoryName`: String
- `accountId`: UUID
- `splitParticipants`: [SplitParticipant]
- `isSubscription`: Bool

### BudgetCategory
- `id`: UUID
- `userId`: UUID
- `name`: String
- `monthlyLimit`: Double
- `spent`: Double
- `month`: Int
- `year`: Int

### BalanceOwed
- `id`: UUID
- `userId`: UUID
- `personName`: String
- `amount`: Double
- `lastUpdated`: Date
- `isOwedToMe`: Bool (true = they owe you, false = you owe them)

### Subscription
- `id`: UUID
- `userId`: UUID
- `name`: String
- `amount`: Double
- `frequency`: SubscriptionFrequency
- `nextDueDate`: Date

### Transfer
- `id`: UUID
- `userId`: UUID
- `fromAccountId`: UUID
- `toAccountId`: UUID
- `amount`: Double
- `date`: Date
- `status`: TransferStatus

---

## 🎯 Key Features Explained

### Split Expenses
When adding an expense, you can split it with others:
1. Enter the total expense amount
2. Tap "Add Person" in the Split With section
3. Choose from existing people (from balances) or add a new person
4. Enter the amount each person owes
5. Your share is automatically calculated (total - others' shares)
6. Balances are automatically created/updated

### Balance Settlements
Two ways to settle up:
- **Full Settlement:** Marks entire balance as paid and removes it
- **Partial Settlement:** Enter specific amount, balance is reduced

### Budget Tracking
- Set budgets per category per month
- Spending is automatically tracked from expenses
- Visual indicators show progress (green = under budget, red = over)
- Action items alert you to overspending

### Month Navigation
In Expenses view:
- Defaults to current month on app launch
- Use ← → arrows to navigate months
- Tap month name to toggle between current month and "All Time"
- Chevrons disabled when viewing "All Time"

---

## ✅ Requirements

- **Platform:** iOS 17.0+
- **Language:** Swift 5.9+
- **Framework:** SwiftUI
- **Architecture:** MVVM with ObservableObject
- **Data Persistence:** Local storage (UserDefaults)
- **Authentication:** Custom implementation

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👤 Author

Developed as a comprehensive personal finance management solution.

---

## 🙏 Acknowledgments

- SwiftUI framework by Apple
- Inspired by modern finance apps like Splitwise, Mint, and YNAB
- Community feedback and feature requests

---

**Happy Budgeting! 💰✨**
