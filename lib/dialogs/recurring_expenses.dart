// Add/edit dialog for a recurring ExpenseModel entry.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation_items/expense_activity/expense_model.dart';
import '../utils/frequency_unit.dart';

// Returns the created/edited ExpenseModel, or null if the dialog was cancelled
Future<ExpenseModel?> showRecurringExpenseDialog(
    BuildContext context, {
    ExpenseModel? existing,
}) {
    return showAdaptiveDialog<ExpenseModel>(
        context: context,
        builder: (context) => _RecurringExpenseDialog(existing: existing),
    );
}

// Dialog-local form state stays here, not in ExpenseActivityState.
class _RecurringExpenseDialog extends StatefulWidget {
    // The existing ExpenseModel to edit, or null to create a new one
    final ExpenseModel? existing;
    const _RecurringExpenseDialog({this.existing});

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
    late String _category = widget.existing?.category ?? "Other";
    // Like the Java app, editing shows the next due date and adding defaults to today.
    late DateTime _startDate = widget.existing?.currentDueDate ?? _today;

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

    // Get current items, including user-specified categories if they exist
    // TODO: Get categories from storage instead of hardcoding them
    List<String> get _currentItems {
        return [_category];
    }

    // Show a date picker and return the selected date, or null if cancelled
    Future<DateTime?> _selectStartDate(BuildContext context) async {
        DateTime? startDate = await showDatePicker(
            context: context,
            initialDate: _startDate,
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
        );
        return startDate;
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
                category: _category,
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
                    if (_formKey.currentState!.validate()) {
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
                onPressed: () {
                    // TODO: Implement delete dialog
                    Navigator.of(context).pop(); // Close the dialog
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
                        // TODO: Add a "From Connected Account" button
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
                                final picked = await _selectStartDate(context);
                                if (picked != null) {
                                    setState(() => _startDate = picked);
                                }
                            },
                            child: Text("Starting Date: ${_formatDate(_startDate)}"),
                        ),
                        // Category dropdown
                        DropdownButton<String>(
                            value: _category,
                            items: _currentItems
                                .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                                .toList(),
                            onChanged: (category) => setState(() => _category = category!),
                        ),
                    ],
                ),
            ),
            actions: _actions(widget.existing),
        );
    }
}