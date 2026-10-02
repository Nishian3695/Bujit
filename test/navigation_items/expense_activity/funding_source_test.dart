// What pays for expenses and cards (FundingSource): manual accounts, charges to
// cards, and Update Balance -- when payments happen (makeRecent), and what the
// checks project, without counting anything twice.
//
// The setup (today = Thu Oct 1, 2026):
//   Job      +$2000 every 2 weeks from Sep 24 -> paydays Oct 8, Oct 22, Nov 5, Nov 19
//   Rent     $1000 monthly from Oct 15, paid from the balance
//   Netflix  $15 monthly from Oct 5, charged to Visa
//   Visa     owes $100, due monthly from Oct 20, paid from the balance
// Checks: 0 = [Oct 1, Oct 8], 1 = (Oct 8, Oct 22], 2 = (Oct 22, Nov 5],
//         3 = (Nov 5, Nov 19], 4 = (Nov 19, Dec 3]
import 'package:bujit/navigation_items/banking/manual_account_model.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/expense_activity/funding_source.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/navigation_items/single_events/single_event_model.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);

late BalanceModel balance;
late ExpenseModel rent;
late ExpenseModel netflix;
late CreditModel visa;

void _setUp() {
    balance = BalanceModel(currentBalance: 5000.0, lastUpdated: today);
    rent = ExpenseModel(name: "Rent", amount: 1000.0, startDate: DateTime(2026, 10, 15),
        frequency: 1, frequencyUnits: FrequencyUnit.monthly);
    netflix = ExpenseModel(name: "Netflix", amount: 15.0, startDate: DateTime(2026, 10, 5),
        frequency: 1, frequencyUnits: FrequencyUnit.monthly,
        source: FundingSource.creditCard, sourceId: "Visa");
    visa = CreditModel(name: "Visa", amount: 100.0, startDate: DateTime(2026, 10, 20),
        frequency: 1, frequencyUnits: FrequencyUnit.monthly, creditLimit: 1000.0);
    balance.expenses.addAll([rent, netflix, visa]);
    final IncomeStreamModel job = IncomeStreamModel(name: "Job", amount: 2000.0,
        startDate: DateTime(2026, 9, 24), frequency: 2, frequencyUnits: FrequencyUnit.weekly);
    balance.incomeStreams.add(job);
    balance.activeIncome = job;
}

ManualAccountModel _savings({bool counts = false, double amount = 3000.0}) {
    final ManualAccountModel savings = ManualAccountModel(name: "Savings", balance: amount, countsTowardBalance: counts);
    balance.manualAccounts.add(savings);
    return savings;
}

