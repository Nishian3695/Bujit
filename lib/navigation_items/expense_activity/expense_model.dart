// Data class for a single recurring expense entry
// import 'package:json_annotation/json_annotation.dart';
import 'expense_item.dart';
import 'package:bujit/utils/category_manager.dart';

class ExpenseModel extends ExpenseItem {
    // TODO: Linked Accounts and Google Sync

    ExpenseModel({
        super.id,
        required super.name,
        required super.amount,
        required super.startDate,
        required super.frequency,
        required super.frequencyUnits,
        super.category = otherCategory,
        super.currentDueDate,
    });

    // Methods

    // Update shown quantities when going to a new period
    @override
    void toPeriod(DateTime start, DateTime end) {
        final result = projectToPeriod(start, end);
        shownDate = result.date;
        catchUpAmount = amount * result.priorOccurrences;
        // Show amount only if due date is this period
        periodAmount = (result.periodOccurrences > 0) ? amount * result.periodOccurrences : 0.00;
    }


    // Getters
    bool get isCreditCard => false;
}