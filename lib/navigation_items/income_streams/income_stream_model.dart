// Class to represent an income stream model
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:bujit/utils/projector.dart';

class IncomeStreamModel {
    int? id; // Row id once persisted to the database
    String name; // Name of the income stream
    double amount; // Amount of the income stream
    // First payday. Also anchors the schedule's day of month (a paycheck on
    // the 31st lands on the 28th/29th in February, then back on the 31st).
    // Crediting paychecks to the balance is BalanceModel's job (see makeRecent).
    DateTime startDate;
    int frequency; // Frequency
    FrequencyUnit frequencyUnits; // Tag to track frequency
    // The two paydays of a twice-a-month (semimonthly) stream; null for other units.
    MonthDays? monthDays;
    bool isActive; // Whether this stream sets the pay periods (see BalanceModel)
    String? googleTaskId; // Its task in Google Tasks, once synced (see TasksSync)
    double periodAmount = 0.00; // Amount for the check currently on screen

    IncomeStreamModel({
        this.id,
        required this.name,
        required this.amount,
        required DateTime startDate,
        required this.frequency,
        required this.frequencyUnits,
        this.isActive = false, // Default to inactive
        this.googleTaskId,
        this.monthDays,
    }) : startDate = dateOnly(startDate) {
        // Twice a month, the first payday must be one of the two days: the first
        // one on or after the chosen date.
        if (frequencyUnits == FrequencyUnit.semimonthly) {
            this.startDate = _projector.firstOnOrAfter(this.startDate);
        }
    }

    // Built on demand so it always reflects the current startDate/frequency.
    // Occurrence 0 is startDate itself.
    Projector get _projector => Projector(
        baseDate: startDate,
        originDate: startDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
        monthDays: monthDays,
    );

    // Methods

    // Human-readable string representation of the income stream
    String displayString() => describeFrequency(frequency, frequencyUnits, days: monthDays);

    // Number of paydays from [from] through [to], both inclusive.
    int occurrencesBetween(DateTime from, DateTime to) {
        final DateTime lo = maxDate(dateOnly(from), startDate);
        final DateTime hi = dateOnly(to);
        if (lo.isAfter(hi)) return 0;
        return _projector.countBetween(lo, hi);
    }

    // Get number of occurrences (paychecks) in the half-open period [start, end)
    int numOccurrencesInPeriod(DateTime start, DateTime end) {
        return occurrencesBetween(start, addDays(end, -1));
    }

    // Total paid in the half-open period [start, end)
    double amountInPeriod(DateTime start, DateTime end) => amount * numOccurrencesInPeriod(start, end);

    // Total paid from [from] through [to], both inclusive.
    double amountBetween(DateTime from, DateTime to) => amount * occurrencesBetween(from, to);

    // Most recent payday on or before [date], or null if the stream hasn't started by then.
    DateTime? paydayOnOrBefore(DateTime date) => _projector.lastOnOrBefore(date);

    // First payday strictly after [date].
    DateTime paydayAfter(DateTime date) => _projector.firstOnOrAfter(addDays(date, 1));

    // Advance a single period and return [start, end) dates
    (DateTime, DateTime) advancePeriod(DateTime fromDate) {
        final DateTime newStart = _projector.advancePeriod(fromDate);
        final DateTime newEnd = _projector.advancePeriod(newStart);
        return (newStart, newEnd);
    }
}
