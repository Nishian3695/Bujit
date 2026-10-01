// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expenses_dao.dart';

// ignore_for_file: type=lint
mixin _$ExpensesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExpenseItemRowsTable get expenseItemRows => attachedDatabase.expenseItemRows;
  ExpensesDaoManager get managers => ExpensesDaoManager(this);
}

class ExpensesDaoManager {
  final _$ExpensesDaoMixin _db;
  ExpensesDaoManager(this._db);
  $$ExpenseItemRowsTableTableManager get expenseItemRows =>
      $$ExpenseItemRowsTableTableManager(
        _db.attachedDatabase,
        _db.expenseItemRows,
      );
}
