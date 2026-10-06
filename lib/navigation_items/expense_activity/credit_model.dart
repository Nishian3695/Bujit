// Data class for a credit card entry.
//
// amount is the card's current balance, due in full on currentDueDate (the
// next due date). Expenses can be charged to the card (FundingSource.creditCard);
// a charge adds to what the card owes on the first due date AFTER the charge's
// date (one on a due date itself rolls into the next one), as in the Java app's
// sourcedChargesBetween. So, matching the Java app:
//   - the next due date owes the balance plus the charges before it; each later
//     due date owes the charges since the one before it (nothing without charges);
//   - when a due date passes, what it owed is paid and the balance resets to the
//     charges made since;
//   - utilization is the balance owed as of a check (charges through its last
//     day included) divided by the limit, not the amount due in that check.
// The charges themselves come from BalanceModel, which knows every expense:
// it passes them in as a ChargesBetween.
import 'package:bujit/utils/date_utils.dart';
import 'check_window.dart';
import 'expense_item.dart';

// Total of the not-yet-applied charges to a card dated [from] through [to], both inclusive.
typedef ChargesBetween = double Function(DateTime from, DateTime to);

// A dated charge already made (an occurrence makeRecent is applying).
typedef Charge = ({DateTime date, double amount});

double _noCharges(DateTime from, DateTime to) => 0.00;

class CreditModel extends ExpenseItem {
    // Far enough back to cover every unpaid charge (unpaid ones are never before today).
    static final DateTime _beginning = DateTime(1900);

    double creditLimit; // Credit limit for the credit card
    double displayBalance; // Balance owed as of the check currently on screen (see showCheckWith)

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
        super.source,
        super.sourceId,
        super.linkedAccountId,
    }) : displayBalance = amount;

    // Methods

    // Due dates from the next one through [to].
    List<DateTime> dueDatesThrough(DateTime to) => occurrenceDatesBetween(currentDueDate, to);

    // What the due dates from [from] through [to] (inclusive) owe, given the
    // charges still to come.
    double owedBetween(DateTime from, DateTime to, [ChargesBetween charges = _noCharges]) {
        final DateTime lo = dateOnly(from);
        double total = 0.00;
        DateTime? previous;
        for (final DateTime due in dueDatesThrough(dateOnly(to))) {
            final double owed = previous == null
                ? amount + charges(_beginning, addDays(due, -1))
                : charges(previous, addDays(due, -1));
            if (!due.isBefore(lo)) total += owed;
            previous = due;
        }
        return total;
    }

    // Without charges: the balance is due once, on the next due date, if that falls in the range.
    @override
    double amountDueBetween(DateTime from, DateTime to) => owedBetween(from, to);

    // A card's history is its balance on its next due date (the only due date with
    // a known amount), as in the Java app's period totals.
    @override
    double historicalAmountBetween(DateTime from, DateTime to) => amountDueBetween(from, to);

    // Brings the card up to [today], with no charges to apply. Returns the amount paid.
    @override
    double makeRecent({DateTime? today}) => makeRecentWithCharges(const [], today: today);

    // Brings the card up to [today] (default: now): applies [charges] (dated
    // before today) in date order, and on every due date that passed pays what
    // was owed then -- the balance plus earlier charges -- leaving the charges
    // made since as the new balance. Returns the total paid, for the caller to
    // take from whatever pays the card.
    double makeRecentWithCharges(List<Charge> charges, {DateTime? today}) {
        final DateTime day = dateOnly(today ?? todayDate());
        final List<Charge> sorted = [...charges]..sort((a, b) => a.date.compareTo(b.date));
        int next = 0;
        double owed = amount;
        double paid = 0.00;
        for (final DateTime due in dueDatesThrough(addDays(day, -1))) {
            while (next < sorted.length && sorted[next].date.isBefore(due)) {
                owed += sorted[next++].amount;
            }
            paid += owed;
            owed = 0.00;
        }
        while (next < sorted.length) {
            owed += sorted[next++].amount;
        }
        amount = owed;
        skipToNextDueDate(today: day);
        displayBalance = amount;
        return paid;
    }

    // Balance owed as of a check's last day, charges included. A due date inside
    // the check doesn't reset it yet (the check shows what that due date pays,
    // as in the Java app); one on or before a projected check's opening payday does.
    double balanceInCheck(CheckWindow check, [ChargesBetween charges = _noCharges]) {
        DateTime? reset;
        if (!check.isCurrent) {
            for (final DateTime due in dueDatesThrough(check.start)) {
                reset = due;
            }
        }
        return reset == null
            ? amount + charges(_beginning, check.expensesTo)
            : charges(reset, check.expensesTo);
    }

    // Balance owed at the end of [date]: due dates through it are paid (as makeRecent
    // pays them), leaving the charges made since, through [date].
    double balanceOn(DateTime date, [ChargesBetween charges = _noCharges]) {
        final DateTime day = dateOnly(date);
        final List<DateTime> dues = dueDatesThrough(day);
        return dues.isEmpty ? amount + charges(_beginning, day) : charges(dues.last, day);
    }

    // Sets the displayed amount and balance for a check, charges included.
    void showCheckWith(CheckWindow check, ChargesBetween charges) {
        toCheck(check);
        periodAmount = owedBetween(check.expensesFrom, check.expensesTo, charges);
        displayBalance = balanceInCheck(check, charges);
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

    // Getters
    bool get isCreditCard => true;
}
