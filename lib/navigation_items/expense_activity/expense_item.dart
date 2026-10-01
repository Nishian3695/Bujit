// Data model for expense entries (e.g., recurring expenses and credit cards)
import 'package:bujit/utils/frequency_unit.dart';
import 'package:bujit/utils/projector.dart';
import 'package:bujit/utils/category_manager.dart';

class ExpenseItem {
    // Persistent fields
    int? id; // Row id once persisted to the database
    String name; // Name of the expense
    int frequency; // Frequency in units of frequencyUnits
    FrequencyUnit frequencyUnits; // Tag to track frequency
    double amount; // Amount due
    DateTime startDate; // Start date
    DateTime currentDueDate; // Current due date
    String category = otherCategory; // Category of the expense

    // Accumulated amount from projections
    double catchUpAmount = 0.00;

    // Displayed date and cost
    late DateTime shownDate;
    double periodAmount = 0.00; // Amount for the current period

    // Projector for handling date projections
    late Projector _projector;

    ExpenseItem({
        this.id,
        required this.name,
        required this.amount,
        required this.startDate,
        required this.frequency,
        required this.frequencyUnits,
        this.category = otherCategory,
        DateTime? currentDueDate,
        }) : currentDueDate = currentDueDate ?? startDate {
            shownDate = startDate;
            periodAmount = amount;
            _projector = Projector(
                baseDate: this.currentDueDate,
                originDate: startDate,
                frequency: frequency,
                frequencyUnits: frequencyUnits,
        );
        makeRecent();
    }

    // Methods

    // Make recent
    void makeRecent() {
        final DateTime today = _projector.today;
        final DateTime oldDueDate = currentDueDate;
        // Get the catchUpAmount based on occurrences newly due since the last check-in
        // (open start so oldDueDate itself, already accounted for last time, isn't recounted;
        // closed end so an occurrence landing exactly on today is included)
        catchUpAmount = amount * _projector.numOccurrencesInPeriod(
            oldDueDate, today, startClosed: false, endClosed: true,
        );
        // Update the currentDueDate to the next occurrence on or after today
        final int occurrencesPassed = _projector.numOccurrencesBefore(today);
        currentDueDate = _projector.occurrenceDate(occurrencesPassed);
    }

    // Get number of occurrences in a period
    int numOccurrencesInPeriod(DateTime start, DateTime end) {
        return _projector.numOccurrencesInPeriod(start, end);
    }

    // Get occurrences and projected date in a period
    ({int priorOccurrences, int periodOccurrences, DateTime date}) projectToPeriod(DateTime start, DateTime end) {
        return _projector.projectToPeriod(start, end);
    }

    // Child methods to be filled
    void toPeriod(DateTime start, DateTime end) {}
}