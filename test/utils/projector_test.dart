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
    });
}