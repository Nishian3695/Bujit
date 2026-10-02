// Mirrors ExpenseActivity/ExpenseActivity.java in the original Java app.
//
// All balance and schedule math lives in BalanceModel; this screen only asks
// it for the check being viewed (index 0 = current, 1+ = projected) and
// displays the result. Data changes go through AppState, which saves them.
// The layout is a placeholder until the UI pass.
import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../dialogs/credit_card_dialog.dart';
import '../../dialogs/recurring_expenses.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import '../app_drawer.dart';
import 'balance_model.dart';
import 'credit_model.dart';
import 'expense_item.dart';
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

// StatefulWidget subclass. Resets state when rebuilt
class ExpenseActivity extends StatefulWidget {
    final AppState state;
    const ExpenseActivity({super.key, required this.state});

    @override
    State<StatefulWidget> createState() => ExpenseActivityState();
}

class ExpenseActivityState extends State<ExpenseActivity> {
    AppState get _state => widget.state;
    BalanceModel get _balance => _state.balance;
    // Which check is on screen: 0 = current, 1+ = projected
    int _checkIndex = 0;
    late CheckSummary _summary = _balance.showCheck(_checkIndex);

    bool get _onHomeScreen => _checkIndex == 0;

    @override
    void initState() {
        super.initState();
        // Any screen changing data (income streams, cards, settings) rebuilds this one.
        _state.addListener(_refresh);
    }

    @override
    void dispose() {
        _state.removeListener(_refresh);
        super.dispose();
    }

    // Recomputes the check on screen and rebuilds.
    void _refresh() {
        if (!mounted) return;
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

    // Back to the current check (the Java app's home button).
    void _goHome() {
        _checkIndex = 0;
        _refresh();
    }

    // Adds a user category the dialog created, so it's offered next time.
    void _rememberCategory(String category) {
        if (!_state.data.categories.contains(category)) _state.data.categories.add(category);
    }

    // Opens the add-expense dialog and adds the result. A date in the past is
    // rolled forward to the next due date without charging anything, like the
    // Java app's dialog: those earlier payments happened outside the app.
    Future<void> _addExpense() async {
        final ExpenseModel? expense = await showRecurringExpenseDialog(
            context,
            categories: _state.data.categories,
        );
        if (expense == null) return;
        expense.skipToNextDueDate();
        _rememberCategory(expense.category);
        _balance.expenses.add(expense);
        await _state.changed();
    }

    // Opens the right edit dialog for a row; Delete removes it.
    Future<void> _editItem(ExpenseItem item) async {
        void delete() {
            _balance.expenses.remove(item);
            _state.changed();
        }

        final ExpenseItem? edited = item is CreditModel
            ? await showCreditCardDialog(context, existing: item, onDelete: delete)
            : await showRecurringExpenseDialog(
                context,
                existing: item as ExpenseModel,
                categories: _state.data.categories,
                onDelete: delete,
            );
        if (edited == null) return;
        // A newly picked date in the past rolls forward without charging, as when adding.
        edited.skipToNextDueDate();
        _rememberCategory(edited.category);
        final int index = _balance.expenses.indexOf(item);
        if (index >= 0) _balance.expenses[index] = edited;
        await _state.changed();
    }

    static String _money(double value) => "\$${value.toStringAsFixed(2)}";
    static String _date(DateTime date) => date.toString().split(' ')[0];

    // Balance summary Card. With the Next Check setting on, the right-hand figure
    // adds the next paycheck and is labelled "NEXT CHECK", as in the Java app.
    Card get balanceSummary {
        final bool nextCheck = _state.data.includeNextCheck;
        return Card(
            child: IntrinsicHeight(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Text("CURRENT BALANCE"),
                        Text(_money(_summary.startBalance)),
                        const VerticalDivider(),
                        Text(nextCheck ? "NEXT CHECK" : "AFTER THIS CHECK"),
                        Text(_money(nextCheck ? _summary.endBalanceWithNextCheck : _summary.endBalance)),
                    ],
                ),
            ),
        );
    }

    // Define the appBar and its actions
    AppBar get appBar => AppBar(
        // An explicit menu button (same as the default) so the tutorial can spotlight it.
        leading: Builder(builder: (context) => TutorialTarget(
            id: "menu_button",
            child: IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            ),
        )),
        title: Text(_onHomeScreen ? "This Check" : "Check of ${_date(_summary.window.start)}"),
        actions: [
            TutorialTarget(
                id: "check_nav",
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                ),
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

    // Expense list for the check on screen. Rows can be edited from the
    // current check only, as in the Java app (projections are read-only).
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
                    onTap: _onHomeScreen ? () => _editItem(expense) : null,
                );
            },
        ),
    );

    // Main activity
    Widget get mainActivity => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            if (!_state.isSaving)
                const MaterialBanner(
                    content: Text("Storage couldn't be opened, so changes won't be saved."),
                    actions: [SizedBox.shrink()],
                ),
            TutorialTarget(id: "balance_card", child: balanceSummary),
            expenseListHeader,
            const Divider(), // Divider between header and list
            // Expanded gives the ListView a bounded height; a scrollable list
            // directly inside a Column fails at runtime with "unbounded height".
            Expanded(child: TutorialTarget(id: "expense_list", child: expenseList)),
        ],
    );

    @override
    Widget build(BuildContext context) {
        return TutorialOverlay(
            state: _state,
            screen: TutorialScreen.home,
            child: Scaffold(
                appBar: appBar,
                drawer: AppDrawer(state: _state, onReturn: _refresh),
                body: mainActivity,
                // Adds an expense on the current check; while viewing a projected check
                // it becomes a home button that returns to the current one.
                floatingActionButton: TutorialTarget(
                    id: "add_button",
                    child: FloatingActionButton(
                        onPressed: _onHomeScreen ? _addExpense : _goHome,
                        tooltip: _onHomeScreen ? "Add expense" : "Back to this check",
                        child: Icon(_onHomeScreen ? Icons.add : Icons.home),
                    ),
                ),
            ),
        );
    }
}
