// Manages storage of data in the app: opens the local, encrypted drift
// database and loads it into an in-memory StorageHolder.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:bujit/storage_management/database/app_database.dart';
import 'package:bujit/storage_management/database/db_connection.dart';
import 'package:bujit/storage_management/database/mappers/expense_mapper.dart';
import 'package:bujit/storage_management/storage_holder.dart';

class StorageManager {
    static const String dataDir = "BujitData"; // Directory for storing app data
    static const String dbFileName = "bujit.sqlite"; // Encrypted database file name
    final Logger logger = Logger("BujitStorageManager");

    // Encryption
    static const String _secureKeyName = "bujit_db_passphrase"; // Key alias in secure storage
    static const int _passphraseEntropyBytes = 32; // 256 bits of randomness before base64
    final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

    // Database + in-memory cache
    late final AppDatabase db;
    late StorageHolder _storageHolder; // Holds the app's data in memory

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
        manager._storageHolder = await manager._loadStorageHolder();
        return manager;
    }

    // Everything loaded from the database at create() time.
    StorageHolder get holder => _storageHolder;

    // Methods

    // Loads everything currently persisted into a StorageHolder. Only
    // expenses are actually wired up so far -- the other four tables are
    // barebones (no DAO yet, see lib/storage_management/database/tables/),
    // so those fields stay empty/default until their DAOs are built
    // following ExpensesDao's pattern.
    Future<StorageHolder> _loadStorageHolder() async {
        final expenseRows = await db.expensesDao.getAllExpenses();
        return StorageHolder(
            expenses: expenseRows.map((row) => row.toDomain()).toList(),
            currentBalance: 0.00, // TODO(you): read from the AppMeta table
            incomeStreams: [], // TODO(you): read once IncomeStreamsDao exists
            lastUpdated: DateTime.now(), // TODO(you): read from AppMeta
            categories: [], // TODO(you): read once CategoriesDao exists
        );
    }

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
