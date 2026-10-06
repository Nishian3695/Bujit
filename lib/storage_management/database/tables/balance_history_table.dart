import 'package:drift/drift.dart';

// Mirrors BalanceHistoryEntry (lib/storage_management/balance_history.dart): one
// row per account per day.
@DataClassName('BalanceHistoryRow')
class BalanceHistoryRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get accountKey => text()();
  TextColumn get name => text()();
  RealColumn get amount => real()();

  @override
  List<Set<Column>> get uniqueKeys => [{date, accountKey}];
}
