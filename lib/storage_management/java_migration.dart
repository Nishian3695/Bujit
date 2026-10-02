// Importing the Java app's data when this app is installed over it (a Play update:
// same package and signing key). On the first launch with no data of its own,
// AppState.open asks JavaDataSource for what the Java app left on the device --
// its data (the same JSON as its backups) and its settings and bank logins -- and
// starts from that instead of the sample data. The Java data file is then renamed,
// not deleted (android/.../JavaMigration.kt), so it's imported once and kept.
//
// Bank logins come along (the same Plaid access tokens), so linked accounts keep
// syncing; their accounts arrive with the first sync, which then puts back the
// ones that made up the balance (AppData.pendingLinkedBalanceIds). Google Tasks
// needs signing in again (it uses a different sign-in); its tasks are reused.
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../navigation_items/banking/bank_account_model.dart';
import '../navigation_items/banking/manual_account_model.dart';
import 'app_data_store.dart';
import 'backup/backup_json.dart';

abstract class JavaDataSource {
    // What the Java app left: {data: json | null, prefs: {...}, plaidTokens: [...],
    // plaidLinkedAccounts: ["token|accountId"], manualLinkedIds: [...]}, or null.
    Future<Map<Object?, Object?>?> read();
    // After a successful import: the Java data isn't imported again.
    Future<void> markMigrated();
}

class AndroidJavaDataSource implements JavaDataSource {
    static const MethodChannel _channel = MethodChannel("bujit/java_migration");

    @override
    Future<Map<Object?, Object?>?> read() async {
        if (defaultTargetPlatform != TargetPlatform.android) return null; // Java was Android-only
        return _channel.invokeMethod<Map<Object?, Object?>>("read");
    }

    @override
    Future<void> markMigrated() => _channel.invokeMethod<bool>("markMigrated");
}

class JavaMigration {
    // The app's data from what the Java app left, or null if it left nothing.
    static AppData? fromJava(Map<Object?, Object?> raw, {DateTime? today}) {
        final Object? json = raw["data"];
        if (json is! String) return null;
        final AppData data = BackupJson.decode(json, today: today, keepBankLinks: true);

        final Map<Object?, Object?> prefs = raw["prefs"] is Map ? raw["prefs"] as Map<Object?, Object?> : const {};
        bool flag(String key) => prefs[key] == true;
        data
            ..includeNextCheck = flag("includeNextCheck")
            ..useCommaSeparators = flag("useCommaSeparators")
            ..appLockEnabled = flag("appLockEnabled")
            // Someone updating from the Java app already accepted it there.
            ..disclaimerAccepted = flag("disclaimerAccepted") || data.balance.expenses.isNotEmpty
            ..tutorialSeen = flag("tutorialSeen");
        final Object? expiry = prefs["singleEventExpiryDays"];
        if (expiry is int && expiry > 0) data.singleEventExpiryDays = expiry;

        // Manual accounts the Java app counted toward the balance.
        final Set<String> manualIds = _strings(raw["manualLinkedIds"]).toSet();
        for (final ManualAccountModel account in data.balance.manualAccounts) {
            account.countsTowardBalance = manualIds.contains(account.id);
        }

        // Bank logins; their accounts (and which count toward the balance) follow at the first sync.
        for (final String token in _strings(raw["plaidTokens"])) {
            data.linkedItems.add(LinkedItem(key: _newKey(), accessToken: token));
        }
        for (final String composite in _strings(raw["plaidLinkedAccounts"])) {
            final int bar = composite.lastIndexOf("|");
            if (bar >= 0) data.pendingLinkedBalanceIds.add(composite.substring(bar + 1));
        }
        return data;
    }

    static List<String> _strings(Object? value) =>
        value is List ? [for (final Object? v in value) if (v is String && v.isNotEmpty) v] : const [];

    static final Random _random = Random.secure();
    static String _newKey() =>
        List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, "0")).join();
}
