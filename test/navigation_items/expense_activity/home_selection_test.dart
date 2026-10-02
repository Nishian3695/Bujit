// The home screen's remaining Java features: multi-select (Select, Select All,
// Delete), the rows' rate/end/link/utilization details, the bank sync line, and
// the first-launch disclaimer before the tutorial. Starts from the tutorial's
// sample data: Rent $850 (in 2 days), Netflix $15.99 (5), Electric Bill $110 (9),
// and cards Everyday ($450 of $2000), Travel ($1200 of $3000), Hobby ($6000 of $6200).
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/banking/bank_account_model.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_activity.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/expense_activity/funding_source.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/storage_management/database/app_database.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppState _sampleState({bool disclaimerAccepted = true}) {
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.0), tutorialSeen: true,
        disclaimerAccepted: disclaimerAccepted);
    seedSampleData(data.balance);
    return AppState(data);
}

Future<AppState> _pumpHome(WidgetTester tester, [AppState? state]) async {
    final AppState s = state ?? _sampleState();
    await tester.pumpWidget(MaterialApp(home: ExpenseActivity(state: s)));
    await tester.pumpAndSettle();
    return s;
}

void main() {
    group("multi-select", () {
        testWidgets("Select shows checkboxes; ticked rows can be deleted together", (tester) async {
            final AppState state = await _pumpHome(tester);
            expect(find.byType(Checkbox), findsNothing);

            await tester.tap(find.byTooltip("Select"));
            await tester.pump();
            expect(find.byType(Checkbox), findsNWidgets(6));
            expect(find.text("0 selected"), findsOneWidget);

            await tester.tap(find.text("Rent"));
            await tester.tap(find.text("Netflix"));
            await tester.pump();
            expect(find.text("2 selected"), findsOneWidget);

            await tester.tap(find.byTooltip("Delete"));
            await tester.pumpAndSettle();
            expect(find.text("Delete 2 expenses? This cannot be undone."), findsOneWidget);
            await tester.tap(find.text("Delete").last);
            await tester.pumpAndSettle();

            expect(state.balance.expenses.map((e) => e.name), isNot(contains("Rent")));
            expect(state.balance.expenses.map((e) => e.name), isNot(contains("Netflix")));
            expect(state.balance.expenses, hasLength(4));
            expect(find.byType(Checkbox), findsNothing); // done selecting
        });

        testWidgets("Select All toggles; unticking the last row ends selecting", (tester) async {
            final AppState state = await _pumpHome(tester);
            await tester.tap(find.byTooltip("Select"));
            await tester.pump();

            await tester.tap(find.byTooltip("Select All"));
            await tester.pump();
            expect(find.text("6 selected"), findsOneWidget);
            await tester.tap(find.byTooltip("Select All"));
            await tester.pump();
            expect(find.text("0 selected"), findsOneWidget);

            await tester.tap(find.text("Rent"));
            await tester.pump();
            await tester.tap(find.text("Rent"));
            await tester.pump();
            expect(find.byType(Checkbox), findsNothing);
            expect(state.balance.expenses, hasLength(6));
        });

        testWidgets("Back and the home button end selecting without deleting", (tester) async {
            final AppState state = await _pumpHome(tester);
            await tester.tap(find.byTooltip("Select"));
            await tester.pump();
            await tester.tap(find.text("Rent"));
            await tester.pump();

            await tester.binding.handlePopRoute();
            await tester.pump();
            expect(find.byType(Checkbox), findsNothing);

            await tester.tap(find.byTooltip("Select"));
            await tester.pump();
            await tester.tap(find.byTooltip("Done").last); // the home button
            await tester.pump();
            expect(find.byType(Checkbox), findsNothing);
            expect(state.balance.expenses, hasLength(6));
        });

        testWidgets("deleting a card sends what was charged to it back to the balance", (tester) async {
            final AppState state = _sampleState();
            final netflix = state.balance.expenses.firstWhere((e) => e.name == "Netflix")
                ..source = FundingSource.creditCard
                ..sourceId = "Everyday Card";
            await _pumpHome(tester, state);
            await tester.tap(find.byTooltip("Select"));
            await tester.pump();
            await tester.tap(find.text("Everyday Card"));
            await tester.pump();
            await tester.tap(find.byTooltip("Delete"));
            await tester.pumpAndSettle();
            await tester.tap(find.text("Delete").last);
            await tester.pumpAndSettle();

            expect(netflix.source, FundingSource.balance);
        });
    });

    group("rows", () {
        testWidgets("show the rate, an end date, a card's utilization and a bank link", (tester) async {
            final AppState state = _sampleState();
            state.balance.expenses.add(ExpenseModel(name: "Gym", amount: 40.0, startDate: addDays(todayDate(), 3),
                frequency: 2, frequencyUnits: FrequencyUnit.weekly, endDate: DateTime(2099, 1, 1),
                linkedAccountId: "loan-1"));
            state.balance.linkedAccounts.add(BankAccountModel(id: "loan-1", itemKey: "k", name: "Loan", type: "loan"));
            await _pumpHome(tester, state);

            expect(find.textContaining("\$850.00/mo"), findsOneWidget);
            expect(find.byType(LinearProgressIndicator), findsNWidgets(3)); // one per card
            await tester.scrollUntilVisible(find.text("Gym"), 100); // the last row
            expect(find.textContaining("\$40.00/2wk · until 2099-01-01"), findsOneWidget);
            await tester.scrollUntilVisible(find.text("Everyday Card"), -100);
            expect(find.textContaining("\$450.00 owed"), findsOneWidget); // a card shows what it owes, not a rate
            expect(find.textContaining("\$450.00/mo"), findsNothing);
            expect(find.byIcon(Icons.link), findsOneWidget);
        });

        testWidgets("an expense past its end date says when it ended", (tester) async {
            final AppState state = _sampleState();
            final DateTime end = addDays(todayDate(), 10);
            state.balance.expenses.add(ExpenseModel(name: "Trial", amount: 9.0, startDate: addDays(todayDate(), 5),
                frequency: 1, frequencyUnits: FrequencyUnit.weekly, endDate: end));
            await _pumpHome(tester, state);

            await tester.tap(find.byTooltip("Next check")); // the following check, after the end date
            await tester.pump();
            await tester.scrollUntilVisible(find.text("Trial"), 100);

            expect(find.textContaining("Ended ${end.toString().split(" ")[0]}"), findsOneWidget);
        });
    });

    testWidgets("the sync line shows while linked accounts make up the balance", (tester) async {
        final AppState state = _sampleState();
        state.balance.linkedAccounts.add(BankAccountModel(id: "chk", itemKey: "k", name: "Checking",
            type: "depository", ledger: 100.0, countsTowardBalance: true));
        final DateTime now = DateTime.now();
        state.data.lastBankSync = DateTime(now.year, now.month, now.day, 15, 4);
        await _pumpHome(tester, state);

        expect(find.text("Synced today at 3:04 PM"), findsOneWidget);

        state.balance.linkedAccounts.single.countsTowardBalance = false;
        await state.changed();
        await tester.pump();
        expect(find.textContaining("Synced"), findsNothing);
    });

    group("first launch", () {
        testWidgets("the disclaimer comes first, then the tutorial", (tester) async {
            final AppData data = AppData(balance: BalanceModel(currentBalance: 0.0), disclaimerAccepted: false);
            seedSampleData(data.balance);
            final AppState state = AppState(data);
            await tester.pumpWidget(MaterialApp(home: ExpenseActivity(state: state)));
            await tester.pumpAndSettle();

            expect(find.text("Before You Begin"), findsOneWidget);
            expect(find.textContaining("not a financial advisor"), findsOneWidget);
            expect(find.text("Navigate pay periods"), findsNothing); // tutorial waits

            await tester.binding.handlePopRoute(); // can't be dismissed
            await tester.pumpAndSettle();
            expect(find.text("Before You Begin"), findsOneWidget);

            await tester.tap(find.text("I Understand"));
            await tester.pumpAndSettle();
            expect(state.data.disclaimerAccepted, isTrue);
            expect(find.text("Navigate pay periods"), findsOneWidget);
        });

        test("a fresh install asks; a later launch remembers", () async {
            final AppDataStore store = AppDataStore(AppDatabase(NativeDatabase.memory()));
            final AppState first = await AppState.open(store);
            expect(first.data.disclaimerAccepted, isFalse);

            await first.acceptDisclaimer();
            expect((await store.load())!.disclaimerAccepted, isTrue);
        });
    });
}
