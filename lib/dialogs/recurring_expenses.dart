// Add/edit dialog for a recurring ExpenseModel entry.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation_items/banking/bank_account_model.dart';
import '../navigation_items/expense_activity/expense_model.dart';
import '../navigation_items/expense_activity/funding_source.dart';
import '../utils/category_manager.dart';
import '../utils/frequency_unit.dart';
import 'confirm_delete.dart';
import 'connected_account_field.dart';
import 'paid_from_field.dart';

// Returns the created/edited ExpenseModel, or null if the dialog was cancelled
// or the expense was deleted. [categories] are the user's categories ("Other"
// and a "New Category" option are added). When editing, Delete asks for
// confirmation and then calls [onDelete]. [showTasksOption] adds the Google
// Tasks reminder switch (while Google Tasks sync is on). [sources] are the
// "Paid from" choices (BalanceModel.paymentOptions(forCard: false)); [connectable]
// the linked credit/loan accounts its amount can sync from.
Future<ExpenseModel?> showRecurringExpenseDialog(
    BuildContext context, {
    ExpenseModel? existing,
    List<String> categories = const [],
    VoidCallback? onDelete,
    bool showTasksOption = false,
    List<SourceOption> sources = const [SourceOption.currentBalance],
    List<BankAccountModel> connectable = const [],
}) {
    return showAdaptiveDialog<ExpenseModel>(
        context: context,
        builder: (context) => _RecurringExpenseDialog(
            existing: existing,
            categories: categories,
            onDelete: onDelete,
            showTasksOption: showTasksOption,
            sources: sources,
            connectable: connectable,
        ),
    );
}

// Dialog-local form state stays here, not in ExpenseActivityState.
class _RecurringExpenseDialog extends StatefulWidget {
    // The existing ExpenseModel to edit, or null to create a new one
    final ExpenseModel? existing;
    final List<String> categories;
    final VoidCallback? onDelete;
    final bool showTasksOption;
    final List<SourceOption> sources;
    final List<BankAccountModel> connectable;
    const _RecurringExpenseDialog({
        this.existing,
        required this.categories,
        this.onDelete,
        this.showTasksOption = false,
        required this.sources,
        required this.connectable,
    });

    @override
    State<_RecurringExpenseDialog> createState() => _RecurringExpenseDialogState();
}

class _RecurringExpenseDialogState extends State<_RecurringExpenseDialog> {
    // Controllers for the text fields so we can read their values and dispose of them properly
    // Fill in with existing values if editing an existing expense
    late final TextEditingController _nameController =
        TextEditingController(text: widget.existing?.name);
    late final TextEditingController _amountController =
        TextEditingController(text: widget.existing?.amount.toStringAsFixed(2));
    // Defaults to 1 for a new expense
    late final TextEditingController _frequencyController =
        TextEditingController(text: widget.existing?.frequency.toString() ?? "1");
    // Key used to trigger validation on all TextFormFields below at once via _formKey.currentState!.validate().
    final _formKey = GlobalKey<FormState>();
    // Defined things to change but keep locally until Save is pressed
    late FrequencyUnit _frequencyUnit = widget.existing?.frequencyUnits ?? FrequencyUnit.values.first;
    late String _category = widget.existing?.category ?? otherCategory;
    // Like the Java app, editing shows the next due date and adding defaults to today.
    late DateTime _startDate = widget.existing?.currentDueDate ?? _today;
    // Optional last date (inclusive); null = never ends.
    late DateTime? _endDate = widget.existing?.endDate;
    late bool _remindInTasks = widget.existing?.remindInTasks ?? true;
    late SourceOption _source = initialSource(widget.sources, widget.existing);
    // The connected account its amount syncs from (null = typed).
    late BankAccountModel? _linked = _connectable(widget.existing?.linkedAccountId);

    BankAccountModel? _connectable(String? id) {
        for (final BankAccountModel a in widget.connectable) {
            if (a.id == id) return a;
        }
        return null;
    }
    // Categories added from this dialog ("New Category"), shown in the dropdown.
    final List<String> _addedCategories = [];
    String? _endDateError;

