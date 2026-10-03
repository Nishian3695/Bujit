// Add/edit dialog for a credit card (CreditModel). Cards always bill monthly.
// Cards are referred to by name (what's charged to them, single events), so a
// name can't be shared with another card. A new card has no due date until one
// is picked (no default that could be saved by accident), and a card filled from
// a bank asks for whatever the bank didn't report (the due date always; the limit
// when it's unknown).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation_items/banking/bank_account_model.dart';
import '../navigation_items/expense_activity/credit_model.dart';
import '../navigation_items/expense_activity/funding_source.dart';
import 'connected_account_field.dart';
import 'date_field.dart';
import 'paid_from_field.dart';
import '../utils/frequency_unit.dart';
import 'confirm_delete.dart';

// Returns the created/edited CreditModel, or null if cancelled or deleted. When
// editing, Delete asks for confirmation and then calls [onDelete].
// [sources] are the "Paid from" choices (BalanceModel.paymentOptions(forCard: true));
// [otherCardNames] are the names already taken; [connectable] the linked credit
// accounts its balance and limit can sync from. [linkTo] starts a new card
// already linked to (and filled from) that account.
Future<CreditModel?> showCreditCardDialog(
    BuildContext context, {
    CreditModel? existing,
    VoidCallback? onDelete,
    List<SourceOption> sources = const [SourceOption.currentBalance],
    Iterable<String> otherCardNames = const [],
    List<BankAccountModel> connectable = const [],
    BankAccountModel? linkTo,
}) {
    return showAdaptiveDialog<CreditModel>(
        context: context,
        builder: (context) => _CreditCardDialog(
            existing: existing,
            onDelete: onDelete,
            sources: sources,
            otherCardNames: otherCardNames.toSet(),
            connectable: connectable,
            linkTo: linkTo,
        ),
    );
}

class _CreditCardDialog extends StatefulWidget {
    final CreditModel? existing;
    final VoidCallback? onDelete;
    final List<SourceOption> sources;
    final Set<String> otherCardNames;
    final List<BankAccountModel> connectable;
    final BankAccountModel? linkTo;
    const _CreditCardDialog({
        this.existing,
        this.onDelete,
        required this.sources,
        required this.otherCardNames,
        required this.connectable,
        this.linkTo,
    });

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
    // Next due date: the card's current one when editing; none until picked for a new card.
    late DateTime? _dueDate = widget.existing?.currentDueDate;
    String? _dueDateError;
    late SourceOption _source = initialSource(widget.sources, widget.existing);
    late BankAccountModel? _linked = widget.linkTo ?? _connectable(widget.existing?.linkedAccountId);
    // The linked bank didn't report a limit (or enough to work one out).
    bool _limitUnknown = false;

    @override
    void initState() {
        super.initState();
        final BankAccountModel? linkTo = widget.linkTo;
        if (linkTo != null) _fillFrom(linkTo);
    }

    BankAccountModel? _connectable(String? id) {
        for (final BankAccountModel a in widget.connectable) {
            if (a.id == id) return a;
        }
        return null;
    }

    // The card's balance and limit from the connected account (the same rules as a sync).
    void _fillFrom(BankAccountModel account) {
        final double? ledger = account.ledger;
        if (_name.text.trim().isEmpty) _name.text = account.displayName;
        if (ledger != null) _balance.text = ledger.abs().toStringAsFixed(2);
        final double? limit = account.limit;
        final double? available = account.available;
        _limitUnknown = false;
        if (limit != null && limit > 0) {
            _limit.text = limit.toStringAsFixed(2);
        } else if (ledger != null && available != null && available > 0) {
            _limit.text = (ledger + available).toStringAsFixed(2);
        } else if (widget.existing == null) {
            _limitUnknown = true;
        }
    }

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
        final DateTime dueDate = _dueDate!;
        final bool keepSchedule = existing != null && dueDate == existing.currentDueDate;
        return CreditModel(
            id: existing?.id,
            name: _name.text.trim(),
            amount: double.parse(_balance.text.trim()),
            creditLimit: double.parse(_limit.text.trim()),
            startDate: keepSchedule ? existing.startDate : dueDate,
            currentDueDate: keepSchedule ? existing.currentDueDate : null,
            frequency: 1,
            frequencyUnits: FrequencyUnit.monthly,
            googleTaskId: existing?.googleTaskId,
            remindInTasks: existing?.remindInTasks ?? true,
            source: _source.source,
            sourceId: _source.id,
            linkedAccountId: _linked?.id,
        );
    }

    TextFormField _moneyField(TextEditingController controller, String label,
            {required bool positive, String? helper}) {
        return TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: InputDecoration(prefixText: '\$', labelText: label, helperText: helper),
            validator: (value) => _amountError(value, positive: positive),
        );
    }

    @override
    Widget build(BuildContext context) {
        final CreditModel? existing = widget.existing;
        return AlertDialog(
            title: Text(existing == null ? "Add Credit Card" : "Edit Credit Card"),
            content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: formSpacing,
                        children: [
                            TextFormField(
                                controller: _name,
                                decoration: const InputDecoration(labelText: "Card Name"),
                                validator: (value) {
                                    final String name = value?.trim() ?? "";
                                    if (name.isEmpty) return "Name is required";
                                    if (widget.otherCardNames.contains(name)) return "Another card has this name";
                                    return null;
                                },
                            ),
                            if (ConnectedAccountField.shows(widget.connectable, _linked)) ConnectedAccountField(
                                accounts: widget.connectable,
                                linked: _linked,
                                onPick: (account) => setState(() {
                                    _linked = account;
                                    _fillFrom(account);
                                }),
                                onUnlink: () => setState(() => _linked = null),
                            ),
                            _moneyField(_balance, "Balance Owed", positive: false),
                            _moneyField(_limit, "Credit Limit", positive: true,
                                helper: _limitUnknown ? "Your bank didn't report a limit; enter it" : null),
                            // Blank for a new card, so today isn't saved by accident.
                            DateField(
                                label: "Next due date",
                                value: _dueDate,
                                errorText: _dueDateError,
                                onPicked: (date) => setState(() {
                                    _dueDate = date;
                                    _dueDateError = null;
                                }),
                            ),
                            PaidFromField(
                                options: widget.sources,
                                value: _source,
                                onChanged: (source) => setState(() => _source = source),
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
                        final bool hasDueDate = _dueDate != null;
                        setState(() => _dueDateError = hasDueDate ? null : "Pick the next due date");
                        if (_formKey.currentState!.validate() && hasDueDate) Navigator.of(context).pop(_build());
                    },
                    child: const Text("Save"),
                ),
            ],
        );
    }
}
