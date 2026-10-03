// Data class for a single recurring expense entry
import 'expense_item.dart';
import 'package:bujit/utils/category_manager.dart';

class ExpenseModel extends ExpenseItem {
    ExpenseModel({
        super.id,
        required super.name,
        required super.amount,
        required super.startDate,
        required super.frequency,
        required super.frequencyUnits,
        super.category = otherCategory,
        super.currentDueDate,
        super.endDate,
        super.googleTaskId,
        super.remindInTasks,
        super.source,
        super.sourceId,
        super.linkedAccountId,
    });

    // Getters
    bool get isCreditCard => false;
}
