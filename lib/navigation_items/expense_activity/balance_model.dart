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
//
// Funding sources (see FundingSource): an expense or card paid from a manual
// account takes from that account, and from currentBalance only if the account
// counts toward it; an expense charged to a card adds to the card instead, and
// leaves the balance when the card is paid. "Expenses due" in a check counts
// only what leaves currentBalance, so nothing is counted twice.
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/navigation_items/banking/manual_account_model.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/storage_management/period_snapshot.dart';
import 'check_window.dart';
import 'credit_model.dart';
import 'expense_item.dart';
import 'funding_source.dart';

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
    // Last day everything was brought up to (see makeRecent); in particular, every
    // stream's paychecks through this day are already in currentBalance.
    DateTime lastUpdated;
    final List<ExpenseItem> expenses = []; // Expenses and credit cards
    final List<IncomeStreamModel> incomeStreams = [];
    IncomeStreamModel? activeIncome; // The income stream whose paydays define the checks
    // Totals of pay periods that have ended, recorded by makeRecent, for Visuals.
    final List<PeriodSnapshot> snapshots = [];
    final List<ManualAccountModel> manualAccounts = [];
    // "Additional funds" in Update Balance: money tracked outside any account
    // (the Java app's manualBalanceAddition), part of currentBalance.
    double balanceExtra;

    BalanceModel({
        required this.currentBalance,
        DateTime? lastUpdated,
        this.balanceExtra = 0.00,
    }) : lastUpdated = dateOnly(lastUpdated ?? todayDate());

    // ── Accounts and funding sources ────────────────────────────────────────

    ManualAccountModel? manualAccount(String? id) {
        for (final ManualAccountModel account in manualAccounts) {
            if (account.id == id) return account;
        }
        return null;
    }

    // Cards are referred to by name, as in the Java app (see renameCard).
    CreditModel? card(String? name) {
        for (final CreditModel card in creditCards) {
            if (card.name == name) return card;
        }
        return null;
    }

    // Sum of the accounts that count toward currentBalance.
    double get countedAccountsTotal => manualAccounts
        .where((a) => a.countsTowardBalance)
        .fold(0.00, (sum, a) => sum + a.balance);

    // Changes an account's balance; currentBalance moves with it when the account
    // counts toward it (the Java app's manualAccountsTotal delta).
    void adjustAccount(ManualAccountModel account, double delta) {
        account.balance += delta;
        if (account.countsTowardBalance) currentBalance += delta;
    }

    // Removes an account. If it counted toward currentBalance, its balance leaves
    // currentBalance with it. Whatever it paid for is paid from the balance instead.
    void removeAccount(ManualAccountModel account) {
        if (account.countsTowardBalance) currentBalance -= account.balance;
        manualAccounts.remove(account);
        _redirectSources(FundingSource.manualAccount, account.id);
    }

    // After a card is deleted: what was charged to it is paid from the balance.
    void cardRemoved(String name) => _redirectSources(FundingSource.creditCard, name);

    // After a card is renamed: keeps what's charged to it pointing at it.
    void renameCard(String oldName, String newName) {
        if (oldName == newName) return;
        for (final ExpenseItem expense in expenses) {
            if (expense.source == FundingSource.creditCard && expense.sourceId == oldName) {
                expense.sourceId = newName;
            }
        }
    }

    void _redirectSources(FundingSource source, String id) {
        for (final ExpenseItem expense in expenses) {
            if (expense.source == source && expense.sourceId == id) {
                expense.source = FundingSource.balance;
                expense.sourceId = null;
            }
        }
    }

    // Update Balance with a typed balance: no account counts toward it anymore
    // (as in the Java app), and currentBalance = [typed] + [extra].
    void setBalanceTyped(double typed, double extra) {
        for (final ManualAccountModel account in manualAccounts) {
            account.countsTowardBalance = false;
        }
        balanceExtra = extra;
        currentBalance = typed + extra;
    }

    // Update Balance "From Accounts": the accounts with [accountIds] count toward
    // currentBalance, which becomes their total + [extra].
    void setBalanceFromAccounts(Set<String> accountIds, double extra) {
        for (final ManualAccountModel account in manualAccounts) {
            account.countsTowardBalance = accountIds.contains(account.id);
        }
        balanceExtra = extra;
        currentBalance = countedAccountsTotal + extra;
    }

    // "Paid from" choices: the balance, each manual account, and (for an expense,
    // not a card) each card.
    List<SourceOption> paymentOptions({required bool forCard}) => [
        SourceOption.currentBalance,
        for (final ManualAccountModel account in manualAccounts)
            SourceOption(FundingSource.manualAccount, account.id, account.name),
        if (!forCard)
            for (final CreditModel card in creditCards)
                SourceOption(FundingSource.creditCard, card.name, "${card.name} (card)"),
    ];

    // What pays [item], for display ("Current Balance", an account, "Visa (card)").
    String paidFromLabel(ExpenseItem item) => switch (item.source) {
        FundingSource.balance => "Current Balance",
        FundingSource.manualAccount => manualAccount(item.sourceId)?.name ?? "Current Balance",
        FundingSource.creditCard => _chargedTo(item) == null ? "Current Balance" : "${item.sourceId} (card)",
    };

    // The card [item] is charged to, or null if it isn't (or the card is gone).
    CreditModel? _chargedTo(ExpenseItem item) {
        if (item is CreditModel || item.source != FundingSource.creditCard) return null;
        return card(item.sourceId);
    }

    // Whether [item]'s payments come out of currentBalance.
    bool hitsBalance(ExpenseItem item) => switch (item.source) {
        FundingSource.balance => true,
        // A missing account falls back to the balance, as _payFrom does.
        FundingSource.manualAccount => manualAccount(item.sourceId)?.countsTowardBalance ?? true,
        FundingSource.creditCard => _chargedTo(item) == null,
    };

    // Takes a payment of [amount] for [item] from whatever pays for it.
    void _payFrom(ExpenseItem item, double amount) {
        if (amount == 0) return;
        final ManualAccountModel? account =
            item.source == FundingSource.manualAccount ? manualAccount(item.sourceId) : null;
        final CreditModel? card = _chargedTo(item);
        if (account != null) {
            adjustAccount(account, -amount);
        } else if (card != null) {
            card.amount += amount;
        } else {
            currentBalance -= amount;
        }
    }

    // The not-yet-applied charges to [card] between two dates (both inclusive).
    ChargesBetween chargesTo(CreditModel card) => (DateTime from, DateTime to) {
        double total = 0.00;
        for (final ExpenseItem expense in expenses) {
            if (identical(_chargedTo(expense), card)) {
                total += expense.amount * expense.occurrencesBetween(from, to);
            }
        }
        return total;
    };

    // Methods

    // Brings everything up to [today] (default: now): pays expenses that came due
    // before today, pays off credit cards whose due date passed, and credits every
    // income stream's paychecks after lastUpdated through today -- not only the
    // active stream's, which just sets the pay periods. A paycheck landing today
    // counts, matching the Java app's pay period rolling over on payday. Returns
    // the net change applied to currentBalance; calling it twice on the same day
    // changes nothing the second time.
    //
    // Nothing before a stream's starting date counts, and the starting date's own
    // paycheck counts only if it's after lastUpdated. Streams are added and edited
    // while the app is open, after this has run for today, so that means: a
    // starting date entered in the future is credited when it arrives, a past or
    // current one is already in the balance, and editing a stream only ever
    // affects future paydays. Same rule as the Java app's incomeArrivedSince.
    double makeRecent({DateTime? today}) {
        final DateTime day = dateOnly(today ?? todayDate());
        // Before anything is paid, so a card's balance lands in the period it was due.
        _recordEndedPeriods(day);
        final double before = currentBalance;
        // Expenses first, collecting charges to cards with their dates...
        final Map<CreditModel, List<Charge>> charges = {};
        for (final ExpenseItem expense in expenses) {
            if (expense is CreditModel) continue;
            final CreditModel? card = _chargedTo(expense);
            if (card == null) {
                _payFrom(expense, expense.makeRecent(today: day));
                continue;
            }
            final List<DateTime> dates = expense.occurrenceDatesBetween(expense.currentDueDate, addDays(day, -1));
            expense.makeRecent(today: day);
            charges.putIfAbsent(card, () => []).addAll(dates.map((date) => (date: date, amount: expense.amount)));
        }
        // ...then cards, so each due date pays the charges made before it.
        for (final CreditModel card in creditCards) {
            _payFrom(card, card.makeRecentWithCharges(charges[card] ?? const [], today: day));
        }
        if (day.isAfter(lastUpdated)) {
            for (final IncomeStreamModel income in incomeStreams) {
                currentBalance += income.amountBetween(addDays(lastUpdated, 1), day);
            }
            lastUpdated = day;
        }
        return currentBalance - before;
    }

    // Records a snapshot for every pay period of the active stream that ended since
    // lastUpdated (its closing payday is after lastUpdated, on or before [day]),
    // once per period, as the Java app does when it rolls a pay period over.
    void _recordEndedPeriods(DateTime day) {
        final IncomeStreamModel? income = activeIncome;
        if (income == null || !day.isAfter(lastUpdated)) return;
        DateTime end = income.paydayAfter(lastUpdated);
        int safety = 0;
        while (!end.isAfter(day) && safety++ < 3650) {
            final DateTime? start = income.paydayOnOrBefore(addDays(end, -1));
            if (start != null && !snapshots.any((s) => s.start == start)) {
                snapshots.add(PeriodSnapshot(
                    start: start,
                    totalIncome: periodIncome(start, end),
                    totalExpenses: periodExpenses(start, end),
                ));
            }
            end = income.paydayAfter(end);
        }
    }

    // Every stream's income in the half-open period [start, end).
    double periodIncome(DateTime start, DateTime end) {
        double total = 0.00;
        for (final IncomeStreamModel income in incomeStreams) {
            total += income.amountInPeriod(start, end);
        }
        return total;
    }

    // Every expense and card payment falling in the half-open period [start, end),
    // paid or not (history counts what happened, not what's still owed). Charges
    // to a card count in the card's payment, not on their own dates.
    double periodExpenses(DateTime start, DateTime end) {
        double total = 0.00;
        final DateTime last = addDays(end, -1);
        for (final ExpenseItem expense in expenses) {
            if (expense is CreditModel) {
                total += expense.owedBetween(start, last, chargesTo(expense));
            } else if (_chargedTo(expense) == null) {
                total += expense.historicalAmountBetween(start, last);
            }
        }
        return total;
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

    // Total due in a check that leaves currentBalance: expenses and card payments
    // paid from the balance (or from an account that counts toward it).
    double expensesForCheck(CheckWindow check) {
        double total = 0.00;
        for (final ExpenseItem expense in expenses) {
            if (!hitsBalance(expense)) continue;
            total += expense is CreditModel
                ? expense.owedBetween(check.expensesFrom, check.expensesTo, chargesTo(expense))
                : expense.amountDueInCheck(check);
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
            if (expense is CreditModel) {
                expense.showCheckWith(summary.window, chargesTo(expense));
            } else {
                expense.toCheck(summary.window);
            }
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
