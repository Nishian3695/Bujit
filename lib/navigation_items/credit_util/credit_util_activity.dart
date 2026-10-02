// Mirrors NavigationItems/CreditUtil/CreditUtilActivity.java in the original Java app:
// every credit card's balance, limit and utilization, with add/edit/delete.
// Cards live in BalanceModel.expenses alongside regular expenses.
import 'package:flutter/material.dart';
import '../../utils/money.dart';
import '../../app_state.dart';
import '../../dialogs/credit_card_dialog.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import '../expense_activity/balance_model.dart';
import '../expense_activity/credit_model.dart';

class CreditUtilActivity extends StatefulWidget {
    final AppState state;
    const CreditUtilActivity({super.key, required this.state});

    @override
    State<CreditUtilActivity> createState() => _CreditUtilActivityState();
}

class _CreditUtilActivityState extends State<CreditUtilActivity> {
    BalanceModel get _balance => widget.state.balance;

    @override
    void initState() {
        super.initState();
        _balance.showCheck(0); // Utilization as of the current check
    }

    Future<void> _save() async {
        _balance.showCheck(0);
        setState(() {});
        await widget.state.changed();
    }

    // A due date entered in the past rolls forward to the next one without
    // paying anything -- the balance entered is what's owed now.
    Future<void> _add() async {
        final CreditModel? card = await showCreditCardDialog(
            context,
            sources: _balance.paymentOptions(forCard: true),
            otherCardNames: _balance.creditCards.map((c) => c.name),
            connectable: _balance.linkedAccounts.where((a) => a.isCredit).toList(),
        );
        if (card == null) return;
        card.skipToNextDueDate();
        _balance.expenses.add(card);
        await _save();
    }

    Future<void> _edit(CreditModel old) async {
        final CreditModel? edited = await showCreditCardDialog(
            context,
            existing: old,
            sources: _balance.paymentOptions(forCard: true),
            otherCardNames: _balance.creditCards.where((c) => c != old).map((c) => c.name),
            connectable: _balance.linkedAccounts.where((a) => a.isCredit).toList(),
            onDelete: () async {
                await widget.state.removeItem(old);
                _refreshCards();
            },
        );
        if (edited == null) return;
        await widget.state.replaceItem(old, edited);
        _refreshCards();
    }

    void _refreshCards() {
        _balance.showCheck(0);
        if (mounted) setState(() {});
    }

    // Green under 30%, amber under 70%, red from 70%, as in the Java app.
    static Color _utilizationColor(double utilization) {
        if (utilization < 0.30) return Colors.green;
        if (utilization < 0.70) return Colors.amber;
        return Colors.red;
    }

    // The Java app's totals row: everything owed against every limit (current
    // balances), the overall percentage colored like the cards', and a sync hint
    // when any card is linked to a bank.
    Widget _totals(List<CreditModel> cards) {
        final double owed = cards.fold(0.00, (sum, c) => sum + c.amount);
        final double limit = cards.fold(0.00, (sum, c) => sum + c.creditLimit);
        final double utilization = limit > 0 ? owed / limit : 0.0;
        final Color color = _utilizationColor(utilization);
        final bool anyLinked = cards.any((c) => _balance.linkedAccount(c.linkedAccountId) != null);
        return Card(
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text("TOTAL ${Money.format(owed)} of ${Money.format(limit)}"),
                                Text("${(utilization * 100).clamp(0, 100).round()}%", style: TextStyle(color: color)),
                            ],
                        ),
                        LinearProgressIndicator(value: utilization.clamp(0.0, 1.0), color: color),
                        if (anyLinked)
                            const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text("Pull down to sync balances", style: TextStyle(fontSize: 12)),
                            ),
                    ],
                ),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        final List<CreditModel> cards = _balance.creditCards.toList();
        return TutorialOverlay(
            state: widget.state,
            screen: TutorialScreen.creditUtil,
            child: Scaffold(
            appBar: AppBar(title: const Text("Credit Utilization")),
            body: Column(children: [
                if (cards.isNotEmpty) _totals(cards),
                Expanded(child: TutorialTarget(id: "credit_list", child: cards.isEmpty
                ? const Center(child: Text("No credit cards yet. Tap + to add one."))
                // Pull to refresh syncs linked cards' balances and limits, as in the Java app.
                : RefreshIndicator(
                    onRefresh: () async {
                        await widget.state.refreshBanks(force: true);
                        _refreshCards();
                    },
                    child: ListView.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                        final CreditModel card = cards[index];
                        final double utilization = card.creditUtilization;
                        return ListTile(
                            title: Text(card.name),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text("${Money.format(card.displayBalance)} of "
                                        "${Money.format(card.creditLimit)} · "
                                        "${(utilization * 100).toStringAsFixed(0)}% · "
                                        "due ${card.currentDueDate.toString().split(' ')[0]}"),
                                    LinearProgressIndicator(
                                        value: utilization.clamp(0.0, 1.0),
                                        color: _utilizationColor(utilization),
                                    ),
                                ],
                            ),
                            onTap: () => _edit(card),
                        );
                    },
                ))))]),
            floatingActionButton: FloatingActionButton(
                onPressed: _add,
                tooltip: "Add credit card",
                child: const Icon(Icons.add),
            ),
            ),
        );
    }
}
