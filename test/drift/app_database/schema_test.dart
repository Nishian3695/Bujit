// Guards the released database schemas (drift_schemas/). The database the code
// creates must match the snapshot of its schemaVersion: changing a table without
// bumping schemaVersion, snapshotting it and writing a migration step fails here.
// See the steps in lib/storage_management/database/app_database.dart.
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/storage_management/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

void main() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());

    test("a new database matches the snapshot of its schema version", () async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        await verifier.migrateAndValidate(db, db.schemaVersion);
        await db.close();
    });

    test("every schema version has a snapshot", () {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        expect(GeneratedHelper.versions, contains(db.schemaVersion));
        expect(GeneratedHelper.versions.last, db.schemaVersion);
        db.close();
    });

    // Each upgrade (from every older snapshot to the current version) migrates to
    // exactly the current schema.
    for (final int from in GeneratedHelper.versions.where((v) => v < GeneratedHelper.versions.last)) {
        test("upgrading from version $from", () async {
            final AppDatabase db = AppDatabase((await verifier.startAt(from)).executor);
            await verifier.migrateAndValidate(db, db.schemaVersion);
            await db.close();
        });
    }

    // Version 2 added the appearance settings: an update keeps everything else and
    // starts them at their defaults.
    test("upgrading from version 1 keeps the data and adds the appearance defaults", () async {
        final schema = await verifier.schemaAt(1);
        schema.rawDatabase.execute("INSERT INTO app_meta_rows (id, current_balance, last_updated, "
            "use_comma_separators) VALUES (0, 1234.5, 1767225600, 1)");
        final AppDatabase db = AppDatabase(schema.newConnection());
        final AppData data = (await AppDataStore(db).load())!;
        expect(data.balance.currentBalance, 1234.5);
        expect(data.useCommaSeparators, isTrue);
        expect(data.themeMode, "system");
        expect(data.accentColor, "blue");
        expect(data.customAccent, 0xFF2979FF);
        await db.close();
    });

    // Version 3 added the task sync service and the review prompt's counters: a
    // Google Tasks user stays on Google Tasks.
    test("upgrading from version 2 keeps Google Tasks sync and starts the counters", () async {
        final schema = await verifier.schemaAt(2);
        schema.rawDatabase.execute("INSERT INTO app_meta_rows (id, current_balance, last_updated, "
            "tasks_sync_enabled, tasks_account, theme_mode) VALUES (0, 50.0, 1767225600, 1, 'me@example.com', 'dark')");
        final AppDatabase db = AppDatabase(schema.newConnection());
        final AppData data = (await AppDataStore(db).load())!;
        expect(data.tasksSyncEnabled, isTrue);
        expect(data.tasksAccount, "me@example.com");
        expect(data.themeMode, "dark");
        expect(data.tasksProvider, "google");
        expect(data.launchCount, 0);
        expect(data.reviewRequested, isFalse);
        await db.close();
    });
}
