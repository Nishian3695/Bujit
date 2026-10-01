// Mirrors ExpenseActivity/ExpenseActivity.java in the original Java app.
//
// All balance and schedule math lives in BalanceModel; this screen only asks
// it for the check being viewed (index 0 = current, 1+ = projected) and
// displays the result. The layout is a placeholder until the UI pass.
import 'package:flutter/material.dart';
import '../../dialogs/recurring_expenses.dart';
import 'balance_model.dart';
import 'expense_item.dart';

enum StorageAction { read, write }
enum DialogOption { add, edit, delete }
enum ExpenseDateFormat {
    view("EEEE, MMMM d, yyyy"),
    store("yyyy.MM.dd"),
    header("MMM dd, yyyy");

    const ExpenseDateFormat(this.format);
    final String format;
}

// StatefulWidget subclass. Resets state when rebuilt
class ExpenseActivity extends StatefulWidget {
    const ExpenseActivity({super.key});

    @override
    State<StatefulWidget> createState() => ExpenseActivityState();
}

class ExpenseActivityState extends State<ExpenseActivity> {
    // TODO: Load from StorageManager, then call _balance.makeRecent() and persist the result
    final BalanceModel _balance = BalanceModel(currentBalance: 0.00);
    // Which check is on screen: 0 = current, 1+ = projected
    int _checkIndex = 0;
    late CheckSummary _summary = _balance.showCheck(_checkIndex);

    bool get _onHomeScreen => _checkIndex == 0;

    // Recomputes the check on screen and rebuilds.
    void _refresh() {
        setState(() => _summary = _balance.showCheck(_checkIndex));
    }

    // Projection paging, like swiping between checks in the Java app.
    void _nextCheck() {
        _checkIndex++;
        _refresh();
    }

    void _previousCheck() {
        if (_onHomeScreen) return;
        _checkIndex--;
        _refresh();
    }

    // Opens the add-expense dialog and adds the result. A date in the past is
    // rolled forward to the next due date without charging anything, like the
    // Java app's dialog: those earlier payments happened outside the app.
    Future<void> _addExpense() async {
        final ExpenseItem? expense = await showRecurringExpenseDialog(context);
        if (expense == null) return;
        expense.skipToNextDueDate();
        _balance.expenses.add(expense);
        // TODO: Persist via StorageManager
        _refresh();
    }

    static String _money(double value) => "\$${value.toStringAsFixed(2)}";
    static String _date(DateTime date) => date.toString().split(' ')[0];

    // Balance summary Card
    Card get balanceSummary => Card(
        child: IntrinsicHeight(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    const Text("CURRENT BALANCE"),
                    Text(_money(_summary.startBalance)),
                    const VerticalDivider(),
                    // TODO: Show "NEXT CHECK" and endBalanceWithNextCheck when that setting is on
                    const Text("AFTER THIS CHECK"),
                    Text(_money(_summary.endBalance)),
                ],
            ),
        ),
    );

    // Define the appBar and its actions
    AppBar get appBar => AppBar(
        title: Text(_onHomeScreen ? "This Check" : "Check of ${_date(_summary.window.start)}"),
        actions: [
            IconButton(
                onPressed: _onHomeScreen ? null : _previousCheck,
                icon: const Icon(Icons.chevron_left),
                tooltip: "Previous check",
            ),
            IconButton(
                onPressed: _nextCheck,
                icon: const Icon(Icons.chevron_right),
                tooltip: "Next check",
            ),
        ],
    );

    // Expense list header
    final Row expenseListHeader = const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            Text("EXPENSE"),
            Text("DUE DATE"),
            Text("RATE"),
            Text("AMOUNT")
        ],
    );

    // Expense list for the check on screen
    Widget get expenseList => RefreshIndicator(
        onRefresh: () async {
            // TODO: Refresh linked bank balances
            _refresh();
        },
        child: ListView.builder(
            itemCount: _balance.expenses.length,
            itemBuilder: (context, index) {
                final ExpenseItem expense = _balance.expenses[index];
                return ListTile(
                    title: Text(expense.name),
                    subtitle: Text(expense.hasEnded ? "Ended" : "Due ${_date(expense.shownDate)}"),
                    trailing: Text(_money(expense.periodAmount)),
                );
            },
        ),
    );

    // Main activity
    Widget get mainActivity => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            balanceSummary,
            expenseListHeader,
            const Divider(), // Divider between header and list
            // Expanded gives the ListView a bounded height; a scrollable list
            // directly inside a Column fails at runtime with "unbounded height".
            Expanded(child: expenseList),
        ],
    );

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: appBar,
            body: mainActivity,
            floatingActionButton: FloatingActionButton(
                onPressed: _addExpense,
                tooltip: "Add expense",
                child: const Icon(Icons.add),
            ),
        );
    }
}
