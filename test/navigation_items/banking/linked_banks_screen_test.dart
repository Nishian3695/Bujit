// The screens around linked banks: Linked Accounts (link, list, disconnect),
// Update Balance's "From Accounts" with linked accounts, and "From connected
// account" in the expense dialog. Uses a fake backend and Plaid Link.
import 'dart:convert';
import 'package:bujit/app_state.dart';
import 'package:bujit/dialogs/credit_card_dialog.dart';
import 'package:bujit/navigation_items/banking/bank_account_model.dart';
import 'package:bujit/navigation_items/banking/banking_activity.dart';
import 'package:bujit/navigation_items/banking/banking_prefs.dart';
import 'package:bujit/navigation_items/banking/plaid_api.dart';
import 'package:bujit/navigation_items/banking/plaid_backend_client.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_activity.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Auth implements BankingAuth {
    @override
    bool get isConfigured => true;
    @override
    Future<String> idToken() async => "id";
    @override
    Future<String?> appCheckToken() async => "check";
}

class _Launcher implements PlaidLinkLauncher {
    @override
    Future<String?> open(String linkToken) async => "public";
}

final List<String> removed = [];

BankingService _service() => BankingService(
    PlaidBackendClient(host: "backend.test", auth: _Auth(), client: MockClient((request) async {
        http.Response json(Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
        return switch (request.url.path) {
            "/plaid/link/token" => json({"link_token": "link"}),
            "/plaid/exchange" => json({"access_token": "access"}),
            "/plaid/remove" => () {
                removed.add(request.headers["X-Plaid-Token"]!);
                return json({});
            }(),
            _ => json([
                {"id": "chk", "name": "Checking", "type": "depository", "subtype": "checking", "mask": "1111",
                    "institution_name": "Chase", "ledger": 2500, "available": 2400},
                {"id": "cc", "name": "Sapphire", "type": "credit", "subtype": "credit card", "mask": "3333",
                    "institution_name": "Chase", "ledger": 640.25, "available": 1359.75, "limit": 2000},
            ]),
        };
    })),
    _Launcher(),
);

AppState _sampleState({bool banking = true}) {
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.0), tutorialSeen: true);
    seedSampleData(data.balance);
    final AppState state = AppState(data);
    if (banking) state.banking = _service();
    return state;
}

