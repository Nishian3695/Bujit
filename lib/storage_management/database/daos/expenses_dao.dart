import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/expense_item_table.dart';

part 'expenses_dao.g.dart';

// A "DAO" (Data Access Object) groups the SQL-shaped operations for one
// table instead of piling every table's queries directly onto
// AppDatabase. @DriftAccessor(tables: [ExpenseItemRows]) tells drift's
// generator to produce a mixin (_$ExpensesDaoMixin) giving this class the
// same query-builder methods (select, into, update, delete) AppDatabase has,
// scoped to the ExpenseItemRows table (exposed as `expenseItemRows`).
@DriftAccessor(tables: [ExpenseItemRows])
class ExpensesDao extends DatabaseAccessor<AppDatabase> with _$ExpensesDaoMixin {
  // DatabaseAccessor needs a reference to the AppDatabase it's attached
  // to (for the actual connection); super(db) wires that up.
  ExpensesDao(super.db);

  // select(expenseItemRows) builds a SELECT * query; .get() runs it once and
  // returns Future<List<ExpenseItemRow>> (the generated row class).
  Future<List<ExpenseItemRow>> getAllExpenses() => select(expenseItemRows).get();

  // .watch() instead of .get() returns a Stream that automatically
  // re-emits a fresh list whenever any write touches this table -- useful
  // later for driving a UI list reactively without manually re-querying
  // after every insert/update/delete.
  Stream<List<ExpenseItemRow>> watchAllExpenses() => select(expenseItemRows).watch();

  // into(...).insert(...) runs an INSERT and returns the new row's id.
  // ExpenseItemRowsCompanion (not the plain row class) is used for inserts
  // specifically because it lets a brand-new expense omit id entirely
  // (autoIncrement fills it in) while still requiring every other column --
  // see the mapper for how an ExpenseModel becomes one.
  Future<int> insertExpense(ExpenseItemRowsCompanion entry) =>
      into(expenseItemRows).insert(entry);

  // .replace(entry) takes a full row (including its id) and overwrites the
  // matching row. Returns false if no row with that id existed.
  Future<bool> updateExpense(ExpenseItemRow entry) => update(expenseItemRows).replace(entry);

  // (delete(...)..where(...)) builds a DELETE with a WHERE clause; .go()
  // executes it and returns the number of rows removed.
  Future<int> deleteExpense(int id) =>
      (delete(expenseItemRows)..where((tbl) => tbl.id.equals(id))).go();
}
