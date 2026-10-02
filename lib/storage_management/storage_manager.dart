// Manages storage of data in the app: opens the local, encrypted drift
// database (with its key kept in the platform's secure storage) and hands out
// an AppDataStore for loading and saving.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/storage_management/database/app_database.dart';
import 'package:bujit/storage_management/database/db_connection.dart';

class StorageManager {
    static const String dataDir = "BujitData"; // Directory for storing app data
    static const String dbFileName = "bujit.sqlite"; // Encrypted database file name
    final Logger logger = Logger("BujitStorageManager");

    // Encryption
    static const String _secureKeyName = "bujit_db_passphrase"; // Key alias in secure storage
    static const int _passphraseEntropyBytes = 32; // 256 bits of randomness before base64
    final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

    late final AppDatabase db;
    late final AppDataStore store; // Loads and saves the app's data

    // Private constructor, don't want to allow direct instantiation, use the async factory instead
    StorageManager._();

    // Async factory. Key retrieval from secure storage must be async, so we can't use a normal constructor
    static Future<StorageManager> create(Directory context) async {
        final manager = StorageManager._();
        // Get the directory for storing app data
        final dir = Directory('${context.path}/$dataDir');
        // Create the directory if it doesn't exist
        if (!dir.existsSync()) dir.createSync(recursive: true);
        final dbFile = File('${dir.path}/$dbFileName');

        final passphrase = await manager._getOrCreatePassphrase();
        manager.db = AppDatabase(openConnection(dbFile, passphrase));
        manager.store = AppDataStore(manager.db);
        return manager;
    }

    // Methods

    // Retrieve the persisted database passphrase from secure storage,
    // generating and storing one if absent.
    Future<String> _getOrCreatePassphrase() async {
        final existing = await _secureStorage.read(key: _secureKeyName);
        if (existing != null) return existing;
        final passphrase = base64Encode(_randomBytes(_passphraseEntropyBytes));
        await _secureStorage.write(key: _secureKeyName, value: passphrase);
        return passphrase;
    }

    Uint8List _randomBytes(int length) {
        final rand = Random.secure();
        return Uint8List.fromList(List.generate(length, (_) => rand.nextInt(256)));
    }
}
