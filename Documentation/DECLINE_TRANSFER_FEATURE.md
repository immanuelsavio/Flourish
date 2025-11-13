# Decline Transfer Feature

## Overview
Added a "Decline Transfer" button to the transfer confirmation sheet, allowing users to cancel scheduled transfers they no longer want to execute.

---

## 🎨 UI Changes

### Updated Confirmation Sheet

```
┌─────────────────────────────────────┐
│  Confirm Transfer      Cancel       │
├─────────────────────────────────────┤
│  Transfer Details                   │
│  From:      Checking                │
│  To:        Savings                 │
│  Amount:    $100.00                 │
│  Recurrence: Every 7 days           │ ← Shows if recurring
│                                     │
│  Confirmation                       │
│  Transfer Date: [Nov 12, 2025]      │
│  Notes (optional): [         ]      │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ Mark Transfer as Completed  │   │ ← Blue button
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    Decline Transfer         │   │ ← NEW: Red button
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## 🔄 Behavior

### For One-Time Transfers

**When user taps "Decline Transfer":**

1. **Alert appears:**
   ```
   ┌──────────────────────────────┐
   │  Decline Transfer?           │
   ├──────────────────────────────┤
   │  This will permanently cancel│
   │  this scheduled transfer.    │
   │  This action cannot be undone│
   │                              │
   │  [Cancel]  [Decline] ⚠️      │
   └──────────────────────────────┘
   ```

2. **If user confirms "Decline":**
   - ✅ Scheduled transfer is marked as completed (soft delete)
   - ✅ Action item is removed from Action Center
   - ✅ Transfer will NOT appear in scheduled list
   - ✅ No balance changes occur
   - ✅ Sheet dismisses
   - ✅ Transfer permanently canceled

---

### For Recurring Transfers

**When user taps "Decline Transfer":**

1. **Alert appears:**
   ```
   ┌──────────────────────────────┐
   │  Decline Transfer?           │
   ├──────────────────────────────┤
   │  This is a recurring         │
   │  transfer. Declining will    │
   │  cancel this occurrence only.│
   │  The next scheduled transfer │
   │  will still appear.          │
   │                              │
   │  [Cancel]  [Decline] ⚠️      │
   └──────────────────────────────┘
   ```

2. **If user confirms "Decline":**
   - ✅ Current occurrence is skipped (no transfer executed)
   - ✅ Action item is removed from Action Center
   - ✅ Next scheduled date is calculated (e.g., +7 days)
   - ✅ Transfer remains active for next occurrence
   - ✅ No balance changes occur
   - ✅ Sheet dismisses

**Example:**
```
Weekly recurring transfer scheduled for Nov 12
User declines Nov 12 occurrence
→ Transfer is skipped
→ Next action item will appear on Nov 19
→ User can approve or decline Nov 19 occurrence independently
```

---

## 💻 Implementation Details

### ActionCenterView.swift Changes

**Added:**
- `@State private var showDeclineAlert = false` - Controls alert presentation
- Recurrence info display in Transfer Details section
- "Decline Transfer" button (red, below approve button)
- Alert with different messages for one-time vs recurring transfers
- `declineTransfer()` method

```swift
private func declineTransfer() {
    dataService.declineScheduledTransfer(scheduled)
    dismiss()
}
```

---

### DataService.swift Changes

**Added new method:**
```swift
func declineScheduledTransfer(_ scheduled: ScheduledTransfer) {
    if let interval = scheduled.recurrenceDays, interval > 0 {
        // Recurring: Skip this occurrence, schedule next
        if let idx = scheduledTransfers.firstIndex(where: { $0.id == scheduled.id }) {
            scheduledTransfers[idx].scheduledDate = Calendar.current.date(
                byAdding: .day, 
                value: interval, 
                to: scheduled.scheduledDate
            ) ?? scheduled.scheduledDate
            saveToLocalStorage()
        }
    } else {
        // One-time: Mark as completed (cancel permanently)
        markScheduledTransferCompleted(scheduled.id, completedDate: Date())
    }
    
    // Remove action item
    actionItems.removeAll { 
        $0.type == .pendingTransfer && 
        $0.relatedEntityId == scheduled.id 
    }
    saveToLocalStorage()
}
```

---

## 🎯 Use Cases

### Use Case 1: Changed Mind About One-Time Transfer
```
Scenario: User scheduled $500 transfer from Checking → Savings for today
          but realized they need the money for bills

