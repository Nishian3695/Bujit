// Add/edit dialog for a credit card (CreditModel). Cards always bill monthly.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation_items/expense_activity/credit_model.dart';
import '../utils/date_utils.dart';
import '../utils/frequency_unit.dart';
import 'confirm_delete.dart';

// Returns the created/edited CreditModel, or null if cancelled or deleted. When
// editing, Delete asks for confirmation and then calls [onDelete].
Future<CreditModel?> showCreditCardDialog(
    BuildContext context, {
    CreditModel? existing,
    VoidCallback? onDelete,
}) {
    return showAdaptiveDialog<CreditModel>(
        context: context,
        builder: (context) => _CreditCardDialog(existing: existing, onDelete: onDelete),
    );
}

class _CreditCardDialog extends StatefulWidget {
    final CreditModel? existing;
    final VoidCallback? onDelete;
    const _CreditCardDialog({this.existing, this.onDelete});

    @override
    State<_CreditCardDialog> createState() => _CreditCardDialogState();
}

class _CreditCardDialogState extends State<_CreditCardDialog> {
    late final TextEditingController _name = TextEditingController(text: widget.existing?.name);
    late final TextEditingController _balance =
        TextEditingController(text: widget.existing?.amount.toStringAsFixed(2) ?? "0.00");
    late final TextEditingController _limit =
        TextEditingController(text: widget.existing?.creditLimit.toStringAsFixed(2));
    final _formKey = GlobalKey<FormState>();
    // Next due date: the card's current one when editing, else a month from today.
    late DateTime _dueDate = widget.existing?.currentDueDate ?? DateTime(
        todayDate().year, todayDate().month + 1, todayDate().day);

    @override
    void dispose() {
        _name.dispose();
        _balance.dispose();
        _limit.dispose();
        super.dispose();
    }

    static String? _amountError(String? value, {required bool positive}) {
        final double? amount = double.tryParse(value?.trim() ?? "");
        if (amount == null) return "Enter a valid amount";
        if (positive && amount <= 0) return "Enter an amount greater than 0";
        return null;
    }

    // An unchanged due date keeps the card's schedule (its original due date
    // anchors the day of month); a new one starts a schedule from that date.
    CreditModel _build() {
        final CreditModel? existing = widget.existing;
        final bool keepSchedule = existing != null && _dueDate == existing.currentDueDate;
        return CreditModel(
            id: existing?.id,
            name: _name.text.trim(),
            amount: double.parse(_balance.text.trim()),
            creditLimit: double.parse(_limit.text.trim()),
            startDate: keepSchedule ? existing.startDate : _dueDate,
            currentDueDate: keepSchedule ? existing.currentDueDate : null,
            frequency: 1,
            frequencyUnits: FrequencyUnit.monthly,
            googleTaskId: existing?.googleTaskId,
            remindInTasks: existing?.remindInTasks ?? true,
        );
    }

    TextFormField _moneyField(TextEditingController controller, String label, {required bool positive}) {
        return TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: InputDecoration(prefixText: '\$', labelText: label),
            validator: (value) => _amountError(value, positive: positive),
        );
    }

    @override
    Widget build(BuildContext context) {
        final CreditModel? existing = widget.existing;
        return AlertDialog.adaptive(
            title: Text(existing == null ? "Add Credit Card" : "Edit Credit Card"),
            content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(labelText: "Card Name"),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty) ? "Name is required" : null,
                            ),
                            _moneyField(_balance, "Balance Owed", positive: false),
                            _moneyField(_limit, "Credit Limit", positive: true),
                            TextButton(
                                onPressed: () async {
                                    final DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: _dueDate,
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime(2100),
                                    );
                                    if (picked != null) setState(() => _dueDate = dateOnly(picked));
                                },
                                child: Text("Next Due Date: ${_dueDate.toString().split(' ')[0]}"),
                            ),
                        ],
                    ),
                ),
            ),
            actions: [
                if (existing != null)
                    TextButton(
                        onPressed: () async {
                            final NavigatorState navigator = Navigator.of(context);
                            if (await confirmDelete(context, "Credit Card", existing.name)) {
                                widget.onDelete?.call();
                                navigator.pop();
                            }
                        },
                        child: const Text("Delete"),
                    ),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                        if (_formKey.currentState!.validate()) Navigator.of(context).pop(_build());
                    },
                    child: const Text("Save"),
                ),
            ],
        );
    }
}
