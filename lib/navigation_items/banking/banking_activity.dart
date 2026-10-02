// Mirrors NavigationItems/Banking/BankingActivity.java in the original Java app:
// the Linked Accounts screen. Banks linked through Plaid (link, reconnect an
// expired one, pull to sync, disconnect) and "My Accounts", the manual accounts
// (add/edit/delete). Which accounts make up the current balance is chosen in
// Update Balance on the home screen ("From Accounts"), as in the Java app.
import 'package:flutter/material.dart';
import '../../utils/money.dart';
import '../../app_state.dart';
import '../../dialogs/manual_account_dialog.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import '../expense_activity/balance_model.dart';
import '../expense_activity/expense_item.dart';
import '../expense_activity/funding_source.dart';
import 'bank_account_model.dart';
import 'banking_prefs.dart';
import 'manual_account_model.dart';

class BankingActivity extends StatefulWidget {
    final AppState state;
    const BankingActivity({super.key, required this.state});

    @override
    State<BankingActivity> createState() => _BankingActivityState();
}

class _BankingActivityState extends State<BankingActivity> {
    BalanceModel get _balance => widget.state.balance;
    bool _linking = false;

    Future<void> _save() async {
        setState(() {});
        await widget.state.changed();
    }

    // ── Linked banks ────────────────────────────────────────────────────────

