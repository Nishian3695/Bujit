// The user's balance and the pay periods ("checks") it's projected across.
//
// Matches the Java app's home screen. The active income stream's paydays
// split time into checks: check 0 (current) runs from the latest payday to the
// next, and check k from the k-th upcoming payday to the one after. For check k:
//   startBalance = currentBalance
//                  + income of checks 1..k (check 0's income already arrived)
//                  - expenses due in checks 0..k-1
//   endBalance   = startBalance - expenses due in check k   ("After This Check")
//   endBalanceWithNextCheck = endBalance + check k+1's income ("Next Check" setting)
// Expense windows follow CheckWindow's payday rule, so an expense on a
// payday is counted exactly once, in the check that payday closes. A check's
// income is every stream's paychecks in [its start, its end), as in the Java
// app, and makeRecent credits every stream too. Each check is computed from
// scratch, so paging forward and back can't accumulate drift or double counting.
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'check_window.dart';
import 'credit_model.dart';
import 'expense_item.dart';

// One check's numbers, as computed by BalanceModel.check().
class CheckSummary {
    final CheckWindow window;
    final double startBalance; // Balance at the start of the check
    final double income; // Income counted for this check (0 for the current check)
    final double expensesDue; // Expenses due in this check
    final double nextCheckIncome; // The following check's income

    const CheckSummary({
        required this.window,
        required this.startBalance,
        required this.income,
        required this.expensesDue,
        required this.nextCheckIncome,
    });

    // "After This Check": the lowest the balance could dip before the next paycheck.
    double get endBalance => startBalance - expensesDue;
    // "Next Check": After This Check plus the next paycheck(s).
    double get endBalanceWithNextCheck => endBalance + nextCheckIncome;
}

class BalanceModel {
    // How long a check is when there's no active income stream (the Java app's default).
    static const int fallbackCheckDays = 7;

    double currentBalance;
    DateTime lastUpdated;
    final List<ExpenseItem> expenses = []; // Expenses and credit cards
    final List<IncomeStreamModel> incomeStreams = [];
    IncomeStreamModel? activeIncome; // The income stream whose paydays define the checks

    BalanceModel({
        required this.currentBalance,
        DateTime? lastUpdated,
    }) : lastUpdated = dateOnly(lastUpdated ?? todayDate());

    // Methods

    // Brings everything up to [today] (default: now): pays expenses that came due
    // before today, pays off credit cards whose due date passed, and credits every
    // income stream's paychecks through today -- not only the active stream's,
    // which just sets the pay periods. Returns the net change applied to currentBalance.
    double makeRecent({DateTime? today}) {
        final DateTime day = dateOnly(today ?? todayDate());
        double change = 0.00;
        for (final ExpenseItem expense in expenses) {
            change -= expense.makeRecent(today: day);
        }
        for (final IncomeStreamModel income in incomeStreams) {
            change += income.makeRecent(today: day);
        }
        currentBalance += change;
        lastUpdated = day;
        return change;
    }

    // The payday check [index] opens on (index 0 = the current check).
    DateTime payday(int index, {DateTime? today}) {
        final DateTime day = dateOnly(today ?? todayDate());
        final IncomeStreamModel? income = activeIncome;
        if (income == null) return addDays(day, fallbackCheckDays * index);
        if (index == 0) return income.paydayOnOrBefore(day) ?? day;
        DateTime date = income.paydayAfter(day);
        for (int i = 1; i < index; i++) {
            date = income.paydayAfter(date);
        }
        return date;
    }

    // Dates for check [index] (0 = current).
    CheckWindow window(int index, {DateTime? today}) {
        final DateTime day = dateOnly(today ?? todayDate());
        return CheckWindow(
            index: index,
            start: payday(index, today: day),
            end: payday(index + 1, today: day),
            today: day,
        );
    }

    // Income counted for a check: every stream's paychecks in [start, end). The
    // current check's has already arrived (it's in currentBalance), so it's 0.
    double incomeForCheck(CheckWindow check) {
        if (check.isCurrent) return 0.00;
        double total = 0.00;
        for (final IncomeStreamModel income in incomeStreams) {
            total += income.amountInPeriod(check.start, check.end);
        }
        return total;
    }

    // Total of every expense and credit card due in a check.
    double expensesForCheck(CheckWindow check) {
        double total = 0.00;
        for (final ExpenseItem expense in expenses) {
            total += expense.amountDueInCheck(check);
        }
        return total;
    }

    // Computes check [index] (0 = current) from scratch.
    CheckSummary check(int index, {DateTime? today}) {
        final DateTime day = dateOnly(today ?? todayDate());
        double startBalance = currentBalance;
        for (int i = 0; i < index; i++) {
            startBalance -= expensesForCheck(window(i, today: day));
            startBalance += incomeForCheck(window(i + 1, today: day));
        }
        final CheckWindow current = window(index, today: day);
        return CheckSummary(
            window: current,
            startBalance: startBalance,
            income: incomeForCheck(current),
            expensesDue: expensesForCheck(current),
            nextCheckIncome: incomeForCheck(window(index + 1, today: day)),
        );
    }

    // Updates every item's displayed date/amount for check [index] and returns
    // that check's numbers -- what the home screen calls when paging.
    CheckSummary showCheck(int index, {DateTime? today}) {
        final CheckSummary summary = check(index, today: today);
        for (final ExpenseItem expense in expenses) {
            expense.toCheck(summary.window);
        }
        for (final IncomeStreamModel income in incomeStreams) {
            income.periodAmount = summary.window.isCurrent
                ? 0.00
                : income.amountInPeriod(summary.window.start, summary.window.end);
        }
        return summary;
    }

    // Credit cards among the expenses, for the utilization screen.
    Iterable<CreditModel> get creditCards => expenses.whereType<CreditModel>();
}
