// Add/edit dialog for a manual account (the Java app's showManualAccountDialog):
// name, type and balance (not negative). Returns the entered values; the caller
// applies them (see LinkedAccountsActivity), so a balance change can move the
// current balance through BalanceModel.adjustAccount.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation_items/banking/manual_account_model.dart';
import 'date_field.dart';

typedef ManualAccountDraft = ({String name, String accountType, double balance});

// Returns the draft, or null if cancelled or deleted. When editing, Delete asks
// for confirmation ([deleteWarning] is added to it) and then calls [onDelete].
Future<ManualAccountDraft?> showManualAccountDialog(
    BuildContext context, {
    ManualAccountModel? existing,
    VoidCallback? onDelete,
    String? deleteWarning,
}) {
    return showAdaptiveDialog<ManualAccountDraft>(
        context: context,
        builder: (context) => _ManualAccountDialog(existing, onDelete, deleteWarning),
    );
}

class _ManualAccountDialog extends StatefulWidget {
    final ManualAccountModel? existing;
    final VoidCallback? onDelete;
    final String? deleteWarning;
    const _ManualAccountDialog(this.existing, this.onDelete, this.deleteWarning);

    @override
    State<_ManualAccountDialog> createState() => _ManualAccountDialogState();
}

class _ManualAccountDialogState extends State<_ManualAccountDialog> {
    late final TextEditingController _name = TextEditingController(text: widget.existing?.name);
    late final TextEditingController _balance =
        TextEditingController(text: widget.existing?.balance.toStringAsFixed(2));
    final _formKey = GlobalKey<FormState>();
    late String _type = widget.existing?.accountType ?? "Savings"; // Java's default

    @override
    void dispose() {
        _name.dispose();
        _balance.dispose();
        super.dispose();
    }

    Future<void> _delete() async {
        final ManualAccountModel existing = widget.existing!;
        final NavigatorState navigator = Navigator.of(context);
        final String warning = widget.deleteWarning == null ? "" : "\n\n${widget.deleteWarning}";
        final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Delete Account"),
                content: Text("Delete \"${existing.name}\"? This cannot be undone.$warning"),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete")),
                ],
            ),
        );
        if (confirmed != true) return;
        widget.onDelete?.call();
        navigator.pop();
    }

    @override
    Widget build(BuildContext context) {
        final bool adding = widget.existing == null;
        // A custom type (e.g. from a CSV import) stays selectable.
        final List<String> types = [
            ...ManualAccountModel.accountTypes,
            if (!ManualAccountModel.accountTypes.contains(_type)) _type,
        ];
        return AlertDialog(
            title: Text(adding ? "Add Account" : "Edit Account"),
            content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: formSpacing,
                        children: [
                            TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(labelText: "Account name", hintText: "e.g., Emergency fund"),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty) ? "Name is required" : null,
                            ),
                            DropdownButtonFormField<String>(
                                initialValue: _type,
                                decoration: const InputDecoration(labelText: "Type"),
                                items: [for (final String type in types) DropdownMenuItem(value: type, child: Text(type))],
                                onChanged: (type) => setState(() => _type = type ?? _type),
                            ),
                            TextFormField(
                                controller: _balance,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                decoration: const InputDecoration(prefixText: "\$", labelText: "Balance"),
                                validator: (value) =>
                                    double.tryParse(value?.trim() ?? "") == null ? "Enter a valid balance" : null,
                            ),
                        ],
                    ),
                ),
            ),
            actions: [
                if (!adding) TextButton(onPressed: _delete, child: const Text("Delete")),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.of(context).pop((
                            name: _name.text.trim(),
                            accountType: _type,
                            balance: double.parse(_balance.text.trim()),
                        ));
                    },
                    child: Text(adding ? "Add" : "Save"),
                ),
            ],
        );
    }
}
