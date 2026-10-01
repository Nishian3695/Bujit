// Run with flutter test test/navigation_items/income_streams/income_stream_model_test.dart
//
// Ported from the Java app's pay-period roll-over tests (FinancialCalcTest's
// rollCheckDateForward): each paycheck is credited exactly once, on or after
// its payday, and monthly paydays don't drift.
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
    DateTime? currentDate,
}) {
    return IncomeStreamModel(
        name: "Test Income",
        amount: amount,
        startDate: start,
        frequency: frequency,
        frequencyUnits: unit,
        currentDate: currentDate,
    );
}

void main() {
    group("makeRecent (crediting paychecks)", () {
        test("a stream starting today credits nothing: that paycheck is already in the balance", () {
            final stream = _stream(start: today);

            expect(stream.makeRecent(today: today), 0.0);
            expect(stream.currentDate, today);
            expect(stream.nextDate, day(10));
        });

        test("a paycheck landing today is credited", () {
            final stream = _stream(start: day(-10));

            expect(stream.makeRecent(today: today), closeTo(100.0, 1e-9));
            expect(stream.currentDate, today);
            expect(stream.nextDate, day(10));
        });

        test("between paydays it credits what arrived and points at the latest payday", () {
            // Paydays -25, -15, -5, +5
            final stream = _stream(start: day(-25));

            expect(stream.makeRecent(today: today), closeTo(200.0, 1e-9));
            expect(stream.currentDate, day(-5));
            expect(stream.nextDate, day(5));
        });

        test("reopening after several missed paydays credits each one once", () {
            final stream = _stream(start: day(-40), currentDate: day(-30));

            expect(stream.makeRecent(today: today), closeTo(300.0, 1e-9)); // -20, -10, 0
            expect(stream.currentDate, today);
        });

        test("calling it again on the same day credits nothing more", () {
            final stream = _stream(start: day(-40), currentDate: day(-30));
            stream.makeRecent(today: today);

            expect(stream.makeRecent(today: today), 0.0);
        });

        test("a stream starting in the future credits nothing", () {
            final stream = _stream(start: day(10));

            expect(stream.makeRecent(today: today), 0.0);
            expect(stream.currentDate, day(10));
        });

        test("monthly paydays on the 31st land on month-ends", () {
            final stream = _stream(start: DateTime(2026, 1, 31), frequency: 1, unit: FrequencyUnit.monthly);

            // Feb 28, Mar 31, Apr 30
            expect(stream.makeRecent(today: DateTime(2026, 5, 1)), closeTo(300.0, 1e-9));
            expect(stream.currentDate, DateTime(2026, 4, 30));
            expect(stream.nextDate, DateTime(2026, 5, 31));
        });
    });

    group("paydays and amounts", () {
        test("amountInPeriod counts paychecks in [start, end)", () {
            final stream = _stream(start: today);

            expect(stream.amountInPeriod(today, day(30)), closeTo(300.0, 1e-9)); // 0, 10, 20
            expect(stream.amountInPeriod(day(1), day(10)), 0.0);
        });

        test("paydayOnOrBefore and paydayAfter find the neighbouring paydays", () {
            final stream = _stream(start: day(-25));

            expect(stream.paydayOnOrBefore(today), day(-5));
            expect(stream.paydayAfter(today), day(5));
            expect(stream.paydayAfter(day(5)), day(15));
            expect(stream.paydayOnOrBefore(day(-30)), isNull);
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
