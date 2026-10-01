// Holds the logic for projecting information from period to period.

import 'dart:math';
import 'date_utils.dart';
import 'frequency_unit.dart';

class Projector {
    // Stand-in date for an occurrence that never comes (see occurrenceDate).
    static final DateTime never = DateTime(9999, 12, 31);

    late DateTime originDate; // The original date from which projections are made
    DateTime baseDate; // Base date for projections: occurrence 0
    int frequency; // Frequency of the expense
    FrequencyUnit frequencyUnits; // Frequency units of the expense
    bool startClosed; // Whether the start of the period is closed (inclusive) or open (exclusive) wrt periodOccurrences
    bool endClosed; // Whether the end of the period is closed (inclusive) or open (exclusive) wrt periodOccurrences

    Projector({
        required DateTime baseDate,
        required this.frequency,
        required this.frequencyUnits,
        this.startClosed = true,
        this.endClosed = false,
        DateTime? originDate,
    }) : baseDate = dateOnly(baseDate),
         originDate = dateOnly(originDate ?? baseDate); // If originDate is not provided, set it to baseDate

    // Methods

    // Converts a frequency count + unit into an exact number of days relative
    // to calendar, so leap years and variable month lengths are accounted for.
    int frequencyToDays(int frequency, FrequencyUnit frequencyUnit, DateTime calendar) {
        return switch (frequencyUnit) {
            FrequencyUnit.daily => frequency,
            FrequencyUnit.weekly => frequency * 7,
            FrequencyUnit.biweekly => frequency * 14,
            FrequencyUnit.monthly => _monthsToDays(frequency, calendar),
            FrequencyUnit.yearly => _yearsToDays(frequency, calendar),
        };
    }

    // Converts a number of months into days, accounting for leap years and variable month lengths.
    int _monthsToDays(int months, DateTime start) {
        return daysBetween(start, DateTime(start.year, start.month + months, start.day));
    }

    // Converts a number of years into days, accounting for leap years.
    int _yearsToDays(int years, DateTime start) {
        return daysBetween(start, DateTime(start.year + years, start.month, start.day));
    }

    // Date of the k-th occurrence relative to baseDate.
    // Uses real calendar days (never Duration) so varying month lengths, leap
    // years and daylight-saving changes don't cause drift.
    DateTime occurrenceDate(int k) {
        // A non-positive frequency (invalid data, e.g. migrated) is a one-off: only
        // occurrence 0 exists, and "the next one" is never.
        if (frequency <= 0 && k > 0) return never;
        return switch (frequencyUnits) {
            FrequencyUnit.daily => addDays(baseDate, frequency * k),
            FrequencyUnit.weekly => addDays(baseDate, frequency * 7 * k),
            FrequencyUnit.biweekly => addDays(baseDate, frequency * 14 * k),
            FrequencyUnit.monthly => _addMonthsClamped(frequency * k),
            FrequencyUnit.yearly => _clampedDate(baseDate.year + frequency * k, originDate.month, originDate.day),
        };
    }

    // Adds months to baseDate, clamping the day to the target month's last valid day
    // (e.g., Jan. 31 + 1 month -> Feb. 28/29 instead of going into March). The day
    // comes from originDate, so the next month returns to the 31st instead of drifting.
    DateTime _addMonthsClamped(int months) {
        int totalMonths0 = baseDate.year * 12 + (baseDate.month - 1) + months;
        int month0 = totalMonths0 % 12; // Dart's `%` on int is floor-mod: always in [0, 11].
        int year = (totalMonths0 - month0) ~/ 12;
        return _clampedDate(year, month0 + 1, originDate.day);
    }

    // Due dates on last day (e.g., Jan. 31) are usually last day of month (e.g., Feb. 28/29)
    // Clamp the day to the last valid day of the month.
    DateTime _clampedDate(int year, int month, int day) {
        int lastDayOfMonth = DateTime(year, month + 1, 0).day;
        // If the day is greater than the last day of the month, clamp it to the last day
        if (day > lastDayOfMonth) {
            day = lastDayOfMonth;
        }
        return DateTime(year, month, day);
    }

