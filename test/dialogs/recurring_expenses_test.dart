// Widget tests for showRecurringExpenseDialog. Run with:
//   flutter test test/dialogs/recurring_expenses_test.dart
// No device or emulator needed -- WidgetTester runs the real framework
// against a fake binding instead of a real screen.
import 'package:bujit/dialogs/recurring_expenses.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter/material.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

// Field order inside the Form's Column, used to target TextFormFields by
// position since none of them have Keys yet.
const int _nameFieldIndex = 0;
const int _amountFieldIndex = 1;

// Pumps a MaterialApp with a button that opens the dialog, then opens it.
// Returns a function giving the Future the real caller would await for the
// dialog's result. It can't return that Future directly: an async function
// that returns a Future waits for it, which would block until the dialog closed.
Future<Future<ExpenseModel?> Function()> _openDialog(WidgetTester tester, {ExpenseModel? existing}) async {
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
    return () => result;
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
        // Start date defaults to today, like the Java app.
        final now = DateTime.now();
        final today = shortDate(DateTime(now.year, now.month, now.day));
        expect(find.text("Starting Date: $today"), findsOneWidget);
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

    testWidgets("valid input lets Save close the dialog and return the expense", (tester) async {
        final resultFuture = await _openDialog(tester);

        await tester.enterText(find.byType(TextFormField).at(_nameFieldIndex), "Rent");
        await tester.enterText(find.byType(TextFormField).at(_amountFieldIndex), "50.00");
        await tester.tap(find.widgetWithText(TextButton, "Save"));
        await tester.pumpAndSettle();

        expect(find.text("Add Expense"), findsNothing);
        final expense = await resultFuture();
        expect(expense, isNotNull);
        expect(expense!.name, "Rent");
        expect(expense.amount, 50.0);
        expect(expense.frequency, 1);
        expect(expense.frequencyUnits, FrequencyUnit.daily);
        final now = DateTime.now();
        expect(expense.startDate, DateTime(now.year, now.month, now.day));
    });

    testWidgets("saving an edit without changing the date keeps the original schedule", (tester) async {
        final existing = ExpenseModel(
            id: 7,
            name: "Rent",
            amount: 1200.0,
            startDate: DateTime(2026, 1, 31),
            frequency: 1,
            frequencyUnits: FrequencyUnit.monthly,
        );
        final resultFuture = await _openDialog(tester, existing: existing);

        await tester.enterText(find.byType(TextFormField).at(_amountFieldIndex), "1250.00");
        await tester.tap(find.widgetWithText(TextButton, "Save"));
        await tester.pumpAndSettle();

        final edited = await resultFuture();
        expect(edited!.id, 7);
        expect(edited.amount, 1250.0);
        // The 31st start still anchors the schedule, so month-end dates don't drift.
        expect(edited.startDate, DateTime(2026, 1, 31));
        expect(edited.currentDueDate, existing.currentDueDate);
    });

    testWidgets("Cancel closes the dialog without popping a value", (tester) async {
        final resultFuture = await _openDialog(tester);

        await tester.tap(find.widgetWithText(TextButton, "Cancel"));
        await tester.pumpAndSettle();

        expect(find.text("Add Expense"), findsNothing);
        await expectLater(resultFuture(), completion(isNull));
    });

    testWidgets("picking a frequency unit updates the dropdown", (tester) async {
        await _openDialog(tester);

        // The frequency-unit dropdown is typed by FrequencyUnit (category's is a
        // DropdownButton<String>), so it can be found by type directly.
        await tester.tap(find.byType(DropdownButton<FrequencyUnit>));
        await tester.pumpAndSettle();
        await tester.tap(find.text("Weekly").last);
        await tester.pumpAndSettle();

        expect(find.text("Weekly"), findsOneWidget);
        expect(find.text("Daily"), findsNothing);
    });
}
