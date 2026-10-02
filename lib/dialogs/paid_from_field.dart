// The "Paid from" dropdown of the expense and credit card dialogs (the Java
// app's Source field). Options come from BalanceModel.paymentOptions.
import 'package:flutter/material.dart';
import '../navigation_items/expense_activity/expense_item.dart';
import '../navigation_items/expense_activity/funding_source.dart';

// The option [existing] is paid from; one that no longer exists falls back to the balance.
SourceOption initialSource(List<SourceOption> options, ExpenseItem? existing) {
    if (existing == null) return SourceOption.currentBalance;
    return options.firstWhere(
        (option) => option.matches(existing.source, existing.sourceId),
        orElse: () => SourceOption.currentBalance,
    );
}

class PaidFromField extends StatelessWidget {
    final List<SourceOption> options;
    final SourceOption value;
    final ValueChanged<SourceOption> onChanged;

    const PaidFromField({super.key, required this.options, required this.value, required this.onChanged});

    @override
    Widget build(BuildContext context) {
        return DropdownButtonFormField<String>(
            initialValue: value.key,
            decoration: const InputDecoration(labelText: "Paid from"),
            items: [
                for (final SourceOption option in options)
                    DropdownMenuItem(value: option.key, child: Text(option.label)),
            ],
            onChanged: (key) => onChanged(
                options.firstWhere((o) => o.key == key, orElse: () => SourceOption.currentBalance)),
        );
    }
}
