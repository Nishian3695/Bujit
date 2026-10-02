// The home screen's + menu, swiping and Back between checks, drag-to-reorder,
// and Projection Settings. Starts from the tutorial's sample data.
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_activity.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppState> _pumpHome(WidgetTester tester) async {
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.0), tutorialSeen: true);
    seedSampleData(data.balance);
    final AppState state = AppState(data);
    await tester.pumpWidget(MaterialApp(home: ExpenseActivity(state: state)));
    return state;
}

void main() {
    testWidgets("+ offers a recurring expense or a single event", (tester) async {
        final AppState state = await _pumpHome(tester);

        await tester.tap(find.byTooltip("Add"));
        await tester.pumpAndSettle();
        expect(find.text("Recurring expense"), findsOneWidget);
        await tester.tap(find.text("Single event"));
        await tester.pumpAndSettle();
        expect(find.text("Add Single Event"), findsOneWidget);
        await tester.enterText(find.widgetWithText(TextFormField, "Name"), "Lunch");
        await tester.enterText(find.widgetWithText(TextFormField, "Amount"), "20");
        await tester.tap(find.text("Add"));
        await tester.pumpAndSettle();

        expect(state.balance.currentBalance, 3480.0);
        expect(state.data.singleEvents.single.name, "Lunch");
        expect(find.text("\$3480.00"), findsOneWidget);

        await tester.tap(find.byTooltip("Add"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Recurring expense"));
        await tester.pumpAndSettle();
        expect(find.text("Add Expense"), findsOneWidget);
    });

    testWidgets("swiping pages between checks, and Back steps back", (tester) async {
        await _pumpHome(tester);

        await tester.fling(find.text("Rent"), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();
        expect(find.text("This Check"), findsNothing);
        await tester.fling(find.text("Rent"), const Offset(-300, 0), 1000);
        await tester.pumpAndSettle();

        await tester.binding.handlePopRoute(); // the system Back button
        await tester.pumpAndSettle();
        expect(find.text("This Check"), findsNothing); // check 1, not the home check yet
        await tester.fling(find.text("Rent"), const Offset(300, 0), 1000);
        await tester.pumpAndSettle();
        expect(find.text("This Check"), findsOneWidget);
    });

    testWidgets("rows can be dragged into a new order, which is kept", (tester) async {
        final AppState state = await _pumpHome(tester);
        expect(state.balance.expenses.first.name, "Rent");

        final TestGesture drag = await tester.startGesture(tester.getCenter(find.text("Rent")));
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
        await drag.moveBy(const Offset(0, 150));
        await tester.pump();
        await drag.up();
        await tester.pumpAndSettle();

        expect(state.balance.expenses.first.name, isNot("Rent"));
        expect(state.balance.expenses.map((e) => e.name), contains("Rent"));
    });

    testWidgets("Projection Settings: a custom period shows under the title until reset", (tester) async {
        final AppState state = await _pumpHome(tester);

        await tester.tap(find.byTooltip("Projection settings"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Custom"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Weeks"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Months").last);
        await tester.pumpAndSettle();
        await tester.tap(find.text("Apply"));
        await tester.pumpAndSettle();

        expect(find.text("Projecting: Main Job · every 1 month"), findsOneWidget);
        expect(state.balance.projection!.isCustomPeriod, isTrue);

        await tester.tap(find.byTooltip("Projection settings"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Reset"));
        await tester.pumpAndSettle();
        expect(find.textContaining("Projecting"), findsNothing);
        expect(state.balance.projection, isNull);
    });
}
