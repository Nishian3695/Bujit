import 'package:drift/drift.dart';
import '../../../utils/frequency_unit.dart';

// Mirrors IncomeStreamModel (lib/navigation_items/income_streams/income_stream_model.dart).
// Note IncomeStreamModel doesn't extend ExpenseItem, so unlike CreditCards
// this table isn't duplicating a shared base -- it just happens to
// overlap in shape with ExpenseItemRows.
//
// frequencyUnits is stored by name (textEnum), same as ExpenseItemRows: an
// intEnum stores the enum's index, so reordering or inserting a FrequencyUnit
// value later would silently reinterpret every saved row.
//
// TODO(you): build an IncomeStreamsDao + mapper following the expenses pattern.
@DataClassName('IncomeStreamModelRow')
class IncomeStreamModelRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  RealColumn get amount => real()();
  DateTimeColumn get startDate => dateTime()();
  // (No per-stream "credited through" date: income is credited through one
  // date for every stream, AppMetaRows.lastUpdated -- see BalanceModel.makeRecent.)
  IntColumn get frequency => integer()();
  TextColumn get frequencyUnits => textEnum<FrequencyUnit>()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get googleTaskId => text().nullable()(); // Its Google Task once synced
}
