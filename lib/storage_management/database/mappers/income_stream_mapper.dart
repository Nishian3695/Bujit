import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../navigation_items/income_streams/income_stream_model.dart';

// Converts between drift's generated IncomeStreamModelRow/Companion classes and
// the domain IncomeStreamModel, like expense_mapper.dart does for expenses.

extension IncomeStreamRowMapper on IncomeStreamModelRow {
  IncomeStreamModel toDomain() => IncomeStreamModel(
        id: id,
        name: name,
        amount: amount,
        startDate: startDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
        isActive: isActive,
      );
}

extension IncomeStreamModelMapper on IncomeStreamModel {
  // For inserting a stream (no id yet); see expense_mapper.dart for Value(...).
  IncomeStreamModelRowsCompanion toInsertCompanion() => IncomeStreamModelRowsCompanion.insert(
        name: name,
        amount: amount,
        startDate: startDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
        isActive: Value(isActive),
      );
}