void main() {
    setUp(_setUp);

    group("charges to a card", () {
        test("aren't counted on their own dates, only in the card's payment", () {
            expect(balance.check(0, today: today).expensesDue, 0.0); // Netflix Oct 5 goes on the card
            expect(balance.check(1, today: today).expensesDue, 1115.0); // Rent + Visa (100 + Netflix 15)
            expect(balance.check(2, today: today).expensesDue, 0.0); // Netflix Nov 5 goes on the card
            expect(balance.check(4, today: today).expensesDue, 15.0); // Visa Nov 20: just Nov 5's charge
        });

        test("projections add up to what catching up actually does", () {
            // Check 2 opens with Oct 22's paycheck in: 5000 + 2000 - 1115 + 2000.
            final double projected = balance.check(2, today: today).startBalance;
            expect(projected, 7885.0);
            balance.makeRecent(today: DateTime(2026, 10, 23));
            expect(balance.currentBalance, projected);
        });

        test("go on the card when they happen, and the balance pays on the due date", () {
            balance.makeRecent(today: DateTime(2026, 10, 6)); // Netflix Oct 5
            expect(visa.amount, 115.0);
            expect(balance.currentBalance, 5000.0);
            expect(netflix.currentDueDate, DateTime(2026, 11, 5));

            balance.makeRecent(today: DateTime(2026, 10, 21)); // Paycheck Oct 8, Rent Oct 15, Visa Oct 20
            expect(balance.currentBalance, 5000.0 + 2000.0 - 1000.0 - 115.0);
            expect(visa.amount, 0.0);
            expect(visa.currentDueDate, DateTime(2026, 11, 20));
        });

        test("catching up over several due dates pays each one what it owed", () {
            final double change = balance.makeRecent(today: DateTime(2026, 11, 21));

            // Visa: Oct 20 pays 100 + Oct 5's 15; Nov 20 pays Nov 5's 15.
            expect(change, 4 * 2000.0 - 2 * 1000.0 - 115.0 - 15.0);
            expect(visa.amount, 0.0);
        });

        test("a charge on a due date goes toward the next one", () {
            balance.expenses.add(ExpenseModel(name: "Gym", amount: 30.0, startDate: DateTime(2026, 10, 20),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly,
                source: FundingSource.creditCard, sourceId: "Visa"));

            expect(balance.check(1, today: today).expensesDue, 1115.0); // Gym Oct 20 isn't in Visa's Oct 20 payment
            balance.makeRecent(today: DateTime(2026, 10, 21));
            expect(visa.amount, 30.0);
        });

        test("utilization includes the charges coming in each check", () {
            balance.showCheck(0, today: today);
            expect(visa.displayBalance, 115.0); // 100 + Oct 5
            expect(visa.periodAmount, 0.0); // nothing due this check

            balance.showCheck(1, today: today);
            expect(visa.displayBalance, 115.0); // what Oct 20 pays
            expect(visa.periodAmount, 115.0);

            balance.showCheck(2, today: today);
            expect(visa.displayBalance, 15.0); // paid off Oct 20, then Nov 5's charge
            expect(visa.periodAmount, 0.0);
        });

        test("a deleted card's charges come from the balance", () {
            balance.expenses.remove(visa);
            balance.cardRemoved("Visa");

            expect(netflix.source, FundingSource.balance);
            expect(balance.check(0, today: today).expensesDue, 15.0);
        });

        test("charges to a card that's gone fall back to the balance", () {
            netflix.sourceId = "Old card";

            expect(balance.hitsBalance(netflix), isTrue);
            balance.makeRecent(today: DateTime(2026, 10, 6));
            expect(balance.currentBalance, 5000.0 - 15.0);
        });

        test("Visuals count a charge once, in the card's payment", () {
            expect(balance.periodExpenses(DateTime(2026, 10, 8), DateTime(2026, 10, 22)), 1115.0);
        });
    });

    group("manual accounts", () {
        test("an account outside the balance pays without touching it", () {
            final ManualAccountModel savings = _savings();
            rent
                ..source = FundingSource.manualAccount
                ..sourceId = savings.id;

            expect(balance.check(1, today: today).expensesDue, 115.0); // just Visa
            balance.makeRecent(today: DateTime(2026, 10, 16));
            expect(savings.balance, 2000.0);
            expect(balance.currentBalance, 5000.0 + 2000.0);
        });

        test("an account in the balance takes the balance down with it", () {
            final ManualAccountModel savings = _savings(counts: true);
            rent
                ..source = FundingSource.manualAccount
                ..sourceId = savings.id;

            expect(balance.check(1, today: today).expensesDue, 1115.0);
            balance.makeRecent(today: DateTime(2026, 10, 16));
            expect(savings.balance, 2000.0);
            expect(balance.currentBalance, 5000.0 + 2000.0 - 1000.0);
        });

        test("a card can be paid from an account", () {
            final ManualAccountModel savings = _savings();
            visa
                ..source = FundingSource.manualAccount
                ..sourceId = savings.id;

            balance.makeRecent(today: DateTime(2026, 10, 21));
            expect(savings.balance, 3000.0 - 115.0);
            expect(balance.currentBalance, 5000.0 + 2000.0 - 1000.0);
        });

        test("deleting an account takes its balance out if it counted, and its expenses go to the balance", () {
            final ManualAccountModel savings = _savings(counts: true);
            balance.currentBalance += savings.balance;
            rent
                ..source = FundingSource.manualAccount
                ..sourceId = savings.id;

            balance.removeAccount(savings);

            expect(balance.currentBalance, 5000.0);
            expect(rent.source, FundingSource.balance);
            expect(rent.sourceId, isNull);
        });

        test("editing an account's balance moves the current balance only if it counts", () {
            final ManualAccountModel outside = _savings();
            final ManualAccountModel inside = _savings(counts: true);

            balance.adjustAccount(outside, 100.0);
            balance.adjustAccount(inside, -50.0);

            expect(balance.currentBalance, 4950.0);
        });
    });

    group("Update Balance", () {
        test("a typed balance plus additional funds; no account counts anymore", () {
            final ManualAccountModel savings = _savings(counts: true);

            balance.setBalanceTyped(1200.0, 300.0);

            expect(balance.currentBalance, 1500.0);
            expect(balance.balanceExtra, 300.0);
            expect(savings.countsTowardBalance, isFalse);
        });

        test("from accounts: their total plus additional funds", () {
            final ManualAccountModel savings = _savings();
            final ManualAccountModel checking = ManualAccountModel(name: "Checking", balance: 800.0);
            balance.manualAccounts.add(checking);

            balance.setBalanceFromAccounts({savings.id, checking.id}, 50.0);

            expect(balance.currentBalance, 3850.0);
            expect(savings.countsTowardBalance, isTrue);
            expect(checking.countsTowardBalance, isTrue);
        });
    });

    group("single events", () {
        test("on an account in the balance move both, and removing one undoes it", () {
            final ManualAccountModel savings = _savings(counts: true);
            final AppData data = AppData(balance: balance);
            final event = SingleEventModel(name: "Gift", amount: 200.0, isDebit: false,
                target: EventTarget.manualAccount, targetId: savings.id, targetName: "Savings");

            data.singleEventsLedger.add(event);
            expect(savings.balance, 3200.0);
            expect(balance.currentBalance, 5200.0);
            expect(event.targetDisplayName, "Savings");

            data.singleEventsLedger.remove(event);
            expect(savings.balance, 3000.0);
            expect(balance.currentBalance, 5000.0);
        });

        test("the targets offered: the balance, accounts, then cards", () {
            _savings();
            expect(AppData(balance: balance).singleEventsLedger.targets.map((t) => t.label),
                ["Current Balance", "Savings", "Visa (card)"]);
        });
    });

    group("renaming", () {
        test("a card keeps its charges and single events", () {
            final AppData data = AppData(balance: balance, singleEvents: [
                SingleEventModel(name: "Dinner", amount: 40.0, isDebit: true,
                    target: EventTarget.creditCard, targetName: "Visa"),
            ]);
            visa.name = "Visa Gold";

            data.renameCard("Visa", "Visa Gold");

            expect(netflix.sourceId, "Visa Gold");
            expect(data.singleEvents.single.targetName, "Visa Gold");
            expect(balance.check(1, today: today).expensesDue, 1115.0);
        });

        test("an account updates the single events that show its name", () {
            final ManualAccountModel savings = _savings();
            final AppData data = AppData(balance: balance, singleEvents: [
                SingleEventModel(name: "Gift", amount: 20.0, isDebit: false,
                    target: EventTarget.manualAccount, targetId: savings.id, targetName: "Savings"),
            ]);
            savings.name = "Rainy day";

            data.accountRenamed(savings);

            expect(data.singleEvents.single.targetDisplayName, "Rainy day");
        });
    });

    test("Paid from choices and labels", () {
        final ManualAccountModel savings = _savings();
        expect(balance.paymentOptions(forCard: false).map((o) => o.label), ["Current Balance", "Savings", "Visa (card)"]);
        expect(balance.paymentOptions(forCard: true).map((o) => o.label), ["Current Balance", "Savings"]);
        expect(balance.paidFromLabel(netflix), "Visa (card)");
        rent
            ..source = FundingSource.manualAccount
            ..sourceId = savings.id;
        expect(balance.paidFromLabel(rent), "Savings");
        expect(balance.paidFromLabel(visa), "Current Balance");
    });
}
