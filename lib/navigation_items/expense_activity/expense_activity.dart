// Mirrors ExpenseActivity/ExpenseActivity.java in the original Java app.
import 'package:flutter/material.dart';
import '../../dialogs/recurring_expenses.dart';
import '../../utils/frequency_unit.dart';
import '../income_streams/income_stream_model.dart';
import 'expense_model.dart';

enum StorageAction { read, write }
enum DialogOption { add, edit, delete }
enum ExpenseDateFormat {
    view("EEEE, MMMM d, yyyy"),
    store("yyyy.MM.dd"),
    header("MMM dd, yyyy");

    const ExpenseDateFormat(this.format);
    final String format;
}
// TextField(
//   keyboardType: const TextInputType.numberWithOptions(decimal: true),
//   inputFormatters: [
//     FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
//   ],
//   decoration: const InputDecoration(prefixText: '\$'),
// )
// StatefulWidget subclass. Resets state when rebuilt
class ExpenseActivity extends StatefulWidget {
    const ExpenseActivity({super.key});

    @override
    State<StatefulWidget> createState() => ExpenseActivityState();
}

class ExpenseActivityState extends State<ExpenseActivity> {
    // region variables
    // final CurrencyFormat currencyFormat = CurrencyFormat();
    // Constants -- moved to enums
    // Keeping track of things
    bool _onHomeScreen = true;
    bool _speedDialOpen = false;
    bool _skipNextOnPauseToWrite = false;
    // Expenses
    // TODO: Get expenses to populate this from storage
    List<ExpenseModel> _expenses = []; // Placeholder for expense data
    // TODO: List<SingleEventModel> _singleEvents = []; // Placeholder for single event data
    List<IncomeStreamModel> _incomeStreams = []; // Placeholder for income stream data
    // Balance information
    double _currentBalance = 0.00, _shownBalance = 0.00, _afterPeriodBalance = 0.00;
    int _projectFrequency = 14; // Default to 14 days for projection
    FrequencyUnit _projectFrequencyUnits = FrequencyUnit.daily; // Default to daily for projection
    DateTime _currentPeriodStart = DateTime.now(), _currentPeriodEnd = DateTime.now().add(Duration(days: 14));
    int _forwardPeriods = 0; // Number of periods we have projected forward
    // Data storage
    // TODO: Implement data storage logic

    
    // Balance summary Card
    Card get balanceSummary => Card(
        child: IntrinsicHeight(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Text("CURRENT BALANCE"),
                    Text("$_shownBalance"), // Placeholder for current balance
                    VerticalDivider(),
                    Text("AFTER THIS CHECK"),
                    Text("$_afterPeriodBalance"), // Placeholder for after this check
                ],
            ),
        ),
    );

    // Get expenses for the current period
    double sumExpensesForPeriod(DateTime start, DateTime end) {
        double total = 0.0;
        for (var expense in _expenses) {
            // Get num occurrences and multiply by amount
            int numOccurrences = expense.numOccurrencesInPeriod(start, end);
            total += numOccurrences * expense.amount;
        }
        return total;
    }

    // Update shown balance
    void updateBalances({DateTime? start, DateTime? end}) {
        // Assert that start and end are not null if one of them is provided
        if (start != null || end != null) {
            assert(start != null && end != null, "Both start and end dates must be provided together.");
        }
        // Get current balance from storage or calculation
        // TODO: Implement logic to retrieve current balance from storage or calculate it
        _currentBalance = double.parse(_currentBalance.toStringAsFixed(2)); // Placeholder for current balance
        // If on home screen, update the shown balance based on the current expenses
        if (_onHomeScreen) {
            _shownBalance = double.parse(_currentBalance.toStringAsFixed(2));
            _currentPeriodStart = DateTime.now();
            // TODO: This logic isn't right; fix later. For now, just set the end date to 14 days from now.
            _currentPeriodEnd = DateTime.now().add(Duration(days: _projectFrequency));
        } else { // Otherwise, do projection 
            // Add income strems for _forwardPeriods for each income stream
            // Need to take into account the frequency of each individual income stream
            double increaseBalanceAmount = 0.00; // Placeholder for increase in balance from income streams
            for (var incomeStream in _incomeStreams) {
                // TODO: Implement logic to calculate increase in balance from each income stream
                increaseBalanceAmount += incomeStream.amount * incomeStream.numOccurrencesInPeriod(_currentPeriodStart, _currentPeriodEnd);
            }
            // Add to shown balance
            _shownBalance = double.parse((_currentBalance + increaseBalanceAmount).toStringAsFixed(2));
            // If start and end are provided, update the current period start and end
            if (start != null && end != null) {
                _currentPeriodStart = start;
                _currentPeriodEnd = end;
            }
        }
        // Decrease the shown balance by the sum of expenses for the current period
        _afterPeriodBalance = double.parse(_shownBalance.toStringAsFixed(2)) - sumExpensesForPeriod(_currentPeriodStart, _currentPeriodEnd);
        // Update UI by rebuilding the widget tree
        setState(() {});
    }

    // Define the appBar and its actions
    AppBar get appBar => AppBar(
        title: const Text("Bujit"),
    );
    //     actions: [

    
    // Expense list header
    Row expenseListHeader = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
            Text("EXPENSE"),
            Text("DUE DATE"),
            Text("RATE"),
            Text("AMOUNT")
        ],
    );

    // Expense list -- Late initialization to avoid null issues
    late RefreshIndicator expenseList = RefreshIndicator(
        onRefresh: () async {
            // TODO: Implement refresh logic
            await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView.builder(
            itemCount: _expenses.length,
            itemBuilder: (context, index) {
                return ListTile(
                    title: Text("Expense $index"), // Placeholder for expense title
                    subtitle: Text("Due Date: TBD"), // Placeholder for due date
                    trailing: Text("\$0.00"), // Placeholder for amount
                );
            },
        ),
    );

    // Floating action button for adding expenses
    FloatingActionButton get addExpenseButton => FloatingActionButton(
        onPressed: () {
            showRecurringExpenseDialog(context);
            // TODO: Update final balance and refresh the expense list after adding an expense
        }
    );
    
    // Main activity
    Widget get mainActivity => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            balanceSummary,
            expenseListHeader,
            Divider(), // Divider between header and list
            // Expanded gives the ListView a bounded height; a scrollable list
            // directly inside a Column fails at runtime with "unbounded height".
            Expanded(child: expenseList),
        ],
    );
    
    @override
    Widget build(BuildContext context) {
        // Build the screen UI here. This is a placeholder for now.
        return Scaffold(
            appBar: appBar, // AppBar defined above
            body: Center(
                child: mainActivity,
            ),
        ); 
    }
}
