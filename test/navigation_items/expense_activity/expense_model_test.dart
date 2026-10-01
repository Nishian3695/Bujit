// Run with flutter test test/navigation_items/expense_activity/expense_model_test.dart
//
// Ported from the Java app's ExpenseModelTest: catch-up payments, end dates,
// month-end anchoring, and the payday rule (see CheckWindow).
import 'package:bujit/navigation_items/expense_activity/check_window.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

// A fixed "today" (a Thursday) so results don't depend on when tests run.
final DateTime today = DateTime(2026, 10, 1);
DateTime day(int offset) => addDays(today, offset);

ExpenseModel _expense({
    double amount = 100.0,
    required DateTime start,
    int frequency = 30,
    FrequencyUnit unit = FrequencyUnit.daily,
    DateTime? endDate,
}) {
    return ExpenseModel(
        name: "Test Expense",
        amount: amount,
        startDate: start,
        frequency: frequency,
        frequencyUnits: unit,
        endDate: endDate,
    );
}

// The current check (payday today, next payday in 14 days) and projected checks after it.
CheckWindow _check(int index, {int length = 14}) => CheckWindow(
    index: index,
    start: day(length * index),
    end: day(length * (index + 1)),
    today: today,
);

void main() {
    group("makeRecent (catching up on app open)", () {
        test("a future date pays nothing and stays put", () {
            final expense = _expense(start: day(10));

            expect(expense.makeRecent(today: today), 0.0);
            expect(expense.currentDueDate, day(10));
        });

        test("pays each occurrence before today and moves to the next one", () {
            final expense = _expense(start: day(-60)); // -60, -30, 0

            expect(expense.makeRecent(today: today), closeTo(200.0, 1e-9));
            expect(expense.currentDueDate, today);
        });

        test("an occurrence due today isn't paid yet", () {
            final expense = _expense(start: today);

            expect(expense.makeRecent(today: today), 0.0);
            expect(expense.currentDueDate, today);
        });

        test("calling it again on the same day pays nothing more", () {
            final expense = _expense(start: day(-60));
            expense.makeRecent(today: today);

            expect(expense.makeRecent(today: today), 0.0);
        });

        test("a monthly expense on the 31st lands on month-ends after a year of catch-up", () {
            final expense = _expense(start: DateTime(2025, 8, 31), frequency: 1, unit: FrequencyUnit.monthly);
            expense.makeRecent(today: today);

            expect(expense.currentDueDate, DateTime(2026, 10, 31));
        });

        test("a frequency of 0 is paid once and never again", () {
            final expense = _expense(start: day(-5), frequency: 0);

            expect(expense.makeRecent(today: today), closeTo(100.0, 1e-9));
            expect(expense.makeRecent(today: day(30)), 0.0);
        });
    });

    group("skipToNextDueDate (a date entered in the past)", () {
        test("moves to the next upcoming date without paying", () {
            final expense = _expense(start: DateTime(2024, 1, 1), frequency: 1, unit: FrequencyUnit.monthly);
            expense.skipToNextDueDate(today: today);

            expect(expense.currentDueDate, today);
            // Nothing is left over for the next catch-up to charge.
            expect(expense.makeRecent(today: today), 0.0);
        });

        test("keeps the month-end day", () {
            final expense = _expense(start: DateTime(2024, 1, 31), frequency: 1, unit: FrequencyUnit.monthly);
            expense.skipToNextDueDate(today: today);

            expect(expense.currentDueDate, DateTime(2026, 10, 31));
        });

        test("an expense that already ended comes in as ended", () {
            final expense = _expense(
                start: DateTime(2024, 1, 5), frequency: 1, unit: FrequencyUnit.monthly,
                endDate: DateTime(2024, 6, 5),
            );
            expense.skipToNextDueDate(today: today);

            expect(expense.hasEnded, isTrue);
            expect(expense.makeRecent(today: today), 0.0);
        });
    });

    group("end dates", () {
        test("only occurrences up to the end date are paid", () {
            // -60 and -30; ended at -45, so only -60.
            final expense = _expense(start: day(-60), endDate: day(-45));

            expect(expense.makeRecent(today: today), closeTo(100.0, 1e-9));
            expect(expense.hasEnded, isTrue);
            expect(expense.amountDueInCheck(_check(0)), 0.0);
        });

        test("an occurrence on the end date is paid", () {
            final expense = _expense(start: day(-60), endDate: day(-30));

            expect(expense.makeRecent(today: today), closeTo(200.0, 1e-9));
        });

        test("reopening long after the end doesn't keep paying", () {
            // Weekly: -365, -358, -351; ended at -351.
            final expense = _expense(amount: 10.0, start: day(-365), frequency: 7, endDate: day(-351));

            expect(expense.makeRecent(today: today), closeTo(30.0, 1e-9));
            expect(expense.makeRecent(today: today), 0.0);
        });

        test("a future end date behaves as unbounded until then", () {
            final expense = _expense(start: day(-60), endDate: day(100));

            expect(expense.makeRecent(today: today), closeTo(200.0, 1e-9));
            expect(expense.hasEnded, isFalse);
        });

        test("an occurrence after the end date isn't due", () {
            final expense = _expense(amount: 15.0, start: day(5), endDate: day(2));

            expect(expense.amountDueInCheck(_check(0)), 0.0);
        });

        test("an occurrence on the end date is due", () {
            final expense = _expense(amount: 15.0, start: day(5), endDate: day(5));

            expect(expense.amountDueInCheck(_check(0)), closeTo(15.0, 1e-9));
        });

        test("a daily expense ending mid-check counts only through the end date", () {
            final expense = _expense(amount: 5.0, start: today, frequency: 1, endDate: day(2));

            expect(expense.amountDueInCheck(_check(0)), closeTo(15.0, 1e-9)); // today, +1, +2
        });
    });

    group("the payday rule", () {
        test("the current check includes an expense due on its closing payday", () {
            final expense = _expense(amount: 5.0, start: today, frequency: 1);

            expect(expense.amountDueInCheck(_check(0)), closeTo(75.0, 1e-9)); // days 0..14 = 15
        });

        test("the next check doesn't count the previous payday again", () {
            final expense = _expense(amount: 5.0, start: today, frequency: 1);

            expect(expense.amountDueInCheck(_check(1)), closeTo(70.0, 1e-9)); // days 15..28 = 14
        });

        test("a weekly expense on a biweekly payday is counted once per occurrence", () {
            final expense = _expense(amount: 40.0, start: today, frequency: 7);

            expect(expense.amountDueInCheck(_check(0)), closeTo(120.0, 1e-9)); // 0, 7, 14
            expect(expense.amountDueInCheck(_check(1)), closeTo(80.0, 1e-9)); // 21, 28
            expect(expense.amountDueInCheck(_check(2)), closeTo(80.0, 1e-9)); // 35, 42
        });

        test("rent due on payday counts in the check that payday closes, not the next", () {
            final rent = _expense(amount: 1000.0, start: day(14), frequency: 1, unit: FrequencyUnit.monthly);

            expect(rent.amountDueInCheck(_check(0)), closeTo(1000.0, 1e-9));
            expect(rent.amountDueInCheck(_check(1)), 0.0);
        });

        test("a monthly expense uses calendar months", () {
            // Jan 31, Feb 28, Mar 31 -- all inside one long projected check.
            final expense = _expense(amount: 10.0, start: DateTime(2027, 1, 31), frequency: 1, unit: FrequencyUnit.monthly);
            final check = CheckWindow(index: 1, start: DateTime(2027, 1, 30), end: DateTime(2027, 3, 31), today: today);

            expect(expense.amountDueInCheck(check), closeTo(30.0, 1e-9));
        });
    });

    group("toCheck (what a row shows)", () {
        test("shows the amount due and the first occurrence in the check", () {
            final expense = _expense(amount: 5.0, start: today, frequency: 1);
            expense.toCheck(_check(1));

            expect(expense.periodAmount, closeTo(70.0, 1e-9));
            expect(expense.shownDate, day(15));
        });

        test("shows 0 when nothing is due in the check", () {
            final expense = _expense(start: DateTime(2026, 1, 1), frequency: 1, unit: FrequencyUnit.yearly);
            expense.skipToNextDueDate(today: today);
            expense.toCheck(_check(0));

            expect(expense.periodAmount, 0.0);
            expect(expense.shownDate, DateTime(2027, 1, 1));
        });
    });

    group("numOccurrencesInPeriod (half-open [start, end))", () {
        test("daily expense recurs once per day", () {
            final expense = _expense(start: DateTime(2026, 1, 1), frequency: 1);
            expect(expense.numOccurrencesInPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 8)), 7);
        });

        test("weekly expense counts weeks, not days", () {
            final expense = _expense(start: DateTime(2026, 1, 1), frequency: 1, unit: FrequencyUnit.weekly);
            // Jan 1, 8, 15, 22 -- Jan 29 is the excluded end
            expect(expense.numOccurrencesInPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 29)), 4);
        });

        test("monthly expense due on the 31st clamps for shorter months", () {
            final expense = _expense(start: DateTime(2026, 1, 31), frequency: 1, unit: FrequencyUnit.monthly);
            expect(expense.numOccurrencesInPeriod(DateTime(2026, 1, 1), DateTime(2026, 2, 1)), 1);
            expect(expense.numOccurrencesInPeriod(DateTime(2026, 2, 1), DateTime(2026, 3, 1)), 1);
        });

        test("period with no occurrences returns 0", () {
            final expense = _expense(start: DateTime(2026, 1, 1), frequency: 1, unit: FrequencyUnit.yearly);
            expect(expense.numOccurrencesInPeriod(DateTime(2026, 2, 1), DateTime(2026, 3, 1)), 0);
        });
    });
}
