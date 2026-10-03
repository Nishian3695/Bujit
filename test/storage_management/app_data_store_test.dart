// Saving and loading everything through a real (in-memory) database, and the
// app's startup flow on top of it (AppState.open).
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/banking/manual_account_model.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/expense_activity/funding_source.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/navigation_items/single_events/single_event_model.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/storage_management/database/app_database.dart';
import 'package:bujit/storage_management/period_snapshot.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);
DateTime day(int offset) => addDays(today, offset);

AppDataStore _memoryStore() => AppDataStore(AppDatabase(NativeDatabase.memory()));

AppData _sampleData() {
    final balance = BalanceModel(currentBalance: 1234.56, lastUpdated: today, balanceExtra: 34.56);
    final savings = ManualAccountModel(id: "acct-1", name: "Savings", accountType: "Savings",
        balance: 900.0, countsTowardBalance: true);
    balance.manualAccounts.addAll([savings, ManualAccountModel(id: "acct-2", name: "Wallet", accountType: "Cash", balance: 40.0)]);
    balance.expenses.addAll([
        ExpenseModel(
            name: "Gym", amount: 40.0, startDate: DateTime(2026, 1, 31), currentDueDate: day(30),
            frequency: 1, frequencyUnits: FrequencyUnit.monthly, endDate: DateTime(2027, 6, 30),
            category: "Health", googleTaskId: "task-gym", remindInTasks: false,
            source: FundingSource.creditCard, sourceId: "Card",
        ),
        CreditModel(
            name: "Card", amount: 300.0, startDate: day(5), frequency: 1,
            frequencyUnits: FrequencyUnit.monthly, creditLimit: 2000.0,
            source: FundingSource.manualAccount, sourceId: "acct-1",
        ),
    ]);
    final side = IncomeStreamModel(name: "Side", amount: 250.0, startDate: day(-35),
        frequency: 30, frequencyUnits: FrequencyUnit.daily);
    final job = IncomeStreamModel(name: "Job", amount: 1000.0, startDate: today,
        frequency: 2, frequencyUnits: FrequencyUnit.weekly, googleTaskId: "task-job");
    balance.incomeStreams.addAll([side, job]);
    balance.activeIncome = job;
    balance.snapshots.add(PeriodSnapshot(start: day(-14), totalIncome: 1250.0, totalExpenses: 410.5));
    return AppData(
        balance: balance,
        categories: ["Housing", "Health"],
        includeNextCheck: true,
        singleEventExpiryDays: 14,
        tasksSyncEnabled: true,
        tasksListId: "list-1",
        tasksAccount: "me@example.com",
        syncedTasks: {"task-gym": '{"title":"Gym"}', "task-job": '{"title":"Job"}'},
        singleEvents: [
            SingleEventModel(name: "Dinner", amount: 60.0, isDebit: true, target: EventTarget.creditCard,
                targetName: "Card", createdDate: day(-3), lastModifiedDate: day(-1)),
            SingleEventModel(name: "Gift", amount: 25.0, isDebit: false, target: EventTarget.manualAccount,
                targetId: "acct-2", targetName: "Wallet", createdDate: day(-2)),
        ],
    );
}

