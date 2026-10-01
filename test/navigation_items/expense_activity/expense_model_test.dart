// Run with flutter test test/navigation_items/expense_activity/expense_model_test.dart
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
}

ExpenseModel _makeExpense({
    String name = "Test Expense",
    double amount = 100.0,
    required DateTime dueDate,
    required int frequency,
    required FrequencyUnit frequencyUnits,
}) {
    return ExpenseModel(
        name: name,
        amount: amount,
        startDate: dueDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
    );
}

void main() {
    final today = _today();

    group("numOccurrencesInPeriod", () {
        test("daily expense recurs once per day", () {
            final expense = _makeExpense(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.daily,
            );
            // [Jan 1, Jan 8) has Jan 1..Jan 7 -- 7 occurrences
            expect(
                expense.numOccurrencesInPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 8)),
                7,
            );
        });

        test("weekly expense counts weeks, not days", () {
            final expense = _makeExpense(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
            );
            // Occurrences: Jan 1, 8, 15, 22, 29 -- [Jan 1, Jan 29) has the first 4.
            expect(
                expense.numOccurrencesInPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 29)),
                4,
            );
        });

        test("monthly expense due on the 31st clamps for shorter months", () {
            final expense = _makeExpense(
                dueDate: DateTime(2026, 1, 31),
                frequency: 1,
                frequencyUnits: FrequencyUnit.monthly,
            );
            // Only the Jan 31 occurrence falls in [Jan 1, Feb 1).
            expect(
                expense.numOccurrencesInPeriod(DateTime(2026, 1, 1), DateTime(2026, 2, 1)),
                1,
            );
            // The clamped Feb 28 occurrence falls in [Feb 1, Mar 1)
            expect(
                expense.numOccurrencesInPeriod(DateTime(2026, 2, 1), DateTime(2026, 3, 1)),
                1,
            );
        });

        test("period with no occurrences returns 0", () {
            final expense = _makeExpense(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.yearly,
            );
            // Next yearly occurrence after Jan 1 2026 is Jan 1 2027
            expect(
                expense.numOccurrencesInPeriod(DateTime(2026, 2, 1), DateTime(2026, 3, 1)),
                0,
            );
        });
    });

    group("toPeriod", () {
        test("sets periodAmount and shownDate from the period", () {
            final expense = _makeExpense(
                dueDate: DateTime(2026, 1, 1),
                amount: 50.0,
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
            );
            expense.toPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 29));

            expect(expense.periodAmount, 200.0); // 4 occurrences * $50
        });

        test("shownDate is the first occurrence on or after the period start", () {
            final expense = _makeExpense(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
            );
            expense.toPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 29));

            expect(expense.shownDate, DateTime(2026, 1, 1));
        });

        test("periodAmount is 0 when no occurrence falls in the period", () {
            final expense = _makeExpense(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.yearly,
            );
            expense.toPeriod(DateTime(2026, 2, 1), DateTime(2026, 3, 1));

            expect(expense.periodAmount, 0.0);
        });
    });

    group("makeRecent", () {
        test("expense due exactly today has no catch-up and dueDate stays put", () {
            final expense = _makeExpense(
                dueDate: today,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );

            expect(expense.catchUpAmount, 0.0);
            expect(expense.currentDueDate, today);
            expect(expense.periodAmount, expense.amount);
        });

        test("expense due one period ago is caught up and dueDate advances", () {
            final expense = _makeExpense(
                dueDate: today.subtract(const Duration(days: 10)),
                amount: 50.0,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );

            // [oldStartDate, today) contains just oldStartDate itself
            expect(expense.catchUpAmount, closeTo(50.0, 1e-9));
            expect(expense.currentDueDate, today);
        });

        test("reopening after multiple missed periods catches up every missed due date", () {
            final expense = _makeExpense(
                dueDate: today.subtract(const Duration(days: 40)),
                amount: 10.0,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );

            // [today-40, today) contains 4 occurrences
            expect(expense.catchUpAmount, closeTo(40.0, 1e-9));
            expect(expense.currentDueDate, today);
        });

        test("calling makeRecent again without time passing produces no additional catch up", () {
            final expense = _makeExpense(
                dueDate: today.subtract(const Duration(days: 40)),
                amount: 10.0,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );

            expect(expense.catchUpAmount, closeTo(40.0, 1e-9));

            expense.makeRecent();
            expect(expense.catchUpAmount, 0.0);
            expect(expense.currentDueDate, today);
        });

        test("expense due in the future has no catch up", () {
            final expense = _makeExpense(
                dueDate: today.add(const Duration(days: 10)),
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );

            expect(expense.catchUpAmount, 0.0);
            expect(expense.currentDueDate, today.add(const Duration(days: 10)));
        });
    });
}
