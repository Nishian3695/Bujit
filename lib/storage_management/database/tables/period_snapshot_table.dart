import 'package:drift/drift.dart';

// Mirrors PeriodSnapshot (lib/storage_management/period_snapshot.dart): one row
// per ended pay period, keyed by the payday it began on.
@DataClassName('PeriodSnapshotRow')
class PeriodSnapshotRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get start => dateTime().unique()();
  RealColumn get totalIncome => real()();
  RealColumn get totalExpenses => real()();
}
