// Applies single events to their targets, matching the Java app's
// SingleEventsActivity: adding an event applies it immediately; editing
// reverses the old effect and applies the new one; removing reverses it;
// clearing an expired event removes it from the list but keeps its effect.
//
// Targets:
//   balance       -> currentBalance changes by the signed amount
//   creditCard    -> the card (found by name, as in the Java app) owes more for a
//                    debit and less for a credit, never below 0
//   manualAccount -> the account changes by the signed amount, and so does
//                    currentBalance if the account counts toward it
// A target that no longer exists is left alone.
import '../../utils/date_utils.dart';
import '../expense_activity/balance_model.dart';
import '../banking/manual_account_model.dart';
import '../expense_activity/credit_model.dart';
import '../expense_activity/funding_source.dart';
import 'single_event_model.dart';

class SingleEventsLedger {
    final BalanceModel balance;
    final List<SingleEventModel> events; // Newest-changed first

    SingleEventsLedger(this.balance, this.events);

    // Applies a new event and lists it first.
    void add(SingleEventModel event) {
        event.appliedAmount = event.signedAmount;
        _apply(event, event.appliedAmount);
        events.insert(0, event);
    }

    // Changes an event: reverses its old effect, then applies the new one.
    void update(
        SingleEventModel event, {
        required String name,
        required double amount,
        required bool isDebit,
        required EventTarget target,
        String? targetName,
        String? targetId,
        DateTime? today,
    }) {
        _apply(event, -event.appliedAmount);
        event
            ..name = name
            ..amount = amount.abs()
            ..isDebit = isDebit
            ..target = target
            ..targetName = targetName
            ..targetId = targetId
            ..lastModifiedDate = dateOnly(today ?? todayDate());
        event.appliedAmount = event.signedAmount;
        _apply(event, event.appliedAmount);
        events.sort((a, b) => b.lastModifiedDate.compareTo(a.lastModifiedDate));
    }

    // Removes an event and undoes its effect.
    void remove(SingleEventModel event) {
        _apply(event, -event.appliedAmount);
        events.remove(event);
    }

    // Clears expired events from the list, keeping their effects (they happened).
    // Returns how many were cleared.
    int clearExpired(int expiryDays, {DateTime? today}) {
        final int before = events.length;
        events.removeWhere((event) => event.isExpired(expiryDays, today: today));
        return before - events.length;
    }

    // Credits and debits (both positive) of the events made on or after [from]
    // that moved currentBalance -- not those on a card, whose payment the
    // check's expenses already count, or on an account outside the balance.
    ({double credits, double debits}) balanceTotalsSince(DateTime from) {
        double credits = 0.00, debits = 0.00;
        for (final SingleEventModel event in events) {
            if (event.createdDate.isBefore(dateOnly(from)) || !_hitsBalance(event)) continue;
            if (event.isDebit) {
                debits += event.amount;
            } else {
                credits += event.amount;
            }
        }
        return (credits: credits, debits: debits);
    }

    bool _hitsBalance(SingleEventModel event) => switch (event.target) {
        EventTarget.balance => true,
        EventTarget.creditCard => false,
        EventTarget.manualAccount => balance.manualAccount(event.targetId)?.countsTowardBalance ?? false,
    };

    // What an event can be applied to: the balance, manual accounts, then cards.
    List<SourceOption> get targets => [
        SourceOption.currentBalance,
        for (final ManualAccountModel account in balance.manualAccounts)
            SourceOption(FundingSource.manualAccount, account.id, account.name),
        for (final CreditModel card in balance.creditCards)
            SourceOption(FundingSource.creditCard, card.name, "${card.name} (card)"),
    ];

    void _apply(SingleEventModel event, double delta) {
        switch (event.target) {
            case EventTarget.balance:
                balance.currentBalance += delta;
            case EventTarget.creditCard:
                final CreditModel? card = balance.card(event.targetName);
                // A debit (negative delta) adds to what's owed; a credit pays it down.
                if (card != null) card.amount = (card.amount - delta).clamp(0.0, double.infinity);
            case EventTarget.manualAccount:
                final ManualAccountModel? account = balance.manualAccount(event.targetId);
                if (account != null) balance.adjustAccount(account, delta);
        }
    }
}