    Future<void> _link({LinkedItem? replacing}) async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        setState(() => _linking = true);
        try {
            final String? institution = await widget.state.linkBank(replacing: replacing);
            if (institution != null) {
                messenger.showSnackBar(SnackBar(content: Text(
                    "${institution.isEmpty ? "Bank" : institution} linked. Pick its accounts for your balance "
                    "with \"From Accounts\" when you update it.")));
            }
        } catch (e) {
            messenger.showSnackBar(SnackBar(content: Text(replacing == null
                ? "Failed to start bank connection"
                : "Failed to reconnect ${replacing.institution}")));
        } finally {
            if (mounted) setState(() => _linking = false);
        }
    }

    Future<void> _sync() async {
        final BankSyncResult? result = await widget.state.refreshBanks(force: true);
        if (!mounted || result == null) return;
        if (result.needsRelink.isNotEmpty) {
            await _offerReconnect(result.needsRelink);
        } else if (!result.synced && result.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't reach your banks")));
        }
        if (mounted) setState(() {});
    }

    // The Java app's "Bank Connection Expired" dialog.
    Future<void> _offerReconnect(List<String> institutions) async {
        final bool? reconnect = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Bank Connection Expired"),
                content: Text("${institutions.join(", ")}: the connection was revoked or expired. "
                    "Reconnect to keep syncing that account's balance."),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Dismiss")),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Reconnect")),
                ],
            ),
        );
        if (reconnect != true) return;
        for (final LinkedItem item in widget.state.data.linkedItems.where((i) => i.needsRelink).toList()) {
            await _link(replacing: item);
        }
    }

    // Pick banks to disconnect (or all), then confirm, as in the Java app.
    Future<void> _disconnect() async {
        final List<LinkedItem> items = widget.state.data.linkedItems;
        final Set<String> picked = {};
        final Set<String>? chosen = await showDialog<Set<String>>(
            context: context,
            builder: (context) => StatefulBuilder(
                builder: (context, setDialogState) => AlertDialog(
                    title: const Text("Disconnect Banks"),
                    content: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                for (final LinkedItem item in items)
                                    CheckboxListTile(
                                        value: picked.contains(item.key),
                                        title: Text(item.institution.isEmpty ? "Bank" : item.institution),
                                        onChanged: (on) => setDialogState(
                                            () => on == true ? picked.add(item.key) : picked.remove(item.key)),
                                    ),
                            ],
                        ),
                    ),
                    actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                        TextButton(
                            onPressed: () => Navigator.of(context).pop({for (final i in items) i.key}),
                            child: const Text("Disconnect All"),
                        ),
                        TextButton(
                            onPressed: picked.isEmpty ? null : () => Navigator.of(context).pop({...picked}),
                            child: const Text("Disconnect Selected"),
                        ),
                    ],
                ),
            ),
        );
        if (chosen == null || chosen.isEmpty || !mounted) return;
        final List<String> names = [
            for (final LinkedItem i in items) if (chosen.contains(i.key)) i.institution.isEmpty ? "Bank" : i.institution,
        ];
        final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Are you sure?"),
                content: Text("${names.length == 1 ? "Disconnect from ${names.single}" : "Disconnect from ${names.length} banks"}? "
                    "Anything paid from or synced with its accounts keeps its last amount and is paid from "
                    "your current balance. This cannot be undone."),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Disconnect")),
                ],
            ),
        );
        if (confirmed != true) return;
        await widget.state.disconnectBanks(chosen);
        if (mounted) setState(() {});
    }

    // ── Manual accounts ─────────────────────────────────────────────────────

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

    // ── Layout ──────────────────────────────────────────────────────────────

    List<Widget> _linkedSection() {
        final AppState state = widget.state;
        final List<LinkedItem> items = state.data.linkedItems;
        final bool configured = state.canLinkBanks;
        return [
            TutorialTarget(
                id: "connect_bank",
                child: ListTile(
                    enabled: configured && !_linking,
                    leading: const Icon(Icons.link),
                    title: const Text("Link a bank or credit card"),
                    subtitle: Text(configured
                        ? "Connect securely through Plaid. Bujit never sees your login."
                        : "Not set up in this build"),
                    trailing: _linking ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator()) : null,
                    onTap: () => _link(),
                ),
            ),
            for (final LinkedItem item in items) ...[
                ListTile(
                    dense: true,
                    title: Text(item.institution.isEmpty ? "BANK" : item.institution.toUpperCase()),
                    trailing: item.needsRelink
                        ? TextButton(onPressed: configured ? () => _link(replacing: item) : null, child: const Text("Reconnect"))
                        : null,
                ),
                for (final BankAccountModel account in _balance.linkedAccounts.where((a) => a.itemKey == item.key))
                    ListTile(
                        title: Text("${account.name}${account.mask.isEmpty ? "" : " …${account.mask}"}"),
                        subtitle: Text([
                            account.displayType,
                            if (account.countsTowardBalance) "in your current balance",
                            if (item.needsRelink) "not syncing",
                        ].where((s) => s.isNotEmpty).join(" · ")),
                        trailing: Text(account.ledger == null ? "—" : _money(account.ledger!)),
                    ),
            ],
            if (items.isNotEmpty)
                ListTile(
                    dense: true,
                    subtitle: Text(state.bankSyncing
                        ? "Syncing…"
                        : state.data.lastBankSync == null
                            ? "Pull down to sync"
                            : "Last synced ${_ago(state.data.lastBankSync!)} · pull down to sync"),
                ),
        ];
    }

    static String _ago(DateTime time) {
        final Duration ago = DateTime.now().difference(time);
        if (ago.inMinutes < 1) return "just now";
        if (ago.inHours < 1) return "${ago.inMinutes} min ago";
        if (ago.inDays < 1) return "${ago.inHours} h ago";
        return "${ago.inDays} d ago";
    }

    @override
    Widget build(BuildContext context) {
        final List<ManualAccountModel> accounts = _balance.manualAccounts;
        return TutorialOverlay(
            state: widget.state,
            screen: TutorialScreen.linkedAccounts,
            child: Scaffold(
                appBar: AppBar(
                    title: const Text("Linked Accounts"),
                    actions: [
                        if (widget.state.data.linkedItems.isNotEmpty)
                            IconButton(
                                onPressed: _disconnect,
                                icon: const Icon(Icons.link_off),
                                tooltip: "Disconnect banks",
                            ),
                    ],
                ),
                body: RefreshIndicator(
                    onRefresh: _sync,
                    child: ListenableBuilder(
                        listenable: widget.state,
                        builder: (context, _) => ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                                ..._linkedSection(),
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
                    ),
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
