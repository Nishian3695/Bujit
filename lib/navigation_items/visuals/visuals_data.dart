// The numbers behind the Visuals screen, matching the Java app's VisualsActivity.
// Kept separate from the widgets so they can be tested.
//
// Cash Flow: one bar pair per pay period of a year (the active stream's
// paydays; months if there's no stream). Periods that have ended show their
// recorded snapshot (zeros if none was recorded); the current and future ones
// are projected from the recurring rules.
//
// Categories: spending per check by category -- each expense's cost scaled to
// one pay period (cost x pay-period days / days between occurrences), skipping
// ended expenses, with credit cards grouped under "Credit Cards".
import '../../storage_management/period_snapshot.dart';
import '../../utils/category_manager.dart';
import '../../utils/date_utils.dart';
import '../../utils/frequency_unit.dart';
import '../expense_activity/balance_model.dart';
import '../expense_activity/credit_model.dart';
import '../expense_activity/expense_item.dart';
import '../income_streams/income_stream_model.dart';

// One pay period's bar pair.
class CashFlowPeriod {
    final DateTime start;
    final DateTime end; // exclusive
    final double income;
    final double expenses;
    final bool isHistory; // true = from a snapshot, false = projected

    const CashFlowPeriod({
        required this.start,
        required this.end,
        required this.income,
        required this.expenses,
        required this.isHistory,
    });

    double get net => income - expenses;
}

class VisualsData {
    final BalanceModel balance;
    final List<String> categories; // User categories, in order

    VisualsData(this.balance, this.categories);

    // Average days per unit, as in the Java app's periodToDays.
    static double unitDays(FrequencyUnit unit) => switch (unit) {
        FrequencyUnit.daily => 1.0,
        FrequencyUnit.weekly => 7.0,
        FrequencyUnit.biweekly => 14.0,
        FrequencyUnit.monthly => 30.44,
        FrequencyUnit.yearly => 365.25,
    };

    // Length of a pay period in days: the active stream's, else the shortest
    // stream's, else a month.
    double get payPeriodDays {
        final IncomeStreamModel? active = balance.activeIncome;
        if (active != null && active.frequency > 0) return active.frequency * unitDays(active.frequencyUnits);
        double best = double.infinity;
        for (final IncomeStreamModel stream in balance.incomeStreams) {
            if (stream.frequency <= 0) continue;
            final double days = stream.frequency * unitDays(stream.frequencyUnits);
            if (days < best) best = days;
        }
        return best.isFinite ? best : 30.44;
    }

    // Pay-period start dates within [year]: the active stream's paydays, or the
    // first of each month if there's no active stream or it has none that year.
    List<DateTime> payDatesInYear(int year) {
        final DateTime yearStart = DateTime(year, 1, 1);
        final DateTime yearEnd = DateTime(year + 1, 1, 1);
        final List<DateTime> dates = [];
        final IncomeStreamModel? income = balance.activeIncome;
        if (income != null) {
            DateTime date = income.paydayAfter(addDays(yearStart, -1));
            int safety = 0;
            while (date.isBefore(yearEnd) && safety++ < 400) {
                dates.add(date);
                date = income.paydayAfter(date);
            }
        }
        if (dates.isEmpty) {
            for (int month = 1; month <= 12; month++) {
                dates.add(DateTime(year, month, 1));
            }
        }
        return dates;
    }

    // The year's pay periods with their income and expenses.
    List<CashFlowPeriod> cashFlow(int year, {DateTime? today}) {
        final DateTime day = dateOnly(today ?? todayDate());
        final List<DateTime> dates = payDatesInYear(year);
        final DateTime yearEnd = DateTime(year + 1, 1, 1);
        final List<CashFlowPeriod> periods = [];
        for (int i = 0; i < dates.length; i++) {
            final DateTime start = dates[i];
            final DateTime end = i + 1 < dates.length ? dates[i + 1] : yearEnd;
            if (!end.isAfter(day)) {
                // Fully ended: recorded history (zeros if it wasn't recorded).
                final PeriodSnapshot? snapshot = _snapshot(start);
                periods.add(CashFlowPeriod(
                    start: start, end: end, isHistory: true,
                    income: snapshot?.totalIncome ?? 0.0,
                    expenses: snapshot?.totalExpenses ?? 0.0,
                ));
            } else {
                periods.add(CashFlowPeriod(
                    start: start, end: end, isHistory: false,
                    income: balance.periodIncome(start, end),
                    expenses: balance.periodExpenses(start, end),
                ));
            }
        }
        return periods;
    }

    PeriodSnapshot? _snapshot(DateTime start) {
        for (final PeriodSnapshot snapshot in balance.snapshots) {
            if (snapshot.start == start) return snapshot;
        }
        return null;
    }

    // An expense's cost scaled to one pay period.
    double perCheckEquivalent(ExpenseItem expense) {
        if (expense.amount <= 0 || expense.frequency <= 0) return 0.0;
        final double daysBetween = expense.frequency * unitDays(expense.frequencyUnits);
        return expense.amount * (payPeriodDays / daysBetween);
    }

    // Per-check spending by category, largest first (ties keep the user's
    // category order, then "Credit Cards" and "Other"). Ended expenses are
    // skipped; categories with nothing are left out.
    Map<String, double> categoryAmounts({bool excludeCredit = false}) {
        final Map<String, double> amounts = {
            for (final String category in categories) category: 0.0,
            creditCardsCategory: 0.0,
            otherCategory: 0.0,
        };
        for (final ExpenseItem expense in balance.expenses) {
            final bool isCard = expense is CreditModel;
            if (excludeCredit && isCard) continue;
            if (expense.hasEnded) continue;
            final double perCheck = perCheckEquivalent(expense);
            if (perCheck <= 0) continue;
            final String category = isCard
                ? creditCardsCategory
                : (expense.category.isEmpty ? otherCategory : expense.category);
            amounts[category] = (amounts[category] ?? 0.0) + perCheck;
        }
        // Largest first, as the Java app orders its slices and legend.
        final List<String> order = amounts.keys.toList();
        final List<MapEntry<String, double>> sorted = amounts.entries.where((e) => e.value > 0.01).toList()
            ..sort((a, b) {
                final int byAmount = b.value.compareTo(a.value);
                return byAmount != 0 ? byAmount : order.indexOf(a.key).compareTo(order.indexOf(b.key));
            });
        return Map.fromEntries(sorted);
    }
}
