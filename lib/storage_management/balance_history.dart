// One account's balance on one day, recorded as the app saves (see
// BalanceModel.recordHistory) so the Visuals Net Balance chart can show history.
// The name is kept so a deleted account's history still has a label.
import '../utils/date_utils.dart';

class BalanceHistoryEntry {
    final DateTime date;
    final String key; // Which account (see BalanceModel.netAccounts)
    final String name;
    final double amount; // Negative for money owed (cards, loans)

    BalanceHistoryEntry({
        required DateTime date,
        required this.key,
        required this.name,
        required this.amount,
    }) : date = dateOnly(date);
}
