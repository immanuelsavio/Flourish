# Monthly Finance Review Feature

## Overview
The Monthly Finance Review feature helps users verify their app finances against actual bank statements at the end of each month. It integrates with the Action Center to provide timely reminders and guides users through a reconciliation workflow.

---

## 🎯 Goals

1. **Help user verify monthly finances** before closing the month
2. **Prompt user multiple times** near end of month (7 days, 3 days, last day)
3. **Allow easy settlement** of discrepancies
4. **Optional budget copying** to next month after review

---

## 🔔 Reminder Timings

### Triggers
- **7 days before end of month**: First reminder appears
- **3 days before end of month**: Reminder persists
- **Last day of month**: Final reminder
- **Carryover**: If not completed by 1st of next month, shows persistent "Overdue" reminder

### Action Center Integration
- **Card Type**: `monthlyFinanceReview`
- **Priority**: High (orange/red dot)
- **Card Text**: "Review your finances for {MONTH_YEAR}"
- **Icon**: Calendar with checkmark (blue)
- **Persistence**: Yes, until review marked completed

---

## 📱 User Flow

### 1. Reminder Appears in Action Center

```
┌─────────────────────────────────────┐
│  Action Center          Close    ↻  │
├─────────────────────────────────────┤
│  ● 📅  Monthly Finance Review       │
│        Review your finances for     │
│        November 2025. Verify that   │
│        your app balances match your │
│        bank statements.             │
│        Nov 24, 2025, 9:00 AM     ×  │
└─────────────────────────────────────┘
```

### 2. User Taps Action Item

Opens **MonthlyReviewView** with comprehensive summary:

```
┌─────────────────────────────────────┐
│  Review                      Close  │
├─────────────────────────────────────┤
│                                     │
│  📅 Monthly Finance Review          │
│     November 2025                   │
│                                     │
│  Account Balances                   │
│  ├─ Checking    $2,450.00          │
│  ├─ Savings     $5,000.00          │
│  └─ Credit Card -$350.00           │
│  Total Balance: $7,100.00           │
│                                     │
│  Income This Month                  │
│  └─ Total Income: $4,500.00        │
│                                     │
│  Expenses This Month                │
│  └─ Total Amount: $2,850.00        │
│                                     │
│  Budget Performance                 │
│  ├─ Total Budget: $3,000.00        │
│  ├─ Total Spent:  $2,850.00        │
│  └─ Remaining:    $150.00          │
│                                     │
│  Do your app numbers match          │
│  your bank statement?               │
│  [Yes, they match] [No, they don't]│
│                                     │
│  ┌─────────────────────────────┐   │
│  │   ✓ Complete Review         │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### 3A. If Numbers Match

**User selects "Yes, they match" → Taps "Complete Review"**

1. **Confirmation alert**: "Are you sure everything is correct for November 2025?"
2. **User confirms**
3. **Review marked completed**
4. **Budget copy prompt**: "Do you want to copy this month's budget to next month?"
   - Yes → Copies budget categories with zero spent
   - No → Does nothing
5. **Action item removed** from Action Center
6. **Sheet dismisses**

### 3B. If Numbers Don't Match

**User selects "No, they don't match" → Taps "Adjust Balances"**

Opens adjustment sheet:

```
┌─────────────────────────────────────┐
│  Adjust Balances    Cancel    Save │
├─────────────────────────────────────┤
│  Enter Actual Balances              │
│  Enter the actual balance from your │
│  bank statement for each account.   │
│                                     │
│  Checking                           │
│  Current: $2,450.00                 │
│  Actual Balance: [2,475.00]         │
│  Adjustment: +$25.00                │
│                                     │
│  Savings                            │
│  Current: $5,000.00                 │
│  Actual Balance: [5,000.00]         │
│                                     │
│  Credit Card                        │
│  Current: -$350.00                  │
│  Actual Balance: [-360.00]          │
│  Adjustment: -$10.00                │
│                                     │
│  [Save & Complete]                  │
└─────────────────────────────────────┘
```

**What happens on "Save & Complete":**
1. **Reconciliation entries created** for each difference
   - Category: "Reconciliation"
   - Description: "Monthly Review Reconciliation"
   - Updates account balances to match entered amounts
2. **Review marked completed**
3. **Budget copy prompt** appears
4. **Action item removed**
5. **Sheets dismiss**

---

## 💾 Data Model

### New Model: MonthlyReviewStatus

```swift
struct MonthlyReviewStatus: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var month: Int          // 1-12
    var year: Int           // 2025
    var isCompleted: Bool
    var completedAt: Date?
    
    var monthYearString: String  // "November 2025"
    var isCurrentMonth: Bool
}
```

**Storage**: Stored in `DataService.monthlyReviewStatuses` array, persisted to UserDefaults

---

## 🔧 Implementation Details

### DataService Functions

#### 1. `getMonthlyReviewStatus(for:month:year:)`
Returns review status for specific month/year, or nil if not exists

#### 2. `saveMonthlyReviewStatus(_:)`
Saves or updates review status

#### 3. `completeMonthlyReview(for:month:year:)`
Marks review as completed, removes action items

#### 4. `shouldShowMonthlyReviewReminder(for:month:year:)`
Logic for determining if reminder should appear:
- Returns false if already completed
- For current month: Shows if within 7 days of month end
- For previous month: Always shows (carryover)

#### 5. `reconcileAccountsForReview(userId:accountBalances:)`
Creates adjustment entries for balance differences:
```swift
// For each account with difference > $0.01:
// - Creates Expense with category "Reconciliation"
// - Updates account.balance to match actual
```

### Action Item Generation

Added to `generateActionItems(for:)`:

```swift
// Check current month review
if shouldShowMonthlyReviewReminder(for: userId, month: currentMonth, year: currentYear) {
    createActionItem(
        type: .monthlyFinanceReview,
        title: "Monthly Finance Review",
        message: "Review your finances for {monthYear}...",
        priority: .high
    )
}

