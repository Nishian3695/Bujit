// Mirrors ExpenseActivity/ExpenseActivity.java in the original Java app.
//
// All balance and schedule math lives in BalanceModel; this screen only asks
// it for the check being viewed (index 0 = current, 1+ = projected) and
// displays the result. Data changes go through AppState, which saves them.
// The layout is a placeholder until the UI pass.
import 'package:flutter/material.dart';
import '../../utils/money.dart';
import '../../app_state.dart';
import '../../dialogs/credit_card_dialog.dart';
import '../../dialogs/projection_settings_dialog.dart';
import '../../dialogs/recurring_expenses.dart';
import '../../dialogs/single_event_dialog.dart';
import '../../dialogs/update_balance_dialog.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import '../app_drawer.dart';
import 'balance_model.dart';
import 'credit_model.dart';
import 'expense_item.dart';
import 'expense_model.dart';
import '../single_events/single_event_model.dart';
import '../single_events/single_events_ledger.dart';

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

    // Swiping the list pages between checks, as in the Java app: left = next.
    void _onSwipe(DragEndDetails details) {
        final double velocity = details.primaryVelocity ?? 0;
        if (velocity < -300) _nextCheck();
        if (velocity > 300) _previousCheck();
    }

    // Projection Settings (session only; see ProjectionSettings). Applying or
    // resetting returns to the current check, as in the Java app.
    Future<void> _openProjectionSettings() async {
        if (_balance.incomeStreams.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Add an income stream first.")));
            return;
        }
        final ProjectionChoice? choice = await showProjectionSettingsDialog(
            context,
            streams: _balance.incomeStreams,
            activeStream: _balance.activeIncome,
            current: _balance.projection,
        );
        if (choice == null) return;
        _balance.projection = choice.settings;
        _goHome();
    }

    // The + button's menu (the Java app's speed dial): a recurring expense or a single event.
    Future<void> _openAddMenu() async {
        final String? choice = await showModalBottomSheet<String>(
            context: context,
            builder: (context) => SafeArea(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ListTile(
                            leading: const Icon(Icons.repeat),
                            title: const Text("Recurring expense"),
                            onTap: () => Navigator.of(context).pop("recurring"),
                        ),
                        ListTile(
                            leading: const Icon(Icons.event),
                            title: const Text("Single event"),
                            onTap: () => Navigator.of(context).pop("single"),
                        ),
                    ],
                ),
            ),
        );
        if (choice == "recurring") await _addExpense();
        if (choice == "single") await _addSingleEvent();
    }

    // Adds a single event from the home screen, applied right away (as on the Single Events screen).
    Future<void> _addSingleEvent() async {
        final SingleEventsLedger ledger = _state.data.singleEventsLedger;
        final SingleEventModel? draft = await showSingleEventDialog(context, targets: ledger.targets);
        if (draft == null) return;
        ledger.add(draft);
        await _state.changed();
    }

    // Drag-to-reorder on the current check; the order is saved.
    // ([newIndex] already allows for the row's removal, as onReorderItem gives it.)
    void _reorder(int oldIndex, int newIndex) {
        final ExpenseItem item = _balance.expenses.removeAt(oldIndex);
        _balance.expenses.insert(newIndex, item);
        _state.changed();
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
            showTasksOption: _state.data.tasksSyncEnabled,
            sources: _balance.paymentOptions(forCard: false),
        );
        if (expense == null) return;
        expense.skipToNextDueDate();
        _rememberCategory(expense.category);
        _balance.expenses.add(expense);
        await _state.changed();
    }

    // Opens the right edit dialog for a row; Delete removes it.
    Future<void> _editItem(ExpenseItem item) async {
        void delete() => _state.removeItem(item);

        final ExpenseItem? edited = item is CreditModel
            ? await showCreditCardDialog(
                context,
                existing: item,
                onDelete: delete,
                sources: _balance.paymentOptions(forCard: true),
                otherCardNames: _balance.creditCards.where((c) => c != item).map((c) => c.name),
            )
            : await showRecurringExpenseDialog(
                context,
                existing: item as ExpenseModel,
                categories: _state.data.categories,
                onDelete: delete,
                showTasksOption: _state.data.tasksSyncEnabled,
                sources: _balance.paymentOptions(forCard: false),
            );
        if (edited == null) return;
        _rememberCategory(edited.category);
        // A newly picked date in the past rolls forward without charging, as when adding.
        await _state.replaceItem(item, edited);
    }

    // Tapping (or long-pressing, as in the Java app) the current balance on this check.
    Future<void> _updateBalance() async {
        if (await showUpdateBalanceDialog(context, _balance)) await _state.changed();
    }

    static String _money(double value) => Money.format(value);
    static String _date(DateTime date) => date.toString().split(' ')[0];

    // Balance summary Card. With the Next Check setting on, the right-hand figure
    // adds the next paycheck and is labelled "NEXT CHECK", as in the Java app.
    // On this check, tapping the current balance updates it.
    Card get balanceSummary {
        final bool nextCheck = _state.data.includeNextCheck;
        return Card(
            child: IntrinsicHeight(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        InkWell(
                            onTap: _onHomeScreen ? _updateBalance : null,
                            onLongPress: _onHomeScreen ? _updateBalance : null,
                            child: Tooltip(
                                message: _onHomeScreen ? "Update balance" : "",
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        const Text("CURRENT BALANCE"),
                                        Text(_money(_summary.startBalance)),
                                    ],
                                ),
                            ),
                        ),
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
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(_onHomeScreen ? "This Check" : "Check of ${_date(_summary.window.start)}"),
                if (_balance.projection != null)
                    Text("Projecting: ${_balance.projection!.describe()}", style: const TextStyle(fontSize: 12)),
            ],
        ),
        actions: [
            IconButton(
                onPressed: _openProjectionSettings,
                icon: const Icon(Icons.tune),
                tooltip: "Projection settings",
            ),
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

    // One row of the expense list.
    Widget _expenseRow(ExpenseItem expense) {
        final String paidFrom = _balance.paidFromLabel(expense);
        return ListTile(
            key: ObjectKey(expense),
            title: Text(expense.name),
            subtitle: Text([
                expense.hasEnded ? "Ended" : "Due ${_date(expense.shownDate)}",
                if (paidFrom != "Current Balance") "from $paidFrom",
            ].join(" · ")),
            trailing: Text(_money(expense.periodAmount)),
            onTap: _onHomeScreen ? () => _editItem(expense) : null,
        );
    }

    // Expense list for the check on screen. Rows can be edited and dragged into
    // a new order on the current check only, as in the Java app (projections
    // are read-only).
    Widget get expenseList => RefreshIndicator(
        onRefresh: () async {
            // TODO: Refresh linked bank balances
            _refresh();
        },
        child: _onHomeScreen
            ? ReorderableListView.builder(
                itemCount: _balance.expenses.length,
                onReorderItem: _reorder,
                itemBuilder: (context, index) => _expenseRow(_balance.expenses[index]),
            )
            : ListView.builder(
                itemCount: _balance.expenses.length,
                itemBuilder: (context, index) => _expenseRow(_balance.expenses[index]),
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
            Expanded(
                child: GestureDetector(
                    onHorizontalDragEnd: _onSwipe,
                    child: TutorialTarget(id: "expense_list", child: expenseList),
                ),
            ),
        ],
    );

    @override
    Widget build(BuildContext context) {
        // Back steps back through projected checks before leaving, as in the Java app.
        return PopScope(
            canPop: _onHomeScreen,
            onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _previousCheck();
            },
            child: TutorialOverlay(
            state: _state,
            screen: TutorialScreen.home,
            child: Scaffold(
                appBar: appBar,
                drawer: AppDrawer(state: _state, onReturn: _refresh),
                body: mainActivity,
                // Adds a recurring expense or single event on the current check; while
                // viewing a projected check it becomes a home button that returns to it.
                floatingActionButton: TutorialTarget(
                    id: "add_button",
                    child: FloatingActionButton(
                        onPressed: _onHomeScreen ? _openAddMenu : _goHome,
                        tooltip: _onHomeScreen ? "Add" : "Back to this check",
                        child: Icon(_onHomeScreen ? Icons.add : Icons.home),
                    ),
                ),
            ),
            ),
        );
    }
}
