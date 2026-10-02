import 'package:drift/drift.dart';

// Linked bank logins (LinkedItem) and their accounts (BankAccountModel). The
// database is encrypted, which is what keeps the Plaid access tokens safe at rest
// (the Java app kept them in encrypted preferences).
@DataClassName('LinkedItemRow')
class LinkedItemRows extends Table {
  TextColumn get key => text()();
  TextColumn get accessToken => text()();
  TextColumn get institution => text().withDefault(const Constant(""))();
  BoolColumn get needsRelink => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('LinkedAccountRow')
class LinkedAccountRows extends Table {
  TextColumn get id => text()();
  TextColumn get itemKey => text()();
  IntColumn get position => integer()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get subtype => text()();
  TextColumn get mask => text()();
  TextColumn get institution => text()();
  RealColumn get ledger => real().nullable()();
  RealColumn get available => real().nullable()();
  RealColumn get creditLimit => real().nullable()();
  BoolColumn get countsTowardBalance => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
