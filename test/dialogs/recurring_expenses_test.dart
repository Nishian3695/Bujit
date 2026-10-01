// Widget tests for showRecurringExpenseDialog. Run with:
//   flutter test test/dialogs/recurring_expenses_test.dart
// No device or emulator needed -- WidgetTester runs the real framework
// against a fake binding instead of a real screen.
import 'package:bujit/dialogs/recurring_expenses.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Field order inside the Form's Column, used to target TextFormFields by
// position since none of them have Keys yet.
const int _nameFieldIndex = 0;
const int _amountFieldIndex = 1;

// Pumps a MaterialApp with a button that opens the dialog, then opens it.
// Returns the Future the real caller would await for the dialog's result.
Future<ExpenseModel?> _openDialog(WidgetTester tester, {ExpenseModel? existing}) async {
    late Future<ExpenseModel?> result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => ElevatedButton(
                onPressed: () {
                    result = showRecurringExpenseDialog(context, existing: existing);
                },
                child: const Text("Open"),
            ),
        ),
    ));
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    return result;
}

void main() {
    testWidgets("shows Add title and defaults when there is no existing expense",
        (tester) async {
        await _openDialog(tester);

        expect(find.text("Add Expense"), findsOneWidget);
        // Frequency count defaults to "1" for a brand-new expense.
        expect(find.text("1"), findsOneWidget);
        // Frequency unit dropdown defaults to the first entry.
        expect(find.text("Daily"), findsOneWidget);
        // No start date chosen yet.
        expect(find.text("Pick start date"), findsOneWidget);
    });

    testWidgets("shows Edit title and prefills fields from the existing expense",
        (tester) async {
        final existing = ExpenseModel(
            name: "Rent",
            amount: 1200.0,
            startDate: DateTime(2026, 1, 1),
            frequency: 1,
            frequencyUnits: FrequencyUnit.monthly,
        );

        await _openDialog(tester, existing: existing);

        expect(find.text("Edit Expense"), findsOneWidget);
        expect(find.text("Rent"), findsOneWidget);
        expect(find.text("1200.00"), findsOneWidget);
        expect(find.text("Monthly"), findsOneWidget);
        // Editing shows a Delete action that adding does not.
        expect(find.widgetWithText(TextButton, "Delete"), findsOneWidget);
    });

    testWidgets("blank name blocks Save and shows a validation error", (tester) async {
        await _openDialog(tester);

        // Name field starts blank when adding; amount/frequency need valid
        // values so the name error is the only one on screen.
        await tester.enterText(find.byType(TextFormField).at(_amountFieldIndex), "50.00");
        await tester.tap(find.widgetWithText(TextButton, "Save"));
        await tester.pumpAndSettle();

        expect(find.text("Name is required"), findsOneWidget);
        // Dialog must still be open -- Save should not have popped it.
        expect(find.text("Add Expense"), findsOneWidget);
    });

    testWidgets("zero amount blocks Save and shows a validation error", (tester) async {
        await _openDialog(tester);

        await tester.enterText(find.byType(TextFormField).at(_nameFieldIndex), "Rent");
        await tester.enterText(find.byType(TextFormField).at(_amountFieldIndex), "0");
        await tester.tap(find.widgetWithText(TextButton, "Save"));
        await tester.pumpAndSettle();

        expect(find.text("Enter an amount greater than 0"), findsOneWidget);
        expect(find.text("Add Expense"), findsOneWidget);
    });

    testWidgets("valid input lets Save close the dialog", (tester) async {
        final resultFuture = await _openDialog(tester);

        await tester.enterText(find.byType(TextFormField).at(_nameFieldIndex), "Rent");
        await tester.enterText(find.byType(TextFormField).at(_amountFieldIndex), "50.00");
        await tester.tap(find.widgetWithText(TextButton, "Save"));
        await tester.pumpAndSettle();

        expect(find.text("Add Expense"), findsNothing);
        // _createExpenseModel isn't wired up yet, so Save currently pops with
        // no value -- this should be updated to check the real ExpenseModel
        // once that TODO is finished.
        await expectLater(resultFuture, completion(isNull));
    });

    testWidgets("Cancel closes the dialog without popping a value", (tester) async {
        final resultFuture = await _openDialog(tester);

        await tester.tap(find.widgetWithText(TextButton, "Cancel"));
        await tester.pumpAndSettle();

        expect(find.text("Add Expense"), findsNothing);
        await expectLater(resultFuture, completion(isNull));
    });

    testWidgets("picking a frequency unit updates the dropdown", (tester) async {
        await _openDialog(tester);

        // The frequency-unit dropdown is the first DropdownButton in the tree
        // (category's is second).
        await tester.tap(find.byType(DropdownButton<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text("Weekly").last);
        await tester.pumpAndSettle();

        expect(find.text("Weekly"), findsOneWidget);
        expect(find.text("Daily"), findsNothing);
    });
}
