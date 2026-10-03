// The screens around the balance: Update Balance on the home screen, the
// Linked Accounts screen's manual accounts, and "Paid from" in the expense
// dialog. Starts from the tutorial's sample data (balance $3500; this check's
// expenses $8625.99, including Netflix $15.99 in 5 days and the Everyday Card's
// $450 in 3 days).
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/banking/banking_activity.dart';
import 'package:bujit/navigation_items/banking/manual_account_model.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_activity.dart';
import 'package:bujit/navigation_items/expense_activity/funding_source.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppState _sampleState() {
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.0), tutorialSeen: true);
    seedSampleData(data.balance);
    return AppState(data);
}

Future<AppState> _pumpHome(WidgetTester tester, [AppState? state]) async {
    final AppState s = state ?? _sampleState();
    await tester.pumpWidget(MaterialApp(home: ExpenseActivity(state: s)));
    return s;
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
    group("Update Balance", () {
        testWidgets("tapping the balance sets a typed balance plus additional funds", (tester) async {
            final AppState state = await _pumpHome(tester);

            await tester.tap(find.text("CURRENT BALANCE"));
            await tester.pumpAndSettle();
            expect(find.text("Update Balance"), findsOneWidget);
            await tester.enterText(_field("Balance"), "1200");
            await tester.enterText(_field("Additional funds"), "50");
            await tester.tap(find.text("Save"));
            await tester.pumpAndSettle();

            expect(state.balance.currentBalance, 1250.0);
            expect(state.balance.balanceExtra, 50.0);
            expect(find.text("\$1250.00"), findsOneWidget);
        });

        testWidgets("From Accounts totals the accounts picked, which then count toward the balance", (tester) async {
            final AppState state = _sampleState();
            final ManualAccountModel savings = ManualAccountModel(name: "Savings", balance: 900.0);
            final ManualAccountModel wallet = ManualAccountModel(name: "Wallet", accountType: "Cash", balance: 60.0);
            state.balance.manualAccounts.addAll([savings, wallet]);
            await _pumpHome(tester, state);

            await tester.tap(find.text("CURRENT BALANCE"));
            await tester.pumpAndSettle();
            await tester.enterText(_field("Additional funds"), "0");
            await tester.tap(find.text("From Accounts"));
            await tester.pumpAndSettle();
            await tester.tap(find.text("Savings"));
            await tester.tap(find.text("Wallet"));
            await tester.tap(find.text("OK"));
            await tester.pumpAndSettle();
            expect(find.text("From 2 accounts"), findsOneWidget);
            await tester.tap(find.text("Save"));
            await tester.pumpAndSettle();

            expect(state.balance.currentBalance, 960.0);
            expect(savings.countsTowardBalance, isTrue);
            expect(wallet.countsTowardBalance, isTrue);
        });

        testWidgets("projected checks can't change the balance", (tester) async {
            await _pumpHome(tester);
            await tester.tap(find.byTooltip("Next check"));
            await tester.pump();

            await tester.tap(find.text("CURRENT BALANCE"));
            await tester.pumpAndSettle();

            expect(find.text("Update Balance"), findsNothing);
        });
    });

    group("Linked Accounts", () {
        testWidgets("the drawer opens it, and + adds a manual account", (tester) async {
            final AppState state = await _pumpHome(tester);
            await tester.tap(find.byTooltip("Open navigation menu"));
            await tester.pumpAndSettle();
            await tester.tap(find.text("Linked Accounts"));
            await tester.pumpAndSettle();
            expect(find.textContaining("No manual accounts yet"), findsOneWidget);

            await tester.tap(find.byTooltip("Add account"));
            await tester.pumpAndSettle();
            await tester.enterText(_field("Account name"), "Emergency fund");
            await tester.enterText(_field("Balance"), "2500");
            await tester.tap(find.text("Add"));
            await tester.pumpAndSettle();

            expect(find.text("Emergency fund"), findsOneWidget);
            final ManualAccountModel account = state.balance.manualAccounts.single;
            expect(account.accountType, "Savings");
            expect(account.balance, 2500.0);
            expect(state.balance.currentBalance, 3500.0); // doesn't count until picked
        });

        testWidgets("editing an account in the balance moves the balance", (tester) async {
            final AppState state = _sampleState();
            final ManualAccountModel savings = ManualAccountModel(name: "Savings", balance: 900.0, countsTowardBalance: true);
            state.balance.manualAccounts.add(savings);
            await tester.pumpWidget(MaterialApp(home: BankingActivity(state: state)));
            expect(find.text("Savings · in your current balance"), findsOneWidget);

            await tester.tap(find.text("Savings").first);
            await tester.pumpAndSettle();
            await tester.enterText(_field("Balance"), "1000");
            await tester.tap(find.text("Save"));
            await tester.pumpAndSettle();

            expect(savings.balance, 1000.0);
            expect(state.balance.currentBalance, 3600.0);
        });

        testWidgets("deleting an account warns what it affects, then removes it", (tester) async {
            final AppState state = _sampleState();
            final ManualAccountModel savings = ManualAccountModel(name: "Savings", balance: 900.0, countsTowardBalance: true);
            state.balance.manualAccounts.add(savings);
            state.balance.expenses.first
                ..source = FundingSource.manualAccount
                ..sourceId = savings.id; // Rent
            await tester.pumpWidget(MaterialApp(home: BankingActivity(state: state)));

            await tester.tap(find.text("Savings").first);
            await tester.pumpAndSettle();
            await tester.tap(find.text("Delete"));
            await tester.pumpAndSettle();
            expect(find.textContaining("Its balance will be removed from your current balance."), findsOneWidget);
            expect(find.textContaining("Rent will be paid from your current balance instead."), findsOneWidget);
            await tester.tap(find.text("Delete").last);
            await tester.pumpAndSettle();

            expect(state.balance.manualAccounts, isEmpty);
            expect(state.balance.currentBalance, 2600.0);
            expect(state.balance.expenses.first.source, FundingSource.balance);
        });
    });

    testWidgets("charging an expense to a card takes it out of this check's total", (tester) async {
        final AppState state = await _pumpHome(tester);
        expect(find.text("\$-5125.99"), findsOneWidget); // 3500 - 8625.99

        await tester.tap(find.text("Netflix"));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text("Current Balance")); // the dialog scrolls on a small screen
        await tester.pumpAndSettle();
        await tester.tap(find.text("Current Balance"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Everyday Card (card)").last);
        await tester.pumpAndSettle();
        await tester.tap(find.text("Save"));
        await tester.pumpAndSettle();

        // Netflix (in 5 days) now lands on the card after its due date (in 3 days),
        // so it isn't paid this check: 8625.99 - 15.99.
        expect(find.text("\$-5110.00"), findsOneWidget);
        expect(find.textContaining("from Everyday Card (card)"), findsOneWidget);
        expect(state.balance.expenses.firstWhere((e) => e.name == "Netflix").source, FundingSource.creditCard);
    });
}
