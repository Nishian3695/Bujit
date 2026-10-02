// Run with flutter test test/utils/sample_data_test.dart
//
// The tutorial's sample data, and how the balance behaves with it -- a quick
// way to see the numbers the home screen should show.
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);
DateTime day(int offset) => addDays(today, offset);

BalanceModel _seeded() {
    final balance = BalanceModel(currentBalance: 0.0);
    seedSampleData(balance, today: today);
    return balance;
}

void main() {
    test("seeds the Java app's tutorial data", () {
        final balance = _seeded();

        expect(balance.currentBalance, 3500.0);
        expect(balance.expenses.map((e) => e.name), [
            "Rent", "Netflix", "Electric Bill", "Everyday Card", "Travel Card", "Hobby Card",
        ]);
        expect(balance.creditCards, hasLength(3));
        expect(balance.activeIncome!.name, "Main Job");
        expect(balance.window(0, today: today).end, day(14));
    });

    test("the first catch-up charges nothing: every date is upcoming", () {
        final balance = _seeded();

        expect(balance.makeRecent(today: today), 0.0);
        expect(balance.currentBalance, 3500.0);
    });

    test("this check: everything falls before the next payday", () {
        final summary = _seeded().check(0, today: today);

        // Rent 850 + Netflix 15.99 + Electric 110 + cards 450 + 1200 + 6000
        expect(summary.expensesDue, closeTo(8625.99, 1e-6));
        expect(summary.endBalance, closeTo(3500.0 - 8625.99, 1e-6));
        expect(summary.endBalanceWithNextCheck, closeTo(3500.0 - 8625.99 + 2400.0, 1e-6));
    });

    test("next check: the paycheck arrives and only next month's bills come due", () {
        final summary = _seeded().check(1, today: today); // days 15..28

        expect(summary.startBalance, closeTo(3500.0 - 8625.99 + 2400.0, 1e-6));
        expect(summary.income, closeTo(2400.0, 1e-6));
        // Rent (day 33), Netflix (36) and Electric (40) are next month; the cards are paid off.
        expect(summary.expensesDue, 0.0);
    });

    test("two checks out, the monthly bills recur but the cards don't", () {
        final summary = _seeded().check(2, today: today); // days 29..42

        expect(summary.expensesDue, closeTo(850.0 + 15.99 + 110.0, 1e-6));
    });

    test("card utilization starts high and drops once each card is paid", () {
        final balance = _seeded();
        balance.showCheck(0, today: today);
        final hobby = balance.creditCards.firstWhere((c) => c.name == "Hobby Card");
        expect(hobby.creditUtilization, closeTo(6000.0 / 6200.0, 1e-9));

        balance.showCheck(1, today: today);
        expect(balance.creditCards.every((CreditModel c) => c.creditUtilization == 0.0), isTrue);
    });
}
