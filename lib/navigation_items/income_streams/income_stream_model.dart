// Class to represent an income stream model
import 'dart:math';

import 'package:bujit/utils/frequency_unit.dart';
import 'package:bujit/utils/projector.dart';

class IncomeStreamModel {
    String name; // Name of the income stream
    double amount; // Amount of the income stream
    DateTime startDate; // Start date of the income stream
    DateTime? currentDate; // Current date of the income stream
    late DateTime nextDate; // Next date of the income stream
    int frequency; // Frequency
    FrequencyUnit frequencyUnits; // Tag to track frequency
    bool isActive; // Whether the income stream is active or not
    double catchUpAmount = 0.00; // Amount to catch up on
    double periodAmount = 0.00; // Amount for the current period
    late Projector _projector; // Projector for handling date projections

    IncomeStreamModel({
        required this.name,
        required this.amount,
        required this.startDate,
        required this.frequency,
        required this.frequencyUnits,
        this.isActive = false, // Default to inactive
        this.currentDate,
    }) {
        // If currentDate is not provided, set it to startDate
        currentDate ??= startDate;
        _projector = Projector(
            baseDate: currentDate!,
            originDate: startDate,
            frequency: frequency,
            frequencyUnits: frequencyUnits,
            startClosed: false,
        );
        makeRecent();
    }

    // Methods 

    // Human-readable string representation of the income stream
    String displayString() {
        String plurality = frequency > 1 ? 's' : '';
        String displayBase = switch (frequencyUnits) {
            FrequencyUnit.daily => 'day',
            FrequencyUnit.weekly => 'week',
            FrequencyUnit.biweekly => 'biweek',
            FrequencyUnit.monthly => 'month',
            FrequencyUnit.yearly => 'year',
        };
        return 'Every $frequency $displayBase$plurality';
    }

    // Make the income stream recent
    void makeRecent() {
        final DateTime today = _projector.today;
        final DateTime oldCurrentDate = currentDate!;
        // Get the catchUpAmount based on period passed
        // end closed to include today in the catch up amount if it lands on today
        catchUpAmount = amount * _projector.numOccurrencesInPeriod(
            oldCurrentDate, today, endClosed: true
        );
        // Update the currentDate
        int numPriorOccurrences = _projector.numOccurrencesBefore(today);
        final bool landsOnToday = _projector.occurrenceDate(numPriorOccurrences) == today;
        numPriorOccurrences = max(0, landsOnToday ? numPriorOccurrences : numPriorOccurrences - 1);
        currentDate = _projector.occurrenceDate(numPriorOccurrences);
        // Update the nextDate
        nextDate = _projector.occurrenceDate(numPriorOccurrences + 1);
    }

    // Get number of occurrences (paychecks) in a period, same as ExpenseItem's
    int numOccurrencesInPeriod(DateTime start, DateTime end) {
        return _projector.numOccurrencesInPeriod(start, end);
    }

    // Project to period
    void toPeriod(DateTime start, DateTime end) {
        final result = _projector.projectToPeriod(start, end);
        catchUpAmount = amount * result.priorOccurrences;
        int periodOccurrences = result.periodOccurrences;
        // Get period amount
        periodAmount = (periodOccurrences > 0) ? amount * periodOccurrences : 0.00;
    }

    // Advance a single period and return [start, end) dates
    (DateTime, DateTime) advancePeriod(DateTime fromDate) {
        final DateTime newStart = _projector.advancePeriod(fromDate);
        final DateTime newEnd = _projector.advancePeriod(newStart);
        return (newStart, newEnd);
    }
}