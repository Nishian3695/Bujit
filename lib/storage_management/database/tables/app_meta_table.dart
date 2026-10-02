import 'package:drift/drift.dart';

// Single-row table for whole-app values that don't belong to any one
// expense/income/category: the balance, the day everything was last brought
// up to (BalanceModel.lastUpdated), and settings. No row at all means the app
// has never been opened (AppDataStore.load returns null).
//
// SQLite has no built-in "singleton table" concept; this is the common
// drift/SQL pattern for emulating one: fix the primary key to a single
// value (0) and CHECK-constrain against any other id. Always read/write
// id 0, and use an upsert (insertOnConflictUpdate) rather than a plain
// insert, so a second "insert" updates the one row instead of failing
// the CHECK.
@DataClassName('AppMetaRow') // named ...Row so the generated class name
// doesn't read as confusingly close to the table class's own name.
class AppMetaRows extends Table {
  // customConstraint() replaces drift's auto-generated column constraints
  // (and any .withDefault()) entirely, so NOT NULL/DEFAULT/CHECK all have
  // to be spelled out together here rather than via separate builder
  // calls. Primary-key-ness is declared separately below via the
  // `primaryKey` getter, not in this string -- putting "PRIMARY KEY" in
  // both places makes drift emit it twice in the generated CREATE TABLE
  // (once inline, once as a trailing table constraint), which SQLite
  // rejects outright ("table has more than one primary key").
  IntColumn get id => integer().customConstraint('NOT NULL DEFAULT 0 CHECK (id = 0)')();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  // Update Balance's "additional funds" (BalanceModel.balanceExtra).
  RealColumn get balanceExtra => real().withDefault(const Constant(0.0))();
  DateTimeColumn get lastUpdated => dateTime()();
  // Settings: show "Next Check" (After This Check plus the next paycheck).
  BoolColumn get includeNextCheck => boolean().withDefault(const Constant(false))();
  // Settings: days after its last change that a single event is cleared (Java default 30).
  IntColumn get singleEventExpiryDays => integer().withDefault(const Constant(30))();
  // Tutorial progress: the next step to show, and whether it was finished or skipped.
  IntColumn get tutorialStep => integer().withDefault(const Constant(0))();
  BoolColumn get tutorialSeen => boolean().withDefault(const Constant(false))();
  // Settings: thousands separators in amounts, and asking to unlock on opening.
  BoolColumn get useCommaSeparators => boolean().withDefault(const Constant(false))();
  BoolColumn get appLockEnabled => boolean().withDefault(const Constant(false))();
  // The first-launch disclaimer was accepted ("I Understand").
  BoolColumn get disclaimerAccepted => boolean().withDefault(const Constant(false))();
  // When linked banks were last synced (refreshes are skipped within 15 minutes).
  DateTimeColumn get lastBankSync => dateTime().nullable()();
  // AppData.pendingLinkedBalanceIds, comma-separated (Plaid account ids have no commas).
  TextColumn get pendingLinkedBalanceIds => text().withDefault(const Constant(""))();
  // Google Tasks: sync turned on, the "Bujit" task list's id, and the signed-in
  // account's email (for display).
  BoolColumn get tasksSyncEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get tasksListId => text().nullable()();
  TextColumn get tasksAccount => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
