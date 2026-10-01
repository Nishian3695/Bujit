import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

// Wires drift up to an encrypted database file. Kept as its own
// file/function so "how the DB is physically opened + encrypted" stays
// separate from "what tables exist" (app_database.dart).
//
// Encryption comes from pubspec.yaml's `hooks: user_defines: sqlite3:
// source: sqlite3mc` block, which makes sqlite3 (drift's native backend)
// bundle a SQLite3MultipleCiphers-enabled build at compile time -- no
// separate encryption plugin needed. The Dart code below just opens the
// database and runs `PRAGMA key`, same as it would for a normal drift
// database.
QueryExecutor openConnection(File dbFile, String passphrase) {
  // LazyDatabase defers actually opening the file until the first query
  // runs, letting this stay a plain synchronous function even though the
  // real setup work happens on a background isolate.
  return LazyDatabase(() {
    return NativeDatabase.createInBackground(
      dbFile,
      setup: (rawDb) {
        // Single quotes here are why the passphrase is base64-encoded
        // before it ever reaches this function (see StorageManager) --
        // base64's alphabet can't contain a `'`, so there's no SQL
        // string-escaping concern injecting this value directly.
        rawDb.execute("PRAGMA key = '$passphrase';");

        // If the pubspec `hooks` block wasn't picked up for some reason
        // (e.g. this Flutter/Dart version doesn't support build hooks
        // yet), PRAGMA key above silently does nothing instead of
        // erroring -- the database would end up written to disk
        // completely unencrypted, which is a far worse failure mode than
        // a crash. This assertion (stripped in release builds, same as
        // any `assert`) catches that during development.
        assert(rawDb.select('PRAGMA cipher;').isNotEmpty,
            'sqlite3 was not built with SQLite3MultipleCiphers support -- '
            'check the `hooks: user_defines: sqlite3: source: sqlite3mc` '
            'block in pubspec.yaml');
      },
    );
  });
}
