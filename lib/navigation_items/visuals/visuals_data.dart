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
//
// Net Balance: the accounts BalanceModel.netAccounts lists, added up. History
// is what was recorded each day (BalanceModel.recordHistory); the projection
// follows the home screen's checks, with a point on each payday just before
// and just after its paychecks, so the dip before payday shows.
import '../../storage_management/balance_history.dart';
import '../../storage_management/period_snapshot.dart';
import '../../utils/category_manager.dart';
import '../../utils/date_utils.dart';
import '../../utils/frequency_unit.dart';
import '../banking/bank_account_model.dart';
import '../banking/manual_account_model.dart';
import '../expense_activity/balance_model.dart';
import '../expense_activity/check_window.dart';
import '../expense_activity/credit_model.dart';
import '../expense_activity/expense_item.dart';
import '../expense_activity/funding_source.dart';
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

// Every account's balance at one moment of the net balance chart.
class NetPoint {
    final DateTime date;
    final Map<String, double> amounts; // By account key; a missing account is 0

    const NetPoint(this.date, this.amounts);

    // The net balance of the accounts not in [hidden].
    double total(Set<String> hidden) => amounts.entries
        .where((e) => !hidden.contains(e.key))
        .fold(0.00, (sum, e) => sum + e.value);
}

// An account in the net balance chart's legend.
class NetLegendItem {
    final String key;
    final String name;
    final double? amount; // Its balance now, or null if it's gone (history only)

    const NetLegendItem(this.key, this.name, this.amount);
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
        FrequencyUnit.semimonthly => 15.22, // Half a month
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

    // ── Net Balance ─────────────────────────────────────────────────────────

    // Recorded balances from [from] on, one point per day recorded, oldest first.
    List<NetPoint> netHistory(DateTime from) {
        final DateTime start = dateOnly(from);
        final Map<DateTime, Map<String, double>> byDate = {};
        for (final BalanceHistoryEntry entry in balance.history) {
            if (entry.date.isBefore(start)) continue;
            byDate.putIfAbsent(entry.date, () => {})[entry.key] = entry.amount;
        }
        final List<DateTime> dates = byDate.keys.toList()..sort();
        return [for (final DateTime date in dates) NetPoint(date, byDate[date]!)];
    }

    // Projected balances from [today] (default: now) through the first payday on
    // or after [until]: today's balances, then on each payday the balances after
    // the check's expenses and, if paychecks arrive, again after them. The
    // expenses and income streams in [excluded] are left out.
    List<NetPoint> netProjection(DateTime until, {DateTime? today, Set<Object> excluded = const {}}) {
        final DateTime day = dateOnly(today ?? todayDate());
        final BalanceModel balance = excluded.isEmpty ? this.balance : this.balance.excluding(excluded);
        final Map<String, double> amounts = {for (final NetAccount a in balance.netAccounts()) a.key: a.amount};
        final List<NetPoint> points = [NetPoint(day, Map.of(amounts))];
        // The accounts that pay for things outside the balance (only ones that
        // don't count toward it are listed, so the others are skipped below).
        final List<(String, FundingSource, String)> payers = [
            for (final ManualAccountModel a in balance.manualAccounts)
                (BalanceModel.manualKey(a.id), FundingSource.manualAccount, a.id),
            for (final BankAccountModel a in balance.linkedAccounts)
                (BalanceModel.linkedKey(a.id), FundingSource.linkedAccount, a.id),
        ];
        for (int k = 0; k < 1000; k++) {
            final CheckWindow check = balance.window(k, today: day);
            amounts[BalanceModel.balanceKey] = amounts[BalanceModel.balanceKey]! - balance.expensesForCheck(check);
            for (final (String key, FundingSource source, String id) in payers) {
                final double? amount = amounts[key];
                if (amount != null) amounts[key] = amount - balance.paidFromInCheck(source, id, check);
            }
            for (final CreditModel card in balance.creditCards) {
                amounts[BalanceModel.cardKey(card.name)] = -card.balanceOn(check.end, balance.chargesTo(card));
            }
            points.add(NetPoint(check.end, Map.of(amounts)));
            final double income = balance.incomeForCheck(balance.window(k + 1, today: day));
            if (income != 0) {
                amounts[BalanceModel.balanceKey] = amounts[BalanceModel.balanceKey]! + income;
                points.add(NetPoint(check.end, Map.of(amounts)));
            }
            if (!check.end.isBefore(until)) break;
        }
        return points;
    }

    // The accounts to list: today's, then any only [history] has (gone since),
    // under the last name recorded for them.
    List<NetLegendItem> netLegend(List<NetPoint> history) {
        final List<NetLegendItem> items = [
            for (final NetAccount a in balance.netAccounts()) NetLegendItem(a.key, a.name, a.amount),
        ];
        final Set<String> listed = {for (final NetLegendItem item in items) item.key};
        final Set<String> inHistory = {for (final NetPoint p in history) ...p.amounts.keys};
        for (final BalanceHistoryEntry entry in balance.history.reversed) {
            if (inHistory.contains(entry.key) && listed.add(entry.key)) {
                items.add(NetLegendItem(entry.key, entry.name, null));
            }
        }
        return items;
    }
}