    static DateTime get _today {
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day);
    }

    // Formats a date for the button label as YYYY-MM-DD.
    static String _formatDate(DateTime date) => date.toLocal().toString().split(' ')[0];

    @override
    void dispose() {
        _nameController.dispose();
        _amountController.dispose();
        _frequencyController.dispose();
        super.dispose();
    }

    // Dropdown entries: the user's categories, "Other", then "New Category". The
    // current category is always included, even if it was since removed.
    List<String> get _currentItems {
        final List<String> items = getCategories([...widget.categories, ..._addedCategories]);
        if (!items.contains(_category)) items.insert(0, _category);
        return items;
    }

    // Show a date picker and return the selected date, or null if cancelled
    Future<DateTime?> _selectDate(BuildContext context, DateTime initial) async {
        return showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
        );
    }

    // An end date before the start is invalid -- unless neither date was touched
    // while editing an expense that has already ended (its next-due date is then
    // past its end date), so it can still be saved. Same rule as the Java app.
    bool _endDateValid() {
        final ExpenseModel? existing = widget.existing;
        final bool untouched = existing != null
            && _startDate == existing.currentDueDate
            && _endDate == existing.endDate;
        final DateTime? end = _endDate;
        return end == null || !end.isBefore(_startDate) || untouched;
    }

    // Get actions if adding an expense
    List<Widget> _actions(ExpenseModel? existing) {
        // Builds the ExpenseModel from the validated form. Saving it is the
        // caller's job: the dialog just returns it from showRecurringExpenseDialog.
        ExpenseModel createExpenseModel() {
            // Name is just name
            final String name = _nameController.text.trim();
            // Amount should already be in currency format based on allowed input
            final double? amount = double.tryParse(_amountController.text.trim());
            // Frequency should be a positive integer
            final int? frequency = int.tryParse(_frequencyController.text.trim());
            // Inputs should be validated by the form, but we can double-check here
            if (name.isEmpty || amount == null || amount <= 0 || frequency == null || frequency <= 0) {
                // Raise an error -- this should not happen if the form is validated correctly
                throw Exception("Invalid input");
            }
            // An unchanged date when editing keeps the existing schedule (its original
            // start anchors the day of month); picking a new date starts a new one.
            final bool keepSchedule = existing != null && _startDate == existing.currentDueDate;
            return ExpenseModel(
                id: existing?.id,
                name: name,
                amount: amount,
                frequency: frequency,
                frequencyUnits: _frequencyUnit,
                startDate: keepSchedule ? existing.startDate : _startDate,
                currentDueDate: keepSchedule ? existing.currentDueDate : null,
                endDate: _endDate,
                category: _category,
                googleTaskId: existing?.googleTaskId,
                remindInTasks: _remindInTasks,
                source: _source.source,
                sourceId: _source.id,
                linkedAccountId: _linked?.id,
            );
        }

        List<Widget> actions = [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
            ),
            TextButton(
                onPressed: () {
                    // validate() runs every TextFormField's validator below and
                    // shows their error text; only proceed if all of them pass.
                    // On failure validate() already shows each field's error inline, so
                    // there's no SnackBar: it would need a Scaffold behind the dialog and
                    // would render under the modal barrier anyway.
                    final bool endOk = _endDateValid();
                    setState(() => _endDateError = endOk ? null : "Ending date can't be before the starting date");
                    if (_formKey.currentState!.validate() && endOk) {
                        // Close the dialog, handing the expense back to the caller
                        Navigator.of(context).pop(createExpenseModel());
                    }
                },
                child: const Text("Save"),
            ),
        ];

        // If editing, add a "Delete" button
        if (existing != null) {
            actions.insert(0, TextButton(
                onPressed: () async {
                    final NavigatorState navigator = Navigator.of(context);
                    if (await confirmDelete(context, "Expense", existing.name)) {
                        widget.onDelete?.call();
                        navigator.pop(); // Close the dialog
                    }
                },
                child: const Text("Delete"),
            ));
        }

        return actions;
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog.adaptive(
            title: Text((widget.existing == null) ? "Add Expense" : "Edit Expense"),
            // Form with GlobalKey<FormState> lets single validate() check TextFormFields
            content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            // Expense name
                            TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                    labelText: "Expense Name",
                                    hintText: "e.g., Rent",
                                ),
                                validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                        return "Name is required";
                                    }
                                    return null;
                                },
                            ),
                            // Expense amount
                            TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                    // Regex to allow only numbers and up to two decimal places
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                decoration: const InputDecoration(
                                    prefixText: '\$',
                                    labelText: "Amount",
                                    hintText: "0.00",
                                ),
                                validator: (value) {
                                    final amount = double.tryParse(value?.trim() ?? "");
                                    if (amount == null) {
                                        return "Enter a valid amount";
                                    }
                                    if (amount <= 0) {
                                        return "Enter an amount greater than 0";
                                    }
                                    return null;
                                },
                            ),
                            ConnectedAccountField(
                                accounts: widget.connectable,
                                linked: _linked,
                                onPick: (account) => setState(() {
                                    _linked = account;
                                    if (_nameController.text.trim().isEmpty) _nameController.text = account.displayName;
                                    final double? ledger = account.ledger;
                                    if (ledger != null) _amountController.text = ledger.abs().toStringAsFixed(2);
                                }),
                                onUnlink: () => setState(() => _linked = null),
                            ),
                            // Row of (frequency, frequency unit) fields
                            Row(
                                children: [
                                    // Frequency count field
                                    Expanded(
                                        child: TextFormField(
                                            controller: _frequencyController,
                                            // Whole numbers only: the frequency is parsed with int.tryParse
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            decoration: const InputDecoration(
                                                labelText: "Frequency",
                                                hintText: "e.g., 1",
                                            ),
                                            validator: (value) {
                                                final frequency = int.tryParse(value?.trim() ?? "");
                                                if (frequency == null || frequency <= 0) {
                                                    return "Enter a frequency greater than 0";
                                                }
                                                return null;
                                            },
                                        ),
                                    ),
                                    // Frequency unit dropdown
                                    DropdownButton<FrequencyUnit>(
                                        value: _frequencyUnit,
                                        items: FrequencyUnit.values
                                            .map((unit) => DropdownMenuItem(value: unit, child: Text(unit.label)))
                                            .toList(),
                                        onChanged: (unit) => setState(() => _frequencyUnit = unit!),
                                    ),
                                ],
                            ),
                            // Start date picker
                            TextButton(
                                onPressed: () async {
                                    final picked = await _selectDate(context, _startDate);
                                    if (picked != null) {
                                        setState(() => _startDate = picked);
                                    }
                                },
                                child: Text("Starting Date: ${_formatDate(_startDate)}"),
                            ),
                            // End date picker ("Never" until one is picked; Clear resets it)
                            Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    TextButton(
                                        onPressed: () async {
                                            final picked = await _selectDate(context, _endDate ?? _startDate);
                                            if (picked != null) {
                                                setState(() { _endDate = picked; _endDateError = null; });
                                            }
                                        },
                                        child: Text("Ending Date: ${_endDate == null ? "Never" : _formatDate(_endDate!)}"),
                                    ),
                                    if (_endDate != null)
                                        TextButton(
                                            onPressed: () => setState(() { _endDate = null; _endDateError = null; }),
                                            child: const Text("Clear"),
                                        ),
                                ],
                            ),
                            if (_endDateError != null)
                                Text(_endDateError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                            // Category dropdown
                            DropdownButton<String>(
                                value: _category,
                                items: _currentItems
                                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                                    .toList(),
                                onChanged: (category) async {
                                    if (category == null) return;
                                    if (category != newCategory) {
                                        setState(() => _category = category);
                                        return;
                                    }
                                    final String? added = await askNewCategory(context);
                                    if (added != null) {
                                        setState(() {
                                            if (!_currentItems.contains(added)) _addedCategories.add(added);
                                            _category = added;
                                        });
                                    }
                                },
                            ),
                            PaidFromField(
                                options: widget.sources,
                                value: _source,
                                onChanged: (source) => setState(() => _source = source),
                            ),
                            if (widget.showTasksOption)
                                SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("Remind me in Google Tasks"),
                                    subtitle: const Text("Its task gets the next due date"),
                                    value: _remindInTasks,
                                    onChanged: (value) => setState(() => _remindInTasks = value),
                                ),
                        ],
                    ),
                ),
            ),
            actions: _actions(widget.existing),
        );
    }
}