void main() {
    group("AppDataStore", () {
        test("load returns null before anything is saved (first launch)", () async {
            expect(await _memoryStore().load(), isNull);
        });

        test("everything round-trips", () async {
            final store = _memoryStore();
            await store.save(_sampleData());

            final AppData loaded = (await store.load())!;
            final BalanceModel balance = loaded.balance;
            expect(balance.currentBalance, closeTo(1234.56, 1e-9));
            expect(balance.lastUpdated, today);
            expect(loaded.includeNextCheck, isTrue);
            expect(loaded.categories, ["Housing", "Health"]);

            final ExpenseModel gym = balance.expenses[0] as ExpenseModel;
            expect(gym.name, "Gym");
            expect(gym.startDate, DateTime(2026, 1, 31));
            expect(gym.currentDueDate, day(30));
            expect(gym.endDate, DateTime(2027, 6, 30));
            expect(gym.category, "Health");
            expect(gym.googleTaskId, "task-gym");
            expect(gym.source, FundingSource.creditCard);
            expect(gym.sourceId, "Card");
            expect(balance.expenses[1].source, FundingSource.manualAccount);
            expect(balance.expenses[1].sourceId, "acct-1");
            expect(balance.balanceExtra, 34.56);
            expect(balance.manualAccounts.map((a) => a.id), ["acct-1", "acct-2"]);
            final ManualAccountModel savings = balance.manualAccounts.first;
            expect(savings.name, "Savings");
            expect(savings.accountType, "Savings");
            expect(savings.balance, 900.0);
            expect(savings.countsTowardBalance, isTrue);
            expect(balance.manualAccounts[1].countsTowardBalance, isFalse);
            expect(gym.remindInTasks, isFalse);
            expect(balance.expenses[1].googleTaskId, isNull);
            expect(balance.expenses[1].remindInTasks, isTrue);
            expect(balance.activeIncome!.googleTaskId, "task-job");
            expect(loaded.tasksSyncEnabled, isTrue);
            expect(loaded.tasksListId, "list-1");
            expect(loaded.tasksAccount, "me@example.com");
            expect(loaded.syncedTasks, {"task-gym": '{"title":"Gym"}', "task-job": '{"title":"Job"}'});

            final CreditModel card = balance.expenses[1] as CreditModel;
            expect(card.amount, 300.0);
            expect(card.creditLimit, 2000.0);
            expect(card.currentDueDate, day(5));

            expect(balance.incomeStreams.map((s) => s.name), ["Side", "Job"]);
            expect(balance.activeIncome!.name, "Job");
            expect(balance.activeIncome!.frequencyUnits, FrequencyUnit.weekly);

            final snapshot = balance.snapshots.single;
            expect(snapshot.start, day(-14));
            expect(snapshot.totalIncome, 1250.0);
            expect(snapshot.totalExpenses, 410.5);

            expect(loaded.singleEventExpiryDays, 14);
            final SingleEventModel gift = loaded.singleEvents[1];
            expect(gift.target, EventTarget.manualAccount);
            expect(gift.targetId, "acct-2");
            expect(gift.targetDisplayName, "Wallet");
            final SingleEventModel event = loaded.singleEvents.first;
            expect(event.name, "Dinner");
            expect(event.isDebit, isTrue);
            expect(event.appliedAmount, -60.0);
            expect(event.target, EventTarget.creditCard);
            expect(event.targetName, "Card");
            expect(event.createdDate, day(-3));
            expect(event.lastModifiedDate, day(-1));
        });

        test("saving again replaces rather than duplicates", () async {
            final store = _memoryStore();
            final AppData data = _sampleData();
            await store.save(data);
            data.balance.expenses.removeAt(0);
            await store.save(data);

            final AppData loaded = (await store.load())!;
            expect(loaded.balance.expenses, hasLength(1));
            expect(loaded.balance.incomeStreams, hasLength(2));
        });
    });

    group("AppState.open", () {
        test("the first launch loads the tutorial's sample data and saves it", () async {
            final store = _memoryStore();
            final AppState state = await AppState.open(store, today: today);

            expect(state.balance.currentBalance, 3500.0);
            expect(state.balance.expenses, hasLength(6));
            final AppData saved = (await store.load())!;
            expect(saved.balance.expenses, hasLength(6));
            expect(saved.balance.activeIncome!.name, "Main Job");
        });

        test("a later launch catches up to today and saves the result", () async {
            final store = _memoryStore();
            await AppState.open(store, today: today); // first launch: sample data

            // 14 days later: the $2400 paycheck arrived; rent (day 2), Netflix (5),
            // electric (9) and every card's balance came due.
            final AppState later = await AppState.open(store, today: day(14));
            const double paid = 850.0 + 15.99 + 110.0 + 450.0 + 1200.0 + 6000.0;
            expect(later.balance.currentBalance, closeTo(3500.0 + 2400.0 - paid, 1e-6));

            final AppData saved = (await store.load())!;
            expect(saved.balance.currentBalance, closeTo(3500.0 + 2400.0 - paid, 1e-6));
            expect(saved.balance.lastUpdated, day(14));
        });

        test("returning to the app on a later day catches up and saves, as a launch does", () async {
            final store = _memoryStore();
            final AppState state = await AppState.open(store, today: today);
            int notified = 0;
            state.addListener(() => notified++);

            await state.catchUp(today: today); // same day: nothing to do
            expect(state.balance.currentBalance, 3500.0);
            expect(notified, 0);

            await state.catchUp(today: day(14));
            const double paid = 850.0 + 15.99 + 110.0 + 450.0 + 1200.0 + 6000.0;
            expect(state.balance.currentBalance, closeTo(3500.0 + 2400.0 - paid, 1e-6));
            expect(notified, greaterThan(0)); // the home screen recomputes
            expect((await store.load())!.balance.lastUpdated, day(14));

            await state.catchUp(today: day(14)); // again the same day: no double payment
            expect(state.balance.currentBalance, closeTo(3500.0 + 2400.0 - paid, 1e-6));
        });

        test("changed() saves", () async {
            final store = _memoryStore();
            final AppState state = await AppState.open(store, today: today);
            state.balance.expenses.clear();
            await state.changed();

            expect((await store.load())!.balance.expenses, isEmpty);
        });
    });
}
