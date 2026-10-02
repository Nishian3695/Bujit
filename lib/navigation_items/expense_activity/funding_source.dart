// Where the money for an expense or a credit card payment comes from -- the
// Java app's ExpenseItem "Source". When an occurrence comes due (see
// BalanceModel.makeRecent):
//   balance       -> the current balance pays it (the default)
//   manualAccount -> that manual account pays it; the balance moves too only if
//                    the account counts toward it
//   creditCard    -> it's charged to that card (expenses only): the card owes
//                    more, and the balance pays when the card is due
//   linkedAccount -> a linked bank account pays it: nothing is deducted here,
//                    since the bank's balance shows it at the next sync (as in
//                    the Java app)
// Projections ("After This Check") count only what leaves the current balance,
// so a charge isn't counted both on its own date and in the card's payment.
enum FundingSource { balance, manualAccount, creditCard, linkedAccount }

// One choice in a "Paid from" dropdown.
class SourceOption {
    final FundingSource source;
    final String? id; // Manual or linked account id, or card name; null for the balance
    final String label;

    const SourceOption(this.source, this.id, this.label);

    static const SourceOption currentBalance = SourceOption(FundingSource.balance, null, "Current Balance");

    bool matches(FundingSource source, String? id) =>
        this.source == source && (source == FundingSource.balance || this.id == id);

    // A dropdown value for this option (unique across options).
    String get key => "${source.name}:${id ?? ""}";
}
