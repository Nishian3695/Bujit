// Widget tests for Visuals' Net Balance tab: its accounts and recurring items
// fold away under "Included items"; the figure is the change over the window
// on screen; the arrows and "Back to today" move the window; and the
// settings sheet sets the timeframe and whether it's centered on today.
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/banking/manual_account_model.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/visuals/visuals_activity.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppData> _pumpNetBalance(WidgetTester tester) async {
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.0), tutorialSeen: true);
    seedSampleData(data.balance);
    data.balance.manualAccounts.add(ManualAccountModel(name: "Rainy Day", balance: 250.0));
    data.balance.recordHistory();
    tester.view.physicalSize = const Size(1080, 4000); // Everything fits without scrolling
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: VisualsActivity(state: AppState(data))));
    await tester.tap(find.text("Net Balance"));
    await tester.pumpAndSettle();
    return data;
}

// The figure's label ("NET BALANCE · Oct 5 – Nov 2") and value.
String _label(WidgetTester tester) => tester.widget<Text>(find.textContaining("NET BALANCE ·")).data!;
String _value(WidgetTester tester) => tester.widgetList<Text>(find.descendant(
    of: find.ancestor(of: find.textContaining("NET BALANCE ·"), matching: find.byType(Column)).first,
    matching: find.byType(Text))).last.data!;

void main() {
    testWidgets("accounts and recurring items fold away under Included items", (tester) async {
        final AppData data = await _pumpNetBalance(tester);
        expect(find.byType(LineChart), findsOneWidget);
        expect(find.text("Rainy Day"), findsNothing);

        await tester.tap(find.text("Included items"));
        await tester.pumpAndSettle();
        for (final expense in data.balance.expenses.where((e) => e is! CreditModel)) {
            expect(find.text(expense.name), findsOneWidget);
        }
        expect(find.text("Rainy Day"), findsOneWidget);

        // Leaving out the paycheck changes how the window ends up.
        final String before = _value(tester);
        await tester.tap(find.text("Main Job"));
        await tester.pumpAndSettle();
        expect(_value(tester), isNot(before));
        expect(find.textContaining("included"), findsOneWidget);
    });

    testWidgets("the arrows and Back to today move the window", (tester) async {
        await _pumpNetBalance(tester);
        final String now = _label(tester);

        await tester.tap(find.byTooltip("Next timeframe"));
        await tester.pumpAndSettle();
        final String next = _label(tester);
        expect(next, isNot(now));

        await tester.tap(find.byTooltip("Back to today"));
        await tester.pumpAndSettle();
        expect(_label(tester), now);

        await tester.tap(find.byTooltip("Previous timeframe"));
        await tester.pumpAndSettle();
        expect(_label(tester), isNot(now));
    });

    testWidgets("the settings set the timeframe and where today sits in it", (tester) async {
        await _pumpNetBalance(tester);
        final DateTime today = todayDate();
        expect(find.byType(TextField), findsNothing); // Tucked away in the settings

        await tester.tap(find.byTooltip("Chart settings"));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), "6");
        await tester.tap(find.text("months"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("weeks").last);
        await tester.pumpAndSettle();
        await tester.tap(find.text("Starting from Today"));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(20, 20)); // Closes the sheet
        await tester.pumpAndSettle();
        expect(_label(tester), "NET BALANCE · ${shortDate(today)} – ${shortDate(addDays(today, 42))}");

        await tester.tap(find.byTooltip("Chart settings"));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Centered on Today"));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
        expect(_label(tester),
            "NET BALANCE · ${shortDate(addDays(today, -21))} – ${shortDate(addDays(today, 21))}");
    });
}
