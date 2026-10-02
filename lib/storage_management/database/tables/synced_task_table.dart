import 'package:drift/drift.dart';

// Every Google Task the app has created, with the body last sent for it
// (AppData.syncedTasks). Syncing compares against it to see which tasks changed,
// and deletes tasks whose expense or income stream is gone.
@DataClassName('SyncedTaskRow')
class SyncedTaskRows extends Table {
  TextColumn get taskId => text()();
  TextColumn get body => text()(); // JSON last sent to Google Tasks

  @override
  Set<Column> get primaryKey => {taskId};
}
