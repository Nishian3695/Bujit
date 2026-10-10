import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../utils/frequency_unit.dart';
import '../../../navigation_items/expense_activity/credit_model.dart';
import '../../../navigation_items/expense_activity/expense_item.dart';
import '../../../navigation_items/expense_activity/expense_model.dart';

// Converts between drift's generated ExpenseItemRow/ExpenseItemRowsCompanion
// classes (storage-shaped) and the domain ExpenseModel/CreditModel classes
// (behaviour-shaped). Keeping this conversion in one place means nothing
// outside storage_management/ ever needs to import drift types directly.

extension ExpenseRowMapper on ExpenseItemRow {
  // Turns a row freshly read out of the database into a "real" domain
  // object: a CreditModel for a credit card row, else an ExpenseModel.
  // Loading doesn't pay anything: call BalanceModel.makeRecent() afterwards
  // to bring loaded items up to today.
  ExpenseItem toDomain() => isCredit
      ? CreditModel(
          id: id,
          name: name,
          amount: amount,
          startDate: startDate,
          currentDueDate: currentDueDate,
          frequency: frequency,
          frequencyUnits: frequencyUnits,
          category: category,
          creditLimit: creditLimit ?? 0.0,
          googleTaskId: googleTaskId,
          remindInTasks: remindInTasks,
          source: source,
          sourceId: sourceId,
          linkedAccountId: linkedAccountId,
        )
      : ExpenseModel(
          id: id,
          name: name,
          amount: amount,
          startDate: startDate,
          currentDueDate: currentDueDate,
          endDate: endDate,
          frequency: frequency,
          frequencyUnits: frequencyUnits,
          monthDays: _monthDays(monthDay1, monthDay2),
          category: category,
          googleTaskId: googleTaskId,
          remindInTasks: remindInTasks,
          source: source,
          sourceId: sourceId,
          linkedAccountId: linkedAccountId,
        );
}

extension ExpenseItemMapper on ExpenseItem {
  // For inserting a *new* expense or card (no id yet). ExpenseItemRowsCompanion.insert(...)
  // is a special named constructor that only requires columns without a
  // database-side default (so id can be omitted -- SQLite assigns it),
  // while the optional columns still need the Value(...) wrapper because the
  // regular (non-.insert) companion fields are all Value<T> under the
  // hood -- Value.absent() (the implicit default) means "don't touch
  // this column", Value(x) means "set it to x". .insert() pre-fills the
  // required ones for you.
  ExpenseItemRowsCompanion toInsertCompanion() {
    final CreditModel? card = this is CreditModel ? this as CreditModel : null;
    return ExpenseItemRowsCompanion.insert(
      name: name,
      amount: amount,
      startDate: startDate,
      currentDueDate: currentDueDate,
      endDate: Value(endDate),
      frequency: frequency,
      frequencyUnits: frequencyUnits,
      monthDay1: Value(monthDays?.first),
      monthDay2: Value(monthDays?.second),
      category: Value(category),
      isCredit: Value(card != null),
      creditLimit: Value(card?.creditLimit),
      googleTaskId: Value(googleTaskId),
      remindInTasks: Value(remindInTasks),
      source: Value(source),
      sourceId: Value(sourceId),
      linkedAccountId: Value(linkedAccountId),
    );
  }
}

// The stored pair of days, or null when either is missing (any unit but semimonthly).
MonthDays? _monthDays(int? first, int? second) =>
    first == null || second == null ? null : MonthDays(first, second);
