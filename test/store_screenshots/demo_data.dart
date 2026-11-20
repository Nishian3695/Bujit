// The data shown in the store screenshots: a believable budget with a biweekly
// paycheck, a side gig, everyday bills, three cards, a savings account, a few
// one-off events, and months of history for Visuals. Dates are relative to
// today, so the screens look current whenever the images are made.
import 'dart:math';

import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/banking/manual_account_model.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/navigation_items/single_events/single_event_model.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/storage_management/balance_history.dart';
import 'package:bujit/storage_management/database/app_database.dart';
import 'package:bujit/storage_management/period_snapshot.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:drift/native.dart';

// The app's accent in the screenshots: the brand's hot pink (BRAND.md).
const int brandPink = 0xFFDB1867;

AppState demoState() {
    final DateTime today = todayDate();
    DateTime day(int offset) => addDays(today, offset);

    final BalanceModel balance = BalanceModel(currentBalance: 2846.17, lastUpdated: today);

    ExpenseModel bill(String name, double amount, int dueIn, String category,
            {int every = 1, FrequencyUnit unit = FrequencyUnit.monthly}) =>
        ExpenseModel(name: name, amount: amount, startDate: day(dueIn), frequency: every,
            frequencyUnits: unit, category: category);
    CreditModel card(String name, double owed, int dueIn, double limit) => CreditModel(
        name: name, amount: owed, startDate: day(dueIn), frequency: 1,
        frequencyUnits: FrequencyUnit.monthly, creditLimit: limit);

    balance.expenses.addAll([
        bill("Rent", 1250.00, 4, "Housing"),
        bill("Groceries", 115.00, 1, "Food", every: 1, unit: FrequencyUnit.weekly),
        bill("Car Payment", 289.50, 6, "Transport"),
        bill("Car Insurance", 142.00, 11, "Transport"),
        bill("Electric", 92.40, 8, "Utilities"),
        bill("Internet", 60.00, 2, "Utilities"),
        bill("Phone", 45.00, 12, "Utilities"),
        bill("Gym", 35.00, 9, "Healthcare"),
        bill("Spotify", 11.99, 3, "Subscriptions"),
        bill("Netflix", 15.49, 13, "Subscriptions"),
        card("Everyday Visa", 412.36, 7, 3000.00),
        card("Travel Rewards", 1180.00, 18, 5000.00),
        card("Store Card", 95.20, 10, 1000.00),
    ]);

    // Paid every two weeks: payday was 3 days ago, so the check has 11 days left.
    // Started over a year ago, so Cash Flow's year is full of past pay periods.
    final IncomeStreamModel job = IncomeStreamModel(name: "Paycheck", amount: 2150.00,
        startDate: day(-3 - 14 * 27), frequency: 2, frequencyUnits: FrequencyUnit.weekly, isActive: true);
    final IncomeStreamModel gig = IncomeStreamModel(name: "Freelance Design", amount: 400.00,
        startDate: day(9), frequency: 1, frequencyUnits: FrequencyUnit.monthly);
    balance.incomeStreams.addAll([job, gig]);
    balance.activeIncome = job;

    final ManualAccountModel savings =
        ManualAccountModel(name: "Emergency Fund", accountType: "Savings", balance: 4200.00);
    balance.manualAccounts.add(savings);

    // Past pay periods, for Visuals' Cash Flow.
    final Random random = Random(7);
    for (int period = 1; period <= 27; period++) {
        final double income = 2150.00 + (period % 2 == 0 ? 400.00 : 0.00);
        balance.snapshots.add(PeriodSnapshot(
            start: day(-3 - 14 * period),
            totalIncome: income,
            totalExpenses: 1500.00 + random.nextDouble() * 900.00,
        ));
    }

    // Balances over the last six months, for Visuals' Net Balance: savings
    // growing, card debt shrinking, the checking balance swinging with paydays.
    for (int back = 182; back > 0; back -= 2) {
        final DateTime date = day(-back);
        final double t = 1 - back / 182;
        final double swing = 450 * cos(2 * pi * back / 14);
        balance.history.addAll([
            BalanceHistoryEntry(date: date, key: BalanceModel.balanceKey, name: "Current Balance",
                amount: 1700 + 900 * t + swing + random.nextDouble() * 150),
            BalanceHistoryEntry(date: date, key: BalanceModel.manualKey(savings.id), name: savings.name,
                amount: 2600 + 1600 * t),
            for (final CreditModel c in balance.creditCards)
                BalanceHistoryEntry(date: date, key: BalanceModel.cardKey(c.name), name: c.name,
                    amount: -(c.amount * (1.9 - 0.9 * t) + random.nextDouble() * 60)),
        ]);
    }
    balance.recordHistory();

    final AppData data = AppData(
        balance: balance,
        tutorialSeen: true,
        useCommaSeparators: true,
        accentColor: "custom",
        customAccent: brandPink,
        themeMode: "light",
        singleEvents: [
            SingleEventModel(name: "Concert tickets", amount: 86.00, isDebit: true, createdDate: day(-1)),
            SingleEventModel(name: "Sold old bike", amount: 120.00, isDebit: false, createdDate: day(-2)),
            SingleEventModel(name: "Car repair", amount: 240.00, isDebit: true, createdDate: day(-5),
                target: EventTarget.creditCard, targetName: "Everyday Visa"),
            SingleEventModel(name: "Birthday money", amount: 50.00, isDebit: false, createdDate: day(-8),
                target: EventTarget.manualAccount, targetName: savings.name, targetId: savings.id),
            SingleEventModel(name: "Dinner out", amount: 64.30, isDebit: true, createdDate: day(-9)),
        ],
    );
    // A store behind it (in memory, and never written: nothing on screen
    // changes), so the home screen doesn't warn that changes won't be saved.
    return AppState(data, AppDataStore(AppDatabase(NativeDatabase.memory())));
}
