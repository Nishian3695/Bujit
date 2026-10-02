// Mirrors NavigationItems/SingleEvents/SingleEventModel.java in the original Java app:
// a one-off debit or credit (an unplanned expense or a windfall) applied
// immediately to a target, rather than recurring like an expense. It expires
// a set number of days after it was last changed and is then cleared from the
// list (its effect stays applied). See SingleEventsLedger for the effects.
import '../../utils/date_utils.dart';

// What an event is applied to.
enum EventTarget { balance, creditCard, manualAccount }

class SingleEventModel {
    int? id; // Row id once persisted to the database
    String name;
    double amount; // Always positive
    bool isDebit; // true = money out (reduces the balance / adds to a card's debt)
    DateTime createdDate;
    DateTime lastModifiedDate;
    // Signed effect currently applied to the target: -amount for a debit,
    // +amount for a credit. Kept so edits and removals can reverse it exactly.
    double appliedAmount;
    EventTarget target;
    // The card's name (EventTarget.creditCard, how cards are found), or the
    // account's name for display (EventTarget.manualAccount).
    String? targetName;
    String? targetId; // The manual account's id for EventTarget.manualAccount

    SingleEventModel({
        this.id,
        required this.name,
        required double amount,
        required this.isDebit,
        this.target = EventTarget.balance,
        this.targetName,
        this.targetId,
        DateTime? createdDate,
        DateTime? lastModifiedDate,
        double? appliedAmount,
    }) : amount = amount.abs(),
         createdDate = dateOnly(createdDate ?? todayDate()),
         lastModifiedDate = dateOnly(lastModifiedDate ?? createdDate ?? todayDate()),
         appliedAmount = appliedAmount ?? (isDebit ? -amount.abs() : amount.abs());

    // The signed effect of the current amount and direction.
    double get signedAmount => isDebit ? -amount : amount;

    // True once [expiryDays] days have passed since the last change.
    bool isExpired(int expiryDays, {DateTime? today}) =>
        !dateOnly(today ?? todayDate()).isBefore(addDays(lastModifiedDate, expiryDays));

    // Days left before it expires (0 when it's due to be cleared).
    int daysUntilExpiry(int expiryDays, {DateTime? today}) {
        final int days = daysBetween(dateOnly(today ?? todayDate()), addDays(lastModifiedDate, expiryDays));
        return days < 0 ? 0 : days;
    }

    // Where it was applied, for display.
    String get targetDisplayName => switch (target) {
        EventTarget.balance => "Current Balance",
        EventTarget.creditCard => "${targetName ?? "Card"} (card)",
        EventTarget.manualAccount => targetName ?? "Account",
    };
}
