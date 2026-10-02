// "Update Balance" (the Java app's changeBankBalance): type the balance, or set
// it "From Accounts" -- the total of the manual and linked bank accounts picked,
// which then count toward it (linked ones keep it in step at each bank sync) --
// plus "Additional funds" for money tracked elsewhere.
//
// Typing a balance means no account counts toward it anymore, as in the Java
// app. Unlike the Java app, opening the dialog and changing only the additional
// funds keeps the accounts that already count (Java unlinked them).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation_items/banking/bank_account_model.dart';
import '../navigation_items/banking/manual_account_model.dart';
import '../navigation_items/expense_activity/balance_model.dart';
import '../utils/money.dart';

// Updates [balance] and returns true if saved.
Future<bool> showUpdateBalanceDialog(BuildContext context, BalanceModel balance) async {
    final bool? saved = await showAdaptiveDialog<bool>(
        context: context,
        builder: (context) => _UpdateBalanceDialog(balance),
    );
    return saved ?? false;
}

class _UpdateBalanceDialog extends StatefulWidget {
    final BalanceModel balance;
    const _UpdateBalanceDialog(this.balance);

    @override
    State<_UpdateBalanceDialog> createState() => _UpdateBalanceDialogState();
}

class _UpdateBalanceDialogState extends State<_UpdateBalanceDialog> {
    BalanceModel get _balance => widget.balance;

    late final TextEditingController _base =
        TextEditingController(text: (_balance.currentBalance - _balance.balanceExtra).toStringAsFixed(2));
    late final TextEditingController _extra =
        TextEditingController(text: _balance.balanceExtra.toStringAsFixed(2));
    final _formKey = GlobalKey<FormState>();
    // What "From Accounts" offers: manual accounts, then linked accounts with money in them.
    late final List<({String id, String title, String subtitle, double balance, bool counts})> _choices = [
        for (final ManualAccountModel a in _balance.manualAccounts)
            (id: a.id, title: a.name, subtitle: a.accountType, balance: a.balance, counts: a.countsTowardBalance),
        for (final BankAccountModel a in _balance.linkedAccounts)
            if (a.isCash && a.ledger != null)
                (id: a.id, title: a.displayName, subtitle: a.displayType, balance: a.ledger!, counts: a.countsTowardBalance),
    ];

    // Accounts the balance comes from; null once a balance is typed.
    late Set<String>? _accountIds = _choices.any((c) => c.counts)
        ? {for (final c in _choices) if (c.counts) c.id}
        : null;

    @override
    void dispose() {
        _base.dispose();
        _extra.dispose();
        super.dispose();
    }

    static final List<TextInputFormatter> _moneyInput = [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
    ];

    static String? _validate(String? value) =>
        double.tryParse(value?.trim() ?? "") == null ? "Enter an amount" : null;

    // Multi-select of the accounts; the field shows their total.
    Future<void> _pickAccounts() async {
        final Set<String> picked = {...?_accountIds};
        final bool? ok = await showDialog<bool>(
            context: context,
            builder: (context) => StatefulBuilder(
                builder: (context, setDialogState) => AlertDialog(
                    title: const Text("From Accounts"),
                    content: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                for (final choice in _choices)
                                    CheckboxListTile(
                                        value: picked.contains(choice.id),
                                        title: Text(choice.title),
                                        subtitle: Text("${choice.subtitle} · ${Money.format(choice.balance)}"),
                                        onChanged: (on) => setDialogState(() {
                                            if (on == true) {
                                                picked.add(choice.id);
                                            } else {
                                                picked.remove(choice.id);
                                            }
                                        }),
                                    ),
                            ],
                        ),
                    ),
                    actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("OK")),
                    ],
                ),
            ),
        );
        if (ok != true) return;
        final double total = _choices
            .where((c) => picked.contains(c.id))
            .fold(0.00, (sum, c) => sum + c.balance);
        setState(() {
            _base.text = total.toStringAsFixed(2);
            _accountIds = picked; // (Setting the text doesn't call onChanged, which clears this.)
        });
    }

    void _save() {
        if (!_formKey.currentState!.validate()) return;
        final double extra = double.parse(_extra.text.trim());
        final Set<String>? ids = _accountIds;
        if (ids == null || ids.isEmpty) {
            _balance.setBalanceTyped(double.parse(_base.text.trim()), extra);
        } else {
            _balance.setBalanceFromAccounts(ids, extra);
        }
        Navigator.of(context).pop(true);
    }

    @override
    Widget build(BuildContext context) {
        final bool hasAccounts = _choices.isNotEmpty;
        final Set<String>? ids = _accountIds;
        return AlertDialog.adaptive(
            title: const Text("Update Balance"),
            content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            TextFormField(
                                controller: _base,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                inputFormatters: _moneyInput,
                                decoration: InputDecoration(
                                    prefixText: "\$",
                                    labelText: "Balance",
                                    helperText: ids == null || ids.isEmpty
                                        ? null
                                        : "From ${ids.length} account${ids.length == 1 ? "" : "s"}",
                                ),
                                validator: _validate,
                                // Typing replaces the accounts with a typed balance.
                                onChanged: (_) => setState(() => _accountIds = null),
                            ),
                            TextButton.icon(
                                onPressed: hasAccounts ? _pickAccounts : null,
                                icon: const Icon(Icons.account_balance),
                                label: Text(hasAccounts ? "From Accounts" : "From Accounts (add some in Linked Accounts)"),
                            ),
                            TextFormField(
                                controller: _extra,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                inputFormatters: _moneyInput,
                                decoration: const InputDecoration(
                                    prefixText: "\$",
                                    labelText: "Additional funds",
                                    helperText: "Cash or anything you track elsewhere",
                                ),
                                validator: _validate,
                            ),
                        ],
                    ),
                ),
            ),
            actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                TextButton(onPressed: _save, child: const Text("Save")),
            ],
        );
    }
}
