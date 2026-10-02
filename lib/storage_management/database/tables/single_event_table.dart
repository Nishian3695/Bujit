import 'package:drift/drift.dart';
import '../../../navigation_items/single_events/single_event_model.dart';

// Mirrors SingleEventModel (lib/navigation_items/single_events/single_event_model.dart).
@DataClassName('SingleEventRow')
class SingleEventRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  RealColumn get amount => real()();
  BoolColumn get isDebit => boolean()();
  DateTimeColumn get createdDate => dateTime()();
  DateTimeColumn get lastModifiedDate => dateTime()();
  // Signed effect currently applied to the target (see SingleEventModel.appliedAmount).
  RealColumn get appliedAmount => real()();
  TextColumn get target => textEnum<EventTarget>()();
  TextColumn get targetName => text().nullable()(); // Credit card name for EventTarget.creditCard
}
