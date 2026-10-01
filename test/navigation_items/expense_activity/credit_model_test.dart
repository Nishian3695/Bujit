// Run with flutter test test/navigation_items/expense_activity/credit_model_test.dart
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
}

CreditModel _makeCreditCard({
    String name = "Test Credit",
    double amount = 100.0,
    required DateTime dueDate,
    required int frequency,
    required FrequencyUnit frequencyUnits,
    required double creditLimit,
}) {
    return CreditModel(
        name: name,
        amount: amount,
        startDate: dueDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
        creditLimit: creditLimit,
    );
}

void main() {
    final today = _today();

    group("numOccurrencesInPeriod", () {
        test("daily creditCard recurs once per day", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.daily,
                creditLimit: 1000.0
            );
            // [Jan 1, Jan 8) has Jan 1..Jan 7 -- 7 occurrences
            expect(
                creditCard.numOccurrencesInPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 8)),
                7,
            );
        });

        test("weekly creditCard counts weeks, not days", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
                creditLimit: 1000.0
            );
            // Occurrences: Jan 1, 8, 15, 22, 29 -- [Jan 1, Jan 29) has the first 4.
            expect(
                creditCard.numOccurrencesInPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 29)),
                4,
            );
        });

        test("monthly creditCard due on the 31st clamps for shorter months", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 31),
                frequency: 1,
                frequencyUnits: FrequencyUnit.monthly,
                creditLimit: 1000.0,
            );
            // Only the Jan 31 occurrence falls in [Jan 1, Feb 1)
            expect(
                creditCard.numOccurrencesInPeriod(DateTime(2026, 1, 1), DateTime(2026, 2, 1)),
                1,
            );
            // The clamped Feb 28 occurrence falls in [Feb 1, Mar 1)
            expect(
                creditCard.numOccurrencesInPeriod(DateTime(2026, 2, 1), DateTime(2026, 3, 1)),
                1,
            );
        });

        test("period with no occurrences returns 0", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.yearly,
                creditLimit: 1000.0,
            );
            // Next yearly occurrence after Jan 1 2026 is Jan 1 2027
            expect(
                creditCard.numOccurrencesInPeriod(DateTime(2026, 2, 1), DateTime(2026, 3, 1)),
                0,
            );
        });
    });

    group("makeRecent", () {
        test("credit card due exactly today has no catch-up and dueDate stays put", () {
            final creditCard = _makeCreditCard(
                dueDate: today,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
                creditLimit: 1000.0,
            );

            expect(creditCard.catchUpAmount, 0.0);
            expect(creditCard.currentDueDate, today);
            expect(creditCard.periodAmount, creditCard.amount);
        });

        test("credit card due one period ago is caught up and dueDate advances", () {
            final creditCard = _makeCreditCard(
                dueDate: today.subtract(const Duration(days: 10)),
                amount: 50.0,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
                creditLimit: 1000.0,
            );

            // [oldDueDate, today) contains just oldDueDate itself
            expect(creditCard.catchUpAmount, closeTo(50.0, 1e-9));
            expect(creditCard.currentDueDate, today);
        });

        test("reopening after multiple missed periods catches up every missed due date", () {
            final creditCard = _makeCreditCard(
                dueDate: today.subtract(const Duration(days: 40)),
                amount: 10.0,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
                creditLimit: 1000.0,
            );

            // [today-40, today) contains 4 occurrences
            expect(creditCard.catchUpAmount, closeTo(40.0, 1e-9));
            expect(creditCard.currentDueDate, today);
        });

        test("calling makeRecent again without time passing produces no additional catch up", () {
            final creditCard = _makeCreditCard(
                dueDate: today.subtract(const Duration(days: 40)),
                amount: 10.0,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
                creditLimit: 1000.0,
            );

            expect(creditCard.catchUpAmount, closeTo(40.0, 1e-9));

            creditCard.makeRecent();
            expect(creditCard.catchUpAmount, 0.0);
            expect(creditCard.currentDueDate, today);
        });

        test("credit card due in the future has no catch up", () {
            final creditCard = _makeCreditCard(
                dueDate: today.add(const Duration(days: 10)),
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
                creditLimit: 1000.0,
            );

            expect(creditCard.catchUpAmount, 0.0);
            expect(creditCard.currentDueDate, today.add(const Duration(days: 10)));
        });
    });

    // CreditModel's toPeriod is binary (unlike ExpenseModel)
    group("toPeriod", () {
        test("periodAmount is the full amount when the due date falls in the period", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 1),
                amount: 50.0,
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
                creditLimit: 1000.0,
            );
            creditCard.toPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 29));

            expect(creditCard.periodAmount, 50.0);
        });

        test("periodAmount is 0 when the due date doesn't fall in the period", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 1),
                amount: 50.0,
                frequency: 1,
                frequencyUnits: FrequencyUnit.yearly,
                creditLimit: 1000.0,
            );
            creditCard.toPeriod(DateTime(2026, 2, 1), DateTime(2026, 3, 1));

            expect(creditCard.periodAmount, 0.0);
        });

        test("shownDate is the first occurrence on or after the period start", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
                creditLimit: 1000.0,
            );
            creditCard.toPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 29));

            expect(creditCard.shownDate, DateTime(2026, 1, 1));
        });

        test("catchUpAmount is a flat amount once the due date has passed, not per-occurrence", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 1),
                amount: 50.0,
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
                creditLimit: 1000.0,
            );
            creditCard.toPeriod(DateTime(2026, 1, 8), DateTime(2026, 1, 29));

            expect(creditCard.catchUpAmount, 50.0);
        });
    });

    group("creditUtilization", () {
        test("is 0 when the due date doesn't fall in the current period", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.yearly,
                creditLimit: 1000,
            );
            creditCard.toPeriod(DateTime(2026, 2, 1), DateTime(2026, 3, 1));
            expect(creditCard.creditUtilization, 0.0);
        });

        test("is periodAmount / creditLimit for a creditCard", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 1),
                amount: 250.0,
                frequency: 1,
                frequencyUnits: FrequencyUnit.monthly,
                creditLimit: 1000,
            );
            creditCard.toPeriod(DateTime(2026, 1, 1), DateTime(2026, 2, 1));
            expect(creditCard.creditUtilization, 0.25);
        });

        test("is 0 for a credit card with no creditLimit set", () {
            final creditCard = _makeCreditCard(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.monthly,
                creditLimit: 0.0,
            );
            creditCard.toPeriod(DateTime(2026, 1, 1), DateTime(2026, 2, 1));
            expect(creditCard.creditUtilization, 0.0);
        });
    });

    test("category defaults to credit cards when not specified", () {
        final creditCard = CreditModel(
            name: "Unlabeled",
            amount: 10.0,
            startDate: DateTime(2026, 1, 1),
            frequency: 1,
            frequencyUnits: FrequencyUnit.monthly,
            creditLimit: 1000.0,
        );
        expect(creditCard.category, "Credit Cards");
    });
}
