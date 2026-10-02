// Ported from the Java app's CsvImportHelperTest.
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/settings/csv_import_helper.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);

AppData _empty() => AppData(balance: BalanceModel(currentBalance: 1000.0, lastUpdated: today), categories: []);

// Imports one expense line and returns the added expense.
ExpenseModel _importExpense(String line) {
    final AppData data = _empty();
    final CsvImportResult result = CsvImportHelper.importInto(data, line, today: today);
    expect(result.errors, isEmpty);
    expect(result.expensesAdded, 1);
    return data.balance.expenses.single as ExpenseModel;
}

// Imports one line expecting it to be rejected; returns the error.
String _rejected(String line) {
    final AppData data = _empty();
    final CsvImportResult result = CsvImportHelper.importInto(data, line, today: today);
    expect(result.hasData, isFalse);
    expect(result.skipped, 1);
    expect(data.balance.expenses, isEmpty);
    return result.errors.single;
}

void main() {
    group("expense rows", () {
        test("a 6-field row imports with defaults and no end date", () {
            final e = _importExpense("expense,Rent,2200,2024-01-01,1,month");
            expect(e.name, "Rent");
            expect(e.amount, 2200.0);
            expect(e.startDate, DateTime(2024, 1, 1)); // the due date is also the start date
            expect(e.frequency, 1);
            expect(e.frequencyUnits, FrequencyUnit.monthly);
            expect(e.category, "Other");
            expect(e.endDate, isNull);
        });

        test("a 7-field row sets the category, and it's remembered", () {
            final AppData data = _empty();
            CsvImportHelper.importInto(data, "expense,Rent,2200,2024-01-01,1,month,Housing", today: today);
            expect((data.balance.expenses.single as ExpenseModel).category, "Housing");
            expect(data.categories, contains("Housing"));
        });

        test("an 8-field row sets the end date", () {
            final e = _importExpense("expense,Car Payment,350,2024-01-10,1,month,Transportation,2028-12-10");
            expect(e.endDate, DateTime(2028, 12, 10));
        });

        test("a blank category with an end date defaults the category", () {
            final e = _importExpense("expense,Gym,40,2026-11-01,1,month,,2027-06-30");
            expect(e.category, "Other");
            expect(e.endDate, DateTime(2027, 6, 30));
        });

        test("a blank end date means no end date", () {
            expect(_importExpense("expense,Rent,2200,2024-01-01,1,month,Housing,").endDate, isNull);
        });

        test("slash dates are accepted", () {
            expect(_importExpense("expense,Gym,40,2026/11/01,1,month,Health,2027/06/30").endDate,
                DateTime(2027, 6, 30));
        });

        test("a quoted name with a comma still finds every field", () {
            final e = _importExpense("expense,\"Gym, Downtown\",40,2026-11-01,1,month,Health,2027-06-30");
            expect(e.name, "Gym, Downtown");
            expect(e.endDate, DateTime(2027, 6, 30));
        });

        test("an end date equal to the due date is accepted", () {
            expect(_importExpense("expense,One-off,99,2026-11-01,1,month,,2026-11-01").endDate,
                DateTime(2026, 11, 1));
        });

        test("amounts may have a \$ and thousands separators", () {
            expect(_importExpense("expense,Rent,\"\$2,200.50\",2026-11-01,1,month").amount, 2200.5);
        });
    });

    group("past dates (earlier payments happened outside the app)", () {
        test("a past due date moves to the next upcoming one without charging", () {
            final AppData data = _empty();
            CsvImportHelper.importInto(data, "expense,Rent,2200,2024-01-01,1,month", today: today);
            final ExpenseModel rent = data.balance.expenses.single as ExpenseModel;

            expect(rent.currentDueDate, today); // Oct 1 is a due date
            expect(data.balance.makeRecent(today: today), 0.0);
            expect(data.balance.currentBalance, 1000.0);
        });

        test("a past due date on the 31st keeps the month-end day", () {
            final e = _importExpense("expense,Rent,2200,2024-01-31,1,month");
            expect(e.currentDueDate, DateTime(2026, 10, 31));
        });

        test("an expense that already ended imports as ended and never charges", () {
            final AppData data = _empty();
            CsvImportHelper.importInto(data, "expense,Old Gym,40,2024-01-05,1,month,Health,2024-06-05", today: today);
            expect(data.balance.expenses.single.hasEnded, isTrue);
            expect(data.balance.makeRecent(today: today), 0.0);
        });

        test("a future due date is left as is", () {
            expect(_importExpense("expense,Insurance,90,2026-10-21,6,month").currentDueDate, DateTime(2026, 10, 21));
        });

        test("a past credit card due date moves forward and keeps the balance", () {
            final AppData data = _empty();
            CsvImportHelper.importInto(data, "credit,Card Name,156,1000,2024-01-15", today: today);
            final CreditModel card = data.balance.expenses.single as CreditModel;

            expect(card.currentDueDate, DateTime(2026, 10, 15));
            expect(card.amount, 156.0);
            expect(card.creditLimit, 1000.0);
            expect(data.balance.makeRecent(today: today), 0.0);
        });
    });

    group("income streams", () {
        test("import, and the first becomes active", () {
            final AppData data = _empty();
            final result = CsvImportHelper.importInto(data,
                "income_stream,Hardware Store,2500.56,2022-03-15,2,week\nincome_stream,Side,100,2026-10-05,1,month",
                today: today);

            expect(result.streamsAdded, 2);
            expect(data.balance.activeIncome!.name, "Hardware Store");
            expect(data.balance.incomeStreams[0].frequencyUnits, FrequencyUnit.weekly);
            expect(data.balance.incomeStreams[0].amount, 2500.56);
        });
    });

    group("rejected rows", () {
        test("an end date before the due date", () {
            expect(_rejected("expense,Gym,40,2026-11-01,1,month,Health,2026-10-01"), contains("before due_date"));
        });

        test("an invalid end date", () {
            expect(_rejected("expense,Gym,40,2026-11-01,1,month,Health,someday"), contains("invalid date"));
        });

        test("an impossible calendar date", () {
            expect(_rejected("expense,Gym,40,2026-02-30,1,month"), contains("invalid date"));
        });

        test("too few fields", () {
            expect(_rejected("expense,Gym,40"), contains("expected format"));
        });

        test("a frequency below 1", () {
            expect(_rejected("expense,Gym,40,2026-11-01,0,month"), contains("frequency must be >= 1"));
        });

        test("an unknown unit", () {
            expect(_rejected("expense,Gym,40,2026-11-01,1,fortnight"), contains("unit must be"));
        });

        test("a credit limit of 0", () {
            expect(_rejected("credit,Card,100,0,2026-11-01"), contains("credit_limit must be > 0"));
        });

        test("an unknown row type", () {
            expect(_rejected("budget,Food,500"), contains("unknown type"));
        });

        test("manual accounts, until Linked Accounts exists", () {
            expect(_rejected("manual_account,My Savings,Savings,0"), contains("aren't supported yet"));
        });
    });

    test("comments and blank lines are ignored; bad rows don't stop the rest", () {
        final AppData data = _empty();
        final result = CsvImportHelper.importInto(data,
            "# comment\n\nexpense,Rent,2200,2026-11-01,1,month\nexpense,Bad,abc,2026-11-01,1,month\r\n"
            "credit,Card,100,1000,2026-11-01",
            today: today);

        expect(result.expensesAdded, 1);
        expect(result.creditsAdded, 1);
        expect(result.skipped, 1);
        expect(result.errors.single, startsWith("Line 4: invalid amount"));
    });

    test("the template imports everything except its manual account", () {
        final AppData data = _empty();
        final result = CsvImportHelper.importInto(data, CsvImportHelper.template, today: today);

        expect(result.expensesAdded, 2);
        expect(result.creditsAdded, 1);
        expect(result.streamsAdded, 1);
        expect(result.skipped, 1);
        expect(data.balance.makeRecent(today: today), 0.0); // past dates charge nothing
    });
}
