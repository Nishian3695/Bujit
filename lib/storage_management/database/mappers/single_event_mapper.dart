import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../navigation_items/single_events/single_event_model.dart';

// Converts between drift's generated SingleEventRow/Companion classes and the
// domain SingleEventModel, like expense_mapper.dart does for expenses.

extension SingleEventRowMapper on SingleEventRow {
  SingleEventModel toDomain() => SingleEventModel(
        id: id,
        name: name,
        amount: amount,
        isDebit: isDebit,
        createdDate: createdDate,
        lastModifiedDate: lastModifiedDate,
        appliedAmount: appliedAmount,
        target: target,
        targetName: targetName,
        targetId: targetId,
      );
}

extension SingleEventModelMapper on SingleEventModel {
  SingleEventRowsCompanion toInsertCompanion() => SingleEventRowsCompanion.insert(
        name: name,
        amount: amount,
        isDebit: isDebit,
        createdDate: createdDate,
        lastModifiedDate: lastModifiedDate,
        appliedAmount: appliedAmount,
        target: target,
        targetName: Value(targetName),
        targetId: Value(targetId),
      );
}
