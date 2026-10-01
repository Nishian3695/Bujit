// Run with flutter test test/navigation_items/expense_activity/balance_model_test.dart
//
// Ported from the Java app's home-screen behaviour: After This Check, the
// Next Check setting, projected checks, and catching up on app open.
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);
DateTime day(int offset) => addDays(today, offset);

IncomeStreamModel _income({
    double amount = 1000.0,
    required DateTime start,
    int frequency = 14,
    FrequencyUnit unit = FrequencyUnit.daily,
}) {
    return IncomeStreamModel(
        name: "Job",
        amount: amount,
        startDate: start,
        frequency: frequency,
        frequencyUnits: unit,
    );
}

ExpenseModel _expense({
    required double amount,
    required DateTime start,
    int frequency = 1,
    FrequencyUnit unit = FrequencyUnit.daily,
}) {
    return ExpenseModel(
        name: "Expense",
        amount: amount,
        startDate: start,
        frequency: frequency,
        frequencyUnits: unit,
    );
}

// $1000 balance, paid $1000 every 14 days with payday today.
BalanceModel _balance({double currentBalance = 1000.0}) {
    final balance = BalanceModel(currentBalance: currentBalance, lastUpdated: today);
    final job = _income(start: today);
    balance.incomeStreams.add(job);
    balance.activeIncome = job;
    return balance;
}

