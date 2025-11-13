# Testing Checklist - Pending Transfer Approval

## Setup
- [ ] Ensure you have at least two accounts created (e.g., Checking and Savings)
- [ ] Ensure user is logged in

## Test 1: One-Time Scheduled Transfer
1. [ ] Navigate to Transfers section
2. [ ] Create a new scheduled transfer:
   - From: Checking
   - To: Savings  
   - Amount: $100
   - Scheduled Date: Today's date
   - Leave recurrence blank (one-time)
3. [ ] Go to Dashboard
4. [ ] Verify action count badge shows "1" on bell icon
5. [ ] Verify orange banner appears: "1 Action Needed"
6. [ ] Tap bell icon or banner to open Action Center
7. [ ] Verify you see "Pending Transfer Approval" action item with:
   - Clock icon in blue
   - Message: "Scheduled transfer of $100.00 from Checking → Savings requires approval to complete."
   - Medium priority (orange dot)
8. [ ] Tap the action item
9. [ ] Verify `ConfirmScheduledTransferView` sheet opens showing:
   - From: Checking
   - To: Savings
   - Amount: $100.00
   - Transfer Date picker (defaulted to today)
   - Notes field (optional)
10. [ ] Tap "Mark Transfer as Completed"
11. [ ] Verify sheet dismisses
12. [ ] Verify action item is removed from Action Center
13. [ ] Verify "All Caught Up!" message appears
14. [ ] Go to Accounts and verify:
    - Checking balance decreased by $100
    - Savings balance increased by $100
15. [ ] Go to Transfers and verify completed transfer appears in history

## Test 2: Recurring Scheduled Transfer
1. [ ] Create a new scheduled transfer:
   - From: Savings
   - To: Checking
   - Amount: $50
   - Scheduled Date: Today's date
   - Recurrence: Every 7 days
2. [ ] Verify action item appears immediately (since it's due today)
3. [ ] Complete the transfer via Action Center
4. [ ] Verify balances update:
   - Savings decreased by $50
   - Checking increased by $50
5. [ ] Verify the scheduled transfer is NOT marked as completed (it's recurring)
6. [ ] Note: In 7 days, the action item should appear again

## Test 3: Future Scheduled Transfer
1. [ ] Create a new scheduled transfer:
   - From: Checking
   - To: Savings
   - Amount: $25
   - Scheduled Date: Tomorrow's date
2. [ ] Verify NO action item appears today
3. [ ] Go to Dashboard
4. [ ] Verify no action badge or banner
5. [ ] Note: Check again tomorrow to verify action item appears

## Test 4: Dismiss Action Item
1. [ ] Create a scheduled transfer for today (any accounts, any amount)
2. [ ] Open Action Center
3. [ ] Tap the X button on the action item
4. [ ] Verify action item is dismissed and removed
5. [ ] Note: Transfer is NOT executed, balances unchanged
6. [ ] Tap refresh button (circular arrow) in Action Center
7. [ ] Verify action item reappears (since transfer is still pending)

## Test 5: Multiple Pending Transfers
1. [ ] Create 3 scheduled transfers all for today
2. [ ] Verify action count shows "3" (or more if other actions exist)
3. [ ] Verify banner shows "3 Actions Needed"
4. [ ] Open Action Center
5. [ ] Verify all 3 pending transfers are listed
6. [ ] Complete them one by one
7. [ ] Verify each completion:
   - Removes that action item
   - Updates balances correctly
   - Decreases action count

## Test 6: Recurring Transfer - Weekly Verification
1. [ ] Create recurring transfer for today with 7-day interval
2. [ ] Complete it today
3. [ ] Change device date to 7 days from now
4. [ ] Launch app
5. [ ] Verify action item appears again
6. [ ] Complete it
7. [ ] Change date to 14 days from original
8. [ ] Verify action item appears again

## Dashboard Visual Tests
- [ ] Verify bell icon has red dot badge when actions exist
- [ ] Verify banner is orange with proper formatting
- [ ] Verify banner disappears when no actions
- [ ] Verify bell icon has no badge when no actions
- [ ] Verify tapping banner opens Action Center
- [ ] Verify tapping bell icon opens Action Center

## Error Cases
- [ ] Try to complete transfer when source account has insufficient funds
- [ ] Verify appropriate error handling (if implemented)
- [ ] Try to complete transfer for deleted account
- [ ] Verify appropriate error handling (if implemented)

## Switch Statement Compilation
- [ ] Build the project
- [ ] Verify no "Switch must be exhaustive" errors
- [ ] Verify no compiler warnings related to switch statements

## Notes
- All tests should pass without crashes
- Balances should always be accurate after transfers
- Action items should only appear for transfers that are due
- Completed one-time transfers should be marked as completed
- Recurring transfers should reschedule after completion
