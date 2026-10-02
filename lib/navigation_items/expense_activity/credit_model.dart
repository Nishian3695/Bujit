// Data class for a credit card entry.
//
// amount is the card's current balance, due in full on currentDueDate (the
// next due date). Matching the Java app:
//   - the balance is due once, on the next due date -- later due dates owe
//     nothing until new charges exist (charges sourced to a card aren't
//     modelled here yet);
//   - when a due date passes, the whole balance is paid (once, however many
//     due dates were missed) and the balance resets to 0;
//   - utilization is the balance still owed as of a check divided by the
//     limit, not the amount due in that check (which is 0 most of the time).
import 'package:bujit/utils/date_utils.dart';
import 'check_window.dart';
import 'expense_item.dart';

class CreditModel extends ExpenseItem {
    // TODO: Linked Accounts and Google Sync
    double creditLimit; // Credit limit for the credit card
    double displayBalance; // Balance owed as of the check currently on screen (see toCheck)

    CreditModel({
        super.id,
        required super.name,
        required super.amount,
        required super.startDate,
        required super.frequency,
        required super.frequencyUnits,
        super.category = "Credit Cards",
        required this.creditLimit,
        super.currentDueDate,
        super.googleTaskId,
        super.remindInTasks,
    }) : displayBalance = amount;

    // Methods

    // The balance is due once, on the next due date, if that falls in the range.
    @override
    double amountDueBetween(DateTime from, DateTime to) {
        final DateTime lo = dateOnly(from);
        final DateTime hi = dateOnly(to);
        final bool dueInRange = !currentDueDate.isBefore(lo) && !currentDueDate.isAfter(hi);
        return dueInRange ? amount : 0.00;
    }

    // A card's history is its balance on its next due date (the only due date with
    // a known amount), as in the Java app's period totals.
    @override
    double historicalAmountBetween(DateTime from, DateTime to) => amountDueBetween(from, to);

    // If the due date has passed, pays the whole balance once, resets it to 0 and
    // moves to the next due date on or after [today]. Returns the amount paid.
    @override
    double makeRecent({DateTime? today}) {
        final DateTime day = dateOnly(today ?? todayDate());
        if (!currentDueDate.isBefore(day)) return 0.00;
        final double paid = amount;
        amount = 0.00;
        skipToNextDueDate(today: day);
        displayBalance = 0.00;
        return paid;
    }

    // Balance still owed as of a check: the full balance until a check that
    // opens after the due date (that due date paid it off).
    double balanceInCheck(CheckWindow check) {
        if (check.isCurrent) return amount;
        return currentDueDate.isAfter(check.start) ? amount : 0.00;
    }

    @override
    void toCheck(CheckWindow check) {
        super.toCheck(check);
        displayBalance = balanceInCheck(check);
    }

    // Get credit utilization as a fraction of the credit limit, for the check
    // currently on screen.
    double get creditUtilization {
        if (creditLimit == 0.0) {
            return 0.0; // Avoid division by zero
        }
        return displayBalance / creditLimit;
    }

    // TODO: Need method to allow expenses with this as a source to add to the balance

    // Getters
    bool get isCreditCard => true;
}
