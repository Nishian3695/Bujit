import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../utils/frequency_unit.dart';
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
        monthDays: monthDay1 == null || monthDay2 == null ? null : MonthDays(monthDay1!, monthDay2!),
        isActive: isActive,
        googleTaskId: googleTaskId,
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
        monthDay1: Value(monthDays?.first),
        monthDay2: Value(monthDays?.second),
        isActive: Value(isActive),
        googleTaskId: Value(googleTaskId),
      );
}
