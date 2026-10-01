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
    late DateTime? _startDate = widget.existing?.dueDate;

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
            initialDate: widget.existing?.dueDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
        );
        return startDate;
    }

    // Get actions if adding an expense
    List<Widget> _actions(ExpenseModel? existing) {
        // Helper function to validate input and create an ExpenseModel
        void createExpenseModel() {
            // Name is just name
            final String name = _nameController.text.trim();
            // Amount should already be in currency format based on allowed input
            final double? amount = double.tryParse(_amountController.text.trim());
            // Frequency should be a positive integer
            final int? frequency = int.tryParse(_frequencyController.text.trim());
            // Frequency unit is already selected from a dropdown
            final FrequencyUnit frequencyUnits = _frequencyUnit;
            // Start date is already selected from a date picker
            final DateTime? dueDate = _startDate;
            // Category is already selected from a dropdown
            final String category = _category;
            // Inputs should be validated by the form, but we can double-check here
            if (name.isEmpty || amount == null || frequency == null || frequency <= 0 || dueDate == null) {
                // Raise an error -- this should not happen if the form is validated correctly
                throw Exception("Invalid input");
            }

            ExpenseModel expense = ExpenseModel(
                name: name,
                amount: amount,
                frequency: frequency,
                frequencyUnits: frequencyUnits,
                dueDate: dueDate,
                category: category,
            );
            // TODO: Save the expense to storage here

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
                    if (_formKey.currentState!.validate()) {
                        createExpenseModel();
                        Navigator.of(context).pop(); // Close the dialog
                    } else {
                        // Show a snackbar or some feedback that validation failed
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please fix the errors in the form")),
                        );
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
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                            // Regex to allow any positive number
                                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                        ],
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
                            child: Text(_startDate == null
                                // If null, use today
                                ? "Starting Date: ${DateTime.now().toLocal().toString().split(' ')[0]}"
                                : "Starting Date: ${_startDate!.toLocal().toString().split(' ')[0]}"
                                ),
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