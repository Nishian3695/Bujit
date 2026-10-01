// Run with flutter test test/navigation_items/income_streams/income_stream_model_test.dart
//
// Paydays and amounts for a single stream. Crediting paychecks to the balance
// is BalanceModel's job -- see balance_model_test.dart's makeRecent group.
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);
DateTime day(int offset) => addDays(today, offset);

IncomeStreamModel _stream({
    double amount = 100.0,
    required DateTime start,
    int frequency = 10,
    FrequencyUnit unit = FrequencyUnit.daily,
}) {
    return IncomeStreamModel(
        name: "Test Income",
        amount: amount,
        startDate: start,
        frequency: frequency,
        frequencyUnits: unit,
    );
}

void main() {
    group("paydays and amounts", () {
        test("amountInPeriod counts paychecks in [start, end)", () {
            final stream = _stream(start: today);

            expect(stream.amountInPeriod(today, day(30)), closeTo(300.0, 1e-9)); // 0, 10, 20
            expect(stream.amountInPeriod(day(1), day(10)), 0.0);
        });

        test("amountBetween counts paychecks in [from, to], including the starting date", () {
            final stream = _stream(start: today);

            expect(stream.amountBetween(today, day(20)), closeTo(300.0, 1e-9)); // 0, 10, 20
            expect(stream.amountBetween(day(1), day(9)), 0.0);
        });

        test("nothing counts before the starting date", () {
            final stream = _stream(start: day(10));

            expect(stream.amountBetween(day(-60), day(9)), 0.0);
        });

        test("paydayOnOrBefore and paydayAfter find the neighbouring paydays", () {
            final stream = _stream(start: day(-25));

            expect(stream.paydayOnOrBefore(today), day(-5));
            expect(stream.paydayAfter(today), day(5));
            expect(stream.paydayAfter(day(5)), day(15));
            expect(stream.paydayOnOrBefore(day(-30)), isNull);
        });

        test("monthly paydays on the 31st land on month-ends", () {
            final stream = _stream(start: DateTime(2026, 1, 31), frequency: 1, unit: FrequencyUnit.monthly);

            // Feb 28, Mar 31, Apr 30
            expect(stream.amountBetween(DateTime(2026, 2, 1), DateTime(2026, 5, 1)), closeTo(300.0, 1e-9));
            expect(stream.paydayAfter(DateTime(2026, 4, 30)), DateTime(2026, 5, 31));
        });
    });

    group("advancePeriod", () {
        test("returns the [start, end) of the next period after the given date", () {
            final stream = _stream(start: today, frequency: 7);
            final (start, end) = stream.advancePeriod(today);
            expect(start, day(7));
            expect(end, day(14));
        });
    });

    group("displayString", () {
        test("describes the frequency in plain language", () {
            final stream = _stream(start: today, frequency: 2, unit: FrequencyUnit.weekly);
            expect(stream.displayString(), "Every 2 weeks");
        });

        test("pluralizes only when the frequency count is greater than 1", () {
            final stream = _stream(start: today, frequency: 1, unit: FrequencyUnit.weekly);
            expect(stream.displayString(), "Every 1 week");
        });
    });
}
