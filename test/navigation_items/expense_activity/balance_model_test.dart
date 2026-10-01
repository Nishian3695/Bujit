// Run with flutter test test/navigation_items/expense_activity/balance_model_test.dart
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _anchor = DateTime(2026, 1, 1);
DateTime d(int offsetDays) => _anchor.add(Duration(days: offsetDays));

BalanceModel _makeBalance({
    double currentBalance = 1000.0,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
}) {
    return BalanceModel(
        currentBalance: currentBalance,
        lastUpdated: d(0),
        currentPeriodStart: currentPeriodStart ?? d(0),
        currentPeriodEnd: currentPeriodEnd ?? d(30),
        projectFrequency: 14,
        projectFrequencyUnits: FrequencyUnit.daily,
    );
}

IncomeStreamModel _income({
    required DateTime startDate,
    double amount = 100.0,
    int frequency = 10,
}) {
    return IncomeStreamModel(
        name: "Test Income",
        amount: amount,
        startDate: startDate,
        frequency: frequency,
        frequencyUnits: FrequencyUnit.daily,
    );
}

ExpenseModel _expense({
    required DateTime startDate,
    double amount = 50.0,
    int frequency = 10,
}) {
    return ExpenseModel(
        name: "Test Expense",
        amount: amount,
        startDate: startDate,
        frequency: frequency,
        frequencyUnits: FrequencyUnit.daily,
    );
}

void main() {
    group("projectToPeriod boundary semantics", () {
        test("income landing exactly on period start is caught up into shownBalance, not the period effect", () {
            final balance = _makeBalance(currentBalance: 1000.0);
            balance.incomeStreams.add(_income(startDate: d(0), amount: 100.0));

            balance.projectToPeriod(d(20), d(25));

            // Occurrences at d0, d10, d20 are all <= start (d20) -- 3 * 100
            expect(balance.shownBalance, closeTo(1300.0, 1e-9));
            // No occurrence strictly between d20 and d25
            expect(balance.afterBalance, closeTo(1300.0, 1e-9));
        });

        test("expense landing exactly on period start is excluded from catch-up but included in the period effect", () {
            final balance = _makeBalance(currentBalance: 1000.0);
            balance.expenses.add(_expense(startDate: d(0), amount: 50.0));

            balance.projectToPeriod(d(20), d(25));

            // d0 and d10 are strictly before start (d20) -- the expense due exactly
            // on d20 itself hasn't "passed" yet, so it's not in catch-up.
            expect(balance.shownBalance, closeTo(900.0, 1e-9));
            // But it does fall in [d20, d25), so it hits the period effect.
            expect(balance.afterBalance, closeTo(850.0, 1e-9));
        });

        test("income landing exactly on period end is deferred to the next period, not double counted", () {
            final balance = _makeBalance(currentBalance: 1000.0);
            balance.incomeStreams.add(_income(startDate: d(0), amount: 100.0));

            // start (d5) isn't an occurrence; end (d10) is.
            balance.projectToPeriod(d(5), d(10));

            // Only d0 is caught up as of d5.
            expect(balance.shownBalance, closeTo(1100.0, 1e-9));
            // d10 is excluded (open end), so it doesn't show up in this period's effect.
            expect(balance.afterBalance, closeTo(1100.0, 1e-9));
        });

        test("expense landing exactly on period end is also deferred to the next period", () {
            final balance = _makeBalance(currentBalance: 1000.0);
            balance.expenses.add(_expense(startDate: d(0), amount: 50.0));

            balance.projectToPeriod(d(5), d(10));

            expect(balance.shownBalance, closeTo(950.0, 1e-9));
            expect(balance.afterBalance, closeTo(950.0, 1e-9));
        });

        test("multiple income streams and expenses all contribute, not just the last one processed", () {
            final balance = _makeBalance(currentBalance: 1000.0);
            // Lands exactly on start -- caught up into shownBalance.
            balance.incomeStreams.add(_income(startDate: d(20), amount: 100.0, frequency: 100));
            // Lands inside (start, end) -- part of the period effect.
            balance.incomeStreams.add(_income(startDate: d(25), amount: 20.0, frequency: 100));
            // Lands exactly on start -- part of the period effect (closed start for expenses).
            balance.expenses.add(_expense(startDate: d(20), amount: 30.0, frequency: 100));
            // Lands inside (start, end) -- part of the period effect.
            balance.expenses.add(_expense(startDate: d(26), amount: 5.0, frequency: 100));

            balance.projectToPeriod(d(20), d(30));

            // shownBalance: +100 (income1 catch-up), everything else is 0 catch-up.
            expect(balance.shownBalance, closeTo(1100.0, 1e-9));
            // afterBalance: shownBalance + income2 (20) - expense1 (30) - expense2 (5) = 1085.
            expect(balance.afterBalance, closeTo(1085.0, 1e-9));
        });
    });

    group("makeRecent", () {
        test("projects from currentBalance using today as the start", () {
            final today = DateTime.now();
            final todayMidnight = DateTime(today.year, today.month, today.day);
            final balance = _makeBalance(
                currentBalance: 500.0,
                currentPeriodEnd: todayMidnight.add(const Duration(days: 30)),
            );
            balance.incomeStreams.add(_income(
                startDate: todayMidnight.subtract(const Duration(days: 10)),
                amount: 100.0,
            ));

            balance.makeRecent();

            // Occurrences at (today - 10) and today itself are both caught up.
            expect(balance.shownBalance, closeTo(700.0, 1e-9));
        });
    });

    group("projectForward", () {
        test("does nothing when there's no active income stream", () {
            final balance = _makeBalance(currentBalance: 1000.0, currentPeriodStart: d(20));
            balance.projectToPeriod(d(20), d(30));
            final balanceBefore = balance.shownBalance;
            final periodBefore = balance.shownPeriod;

            balance.projectForward();

            expect(balance.shownBalance, balanceBefore);
            expect(balance.shownPeriod, periodBefore);
        });

        test("calling it twice does not double-count catch-up from the first call", () {
            final balance = _makeBalance(currentBalance: 1000.0, currentPeriodStart: d(20));
            final income = _income(startDate: d(0), amount: 10.0);
            balance.incomeStreams.add(income);
            balance.activeIncome = income;

            balance.projectForward();
            // shownPeriod advances d20 -> d30; catch-up as of d30 is d0,10,20,30 = 4 occurrences.
            expect(balance.shownPeriod, d(30));
            expect(balance.shownBalance, closeTo(1040.0, 1e-9));

            balance.projectForward();
            // shownPeriod advances d30 -> d40; catch-up as of d40 is d0,10,20,30,40 = 5 occurrences.
            // If this were chained on top of the previous call it would be 1040 + 50 = 1090.
            expect(balance.shownPeriod, d(40));
            expect(balance.shownBalance, closeTo(1050.0, 1e-9));
        });
    });
}
