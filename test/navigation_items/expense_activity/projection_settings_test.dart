// Projection Settings: projected checks with a chosen stream and period.
//
// today = Thu Oct 1, 2026. Job pays $2000 every 2 weeks from Sep 24 (paydays
// Oct 8, Oct 22, ...), so the current check is [Sep 24, Oct 8].
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/expense_activity/projection_settings.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);

late BalanceModel balance;
late IncomeStreamModel job;
late IncomeStreamModel side;

void main() {
    setUp(() {
        balance = BalanceModel(currentBalance: 1000.0, lastUpdated: today);
        job = IncomeStreamModel(name: "Job", amount: 2000.0, startDate: DateTime(2026, 9, 24),
            frequency: 2, frequencyUnits: FrequencyUnit.weekly);
        side = IncomeStreamModel(name: "Side", amount: 500.0, startDate: DateTime(2026, 9, 1),
            frequency: 1, frequencyUnits: FrequencyUnit.monthly);
        balance.incomeStreams.addAll([job, side]);
        balance.activeIncome = job;
        balance.expenses.add(ExpenseModel(name: "Phone", amount: 50.0, startDate: DateTime(2026, 10, 1),
            frequency: 1, frequencyUnits: FrequencyUnit.weekly));
    });

    test("without settings, checks follow the active stream's paydays and every stream's pay", () {
        expect(balance.window(1, today: today).start, DateTime(2026, 10, 8));
        expect(balance.window(1, today: today).end, DateTime(2026, 10, 22));
        expect(balance.check(1, today: today).income, 2000.0); // Job Oct 8 (Side pays Nov 1)
    });

    test("a custom period: projected checks run on from the end of the current check", () {
        balance.projection = ProjectionSettings(stream: job, frequency: 1, unit: FrequencyUnit.monthly);

        // The current check is untouched.
        expect(balance.window(0, today: today).start, DateTime(2026, 9, 24));
        expect(balance.window(0, today: today).end, DateTime(2026, 10, 8));
        // Then one month at a time, with no gap or overlap.
        expect(balance.window(1, today: today).start, DateTime(2026, 10, 8));
        expect(balance.window(1, today: today).end, DateTime(2026, 11, 8));
        expect(balance.window(2, today: today).start, DateTime(2026, 11, 8));
        expect(balance.window(2, today: today).end, DateTime(2026, 12, 8));
        // Weekly Phone, Oct 9 - Nov 8: Oct 15, 22, 29, Nov 5 (Oct 8 was in the current check).
        expect(balance.check(1, today: today).expensesDue, 200.0);
    });

    test("a custom period's pay is the stream's scaled by days", () {
        final settings = ProjectionSettings(stream: job, frequency: 1, unit: FrequencyUnit.monthly);
        balance.projection = settings;

        // October 1 -> November 1 is 31 days; Job's period is 14.
        expect(settings.amountPerCheck(today: today), closeTo(2000.0 * 31 / 14, 1e-9));
        expect(balance.check(1, today: today).income, closeTo(2000.0 * 31 / 14, 1e-9));
        // Opens with its own pay in, after the current check's Phone (Oct 1 and Oct 8).
        expect(balance.check(1, today: today).startBalance, closeTo(1000.0 - 100.0 + 2000.0 * 31 / 14, 1e-9));
    });

    test("another stream on its own period: its pay, every check", () {
        balance.projection = ProjectionSettings.streamPeriod(side);

        expect(balance.projection!.isCustomPeriod, isFalse);
        expect(balance.window(1, today: today).end, DateTime(2026, 11, 8));
        expect(balance.check(1, today: today).income, 500.0);
        expect(balance.check(2, today: today).nextCheckIncome, 500.0);
        expect(balance.projection!.describe(), "Side · every 1 month");
    });

    test("deleting or editing the stream drops the settings", () {
        balance.projection = ProjectionSettings.streamPeriod(side);
        balance.incomeStreams.remove(side);

        expect(balance.projection, isNull);
        expect(balance.window(1, today: today).end, DateTime(2026, 10, 22));
    });

    test("the current check and catching up ignore the settings", () {
        balance.projection = ProjectionSettings(stream: side, frequency: 3, unit: FrequencyUnit.daily);

        expect(balance.check(0, today: today).income, 0.0);
        expect(balance.makeRecent(today: DateTime(2026, 10, 9)), 2000.0 - 2 * 50.0); // Oct 8 pay; Oct 1, 8 phone
    });
}
