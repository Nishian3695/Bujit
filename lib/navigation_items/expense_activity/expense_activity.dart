// Mirrors ExpenseActivity/ExpenseActivity.java in the original Java app.
//
// All balance and schedule math lives in BalanceModel; this screen only asks
// it for the check being viewed (index 0 = current, 1+ = projected) and
// displays the result. Data changes go through AppState, which saves them.
// The layout is a placeholder until the UI pass.
import 'package:flutter/material.dart';
import '../../utils/date_utils.dart';
import '../../utils/frequency_unit.dart';
import '../../utils/legal.dart';
import '../../utils/money.dart';
import '../../utils/theme_helper.dart';
import '../../utils/ui.dart';
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

    // Multi-select (the Java app's selection mode): the rows ticked, or null when
    // not selecting.
    Set<ExpenseItem>? _selected;
    bool get _selecting => _selected != null;

    @override
    void initState() {
        super.initState();
        // Any screen changing data (income streams, cards, settings) rebuilds this one.
        _state.addListener(_refresh);
        // A fresh install shows the disclaimer first; the tutorial follows it.
        if (!_state.data.disclaimerAccepted) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _showDisclaimer());
        }
    }

    // The Java app's "Before You Begin" dialog; it can only be accepted.
    Future<void> _showDisclaimer() async {
        if (!mounted) return;
        await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => PopScope(
                canPop: false,
                child: AlertDialog(
                    title: const Text("Before You Begin"),
                    content: const SingleChildScrollView(child: Text("$disclaimerText\n\n$disclaimerAcknowledgement")),
                    actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("I Understand")),
                    ],
                ),
            ),
        );
        await _state.acceptDisclaimer();
    }

    // ── Multi-select ────────────────────────────────────────────────────────

    void _startSelecting() => setState(() => _selected = Set.identity());

    void _stopSelecting() => setState(() => _selected = null);

    // Ticking the last row off ends selecting, as in the Java app.
    void _toggleSelected(ExpenseItem item) {
        final Set<ExpenseItem> selected = _selected!;
        setState(() {
            if (!selected.remove(item)) selected.add(item);
            if (selected.isEmpty) _selected = null;
        });
    }

    // Select All, or none if everything is already selected.
    void _toggleSelectAll() {
        final Set<ExpenseItem> selected = _selected!;
        setState(() {
            if (selected.length == _balance.expenses.length) {
                selected.clear();
            } else {
                selected.addAll(_balance.expenses);
            }
        });
    }

    Future<void> _deleteSelected() async {
        final Set<ExpenseItem> selected = _selected!;
        if (selected.isEmpty) return;
        final int count = selected.length;
        final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Delete Expenses"),
                content: Text("Delete $count expense${count == 1 ? "" : "s"}? This cannot be undone."),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete")),
                ],
            ),
        );
        if (confirmed != true) return;
        _stopSelecting();
        await _state.removeItems(selected);
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
        if (_selecting) return;
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

    // Pull to refresh: syncs linked banks' balances right away (the Java app's
    // swipe refresh), offering to reconnect any that expired.
    Future<void> _syncBanks() async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        final result = await _state.refreshBanks(force: true);
        _refresh();
        if (result != null && result.needsRelink.isNotEmpty) {
            messenger.showSnackBar(SnackBar(
                content: Text("${result.needsRelink.join(", ")}: bank connection expired. Reconnect in Linked Accounts."),
            ));
        }
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
            connectable: _balance.linkedAccounts.where((a) => a.isCredit || a.isLoan).toList(),
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
                connectable: _balance.linkedAccounts.where((a) => a.isCredit).toList(),
            )
            : await showRecurringExpenseDialog(
                context,
                existing: item as ExpenseModel,
                categories: _state.data.categories,
                onDelete: delete,
                showTasksOption: _state.data.tasksSyncEnabled,
                sources: _balance.paymentOptions(forCard: false),
                connectable: _balance.linkedAccounts.where((a) => a.isCredit || a.isLoan).toList(),
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
    static String _date(DateTime date) => shortDate(date);

    // "Synced today at 3:04 PM" / "Synced Oct 2 at 3:04 PM" under the balance, while
    // linked accounts make it up (the Java app's sync label).
    String? get _syncLabel {
        final DateTime? time = _state.data.lastBankSync;
        if (time == null || !_balance.linkedAccounts.any((a) => a.countsTowardBalance)) return null;
        final DateTime now = DateTime.now();
        final int hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
        final String clock = "$hour:${time.minute.toString().padLeft(2, "0")} ${time.hour < 12 ? "AM" : "PM"}";
        final bool today = time.year == now.year && time.month == now.month && time.day == now.day;
        return today ? "Synced today at $clock" : "Synced ${shortDate(time, today: now)} at $clock";
    }

    // The Java app's check bar: a card in the accent color with ◀ the check ▶, and
    // what's being projected under it. Long-pressing the title opens the
    // projection settings, as in the Java app.
    Widget get checkBar {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final String? subtitle = _balance.projection == null ? null : "Projecting: ${_balance.projection!.describe()}";
        return Card(
            color: scheme.primary,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TutorialTarget(
                id: "check_nav",
                child: Row(
                    children: [
                        IconButton(
                            onPressed: _onHomeScreen ? null : _previousCheck,
                            icon: const Icon(Icons.chevron_left),
                            color: scheme.onPrimary,
                            disabledColor: scheme.onPrimary.withValues(alpha: 0.35),
                            tooltip: "Previous check",
                        ),
                        Expanded(
                            child: GestureDetector(
                                onLongPress: _openProjectionSettings,
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Column(
                                        children: [
                                            Text(
                                                _onHomeScreen ? "This Check" : "Check of ${_date(_summary.window.start)}",
                                                style: TextStyle(color: scheme.onPrimary, fontSize: 17,
                                                    fontWeight: FontWeight.w500),
                                            ),
                                            if (subtitle != null)
                                                Text(subtitle,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.75),
                                                        fontSize: 11)),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                        IconButton(
                            onPressed: _nextCheck,
                            icon: const Icon(Icons.chevron_right),
                            color: scheme.onPrimary,
                            tooltip: "Next check",
                        ),
                    ],
                ),
            ),
        );
    }

    // Balance summary card, laid out as in the Java app: two halves with a small
    // label over a large figure. With the Next Check setting on, the right-hand
    // figure adds the next paycheck and is labelled "NEXT CHECK". On this check,
    // tapping the current balance updates it.
    Widget get balanceSummary {
        final bool nextCheck = _state.data.includeNextCheck;
        final double after = nextCheck ? _summary.endBalanceWithNextCheck : _summary.endBalance;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final String? syncLabel = _syncLabel;
        return Card(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            clipBehavior: Clip.antiAlias,
            child: Column(
                children: [
                    IntrinsicHeight(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                Expanded(
                                    child: Tooltip(
                                        message: _onHomeScreen ? "Update balance" : "",
                                        child: InkWell(
                                            onTap: _onHomeScreen ? _updateBalance : null,
                                            onLongPress: _onHomeScreen ? _updateBalance : null,
                                            child: _balanceFigure("CURRENT BALANCE", _summary.startBalance,
                                                scheme.primary),
                                        ),
                                    ),
                                ),
                                const VerticalDivider(width: 1, indent: 12, endIndent: 12),
                                Expanded(
                                    child: _balanceFigure(nextCheck ? "NEXT CHECK" : "AFTER THIS CHECK", after,
                                        BujitColors.of(context).forAmount(after)),
                                ),
                            ],
                        ),
                    ),
                    if (syncLabel != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(syncLabel, style: TextStyle(fontSize: 11,
                                color: scheme.onSurface.withValues(alpha: 0.6))),
                        ),
                ],
            ),
        );
    }

    Widget _balanceFigure(String label, double amount, Color color) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        child: Figure(label: label, value: _money(amount), color: color),
    );

    // The app bar while selecting: how many, Select All and Delete (the Java app's action mode).
    AppBar get _selectionAppBar => AppBar(
        leading: IconButton(onPressed: _stopSelecting, icon: const Icon(Icons.close), tooltip: "Done"),
        title: Text("${_selected!.length} selected"),
        actions: [
            IconButton(
                onPressed: _toggleSelectAll,
                icon: Icon(_selected!.length == _balance.expenses.length ? Icons.deselect : Icons.select_all),
                tooltip: "Select All",
            ),
            IconButton(
                onPressed: _selected!.isEmpty ? null : _deleteSelected,
                icon: const Icon(Icons.delete),
                tooltip: "Delete",
            ),
        ],
    );

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
        title: const Text("Bujit"),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
            if (_onHomeScreen && _balance.expenses.isNotEmpty)
                IconButton(
                    onPressed: _startSelecting,
                    icon: const Icon(Icons.checklist),
                    tooltip: "Select",
                ),
            IconButton(
                onPressed: _openProjectionSettings,
                icon: const Icon(Icons.tune),
                tooltip: "Projection settings",
            ),
        ],
    );

    // Expense list header, over the rows' name (with its details) and amount.
    Widget get expenseListHeader {
        final TextStyle style = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.9,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55));
        return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text("EXPENSE", style: style), Text("AMOUNT", style: style)],
            ),
        );
    }

    // The Java app's Rate column: the amount per period ("$15.99/mo", "$40.00/2wk").
    // A card has no fixed rate, so it shows what it owes as of this check
    // ("$640.25 owed"; Java's "/mo" there wasn't true).
    static String _rate(ExpenseItem expense) {
        if (expense is CreditModel) return "${_money(expense.displayBalance)} owed";
        final int f = expense.frequency;
        final String unit = switch (expense.frequencyUnits) {
            FrequencyUnit.daily => f == 1 ? "day" : "${f}d",
            FrequencyUnit.weekly => f == 1 ? "wk" : "${f}wk",
            FrequencyUnit.biweekly => "${2 * f}wk",
            FrequencyUnit.monthly => f == 1 ? "mo" : "${f}mo",
            FrequencyUnit.yearly => f == 1 ? "yr" : "${f}yr",
        };
        return "${_money(expense.amount)}/$unit";
    }

    // One row of the expense list, as in the Java app: name; due date (or when it
    // ended); rate (and end date); what pays for it; a link icon when its amount
    // syncs from a bank; a card's utilization bar; and the amount due this check.
    Widget _expenseRow(ExpenseItem expense) {
        final String paidFrom = _balance.paidFromLabel(expense);
        final DateTime? end = expense.endDate;
        final bool ended = end != null && expense.shownDate.isAfter(end);
        final Set<ExpenseItem>? selected = _selected;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final double amount = expense.periodAmount;
        return ListTile(
            key: ObjectKey(expense),
            leading: selected == null
                ? null
                : Checkbox(value: selected.contains(expense), onChanged: (_) => _toggleSelected(expense)),
            title: Row(
                children: [
                    Flexible(child: Text(expense.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
                    if (_balance.linkedAccount(expense.linkedAccountId) != null)
                        Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.link, size: 16, color: scheme.primary, semanticLabel: "Synced from a bank"),
                        ),
                ],
            ),
            subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const SizedBox(height: 2),
                    Text(
                        [
                            ended ? "Ended ${_date(end)}" : "Due ${_date(expense.shownDate)}",
                            _rate(expense) + (end != null && !ended ? " · until ${_date(end)}" : ""),
                            if (paidFrom != "Current Balance") "from $paidFrom",
                        ].join(" · "),
                        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                    if (expense is CreditModel)
                        Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: LinearProgressIndicator(
                                value: expense.creditUtilization.clamp(0.0, 1.0),
                                color: BujitColors.of(context).forUtilization(expense.creditUtilization),
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                            ),
                        ),
                ],
            ),
            // Nothing due this check reads quieter than an amount that is.
            trailing: Text(_money(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                color: amount == 0 ? scheme.onSurfaceVariant.withValues(alpha: 0.6) : scheme.onSurface)),
            onTap: selected != null
                ? () => _toggleSelected(expense)
                : _onHomeScreen ? () => _editItem(expense) : null,
            onLongPress: selected != null ? () => _toggleSelected(expense) : null,
        );
    }

    // Expense list for the check on screen. Rows can be edited and dragged into
    // a new order on the current check only, as in the Java app (projections
    // are read-only).
    Widget get expenseList => RefreshIndicator(
        onRefresh: _syncBanks,
        child: _onHomeScreen && !_selecting
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
            if (!_selecting) checkBar,
            TutorialTarget(id: "balance_card", child: balanceSummary),
            expenseListHeader,
            const Divider(indent: 16, endIndent: 16), // Divider between header and list
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
        // Back ends selecting first.
        return PopScope(
            canPop: _onHomeScreen && !_selecting,
            onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                if (_selecting) {
                    _stopSelecting();
                } else {
                    _previousCheck();
                }
            },
            child: TutorialOverlay(
            state: _state,
            screen: TutorialScreen.home,
            child: Scaffold(
                appBar: _selecting ? _selectionAppBar : appBar,
                drawer: AppDrawer(state: _state, onReturn: _refresh),
                body: mainActivity,
                // Adds a recurring expense or single event on the current check; while
                // viewing a projected check, or selecting, it becomes a home button.
                floatingActionButton: TutorialTarget(
                    id: "add_button",
                    child: FloatingActionButton(
                        onPressed: _selecting ? _stopSelecting : _onHomeScreen ? _openAddMenu : _goHome,
                        tooltip: _selecting ? "Done" : _onHomeScreen ? "Add" : "Back to this check",
                        child: Icon(_onHomeScreen && !_selecting ? Icons.add : Icons.home),
                    ),
                ),
            ),
            ),
        );
    }
}
