import 'package:drift/drift.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:bujit/utils/category_manager.dart';

// -----------------------------------------------------------------------
// The Expenses table
// -----------------------------------------------------------------------
// In drift, a "table" is a plain Dart class extending `Table`, with one
// getter per database column. You never hand-write `CREATE TABLE` SQL --
// drift's code generator (run via `build_runner`) reads this class and
// produces:
//   1. The actual SQL used to create the table.
//   2. A generated *row* data class (`Expense`, see @DataClassName below)
//      representing one record read back out of the database.
//   3. A generated *companion* class (`ExpensesCompanion`) used for
//      inserting/updating, where every field is wrapped in a `Value<T>`
//      so drift can distinguish "set this column to null" from "don't
//      touch this column at all".
//
// This table mirrors, but does not replace, the domain class ExpenseModel
// (lib/navigation_items/expense_activity/expense_model.dart). The table
// only describes *storage* (columns + SQL types); domain behaviour
// (projections, shownAmount/shownDate, curNumOccurrences) stays on
// ExpenseModel. Converting between "generated row" and "domain object" is
// handled separately in mappers/expense_mapper.dart, so the rest of the
// app never needs to import drift types directly.
//
// Generated names: row class ExpenseItemRow, companion ExpenseItemRowsCompanion,
// and the table accessor `expenseItemRows` on the database/DAO.
class ExpenseItemRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  RealColumn get amount => real()();
  // Both dates are needed to rebuild ExpenseItem's Projector: startDate is the
  // origin the schedule is anchored to (its day of month keeps month-end dates
  // from drifting), currentDueDate is the next occurrence as of the last check-in.
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get currentDueDate => dateTime()();
  // Last date an occurrence may fall on (inclusive); null = never ends.
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get frequency => integer()();
  TextColumn get frequencyUnits => textEnum<FrequencyUnit>()();
  TextColumn get category => text().withDefault(const Constant(otherCategory))();
  // Credit cards share this table (CreditModel extends ExpenseItem): amount is
  // the card's balance and creditLimit its limit; null for regular expenses.
  BoolColumn get isCredit => boolean().withDefault(const Constant(false))();
  RealColumn get creditLimit => real().nullable()();
  // Google Tasks: the item's task id once synced, and whether the task gets a due date.
  TextColumn get googleTaskId => text().nullable()();
  BoolColumn get remindInTasks => boolean().withDefault(const Constant(true))();
}
