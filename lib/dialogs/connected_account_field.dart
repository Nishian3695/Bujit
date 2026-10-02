// "From Connected Account" in the expense and credit card dialogs (the Java
// app's showConnectedAccountPicker): link the item to an account at a linked
// bank, so each bank sync sets its amount (and a card's limit). A banner shows
// the link, with Unlink.
import 'package:flutter/material.dart';
import '../navigation_items/banking/bank_account_model.dart';
import '../utils/money.dart';

class ConnectedAccountField extends StatelessWidget {
    final List<BankAccountModel> accounts; // What can be linked (credit/loan, or credit for cards)
    final BankAccountModel? linked;
    final ValueChanged<BankAccountModel> onPick;
    final VoidCallback onUnlink;

    const ConnectedAccountField({
        super.key,
        required this.accounts,
        required this.linked,
        required this.onPick,
        required this.onUnlink,
    });

    static String label(BankAccountModel a) => [
        a.institution,
        "– ${a.displayType}",
        if (a.mask.isNotEmpty) "(…${a.mask})",
        if (a.ledger != null) " ${Money.format(a.ledger!)}",
    ].where((s) => s.isNotEmpty).join(" ");

    Future<void> _pick(BuildContext context) async {
        final BankAccountModel? picked = await showDialog<BankAccountModel>(
            context: context,
            builder: (context) => SimpleDialog(
                title: const Text("Link connected account"),
                children: [
                    for (final BankAccountModel account in accounts)
                        SimpleDialogOption(
                            onPressed: () => Navigator.of(context).pop(account),
                            child: Text(label(account)),
                        ),
                ],
            ),
        );
        if (picked != null) onPick(picked);
    }

    @override
    Widget build(BuildContext context) {
        final BankAccountModel? account = linked;
        if (account != null) {
            return Row(
                children: [
                    const Icon(Icons.link, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Amount syncs from ${account.displayName}")),
                    TextButton(onPressed: onUnlink, child: const Text("Unlink")),
                ],
            );
        }
        if (accounts.isEmpty) return const SizedBox.shrink();
        return Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed: () => _pick(context),
                icon: const Icon(Icons.account_balance),
                label: const Text("From connected account"),
            ),
        );
    }
}
