// The tutorial's sample data, matching the Java app's seedSampleDataIfNeeded().
// Dates are relative to [today] so nothing is in the past on first launch: the
// first catch-up (BalanceModel.makeRecent) pays nothing and the balance stays
// at $3500.
import '../navigation_items/expense_activity/balance_model.dart';
import '../navigation_items/expense_activity/credit_model.dart';
import '../navigation_items/expense_activity/expense_model.dart';
import '../navigation_items/income_streams/income_stream_model.dart';
import 'date_utils.dart';
import 'frequency_unit.dart';

// Fills [balance] with the sample data, replacing its balance, expenses and streams.
void seedSampleData(BalanceModel balance, {DateTime? today}) {
    final DateTime day = dateOnly(today ?? todayDate());

    ExpenseModel monthly(String name, double amount, int inDays, String category) => ExpenseModel(
        name: name,
        amount: amount,
        startDate: addDays(day, inDays),
        frequency: 1,
        frequencyUnits: FrequencyUnit.monthly,
        category: category,
    );

    // Credit cards bill monthly (they appear in the expense list and on the utilization screen)
    CreditModel card(String name, double balanceOwed, int inDays, double limit) => CreditModel(
        name: name,
        amount: balanceOwed,
        startDate: addDays(day, inDays),
        frequency: 1,
        frequencyUnits: FrequencyUnit.monthly,
        creditLimit: limit,
    );

    balance.expenses
        ..clear()
        ..addAll([
            monthly("Rent", 850.00, 2, "Housing"),
            monthly("Netflix", 15.99, 5, "Entertainment"),
            monthly("Electric Bill", 110.00, 9, "Utilities"),
            card("Everyday Card", 450.00, 3, 2000.00),
            card("Travel Card", 1200.00, 13, 3000.00),
            card("Hobby Card", 6000.00, 7, 6200.00),
        ]);

    // Biweekly income stream, paid today (already in the starting balance)
    final IncomeStreamModel mainJob = IncomeStreamModel(
        name: "Main Job",
        amount: 2400.00,
        startDate: day,
        frequency: 2,
        frequencyUnits: FrequencyUnit.weekly,
        isActive: true,
    );
    balance.incomeStreams
        ..clear()
        ..add(mainJob);
    balance.activeIncome = mainJob;

    // Starting balance so the dashboard looks healthy from day one
    balance.currentBalance = 3500.00;
    balance.lastUpdated = day;
    balance.snapshots.clear();
    balance.manualAccounts.clear();
    balance.balanceExtra = 0.00;
}
