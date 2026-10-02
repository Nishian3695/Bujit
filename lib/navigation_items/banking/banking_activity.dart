// Mirrors NavigationItems/Banking/BankingActivity.java in the original Java app:
// the Linked Accounts screen. Linking a bank through Plaid isn't built yet (see
// SETUP_TODO.md); "My Accounts" lists the manual accounts, with add/edit/delete.
// Which accounts make up the current balance is chosen in Update Balance on the
// home screen ("From Accounts"), as in the Java app.
import 'package:flutter/material.dart';
import '../../utils/money.dart';
import '../../app_state.dart';
import '../../dialogs/manual_account_dialog.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import '../expense_activity/balance_model.dart';
import '../expense_activity/expense_item.dart';
import '../expense_activity/funding_source.dart';
import 'manual_account_model.dart';

class BankingActivity extends StatefulWidget {
    final AppState state;
    const BankingActivity({super.key, required this.state});

    @override
    State<BankingActivity> createState() => _BankingActivityState();
}

class _BankingActivityState extends State<BankingActivity> {
    BalanceModel get _balance => widget.state.balance;

    Future<void> _save() async {
        setState(() {});
        await widget.state.changed();
    }

    Future<void> _add() async {
        final ManualAccountDraft? draft = await showManualAccountDialog(context);
        if (draft == null) return;
        _balance.manualAccounts.add(ManualAccountModel(
            name: draft.name, accountType: draft.accountType, balance: draft.balance));
        await _save();
    }

    // A new balance moves the current balance too if the account counts toward it.
    Future<void> _edit(ManualAccountModel account) async {
        final List<String> paidHere = [
            for (final ExpenseItem e in _balance.expenses)
                if (e.source == FundingSource.manualAccount && e.sourceId == account.id) e.name,
        ];
        final ManualAccountDraft? draft = await showManualAccountDialog(
            context,
            existing: account,
            deleteWarning: [
                if (account.countsTowardBalance) "Its balance will be removed from your current balance.",
                if (paidHere.isNotEmpty) "${paidHere.join(", ")} will be paid from your current balance instead.",
            ].join(" ").ifEmptyNull(),
            onDelete: () {
                _balance.removeAccount(account);
                _save();
            },
        );
        if (draft == null) return;
        final bool renamed = draft.name != account.name;
        account
            ..name = draft.name
            ..accountType = draft.accountType;
        _balance.adjustAccount(account, draft.balance - account.balance);
        if (renamed) widget.state.data.accountRenamed(account);
        await _save();
    }

    static String _money(double value) => Money.format(value);

    @override
    Widget build(BuildContext context) {
        final List<ManualAccountModel> accounts = _balance.manualAccounts;
        return TutorialOverlay(
            state: widget.state,
            screen: TutorialScreen.linkedAccounts,
            child: Scaffold(
                appBar: AppBar(title: const Text("Linked Accounts")),
                body: ListView(
                    children: [
                        const TutorialTarget(
                            id: "connect_bank",
                            child: ListTile(
                                enabled: false,
                                leading: Icon(Icons.link),
                                title: Text("Link a bank or credit card"),
                                subtitle: Text("Coming soon: connect securely through Plaid"),
                            ),
                        ),
                        const Divider(),
                        TutorialTarget(
                            id: "manual_accounts",
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                    const ListTile(title: Text("MY ACCOUNTS")),
                                    if (accounts.isEmpty)
                                        const ListTile(
                                            subtitle: Text("No manual accounts yet. Tap + to track an account by hand."),
                                        ),
                                    for (final ManualAccountModel account in accounts)
                                        ListTile(
                                            title: Text(account.name),
                                            subtitle: Text(account.countsTowardBalance
                                                ? "${account.accountType} · in your current balance"
                                                : account.accountType),
                                            trailing: Text(_money(account.balance)),
                                            onTap: () => _edit(account),
                                        ),
                                ],
                            ),
                        ),
                    ],
                ),
                floatingActionButton: FloatingActionButton(
                    onPressed: _add,
                    tooltip: "Add account",
                    child: const Icon(Icons.add),
                ),
            ),
        );
    }
}

extension on String {
    String? ifEmptyNull() => isEmpty ? null : this;
}
