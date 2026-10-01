// Run with flutter test test/utils/projector_test.dart
import 'package:bujit/utils/projector.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';


Projector _makeProjector({
    required DateTime dueDate,
    required int frequency,
    required FrequencyUnit frequencyUnits,
}) {
    return Projector(
        baseDate: dueDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
    );
}

void main() {
    group("frequencyToDays", () {
        test("daily is just the frequency count in days", () {
            final projector = _makeProjector(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.daily,
            );
            expect(projector.frequencyToDays(5, FrequencyUnit.daily, DateTime(2026, 1, 1)), 5);
        });

        test("weekly multiplies by 7", () {
            final projector = _makeProjector(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
            );
            expect(projector.frequencyToDays(2, FrequencyUnit.weekly, DateTime(2026, 1, 1)), 14);
        });

        test("biweekly multiplies by 14", () {
            final projector = _makeProjector(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.biweekly,
            );
            expect(projector.frequencyToDays(1, FrequencyUnit.biweekly, DateTime(2026, 1, 1)), 14);
        });

        test("monthly counts the real number of days in that month, not a flat 30", () {
            final projector = _makeProjector(
                dueDate: DateTime(2026, 2, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.monthly,
            );
            // February 2026 is not a leap year
            expect(projector.frequencyToDays(1, FrequencyUnit.monthly, DateTime(2026, 2, 1)), 28);
        });

        test("yearly counts 366 days across a leap day, not a flat 365", () {
            final projector = _makeProjector(
                dueDate: DateTime(2024, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.yearly,
            );
            // 2024 is a leap year
            expect(projector.frequencyToDays(1, FrequencyUnit.yearly, DateTime(2024, 1, 1)), 366);
        });

        test("monthly across the daylight-saving change is still a whole number of days", () {
            final projector = _makeProjector(
                dueDate: DateTime(2026, 10, 15),
                frequency: 1,
                frequencyUnits: FrequencyUnit.monthly,
            );
            expect(projector.frequencyToDays(1, FrequencyUnit.monthly, DateTime(2026, 10, 15)), 31);
        });
    });

    group("month-end and leap-day anchoring", () {
        test("a monthly date on the 31st returns to the 31st after short months", () {
            final projector = _makeProjector(
                dueDate: DateTime(2027, 1, 31),
                frequency: 1,
                frequencyUnits: FrequencyUnit.monthly,
            );
            expect(projector.occurrenceDate(1), DateTime(2027, 2, 28));
            expect(projector.occurrenceDate(2), DateTime(2027, 3, 31));
            expect(projector.occurrenceDate(3), DateTime(2027, 4, 30));
            expect(projector.occurrenceDate(4), DateTime(2027, 5, 31));
        });

        test("a yearly Feb 29 date falls on Feb 28, then returns to Feb 29 in leap years", () {
            final projector = _makeProjector(
                dueDate: DateTime(2028, 2, 29),
                frequency: 1,
                frequencyUnits: FrequencyUnit.yearly,
            );
            expect(projector.occurrenceDate(1), DateTime(2029, 2, 28));
            expect(projector.occurrenceDate(3), DateTime(2031, 2, 28));
            expect(projector.occurrenceDate(4), DateTime(2032, 2, 29));
        });
    });

    group("daylight saving", () {
        test("daily occurrences across the change stay on midnight", () {
            // US daylight saving ends Nov 1, 2026.
            final projector = _makeProjector(
                dueDate: DateTime(2026, 10, 25),
                frequency: 1,
                frequencyUnits: FrequencyUnit.daily,
            );
            final DateTime tenth = projector.occurrenceDate(10);
            expect(tenth, DateTime(2026, 11, 4));
            expect(tenth.hour, 0);
        });

        test("counting across the change counts every day once", () {
            final projector = _makeProjector(
                dueDate: DateTime(2026, 10, 25),
                frequency: 1,
                frequencyUnits: FrequencyUnit.daily,
            );
            expect(projector.countBetween(DateTime(2026, 10, 25), DateTime(2026, 11, 7)), 14);
        });
    });

    group("queries", () {
        test("countBetween includes both ends", () {
            final projector = _makeProjector(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
            );
            // Jan 1, 8, 15
            expect(projector.countBetween(DateTime(2026, 1, 1), DateTime(2026, 1, 15)), 3);
        });

        test("firstOnOrAfter and lastOnOrBefore find the neighbouring occurrences", () {
            final projector = _makeProjector(
                dueDate: DateTime(2026, 1, 1),
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
            );
            expect(projector.firstOnOrAfter(DateTime(2026, 1, 9)), DateTime(2026, 1, 15));
            expect(projector.firstOnOrAfter(DateTime(2026, 1, 8)), DateTime(2026, 1, 8));
            expect(projector.lastOnOrBefore(DateTime(2026, 1, 14)), DateTime(2026, 1, 8));
            expect(projector.lastOnOrBefore(DateTime(2025, 12, 31)), isNull);
        });

        test("nothing counts before the base date", () {
            final projector = _makeProjector(
                dueDate: DateTime(2026, 1, 15),
                frequency: 1,
                frequencyUnits: FrequencyUnit.weekly,
            );
            expect(projector.countBetween(DateTime(2025, 12, 1), DateTime(2026, 1, 14)), 0);
        });

        test("a frequency of 0 is a one-off that never comes again", () {
            final projector = _makeProjector(
                dueDate: DateTime(2026, 1, 1),
                frequency: 0,
                frequencyUnits: FrequencyUnit.monthly,
            );
            expect(projector.countBetween(DateTime(2026, 1, 1), DateTime(2030, 1, 1)), 1);
            expect(projector.firstOnOrAfter(DateTime(2026, 1, 2)), Projector.never);
        });
    });
}