void main() {
    group("checks follow the active stream's paydays", () {
        test("the current check runs from the latest payday to the next", () {
            final balance = _balance();

            final current = balance.window(0, today: today);
            expect(current.start, today);
            expect(current.end, day(14));
            final next = balance.window(1, today: today);
            expect(next.start, day(14));
            expect(next.end, day(28));
        });

        test("between paydays the current check started on the last payday", () {
            final balance = BalanceModel(currentBalance: 0.0);
            final job = _income(start: day(-5));
            balance.incomeStreams.add(job);
            balance.activeIncome = job;

            expect(balance.window(0, today: today).start, day(-5));
            expect(balance.window(0, today: today).end, day(9));
        });

        test("monthly paydays on the 31st don't drift", () {
            final balance = BalanceModel(currentBalance: 0.0);
            final job = _income(start: DateTime(2026, 1, 31), frequency: 1, unit: FrequencyUnit.monthly);
            balance.incomeStreams.add(job);
            balance.activeIncome = job;
            final DateTime march = DateTime(2026, 3, 5);

            expect(balance.payday(0, today: march), DateTime(2026, 2, 28));
            expect(balance.payday(1, today: march), DateTime(2026, 3, 31));
            expect(balance.payday(2, today: march), DateTime(2026, 4, 30));
        });

        test("with no active stream, checks are a week long", () {
            final balance = BalanceModel(currentBalance: 0.0);

            expect(balance.window(0, today: today).end, day(7));
            expect(balance.window(2, today: today).start, day(14));
        });

        test("a stream starting in the future: the current check runs to its first payday", () {
            final balance = BalanceModel(currentBalance: 0.0);
            final job = _income(start: day(10));
            balance.incomeStreams.add(job);
            balance.activeIncome = job;

            expect(balance.window(0, today: today).start, today);
            expect(balance.window(0, today: today).end, day(10));
        });
    });

    group("After This Check", () {
        test("is the balance minus expenses due through the next payday, inclusive", () {
            final balance = _balance();
            balance.expenses.add(_expense(amount: 5.0, start: today)); // daily: days 0..14

            final summary = balance.check(0, today: today);
            expect(summary.startBalance, closeTo(1000.0, 1e-9));
            expect(summary.expensesDue, closeTo(75.0, 1e-9));
            expect(summary.endBalance, closeTo(925.0, 1e-9));
        });

        test("Next Check adds the next paycheck", () {
            final balance = _balance();
            balance.expenses.add(_expense(amount: 5.0, start: today));

            expect(balance.check(0, today: today).endBalanceWithNextCheck, closeTo(1925.0, 1e-9));
        });

        test("credit cards count, once, on their next due date", () {
            final balance = _balance();
            balance.expenses.add(CreditModel(
                name: "Card", amount: 300.0, startDate: day(10),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, creditLimit: 1000.0,
            ));

            expect(balance.check(0, today: today).endBalance, closeTo(700.0, 1e-9));
            // Its next due date (Nov 11) owes nothing new.
            expect(balance.check(3, today: today).expensesDue, 0.0);
        });
    });

    group("projected checks", () {
        test("start from the previous check's end plus this check's paycheck", () {
            final balance = _balance();
            balance.expenses.add(_expense(amount: 5.0, start: today));

            final next = balance.check(1, today: today);
            expect(next.startBalance, closeTo(1925.0, 1e-9)); // 1000 - 75 + 1000
            expect(next.income, closeTo(1000.0, 1e-9));
            expect(next.expensesDue, closeTo(70.0, 1e-9)); // days 15..28
            expect(next.endBalance, closeTo(1855.0, 1e-9));
        });

        test("rent due on payday is counted once, in the check that payday closes", () {
            final balance = _balance();
            balance.expenses.add(_expense(amount: 1200.0, start: day(14), frequency: 1, unit: FrequencyUnit.monthly));

            expect(balance.check(0, today: today).expensesDue, closeTo(1200.0, 1e-9));
            expect(balance.check(1, today: today).expensesDue, 0.0);
        });

        test("nothing is double counted across many checks", () {
            final balance = _balance();
            balance.expenses.add(_expense(amount: 5.0, start: today)); // every day
            balance.expenses.add(_expense(amount: 40.0, start: today, frequency: 7)); // every payday and between

            double total = 0.0;
            for (int i = 0; i < 6; i++) {
                total += balance.check(i, today: today).expensesDue;
            }
            // Days 0..84 inclusive: 85 daily occurrences and 13 weekly ones.
            expect(total, closeTo(85 * 5.0 + 13 * 40.0, 1e-9));
        });

        test("computing a check directly matches stepping through the Java app's way", () {
            final balance = _balance();
            balance.expenses.add(_expense(amount: 5.0, start: today));
            balance.expenses.add(_expense(amount: 900.0, start: day(3), frequency: 1, unit: FrequencyUnit.monthly));
            balance.incomeStreams.add(_income(amount: 250.0, start: day(5), frequency: 30));

            // The Java app: shown -= this check's expenses; shown += next check's income.
            double shown = balance.currentBalance;
            for (int i = 0; i < 4; i++) {
                shown -= balance.check(i, today: today).expensesDue;
                shown += balance.check(i + 1, today: today).income;
                expect(balance.check(i + 1, today: today).startBalance, closeTo(shown, 1e-9));
            }
        });

        test("every stream's paychecks count toward a projected check's income", () {
            final balance = _balance();
            balance.incomeStreams.add(_income(amount: 250.0, start: day(20), frequency: 30));

            // Check 1 is [day 14, day 28): the job's day-14 paycheck and the side job's day 20.
            expect(balance.check(1, today: today).income, closeTo(1250.0, 1e-9));
        });

        test("showCheck updates each row's amount and each card's balance", () {
            final balance = _balance();
            final daily = _expense(amount: 5.0, start: today);
            final card = CreditModel(
                name: "Card", amount: 300.0, startDate: day(10),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, creditLimit: 1000.0,
            );
            balance.expenses.addAll([daily, card]);

            balance.showCheck(1, today: today);
            expect(daily.periodAmount, closeTo(70.0, 1e-9));
            expect(daily.shownDate, day(15));
            expect(card.periodAmount, 0.0);
            expect(card.creditUtilization, 0.0); // paid off on day 10, before this check
        });
    });

    group("makeRecent (catching up on app open)", () {
        test("pays past expenses and credits the active stream's arrived paychecks", () {
            final balance = BalanceModel(currentBalance: 1000.0, lastUpdated: day(-20));
            final job = _income(start: day(-28)); // paydays -28, -14, 0
            balance.incomeStreams.add(job);
            balance.activeIncome = job;
            balance.expenses.add(_expense(amount: 10.0, start: day(-20), frequency: 10)); // -20, -10 paid; 0 not yet

            final change = balance.makeRecent(today: today);
            expect(change, closeTo(2000.0 - 20.0, 1e-9));
            expect(balance.currentBalance, closeTo(2980.0, 1e-9));
            expect(balance.lastUpdated, today);
        });

        test("pays a credit card whose due date passed", () {
            final balance = _balance();
            balance.expenses.add(CreditModel(
                name: "Card", amount: 300.0, startDate: day(-3),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, creditLimit: 1000.0,
            ));

            expect(balance.makeRecent(today: today), closeTo(-300.0, 1e-9));
        });

        // Confirmed against the previous code, which only credited the active stream ($0 here).
        test("credits every stream's arrived paychecks, not only the active one's", () {
            final balance = _balance(); // job: payday today, already in the balance
            // Side job: paydays -35 and -5; credited through -35, so the -5 paycheck is new.
            final side = IncomeStreamModel(
                name: "Side", amount: 250.0, startDate: day(-35),
                frequency: 30, frequencyUnits: FrequencyUnit.daily,
            );
            balance.incomeStreams.add(side);

            expect(balance.makeRecent(today: today), closeTo(250.0, 1e-9));
        });

        // Guards against the double subtraction found in the Java app (not present here).
        test("a credit card paid this check isn't subtracted again from After This Check", () {
            final balance = _balance();
            balance.expenses.add(CreditModel(
                name: "Card", amount: 300.0, startDate: day(-3),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, creditLimit: 1000.0,
            ));

            balance.makeRecent(today: today);
            expect(balance.currentBalance, closeTo(700.0, 1e-9));
            expect(balance.check(0, today: today).endBalance, closeTo(700.0, 1e-9));
        });

        test("a stream starting in the future credits nothing yet", () {
            final balance = _balance();
            balance.incomeStreams.add(_income(amount: 250.0, start: day(10), frequency: 30));

            expect(balance.makeRecent(today: today), 0.0);
        });

        test("opening again on the same day changes nothing", () {
            final balance = BalanceModel(currentBalance: 1000.0);
            final job = _income(start: day(-28));
            balance.incomeStreams.add(job);
            balance.activeIncome = job;
            balance.expenses.add(_expense(amount: 10.0, start: day(-20), frequency: 10));
            balance.makeRecent(today: today);

            expect(balance.makeRecent(today: today), 0.0);
        });
    });
}
