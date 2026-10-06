// History snapshots (recorded as pay periods end) and the Visuals numbers.
import 'package:bujit/navigation_items/banking/manual_account_model.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/expense_activity/funding_source.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/navigation_items/visuals/visuals_data.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);
DateTime day(int offset) => addDays(today, offset);

// $1000 every 14 days starting today; a $5 daily expense.
BalanceModel _balance() {
    final balance = BalanceModel(currentBalance: 0.0, lastUpdated: today);
    final job = IncomeStreamModel(name: "Job", amount: 1000.0, startDate: today,
        frequency: 14, frequencyUnits: FrequencyUnit.daily);
    balance.incomeStreams.add(job);
    balance.activeIncome = job;
    balance.expenses.add(ExpenseModel(name: "Coffee", amount: 5.0, startDate: today,
        frequency: 1, frequencyUnits: FrequencyUnit.daily, category: "Food"));
    return balance;
}

void main() {
    group("history snapshots", () {
        test("an ended pay period is recorded once", () {
            final balance = _balance();
            balance.makeRecent(today: day(14));

            expect(balance.snapshots, hasLength(1));
            final snapshot = balance.snapshots.single;
            expect(snapshot.start, today);
            expect(snapshot.totalIncome, closeTo(1000.0, 1e-9)); // the day-0 paycheck
            expect(snapshot.totalExpenses, closeTo(70.0, 1e-9)); // days 0..13

            balance.makeRecent(today: day(14));
            expect(balance.snapshots, hasLength(1));
        });

        test("a card's balance is recorded in the period it was due, before it's paid", () {
            final balance = _balance();
            balance.expenses.add(CreditModel(name: "Card", amount: 300.0, startDate: day(5),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, creditLimit: 1000.0));
            balance.makeRecent(today: day(14));

            expect(balance.snapshots.single.totalExpenses, closeTo(70.0 + 300.0, 1e-9));
        });

        test("a long gap records every pay period that ended", () {
            final balance = _balance();
            balance.makeRecent(today: day(43));

            expect(balance.snapshots.map((s) => s.start), [today, day(14), day(28)]);
        });

        test("nothing is recorded without an active stream", () {
            final balance = _balance()..activeIncome = null;
            balance.makeRecent(today: day(30));

            expect(balance.snapshots, isEmpty);
        });
    });

    group("cash flow", () {
        test("pay periods follow the active stream's paydays within the year", () {
            final data = VisualsData(_balance(), []);
            final dates = data.payDatesInYear(2026);

            expect(dates.first, today); // the stream starts Oct 1
            expect(dates[1], day(14));
            expect(dates.last.year, 2026);
        });

        test("without an active stream, periods are months", () {
            final data = VisualsData(_balance()..activeIncome = null, []);

            expect(data.payDatesInYear(2027), [for (int m = 1; m <= 12; m++) DateTime(2027, m, 1)]);
        });

        test("ended periods show their snapshot; the rest are projected", () {
            final balance = _balance();
            balance.makeRecent(today: day(14));
            final periods = VisualsData(balance, []).cashFlow(2026, today: day(14));

            final first = periods.first; // [Oct 1, Oct 15): ended, recorded
            expect(first.isHistory, isTrue);
            expect(first.income, closeTo(1000.0, 1e-9));
            expect(first.expenses, closeTo(70.0, 1e-9));
            final second = periods[1]; // [Oct 15, Oct 29): projected
            expect(second.isHistory, isFalse);
            expect(second.income, closeTo(1000.0, 1e-9));
            expect(second.expenses, closeTo(70.0, 1e-9));
            expect(second.net, closeTo(930.0, 1e-9));
        });
    });

    group("categories", () {
        test("expenses are scaled to one pay period and grouped", () {
            final balance = _balance();
            balance.expenses.add(ExpenseModel(name: "Rent", amount: 850.0, startDate: day(2),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, category: "Housing"));
            balance.expenses.add(CreditModel(name: "Card", amount: 300.0, startDate: day(5),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, creditLimit: 1000.0));
            final data = VisualsData(balance, ["Housing", "Food"]);

            final amounts = data.categoryAmounts();
            expect(amounts.keys.toList(), ["Housing", "Credit Cards", "Food"]); // largest first
            expect(amounts["Housing"], closeTo(850.0 * 14 / 30.44, 1e-9));
            expect(amounts["Food"], closeTo(5.0 * 14, 1e-9));
            expect(amounts["Credit Cards"], closeTo(300.0 * 14 / 30.44, 1e-9));
            expect(data.categoryAmounts(excludeCredit: true).containsKey("Credit Cards"), isFalse);
        });

        test("ended expenses are left out", () {
            final balance = _balance();
            balance.expenses.add(ExpenseModel(name: "Old", amount: 50.0, startDate: DateTime(2024, 1, 1),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, endDate: DateTime(2024, 6, 1)));
            balance.expenses.last.skipToNextDueDate(today: today);

            expect(VisualsData(balance, []).categoryAmounts().containsKey("Other"), isFalse);
        });
    });

    group("net balance", () {
        test("the projection dips before each payday and rises after it", () {
            final points = VisualsData(_balance(), []).netProjection(day(20), today: today);

            expect(points.map((p) => p.date), [today, day(14), day(14), day(28), day(28)]);
            expect(points.map((p) => p.total(const {})), [
                closeTo(0.0, 1e-9),
                closeTo(-75.0, 1e-9), // coffee days 0..14
                closeTo(925.0, 1e-9), // the day-14 paycheck
                closeTo(855.0, 1e-9), // coffee days 15..28
                closeTo(1855.0, 1e-9),
            ]);
        });

        test("left-out expenses and income streams drop out of the projection only", () {
            final balance = _balance();
            final data = VisualsData(balance, []);
            final Set<Object> noCoffee = {balance.expenses.single};
            expect(data.netProjection(day(20), today: today, excluded: noCoffee).map((p) => p.total(const {})),
                [0.0, 0.0, 1000.0, 1000.0, 2000.0]);
            final Set<Object> noJob = {balance.incomeStreams.single};
            final points = data.netProjection(day(20), today: today, excluded: noJob);
            // Same paydays (the job still sets the checks), but no paychecks.
            expect(points.map((p) => p.date), [today, day(14), day(28)]);
            expect(points.map((p) => p.total(const {})), [0.0, -75.0, -145.0]);
            expect(balance.expenses, hasLength(1)); // The real data is untouched
        });

        test("accounts outside the balance and cards are projected separately", () {
            final balance = _balance();
            final savings = ManualAccountModel(name: "Savings", balance: 500.0);
            final checking = ManualAccountModel(name: "Checking", balance: 200.0, countsTowardBalance: true);
            balance.manualAccounts.addAll([savings, checking]);
            balance.expenses.add(ExpenseModel(name: "Gym", amount: 30.0, startDate: day(3),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly,
                source: FundingSource.manualAccount, sourceId: savings.id));
            balance.expenses.add(CreditModel(name: "Card", amount: 300.0, startDate: day(5),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, creditLimit: 1000.0));
            balance.expenses.add(ExpenseModel(name: "Books", amount: 10.0, startDate: day(7),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly,
                source: FundingSource.creditCard, sourceId: "Card"));
            final data = VisualsData(balance, []);

            // Checking counts toward the balance, so it isn't listed on its own.
            expect(balance.netAccounts().map((a) => a.key),
                [BalanceModel.balanceKey, BalanceModel.manualKey(savings.id), BalanceModel.cardKey("Card")]);
            final payday = data.netProjection(day(10), today: today)[1];
            expect(payday.date, day(14));
            expect(payday.amounts[BalanceModel.balanceKey], closeTo(-75.0 - 300.0, 1e-9)); // card paid on day 5
            expect(payday.amounts[BalanceModel.manualKey(savings.id)], closeTo(470.0, 1e-9));
            expect(payday.amounts[BalanceModel.cardKey("Card")], closeTo(-10.0, 1e-9)); // charged since
            expect(payday.total({BalanceModel.cardKey("Card")}), closeTo(95.0, 1e-9));
        });

        test("history keeps one entry per account per day", () {
            final balance = _balance()..currentBalance = 100.0;
            final savings = ManualAccountModel(name: "Savings", balance: 50.0);
            balance.manualAccounts.add(savings);
            balance.recordHistory();
            balance.currentBalance = 120.0;
            balance.recordHistory(); // Later the same day: replaces
            balance.manualAccounts.clear();
            balance.lastUpdated = day(1);
            balance.recordHistory();

            final data = VisualsData(balance, []);
            final history = data.netHistory(day(-30));
            expect(history.map((p) => p.date), [today, day(1)]);
            expect(history.map((p) => p.total(const {})), [170.0, 120.0]);
            expect(data.netLegend(history).map((i) => (i.name, i.amount)),
                [("Current Balance", 120.0), ("Savings", null)]); // gone, but in the history
        });

        test("renaming a card keeps its history", () {
            final balance = _balance();
            balance.expenses.add(CreditModel(name: "Card", amount: 40.0, startDate: day(5),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, creditLimit: 1000.0));
            balance.recordHistory();
            balance.renameCard("Card", "Visa");

            final entry = balance.history.singleWhere((h) => h.key == BalanceModel.cardKey("Visa"));
            expect((entry.name, entry.amount), ("Visa", -40.0));
        });
    });
}