Steps:
1. Action Center shows pending transfer
2. User taps action item
3. User taps "Decline Transfer"
4. Confirms in alert
5. Transfer is canceled
6. No balance changes
7. Transfer disappears from scheduled list
```

### Use Case 2: Skip One Recurring Transfer
```
Scenario: User has weekly $100 transfer but needs to skip this week

Steps:
1. Action Center shows this week's transfer (Nov 12)
2. User taps action item
3. User taps "Decline Transfer"
4. Alert explains "next scheduled transfer will still appear"
5. User confirms
6. Nov 12 transfer is skipped (no execution)
7. Next week (Nov 19) transfer will still appear
```

### Use Case 3: Cancel Recurring Transfer Permanently
```
Scenario: User wants to stop all future recurring transfers

Steps:
1. Go to More → Account Transfers
2. Switch to "Scheduled" tab
3. Find the recurring transfer
4. Swipe left → Delete
5. Transfer is marked completed (canceled)
6. No future occurrences will appear
```

---

## 🔍 Comparison: Cancel vs Decline vs Delete

| Action | Location | One-Time Effect | Recurring Effect |
|--------|----------|----------------|------------------|
| **Cancel** (top left) | Confirmation sheet | Closes sheet, no changes | Closes sheet, no changes |
| **Decline** (red button) | Confirmation sheet | Cancels permanently | Skips current, keeps next |
| **Delete** (swipe) | Transfers list | Removes from list | Cancels all future |

---

## ⚠️ Important Notes

1. **Decline vs Cancel Button:**
   - "Cancel" button (top left) = Close sheet without making any changes
   - "Decline Transfer" button (red) = Take action to skip/cancel transfer

2. **No Undo:**
   - Declining a one-time transfer permanently cancels it
   - Cannot be recovered
   - User would need to create a new scheduled transfer

3. **Recurring Safety:**
   - Declining a recurring transfer only skips current occurrence
   - Protects user from accidentally canceling all future transfers
   - To permanently stop recurring transfers, use swipe-to-delete

4. **Balance Safety:**
   - Declining never changes account balances
   - Only approving ("Mark Transfer as Completed") updates balances

5. **Action Item Removal:**
   - Both approve and decline remove the action item
   - Difference: approve executes transfer, decline does not

---

## 🧪 Testing

### Test 1: Decline One-Time Transfer
1. Create transfer for today (one-time)
2. Action item appears
3. Tap action item
4. Tap "Decline Transfer"
5. ✅ Verify alert mentions "permanently cancel"
6. Confirm decline
7. ✅ Verify action item removed
8. ✅ Verify transfer not in Scheduled tab
9. ✅ Verify balances unchanged

### Test 2: Decline Recurring Transfer
1. Create transfer for today (recurring, every 7 days)
2. Action item appears
3. Tap action item
4. Tap "Decline Transfer"
5. ✅ Verify alert mentions "cancel this occurrence only"
6. Confirm decline
7. ✅ Verify action item removed
8. ✅ Verify transfer still in Scheduled tab
9. ✅ Verify scheduled date changed to +7 days
10. ✅ Verify balances unchanged

### Test 3: Cancel vs Decline
1. Create transfer for today
2. Tap action item
3. Tap "Cancel" (top left)
4. ✅ Verify sheet closes
5. ✅ Verify action item still present
6. Tap action item again
7. Tap "Decline Transfer"
8. Confirm
9. ✅ Verify action item removed permanently

---

## 📝 Summary

**Added:** "Decline Transfer" button to give users more control over scheduled transfers

**Benefits:**
- ✅ Users can cancel transfers they no longer want
- ✅ Separate control for skipping one occurrence of recurring transfers
- ✅ Clear confirmation alerts prevent accidents
- ✅ Different behavior for one-time vs recurring transfers
- ✅ No balance changes when declining

**User Experience:**
- More flexibility and control
- Safety through confirmation alerts
- Clear distinction between approve and decline
- Recurring transfers protected from accidental full cancellation
