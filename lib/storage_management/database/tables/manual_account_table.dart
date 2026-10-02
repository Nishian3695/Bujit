import 'package:drift/drift.dart';

// Mirrors ManualAccountModel (lib/navigation_items/banking/manual_account_model.dart).
// Keyed by the account's own id, which expenses and single events refer to.
@DataClassName('ManualAccountRow')
class ManualAccountRows extends Table {
  TextColumn get id => text()();
  IntColumn get position => integer()(); // Order in the list
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get accountType => text()();
  RealColumn get balance => real()();
  BoolColumn get countsTowardBalance => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