    // Estimate of the occurrence index nearest to the given date
    // Exact for the fixed-day-length units
    int _estimateOccurrenceIndex(DateTime date) {
        return switch (frequencyUnits) {
            // Difference in days divided by frequency, rounded to nearest integer
            FrequencyUnit.daily => (daysBetween(baseDate, date) / frequency).round(),
            // Difference in weeks divided by frequency, rounded to nearest integer
            FrequencyUnit.weekly => (daysBetween(baseDate, date) / (frequency * 7)).round(),
            // Difference in biweeks divided by frequency, rounded to nearest integer
            FrequencyUnit.biweekly => (daysBetween(baseDate, date) / (frequency * 14)).round(),
            // Difference in months (excluding day portion) divided by frequency
            FrequencyUnit.monthly =>
                ((date.year - baseDate.year) * 12 + date.month - baseDate.month) ~/ frequency,
            // Difference in years (excluding month and day portion) divided by frequency
            FrequencyUnit.yearly => (date.year - baseDate.year) ~/ frequency,
        };
    }

    // Smallest occurrence index k such that occurrenceDate(k) is on or after the given date,
    // i.e. the number of occurrences strictly before it.
    // Starts from an estimate and walks to the date (usually a step or two)
    int numOccurrencesBefore(DateTime date) {
        date = dateOnly(date);
        // A non-positive frequency never advances: there's only the one occurrence
        // (stepping from an estimate would otherwise loop forever).
        if (frequency <= 0) return baseDate.isBefore(date) ? 1 : 0;
        // Get the estimate
        int k = _estimateOccurrenceIndex(date);
        // Go forward until on or after the date
        while (occurrenceDate(k).isBefore(date)) {
            k++;
        }
        // At this point, we're either on or after the date
        // Go backwards until until (k - 1) is before the date to get first occurrence on or after the date
        while (k > 0 && !occurrenceDate(k - 1).isBefore(date)) {
            k--;
        }
        // A date before baseDate has no real occurrences before it -- clamp
        // instead of extrapolating a negative count backward past genesis.
        return max(0, k);
    }

    // Number of occurrences in the period [start, end) by default; startClosed/endClosed
    // override either bound. A reversed period (start after end, e.g. querying before an
    // item's genesis date) has no occurrences, so the result is clamped to 0
    // instead of going negative.
    int numOccurrencesInPeriod(DateTime start, DateTime end, {bool? startClosed, bool? endClosed}) {
        startClosed ??= this.startClosed;
        endClosed ??= this.endClosed;
        start = startClosed ? dateOnly(start) : addDays(start, 1);
        end = endClosed ? addDays(end, 1) : dateOnly(end);
        return max(0, numOccurrencesBefore(end) - numOccurrencesBefore(start));
    }

    // Number of occurrences from [from] through [to], both inclusive.
    int countBetween(DateTime from, DateTime to) =>
        numOccurrencesInPeriod(from, to, startClosed: true, endClosed: true);

    // First occurrence on or after [date].
    DateTime firstOnOrAfter(DateTime date) => occurrenceDate(numOccurrencesBefore(date));

    // Last occurrence on or before [date], or null if the schedule hasn't started by then.
    DateTime? lastOnOrBefore(DateTime date) {
        final int count = numOccurrencesBefore(addDays(date, 1));
        return count > 0 ? occurrenceDate(count - 1) : null;
    }

    // Get occurrences and projected date in a period
    ({int priorOccurrences, int periodOccurrences, DateTime date}) projectToPeriod(DateTime start, DateTime end, {bool? startClosed, bool? endClosed}) {
        startClosed ??= this.startClosed;
        endClosed ??= this.endClosed;
        int priorOccurrences = numOccurrencesBefore(
            (startClosed ? start : addDays(start, 1))
        );
        int numOccurrences = numOccurrencesInPeriod(start, end, startClosed: startClosed, endClosed: endClosed);
        // Next due date after or on start date
        DateTime newbaseDate = occurrenceDate(priorOccurrences);
        return (priorOccurrences: priorOccurrences, periodOccurrences: numOccurrences, date: newbaseDate);
    }

    // Advance a single period
    DateTime advancePeriod(DateTime date) {
        final int numPriorOccurrences = numOccurrencesBefore(date);
        final DateTime occurrence = occurrenceDate(numPriorOccurrences);
        // If the date is on an occurrence, advance to the next occurrence, else stay on current occurrence
        final DateTime advancedDate = occurrence.isAfter(dateOnly(date)) ? occurrence : occurrenceDate(numPriorOccurrences + 1);
        return advancedDate;
    }

    // Retreat a single period
    DateTime retreatPeriod(DateTime date) {
        final int numPriorOccurrences = numOccurrencesBefore(date);
        final DateTime retreatedDate = occurrenceDate(
            max(0, numPriorOccurrences - 1)
        );
        return retreatedDate;
    }

    DateTime get today => todayDate();
}
