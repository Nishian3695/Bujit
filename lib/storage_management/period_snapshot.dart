// Mirrors StorageManagement/PeriodSnapshot.java in the original Java app: the
// income and expense totals of a pay period that has ended, recorded as it
// ends (see BalanceModel.makeRecent) so the Visuals chart can show history.
import '../utils/date_utils.dart';

class PeriodSnapshot {
    final DateTime start; // Payday the period began on (its key)
    final double totalIncome;
    final double totalExpenses;

    PeriodSnapshot({
        required DateTime start,
        required this.totalIncome,
        required this.totalExpenses,
    }) : start = dateOnly(start);
}
