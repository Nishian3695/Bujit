import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../navigation_items/expense_activity/expense_model.dart';

// Converts between drift's generated ExpenseItemRow/ExpenseItemRowsCompanion
// classes (storage-shaped) and the domain ExpenseModel class
// (behaviour-shaped). Keeping this conversion in one place means nothing
// outside storage_management/ ever needs to import drift types directly.

extension ExpenseRowMapper on ExpenseItemRow {
  // Turns a row freshly read out of the database into a "real" domain
  // object, restoring its projector/periodAmount/shownDate machinery
  // (handled by ExpenseModel's own constructor).
  ExpenseModel toDomain() => ExpenseModel(
        id: id,
        name: name,
        amount: amount,
        startDate: startDate,
        currentDueDate: currentDueDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
        category: category,
      );
}

extension ExpenseModelMapper on ExpenseModel {
  // For inserting a *new* expense (no id yet). ExpenseItemRowsCompanion.insert(...)
  // is a special named constructor that only requires columns without a
  // database-side default (so id can be omitted -- SQLite assigns it),
  // while category still needs the Value(...) wrapper because the
  // regular (non-.insert) companion fields are all Value<T> under the
  // hood -- Value.absent() (the implicit default) means "don't touch
  // this column", Value(x) means "set it to x". .insert() pre-fills the
  // required ones for you.
  ExpenseItemRowsCompanion toInsertCompanion() => ExpenseItemRowsCompanion.insert(
        name: name,
        amount: amount,
        startDate: startDate,
        currentDueDate: currentDueDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
        category: Value(category),
      );

  // For updating an *existing* expense (id must already be set -- i.e.
  // this object came from toDomain() or was already inserted once).
  // Throws if id is null, which is intentional: calling this on an
  // unsaved expense is a programmer error, not a recoverable case.
  ExpenseItemRow toRow() => ExpenseItemRow(
        id: id!,
        name: name,
        amount: amount,
        startDate: startDate,
        currentDueDate: currentDueDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
        category: category,
      );
}
