// Data class for a credit card entry
import 'expense_item.dart';

class CreditModel extends ExpenseItem {
    // TODO: Linked Accounts and Google Sync
    double creditLimit; // Credit limit for the credit card

    CreditModel({
        super.id,
        required super.name,
        required super.amount,
        required super.startDate,
        required super.frequency,
        required super.frequencyUnits,
        super.category = "Credit Cards",
        required this.creditLimit,
        super.currentDueDate
    });

    // Methods

    // Update shown quantities when going forward or backward in time to a new period
    @override
    void toPeriod(DateTime start, DateTime end) {
        final result = projectToPeriod(start, end);
        shownDate = result.date;
        final bool dueDatePassed = (result.priorOccurrences > 0);
        catchUpAmount = amount * (dueDatePassed ? 1 : 0);
        periodAmount = (result.periodOccurrences > 0) ? amount : 0.00;
    } 

    // Get credit utilization as a percentage of the credit limit
    double get creditUtilization {
        if (creditLimit == 0.0) {
            return 0.0; // Avoid division by zero
        }
        return periodAmount / creditLimit;
    }

    // TODO: Need method to allow expenses with this as a source to add to periodAmount when appropriate

    // Getters
    bool get isCreditCard => true;
}