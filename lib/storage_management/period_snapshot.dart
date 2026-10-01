// Gets snapshots of pay periods
// Used for visual activity
class PeriodSnapshot {
    DateTime start;
    double totalIncome;
    double totalExpenses;

    PeriodSnapshot({
        required this.start,
        required this.totalIncome,
        required this.totalExpenses
    });
}
