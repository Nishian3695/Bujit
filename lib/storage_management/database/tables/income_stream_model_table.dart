import 'package:drift/drift.dart';
import '../../../utils/frequency_unit.dart';

// Mirrors IncomeStreamModel (lib/navigation_items/income_streams/income_stream_model.dart).
// Note IncomeStreamModel doesn't extend ExpenseItem, so unlike CreditCards
// this table isn't duplicating a shared base -- it just happens to
// overlap in shape with Expenses.
//
// TODO(you): build an IncomeStreamsDao + mapper following the Expenses pattern.
@DataClassName('IncomeStream')
class IncomeStreams extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  RealColumn get amount => real()();
  DateTimeColumn get startDate => dateTime()();
  IntColumn get frequency => integer()();
  IntColumn get frequencyUnits => intEnum<FrequencyUnit>()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}