// Check previous month (carryover)
if shouldShowMonthlyReviewReminder(for: userId, month: previousMonth, year: previousYear) {
    createActionItem(
        type: .monthlyFinanceReview,
        title: "⚠️ Overdue: Monthly Finance Review",
        message: "You haven't completed your review for {monthYear}...",
        priority: .high
    )
}
```

---

## 📊 MonthlyReviewView Components

### Summary Section
- Lists all accounts with current balances
- Shows total balance
- Color-coded (green for positive, red for negative/credit)

### Income Section
- Shows all income transactions for the month
- Displays total income
- Empty state if no income

### Expense Section
- Shows transaction count and total expenses
- Color-coded in red

### Budget Section
- Shows total budget vs. spent
- Calculates remaining amount
- Color-coded (green if under budget, red if over)

### Action Buttons
- Segmented picker: "Yes, they match" / "No, they don't match"
- Green "Complete Review" button if match
- Orange "Adjust Balances" button if don't match

### AdjustBalancesView (Sheet)
- Lists all accounts
- Shows current balance from app
- Text fields for entering actual balances
- Calculates and displays adjustment amount
- "Save & Complete" button

---

## 🔄 Post-Review Flow

After successful review completion:

1. **Budget Copy Prompt**
   ```
   ┌────────────────────────────┐
   │  Copy Budget?              │
   ├────────────────────────────┤
   │  Do you want to copy this  │
   │  month's budget to next    │
   │  month?                    │
   │                            │
   │  [No]         [Yes]        │
   └────────────────────────────┘
   ```

2. **On "Yes"**: Calls existing `copyBudgetToNextMonth()` function
   - Copies all budget categories
   - Resets spent amounts to 0
   - Increments month/year

3. **On "No"**: Does nothing, dismisses all sheets

---

## 🎨 UI/UX Details

### Colors
- **Action item dot**: Orange (high priority)
- **Icon**: Blue calendar with checkmark
- **Complete button**: Green
- **Adjust button**: Orange
- **Positive balances**: Green
- **Negative balances/expenses**: Red
- **Section backgrounds**: Light opacity tints

### Accessibility
- All buttons have SF Symbols icons
- Clear text labels
- Color + text indicators (not just color)
- Proper contrast ratios

---

## 🧪 Testing Scenarios

### Test 1: First Reminder (7 Days Before End)
1. Set device date to Nov 24, 2025 (7 days before end)
2. Launch app, go to Dashboard
3. ✅ Verify action badge appears
4. Open Action Center
5. ✅ Verify "Monthly Finance Review" card appears
6. ✅ Verify message says "November 2025"

### Test 2: Complete Review (Numbers Match)
1. Tap monthly review action item
2. Review summary sections
3. Select "Yes, they match"
4. Tap "Complete Review"
5. Confirm in alert
6. ✅ Verify budget copy prompt appears
7. Select "Yes"
8. ✅ Verify next month has budget categories
9. ✅ Verify action item removed
10. ✅ Verify review status saved

### Test 3: Adjust Balances (Numbers Don't Match)
1. Note current account balances
2. Tap monthly review action item
3. Select "No, they don't match"
4. Tap "Adjust Balances"
5. Enter different actual balances
6. ✅ Verify adjustment amounts calculated
7. Tap "Save & Complete"
8. ✅ Verify reconciliation expenses created
9. ✅ Verify account balances updated to actual
10. ✅ Verify budget copy prompt appears

### Test 4: Carryover to Next Month
1. Complete November 2025 without completing review
2. Set date to Dec 1, 2025
3. Launch app
4. ✅ Verify "⚠️ Overdue" action item appears
5. ✅ Verify message references November 2025
6. Complete the overdue review
7. ✅ Verify action item removed

### Test 5: Multiple Months
1. Complete review for November
2. Set date to December 24
3. ✅ Verify new action item for December appears
4. ✅ Verify November is not shown (already completed)

### Test 6: Dismiss vs Complete
1. Open monthly review action item
2. Tap "Close" (cancel)
3. ✅ Verify action item still appears
4. Tap X to dismiss action item
5. ✅ Verify temporarily removed
6. Tap refresh
7. ✅ Verify reappears (not completed)

---

## ⚠️ Important Notes

### 1. Reminder Timing Logic
- Uses **start of day** comparison to determine if within trigger window
- Calculates last day of month dynamically (handles 28/29/30/31 days)
- Previous month calculation handles year rollover (Dec → Jan)

### 2. Reconciliation Behavior
- Only creates adjustments for differences > $0.01 (ignores rounding errors)
- Creates "Reconciliation" category expenses (not counted in budget)
- Updates actual account balance immediately
- Reconciliation entries are permanent records (audit trail)

### 3. Budget Copying
- Optional, user must confirm
- Uses existing `copyBudgetToNextMonth()` function
- Only offered after successful review completion
- Handles month/year rollover automatically

### 4. Action Item Persistence
- Dismissed items reappear on refresh (until completed)
- Multiple action items can exist (current + overdue previous month)
- Removed only when review marked completed
- Uses `relatedEntityId` to link to `MonthlyReviewStatus`

### 5. Data Integrity
- Review status persists across app restarts
- Can't accidentally re-review completed month
- Each month tracked independently
- No automatic completion (requires user action)

---

## 🔗 Integration Points

### Existing Features Used
1. **Action Center** - Displays reminders
2. **DataService** - Stores review statuses
3. **Account reconciliation** - Reuses `reconcileAccount` logic
4. **Budget copying** - Uses `copyBudgetToNextMonth()`
5. **Expense system** - Creates reconciliation entries

### New Files Created
1. `MonthlyReviewStatus.swift` - Data model
2. `MonthlyReviewView.swift` - Main review UI
3. `AdjustBalancesView.swift` - Adjustment sheet (in same file)

### Modified Files
1. `ActionItem.swift` - Added `.monthlyFinanceReview` case
2. `DataService.swift` - Added review operations
3. `ActionCenterView.swift` - Added handling for review action items

---

## 📝 Summary

**What it does:**
- Reminds users to review finances 7/3/1 days before month end
- Shows comprehensive month summary
- Allows easy balance reconciliation
- Offers budget copying after completion
- Persists until completed (even into next month)

**Benefits:**
- Ensures app accuracy matches real bank accounts
- Prevents month-to-month drift in balances
- Provides audit trail via reconciliation entries
- Streamlines budget planning with copy feature
- Reduces financial stress through regular check-ins

**User Experience:**
- Non-intrusive (only shows when needed)
- Clear, step-by-step workflow
- Optional adjustments (works even if perfect match)
- Smart timing (near month end)
- Persistent reminders (won't let you forget)
