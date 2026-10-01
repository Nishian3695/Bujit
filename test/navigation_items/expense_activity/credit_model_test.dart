// Run with flutter test test/navigation_items/expense_activity/credit_model_test.dart
//
// Ported from the Java app's CreditModelTest: the balance is due once on the
// next due date, is paid off (once) when that date passes, and utilization
// follows the balance still owed rather than the amount due in a check.
import 'package:bujit/navigation_items/expense_activity/check_window.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);
DateTime day(int offset) => addDays(today, offset);

CreditModel _card({
    double balance = 500.0,
    required DateTime dueDate,
    double creditLimit = 2000.0,
}) {
    return CreditModel(
        name: "Card",
        amount: balance,
        startDate: dueDate,
        frequency: 1,
        frequencyUnits: FrequencyUnit.monthly,
        creditLimit: creditLimit,
    );
}

CheckWindow _check(int index) => CheckWindow(
    index: index,
    start: day(14 * index),
    end: day(14 * (index + 1)),
    today: today,
);

void main() {
    group("makeRecent", () {
        test("a future due date pays nothing and keeps the balance", () {
            final card = _card(dueDate: day(10));

            expect(card.makeRecent(today: today), 0.0);
            expect(card.amount, 500.0);
        });

        test("a due date today isn't paid yet", () {
            final card = _card(dueDate: today);

            expect(card.makeRecent(today: today), 0.0);
            expect(card.amount, 500.0);
        });

        test("a passed due date pays the whole balance once and resets it", () {
            final card = _card(dueDate: day(-10));

            expect(card.makeRecent(today: today), closeTo(500.0, 1e-9));
            expect(card.amount, 0.0);
            expect(card.currentDueDate, DateTime(2026, 10, 21));
            expect(card.makeRecent(today: today), 0.0);
        });

        test("several missed due dates still pay the balance only once", () {
            final card = _card(dueDate: DateTime(2026, 6, 21));

            expect(card.makeRecent(today: today), closeTo(500.0, 1e-9));
            expect(card.amount, 0.0);
        });

        test("a card due on the 31st lands on month-ends", () {
            final card = _card(dueDate: DateTime(2025, 8, 31));
            card.makeRecent(today: today);

            expect(card.currentDueDate, DateTime(2026, 10, 31));
        });
    });

    group("amount due", () {
        test("the balance is due in the check holding the next due date", () {
            final card = _card(dueDate: day(10));

            expect(card.amountDueInCheck(_check(0)), closeTo(500.0, 1e-9));
        });

        test("the balance is due only once, not again at the following due dates", () {
            final card = _card(dueDate: day(10)); // next due dates: Nov 11 (day 41), Dec 11

            expect(card.amountDueInCheck(_check(1)), 0.0);
            expect(card.amountDueInCheck(_check(2)), 0.0);
            expect(card.amountDueInCheck(_check(3)), 0.0);
        });

        test("a due date on payday counts in the check that payday closes", () {
            final card = _card(dueDate: day(14));

            expect(card.amountDueInCheck(_check(0)), closeTo(500.0, 1e-9));
            expect(card.amountDueInCheck(_check(1)), 0.0);
        });
    });

    group("utilization", () {
        test("the current check uses the balance owed, not the amount due", () {
            final card = _card(balance: 500.0, dueDate: day(40)); // not due this check
            card.toCheck(_check(0));

            expect(card.periodAmount, 0.0);
            expect(card.creditUtilization, closeTo(0.25, 1e-9));
        });

        test("the check holding the due date still shows the balance owed", () {
            final card = _card(balance: 500.0, dueDate: day(20));
            card.toCheck(_check(1));

            expect(card.periodAmount, closeTo(500.0, 1e-9));
            expect(card.creditUtilization, closeTo(0.25, 1e-9));
        });

        test("checks after the due date show the card paid off", () {
            final card = _card(balance: 500.0, dueDate: day(20));
            card.toCheck(_check(2));

            expect(card.displayBalance, 0.0);
            expect(card.creditUtilization, 0.0);
        });

        test("is 0 for a card with no limit set", () {
            final card = _card(dueDate: day(10), creditLimit: 0.0);
            card.toCheck(_check(0));

            expect(card.creditUtilization, 0.0);
        });
    });

    test("category defaults to credit cards when not specified", () {
        final card = _card(dueDate: today);
        expect(card.category, "Credit Cards");
    });
}