void main() {
    setUp(removed.clear);

    testWidgets("without Firebase config, linking a bank shows as not set up", (tester) async {
        await tester.pumpWidget(MaterialApp(home: BankingActivity(state: _sampleState(banking: false))));
        expect(find.text("Not set up in this build"), findsOneWidget);
    });

    testWidgets("linking lists the bank's accounts; disconnecting removes them", (tester) async {
        final AppState state = _sampleState();
        await tester.pumpWidget(MaterialApp(home: BankingActivity(state: state)));

        await tester.tap(find.text("Link a bank or credit card"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Not now")); // the offer to add its card
        await tester.pumpAndSettle();

        expect(find.text("CHASE"), findsOneWidget);
        expect(find.text("Checking …1111"), findsOneWidget);
        expect(find.text("\$2500.00"), findsOneWidget);
        expect(find.textContaining("Last synced just now"), findsOneWidget);

        await tester.tap(find.byTooltip("Disconnect banks"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Disconnect All"));
        await tester.pumpAndSettle();
        expect(find.textContaining("Disconnect from Chase?"), findsOneWidget);
        await tester.tap(find.text("Disconnect"));
        await tester.pumpAndSettle();

        expect(removed, ["access"]);
        expect(find.text("CHASE"), findsNothing);
        expect(state.balance.linkedAccounts, isEmpty);
    });

    testWidgets("a linked bank's cards can be added, asking for the due date it can't give", (tester) async {
        final AppState state = _sampleState();
        await tester.pumpWidget(MaterialApp(home: BankingActivity(state: state)));
        await tester.tap(find.text("Link a bank or credit card"));
        await tester.pumpAndSettle();

        expect(find.text("Add these cards to Credit Utilization?"), findsOneWidget);
        expect(find.text("Chase Sapphire …3333"), findsOneWidget);
        expect(find.text("Chase Checking …1111"), findsNothing); // only cards
        await tester.tap(find.text("Add"));
        await tester.pumpAndSettle();

        // Filled from the bank, linked, with no due date until one is picked.
        expect(find.text("Add Credit Card"), findsOneWidget);
        expect(find.text("Amount syncs from Chase Sapphire …3333"), findsOneWidget);
        expect(find.text("640.25"), findsOneWidget);
        expect(find.text("2000.00"), findsOneWidget);
        expect(find.text("Pick a date"), findsOneWidget);
        await tester.tap(find.text("Save"));
        await tester.pumpAndSettle();
        expect(find.text("Pick the next due date"), findsOneWidget);

        await tester.tap(find.text("Pick a date"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("15"));
        await tester.tap(find.text("OK"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Save"));
        await tester.pumpAndSettle();

        final CreditModel card = state.balance.creditCards.firstWhere((c) => c.name == "Chase Sapphire …3333");
        expect(card.linkedAccountId, "cc");
        expect(card.amount, 640.25);
        expect(card.creditLimit, 2000.0);
        final DateTime today = todayDate();
        expect(card.currentDueDate, today.day <= 15
            ? DateTime(today.year, today.month, 15)
            : DateTime(today.year, today.month + 1, 15)); // a past date rolls to the next one
    });

    testWidgets("a linked card not yet tracked can be added from Linked Accounts", (tester) async {
        final AppState state = _sampleState();
        await state.linkBank();
        await tester.pumpWidget(MaterialApp(home: BankingActivity(state: state)));

        expect(find.textContaining("tap to add to Credit Utilization"), findsOneWidget); // the card, not checking
        await tester.tap(find.text("Sapphire …3333"));
        await tester.pumpAndSettle();
        expect(find.text("Amount syncs from Chase Sapphire …3333"), findsOneWidget);
        await tester.tap(find.text("Pick a date"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("15"));
        await tester.tap(find.text("OK"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Save"));
        await tester.pumpAndSettle();

        expect(state.balance.creditCards.where((c) => c.linkedAccountId == "cc"), hasLength(1));
        expect(find.textContaining("tap to add to Credit Utilization"), findsNothing);
    });

    testWidgets("a new card has no due date, and a bank without a limit asks for it", (tester) async {
        final BankAccountModel noLimit = BankAccountModel(id: "amex", itemKey: "k", name: "Gold", type: "credit",
            mask: "1005", institution: "Amex", ledger: 300.0);
        CreditModel? saved;
        await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => TextButton(
            onPressed: () async => saved = await showCreditCardDialog(context, linkTo: noLimit, connectable: [noLimit]),
            child: const Text("open"),
        ))));
        await tester.tap(find.text("open"));
        await tester.pumpAndSettle();

        expect(find.text("Your bank didn't report a limit; enter it"), findsOneWidget);
        await tester.tap(find.text("Save"));
        await tester.pumpAndSettle();
        expect(find.text("Pick the next due date"), findsOneWidget);
        expect(find.text("Enter a valid amount"), findsOneWidget); // the empty limit
        expect(saved, isNull);
    });

    testWidgets("From Accounts offers linked checking and savings, not cards", (tester) async {
        final AppState state = _sampleState();
        await state.linkBank();
        await tester.pumpWidget(MaterialApp(home: ExpenseActivity(state: state)));

        await tester.tap(find.text("CURRENT BALANCE"));
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextFormField, "Additional funds"), "0");
        await tester.tap(find.text("From Accounts"));
        await tester.pumpAndSettle();
        expect(find.text("Chase Sapphire …3333"), findsNothing);
        await tester.tap(find.text("Chase Checking …1111"));
        await tester.tap(find.text("OK"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Save"));
        await tester.pumpAndSettle();

        expect(state.balance.currentBalance, 2500.0);
        expect(state.balance.linkedAccount("chk")!.countsTowardBalance, isTrue);
    });

    testWidgets("an expense's amount can come from a connected card or loan", (tester) async {
        final AppState state = _sampleState();
        await state.linkBank();
        await tester.pumpWidget(MaterialApp(home: ExpenseActivity(state: state)));

        await tester.tap(find.byTooltip("Add"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Recurring expense"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("From connected account"));
        await tester.pumpAndSettle();
        // The Java app's labels: bank – type (…last four) balance.
        expect(find.text("Chase – Credit – Credit card (…3333)  \$640.25"), findsOneWidget);
        await tester.tap(find.textContaining("(…3333)"));
        await tester.pumpAndSettle();

        expect(find.text("Amount syncs from Chase Sapphire …3333"), findsOneWidget);
        expect(find.text("640.25"), findsOneWidget);
        await tester.tap(find.text("Save"));
        await tester.pumpAndSettle();

        final expense = state.balance.expenses.last;
        expect(expense.name, "Chase Sapphire …3333");
        expect(expense.linkedAccountId, "cc");
        expect(expense.amount, 640.25);
    });
}
