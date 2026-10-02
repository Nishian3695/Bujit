// Widget tests for the home screen's navigation: paging between checks, the
// add/home button, the drawer, and adding an income stream from it.
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_activity.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The sample data with no storage behind it (nothing is saved). The tutorial is
// off: its overlay blocks taps (see tutorial_test.dart for the tutorial itself).
AppState _sampleState() {
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.0), tutorialSeen: true);
    seedSampleData(data.balance);
    return AppState(data);
}

Future<AppState> _pumpHome(WidgetTester tester) async {
    final AppState state = _sampleState();
    await tester.pumpWidget(MaterialApp(home: ExpenseActivity(state: state)));
    return state;
}

void main() {
    testWidgets("the add button becomes a home button on a projected check", (tester) async {
        await _pumpHome(tester);
        expect(find.text("This Check"), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);

        await tester.tap(find.byTooltip("Next check"));
        await tester.pump();
        expect(find.text("This Check"), findsNothing);
        expect(find.byIcon(Icons.home), findsOneWidget);

        await tester.tap(find.byIcon(Icons.home));
        await tester.pump();
        expect(find.text("This Check"), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets("Show Next Check changes the label and figure", (tester) async {
        final AppState state = await _pumpHome(tester);
        expect(find.text("AFTER THIS CHECK"), findsOneWidget);

        state.data.includeNextCheck = true;
        await state.changed();
        await tester.pump();
        expect(find.text("NEXT CHECK"), findsOneWidget);
        expect(find.text("\$-2725.99"), findsOneWidget); // 3500 - 8625.99 + 2400
    });

    testWidgets("the drawer lists the Java app's menu items", (tester) async {
        await _pumpHome(tester);
        await tester.tap(find.byTooltip("Open navigation menu"));
        await tester.pumpAndSettle();

        for (final String item in ["Income Streams", "Credit Utilization", "Linked Accounts",
                "Single Events", "Visuals", "Settings"]) {
            expect(find.text(item), findsOneWidget);
        }
    });

    testWidgets("adding an income stream from the drawer updates the data", (tester) async {
        final AppState state = await _pumpHome(tester);
        await tester.tap(find.byTooltip("Open navigation menu"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Income Streams"));
        await tester.pumpAndSettle();
        expect(find.text("Main Job"), findsOneWidget);

        await tester.tap(find.byTooltip("Add income stream"));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), "Side Job");
        await tester.enterText(find.byType(TextFormField).at(1), "250");
        await tester.tap(find.text("Save"));
        await tester.pumpAndSettle();

        expect(find.text("Side Job"), findsOneWidget);
        expect(state.balance.incomeStreams.map((s) => s.name), contains("Side Job"));
        // The first stream stays active.
        expect(state.balance.activeIncome!.name, "Main Job");
    });
}
