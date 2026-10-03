// Add/edit dialog for a single event: name, amount, debit/credit, and what it
// applies to (the Current Balance, a manual account or a credit card). Returns
// an unapplied draft; the caller applies it through SingleEventsLedger.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation_items/expense_activity/funding_source.dart';
import '../navigation_items/single_events/single_event_model.dart';
import 'date_field.dart';

// Returns the draft, or null if cancelled or removed. When editing, Remove asks
// for confirmation (warning the effect will be undone) and then calls [onRemove].
Future<SingleEventModel?> showSingleEventDialog(
    BuildContext context, {
    SingleEventModel? existing,
    required List<SourceOption> targets,
    VoidCallback? onRemove,
}) {
    return showAdaptiveDialog<SingleEventModel>(
        context: context,
        builder: (context) => _SingleEventDialog(existing: existing, targets: targets, onRemove: onRemove),
    );
}

class _SingleEventDialog extends StatefulWidget {
    final SingleEventModel? existing;
    final List<SourceOption> targets; // SingleEventsLedger.targets
    final VoidCallback? onRemove;
    const _SingleEventDialog({this.existing, required this.targets, this.onRemove});

    @override
    State<_SingleEventDialog> createState() => _SingleEventDialogState();
}

class _SingleEventDialogState extends State<_SingleEventDialog> {
    late final TextEditingController _name = TextEditingController(text: widget.existing?.name);
    late final TextEditingController _amount =
        TextEditingController(text: widget.existing?.amount.toStringAsFixed(2));
    final _formKey = GlobalKey<FormState>();
    late bool _isDebit = widget.existing?.isDebit ?? true;
    // The chosen target. One that no longer exists falls back to the balance.
    late SourceOption _target = _initialTarget();

    static FundingSource _sourceOf(EventTarget target) => switch (target) {
        EventTarget.balance => FundingSource.balance,
        EventTarget.creditCard => FundingSource.creditCard,
        EventTarget.manualAccount => FundingSource.manualAccount,
    };

    SourceOption _initialTarget() {
        final SingleEventModel? existing = widget.existing;
        if (existing == null) return SourceOption.currentBalance;
        final String? id = existing.target == EventTarget.manualAccount ? existing.targetId : existing.targetName;
        return widget.targets.firstWhere(
            (option) => option.matches(_sourceOf(existing.target), id),
            orElse: () => SourceOption.currentBalance,
        );
    }

    @override
    void dispose() {
        _name.dispose();
        _amount.dispose();
        super.dispose();
    }

    SingleEventModel _draft() => SingleEventModel(
        name: _name.text.trim(),
        amount: double.parse(_amount.text.trim()),
        isDebit: _isDebit,
        target: switch (_target.source) {
            FundingSource.balance || FundingSource.linkedAccount => EventTarget.balance,
            FundingSource.creditCard => EventTarget.creditCard,
            FundingSource.manualAccount => EventTarget.manualAccount,
        },
        targetName: switch (_target.source) {
            FundingSource.balance || FundingSource.linkedAccount => null,
            FundingSource.creditCard => _target.id,
            FundingSource.manualAccount => _target.label,
        },
        targetId: _target.source == FundingSource.manualAccount ? _target.id : null,
    );

    Future<void> _remove() async {
        final SingleEventModel existing = widget.existing!;
        final NavigatorState navigator = Navigator.of(context);
        final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Remove Event"),
                content: Text("Remove \"${existing.name}\"? Its effect on your balance will be undone."),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Remove")),
                ],
            ),
        );
        if (confirmed != true) return;
        widget.onRemove?.call();
        navigator.pop();
    }

    @override
    Widget build(BuildContext context) {
        final bool adding = widget.existing == null;
        return AlertDialog(
            title: Text(adding ? "Add Single Event" : "Edit Single Event"),
            content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: formSpacing,
                        children: [
                            TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(labelText: "Name", hintText: "e.g., Concert tickets"),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty) ? "Name is required" : null,
                            ),
                            TextFormField(
                                controller: _amount,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                decoration: const InputDecoration(prefixText: '\$', labelText: "Amount"),
                                validator: (value) {
                                    final double? amount = double.tryParse(value?.trim() ?? "");
                                    return (amount == null || amount <= 0) ? "Enter a valid amount" : null;
                                },
                            ),
                            SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<bool>(
                                    segments: const [
                                        ButtonSegment(value: true, label: Text("Debit")),
                                        ButtonSegment(value: false, label: Text("Credit")),
                                    ],
                                    selected: {_isDebit},
                                    onSelectionChanged: (selection) => setState(() => _isDebit = selection.first),
                                ),
                            ),
                            DropdownButtonFormField<String>(
                                initialValue: _target.key,
                                decoration: const InputDecoration(labelText: "Apply to"),
                                items: [
                                    for (final SourceOption option in widget.targets)
                                        DropdownMenuItem(value: option.key, child: Text(option.label)),
                                ],
                                onChanged: (key) => setState(() => _target = widget.targets
                                    .firstWhere((o) => o.key == key, orElse: () => SourceOption.currentBalance)),
                            ),
                        ],
                    ),
                ),
            ),
            actions: [
                if (!adding) TextButton(onPressed: _remove, child: const Text("Remove")),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                TextButton(
                    onPressed: () {
                        if (_formKey.currentState!.validate()) Navigator.of(context).pop(_draft());
                    },
                    child: Text(adding ? "Add" : "Save"),
                ),
            ],
        );
    }
}
