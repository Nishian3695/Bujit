// Importing the Java app's data when this app is installed over it: what's read
// from the device (its data JSON, settings and bank logins) becomes the app's data,
// once, and bank accounts that made up the balance come back with the first sync.
import 'dart:convert';
import 'dart:io';
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/banking/banking_prefs.dart';
import 'package:bujit/navigation_items/banking/plaid_api.dart';
import 'package:bujit/navigation_items/banking/plaid_backend_client.dart';
import 'package:bujit/navigation_items/expense_activity/funding_source.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/storage_management/database/app_database.dart';
import 'package:bujit/storage_management/java_migration.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final DateTime today = DateTime(2026, 10, 1);

// The fixture is the Java app's StorageManager JSON (see backup_test.dart), with a
// linked loan and a bank-paid expense added.
String _javaJson() {
    final Map<String, dynamic> json = jsonDecode(File("test/fixtures/java_backup_payload.json").readAsStringSync());
    final List<dynamic> expenses = json["expenseList"];
    expenses.firstWhere((e) => e["name"] == "Rent")["linkedAccountId"] = "loan-1";
    return jsonEncode(json);
}

Map<Object?, Object?> _deviceData() => {
    "data": _javaJson(),
    "prefs": {
        "includeNextCheck": true,
        "useCommaSeparators": true,
        "appLockEnabled": true,
        "disclaimerAccepted": true,
        "tutorialSeen": true,
        "singleEventExpiryDays": 14,
    },
    "plaidTokens": ["access-java"],
    "plaidLinkedAccounts": ["access-java|chk-1"],
    "manualLinkedIds": ["acct-1"],
};

class FakeJavaData implements JavaDataSource {
    Map<Object?, Object?>? left;
    int marked = 0;
    FakeJavaData(this.left);

    @override
    Future<Map<Object?, Object?>?> read() async => left;
    @override
    Future<void> markMigrated() async {
        marked++;
        left = null; // renamed: not found again
    }
}

class _Auth implements BankingAuth {
    @override
    bool get isConfigured => true;
    @override
    Future<String> idToken() async => "id";
    @override
    Future<String?> appCheckToken() async => "check";
}

class _NoLink implements PlaidLinkLauncher {
    @override
    Future<String?> open(String linkToken) async => null;
}

void main() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    group("JavaMigration.fromJava", () {
        test("brings the data, settings, counted accounts and bank logins", () {
            final AppData data = JavaMigration.fromJava(_deviceData(), today: today)!;

            expect(data.balance.currentBalance, 2450.75);
            expect(data.balance.expenses, hasLength(6));
            expect(data.includeNextCheck, isTrue);
            expect(data.useCommaSeparators, isTrue);
            expect(data.appLockEnabled, isTrue);
            expect(data.disclaimerAccepted, isTrue);
            expect(data.tutorialSeen, isTrue);
            expect(data.singleEventExpiryDays, 14);
            expect(data.balance.manualAccounts.single.countsTowardBalance, isTrue); // acct-1
            expect(data.linkedItems.single.accessToken, "access-java");
            expect(data.pendingLinkedBalanceIds, {"chk-1"});
            // Bank links stay (unlike restoring a backup file).
            expect(data.balance.expenses.firstWhere((e) => e.name == "Rent").linkedAccountId, "loan-1");
            final coffee = data.balance.expenses.firstWhere((e) => e.name == "Coffee");
            expect(coffee.source, FundingSource.linkedAccount);
            expect(coffee.sourceId, "plaid-123");
        });

        test("nothing left behind means nothing to import", () {
            expect(JavaMigration.fromJava({"data": null}), isNull);
        });

        test("missing settings fall back to the defaults", () {
            final AppData data = JavaMigration.fromJava({"data": _javaJson()}, today: today)!;
            expect(data.includeNextCheck, isFalse);
            expect(data.singleEventExpiryDays, 30);
            expect(data.disclaimerAccepted, isTrue); // they had data, so they'd accepted it in Java
            expect(data.linkedItems, isEmpty);
        });
    });

    group("AppState.open", () {
        test("imports the Java data on the first launch, once, instead of the sample data", () async {
            final AppDataStore store = AppDataStore(AppDatabase(NativeDatabase.memory()));
            final FakeJavaData java = FakeJavaData(_deviceData());

            final AppState first = await AppState.open(store, today: today, javaData: java);

            expect(first.balance.expenses.map((e) => e.name), contains("Coffee"));
            expect(first.balance.expenses.map((e) => e.name), isNot(contains("Electric Bill"))); // sample data
            expect(java.marked, 1);
            expect((await store.load())!.linkedItems.single.accessToken, "access-java");

            final AppState second = await AppState.open(store, today: today, javaData: FakeJavaData(_deviceData()));
            expect(second.balance.expenses, hasLength(first.balance.expenses.length)); // not imported again
        });

        test("unreadable Java data starts fresh, and isn't marked imported", () async {
            final AppDataStore store = AppDataStore(AppDatabase(NativeDatabase.memory()));
            final FakeJavaData java = FakeJavaData({"data": "not json"});

            final AppState state = await AppState.open(store, today: today, javaData: java);

            expect(state.data.disclaimerAccepted, isFalse); // the fresh-install path
            expect(java.marked, 0);
        });

        test("the first sync puts the Java app's balance accounts back and names the bank", () async {
            final AppDataStore store = AppDataStore(AppDatabase(NativeDatabase.memory()));
            final BankingService banking = BankingService(
                PlaidBackendClient(host: "backend.test", auth: _Auth(), client: MockClient((request) async =>
                    http.Response.bytes(utf8.encode(jsonEncode([
                        {"id": "chk-1", "name": "Checking", "type": "depository", "subtype": "checking",
                            "mask": "1111", "institution_name": "Chase", "ledger": "1800.00"},
                        {"id": "loan-1", "name": "Auto", "type": "loan", "subtype": "auto",
                            "mask": "2222", "institution_name": "Chase", "ledger": "9100"},
                    ])), 200))),
                _NoLink(),
            );

            final AppState state = await AppState.open(store, today: today,
                javaData: FakeJavaData(_deviceData()), banking: banking);
            while (state.bankSyncing || state.lastBankSync == null) {
                await Future<void>.delayed(const Duration(milliseconds: 1)); // the sync open() started
            }

            expect(state.data.linkedItems.single.institution, "Chase");
            expect(state.balance.linkedAccount("chk-1")!.countsTowardBalance, isTrue);
            expect(state.data.pendingLinkedBalanceIds, isEmpty);
            // Balance = linked checking + counted manual account (Savings 900) + additional funds (50).
            expect(state.balance.currentBalance, 1800.0 + 900.0 + 50.0);
            expect(state.balance.expenses.firstWhere((e) => e.name == "Rent").amount, 9100.0);
        });
    });
}
