// Run with flutter test test/navigation_items/income_streams/income_stream_model_test.dart
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
}

IncomeStreamModel _makeIncomeStream({
    String name = "Test Income",
    double amount = 100.0,
    required DateTime startDate,
    required int frequency,
    required FrequencyUnit frequencyUnits,
    DateTime? currentDate,
    bool isActive = false,
}) {
    return IncomeStreamModel(
        name: name,
        amount: amount,
        startDate: startDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
        currentDate: currentDate,
        isActive: isActive,
    );
}

void main() {
    final today = _today();

    group("makeRecent on construction", () {
        test("stream starting exactly today has no catch up and projects to the next period", () {
            final stream = _makeIncomeStream(
                startDate: today,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );
            expect(stream.currentDate, today);
            expect(stream.catchUpAmount, 0.0);
            expect(stream.nextDate, today.add(const Duration(days: 10)));
            // No occurrence strictly between today and today + 10 every 10 days
            expect(stream.periodAmount, 0.0);
        });

        test("stream that started exactly one period ago credits that check immediately", () {
            final stream = _makeIncomeStream(
                startDate: today.subtract(const Duration(days: 10)),
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );
            // 1 occurrence
            expect(stream.catchUpAmount, closeTo(100.0, 1e-9));
            expect(stream.currentDate, today);
            expect(stream.nextDate, today.add(const Duration(days: 10)));
        });

        test("reopening between paydays snaps currentDate to the most recent past check", () {
            // Occurrences relative to startDate (today - 25): -25, -15, -5, +5, ...
            final stream = _makeIncomeStream(
                startDate: today.subtract(const Duration(days: 25)),
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );
            // Most recent check on/before today is today - 5; next is today + 5
            expect(stream.currentDate, today.subtract(const Duration(days: 5)));
            expect(stream.nextDate, today.add(const Duration(days: 5)));
            // Catch up window (today - 25, today] contains today - 15 and today - 5, so 2 checks
            expect(stream.catchUpAmount, closeTo(200.0, 1e-9));
        });

        test("reopening after multiple missed periods credits every missed check", () {
            final stream = _makeIncomeStream(
                startDate: today.subtract(const Duration(days: 40)),
                currentDate: today.subtract(const Duration(days: 30)),
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );
            // Occurrences in (today - 30, today]: today - 20, today - 10, today, so 3 checks.
            expect(stream.catchUpAmount, closeTo(300.0, 1e-9));
            expect(stream.currentDate, today);
            expect(stream.nextDate, today.add(const Duration(days: 10)));
        });

        test("stream starting in the future has no catch up", () {
            final stream = _makeIncomeStream(
                startDate: today.add(const Duration(days: 10)),
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );
            expect(stream.catchUpAmount, 0.0);
        });
    });

    group("makeRecent called again", () {
        test("calling it twice without time passing produces no additional catch up", () {
            final stream = _makeIncomeStream(
                startDate: today.subtract(const Duration(days: 40)),
                currentDate: today.subtract(const Duration(days: 30)),
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );
            expect(stream.catchUpAmount, closeTo(300.0, 1e-9));

            stream.makeRecent();

            expect(stream.catchUpAmount, closeTo(0.0, 1e-9));
            expect(stream.currentDate, today);
        });
    });

    group("toPeriod", () {
        test("periodAmount reflects occurrences strictly within (start, end)", () {
            final stream = _makeIncomeStream(
                startDate: today,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );
            stream.toPeriod(today, today.add(const Duration(days: 30)));

            expect(stream.periodAmount, closeTo(200.0, 1e-9));
        });

        test("periodAmount is 0 when nothing falls inside the window", () {
            final stream = _makeIncomeStream(
                startDate: today,
                frequency: 10,
                frequencyUnits: FrequencyUnit.daily,
            );
            stream.toPeriod(today, today.add(const Duration(days: 10)));

            expect(stream.periodAmount, 0.0);
        });
    });

    group("advancePeriod", () {
        test("returns the [start, end) of the next period after the given date", () {
            final stream = _makeIncomeStream(
                startDate: today,
                frequency: 7,
                frequencyUnits: FrequencyUnit.daily,
            );
            final (start, end) = stream.advancePeriod(today);
            expect(start, today.add(const Duration(days: 7)));
            expect(end, today.add(const Duration(days: 14)));
        });
    });

    group("displayString", () {
        test("describes the frequency in plain language", () {
            final stream = _makeIncomeStream(
                startDate: today,
                frequency: 2,
                frequencyUnits: FrequencyUnit.weekly,
            );
            expect(stream.displayString(), "Every 2 weeks");
        });

        test("pluralizes only when the frequency count is greater than 1", () {
            final stream = _makeIncomeStream(
                startDate: today,
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
            );
            expect(stream.displayString(), "Every 1 week");
        });
    });
}
