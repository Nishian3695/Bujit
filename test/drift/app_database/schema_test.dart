// Guards the released database schemas (drift_schemas/). The database the code
// creates must match the snapshot of its schemaVersion: changing a table without
// bumping schemaVersion, snapshotting it and writing a migration step fails here.
// See the steps in lib/storage_management/database/app_database.dart.
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
    // exactly the current schema. Nothing to upgrade from until version 2.
    for (final int from in GeneratedHelper.versions.where((v) => v < GeneratedHelper.versions.last)) {
        test("upgrading from version $from", () async {
            final AppDatabase db = AppDatabase((await verifier.startAt(from)).executor);
            await verifier.migrateAndValidate(db, db.schemaVersion);
            await db.close();
        });
    }
}
