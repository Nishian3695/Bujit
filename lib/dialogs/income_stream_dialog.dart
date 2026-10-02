// Add/edit dialog for an income stream (IncomeStreamModel).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation_items/income_streams/income_stream_model.dart';
import '../utils/date_utils.dart';
import '../utils/frequency_unit.dart';
import 'confirm_delete.dart';

// Returns the created/edited stream, or null if cancelled or deleted. When
// editing, Delete asks for confirmation and then calls [onDelete].
//
// The starting date is the first (or most recent) payday. Paychecks are
// credited by BalanceModel.makeRecent: a starting date in the future gets its
// first paycheck credited when it arrives; a past or current one is treated as
// already in the balance, and editing only ever affects future paydays.
Future<IncomeStreamModel?> showIncomeStreamDialog(
    BuildContext context, {
    IncomeStreamModel? existing,
    VoidCallback? onDelete,
}) {
    return showAdaptiveDialog<IncomeStreamModel>(
        context: context,
        builder: (context) => _IncomeStreamDialog(existing: existing, onDelete: onDelete),
    );
}

class _IncomeStreamDialog extends StatefulWidget {
    final IncomeStreamModel? existing;
    final VoidCallback? onDelete;
    const _IncomeStreamDialog({this.existing, this.onDelete});

    @override
    State<_IncomeStreamDialog> createState() => _IncomeStreamDialogState();
}

class _IncomeStreamDialogState extends State<_IncomeStreamDialog> {
    late final TextEditingController _name = TextEditingController(text: widget.existing?.name);
    late final TextEditingController _amount =
        TextEditingController(text: widget.existing?.amount.toStringAsFixed(2));
    late final TextEditingController _frequency =
        TextEditingController(text: widget.existing?.frequency.toString() ?? "2");
    final _formKey = GlobalKey<FormState>();
    late FrequencyUnit _unit = widget.existing?.frequencyUnits ?? FrequencyUnit.weekly;
    late DateTime _startDate = widget.existing?.startDate ?? todayDate();

    @override
    void dispose() {
        _name.dispose();
        _amount.dispose();
        _frequency.dispose();
        super.dispose();
    }

    IncomeStreamModel _build() => IncomeStreamModel(
        id: widget.existing?.id,
        name: _name.text.trim(),
        amount: double.parse(_amount.text.trim()),
        startDate: _startDate,
        frequency: int.parse(_frequency.text.trim()),
        frequencyUnits: _unit,
        isActive: widget.existing?.isActive ?? false,
    );

    @override
    Widget build(BuildContext context) {
        final IncomeStreamModel? existing = widget.existing;
        return AlertDialog.adaptive(
            title: Text(existing == null ? "Add Income Stream" : "Edit Income Stream"),
            content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(labelText: "Name", hintText: "e.g., Main Job"),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty) ? "Name is required" : null,
                            ),
                            TextFormField(
                                controller: _amount,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                decoration: const InputDecoration(prefixText: '\$', labelText: "Paycheck Amount"),
                                validator: (value) {
                                    final double? amount = double.tryParse(value?.trim() ?? "");
                                    if (amount == null) return "Enter a valid amount";
                                    if (amount <= 0) return "Enter an amount greater than 0";
                                    return null;
                                },
                            ),
                            Row(
                                children: [
                                    Expanded(
                                        child: TextFormField(
                                            controller: _frequency,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            decoration: const InputDecoration(labelText: "Every"),
                                            validator: (value) {
                                                final int? frequency = int.tryParse(value?.trim() ?? "");
                                                return (frequency == null || frequency <= 0)
                                                    ? "Enter a number greater than 0" : null;
                                            },
                                        ),
                                    ),
                                    DropdownButton<FrequencyUnit>(
                                        value: _unit,
                                        items: FrequencyUnit.values
                                            .map((unit) => DropdownMenuItem(value: unit, child: Text(unit.label)))
                                            .toList(),
                                        onChanged: (unit) => setState(() => _unit = unit!),
                                    ),
                                ],
                            ),
                            TextButton(
                                onPressed: () async {
                                    final DateTime? picked = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate,
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime(2100),
                                    );
                                    if (picked != null) setState(() => _startDate = dateOnly(picked));
                                },
                                child: Text("Starting Date: ${_startDate.toString().split(' ')[0]}"),
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
                            if (await confirmDelete(context, "Income Stream", existing.name)) {
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
