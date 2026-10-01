// Holds storage items for the app
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/utils/category_manager.dart';

class StorageHolder {
    // Stored data
    List<ExpenseModel> expenses = [];
    double currentBalance = 0.00;
    List<IncomeStreamModel> incomeStreams = [];
    DateTime lastUpdated = DateTime.now();
    List<String> categories = defaultCategories();
    // List<SingleEventModel> singleEvents = []; // TODO: Implement single events
    // List<ManualAccount> manualAccounts = []; // TODO: Implement manual accounts

    StorageHolder({
        required this.expenses,
        required this.currentBalance,
        required this.incomeStreams,
        required this.lastUpdated,
        required this.categories,
    });
    // Everything should be validated outside of the holder, so no need for getters/setters here. Just store and retrieve.
}
