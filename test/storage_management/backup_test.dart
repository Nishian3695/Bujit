// Encrypted backups: compatibility with the Java app's BackupCrypto, and moving
// data between the apps through its StorageManager JSON.
//
// fixtures/java_backup.bujitbackup was encrypted by real javax.crypto code
// (PBKDF2WithHmacSHA256 + AES/GCM/NoPadding, as in BackupCrypto.java) from
// fixtures/java_backup_payload.json, with the passphrase "correct horse battery"
// and 1,000 iterations (the count is read from the file; the app writes 210,000).
import 'dart:convert';
import 'dart:io';
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/banking/manual_account_model.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_item.dart';
import 'package:bujit/navigation_items/expense_activity/funding_source.dart';
import 'package:bujit/navigation_items/single_events/single_event_model.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/storage_management/backup/backup_crypto.dart';
import 'package:bujit/storage_management/backup/backup_json.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);
const String passphrase = "correct horse battery";

String _fixture(String name) => File("test/fixtures/$name").readAsStringSync().trim();

ExpenseItem _expense(AppData data, String name) => data.balance.expenses.firstWhere((e) => e.name == name);

Future<BackupFailure> _failure(Future<void> Function() action) async {
    try {
        await action();
    } on BackupCryptoException catch (e) {
        return e.reason;
    }
    fail("expected a BackupCryptoException");
}

void main() {
    group("BackupCrypto", () {
        test("decrypts a backup encrypted by the Java app's crypto", () async {
            expect(await BackupCrypto.decrypt(_fixture("java_backup.bujitbackup"), passphrase),
                _fixture("java_backup_payload.json"));
        });

        test("round-trips, in Java's envelope format", () async {
            final String envelope = await BackupCrypto.encrypt('{"a":"€ ✓"}', "my passphrase",
                iterationCount: 1000, today: today);
            final Map<String, dynamic> fields = jsonDecode(envelope);

            expect(fields["format"], "bujit_backup");
            expect(fields["version"], 1);
            expect(fields["exportedAt"], "2026-10-01");
            expect(fields["kdf"], "PBKDF2WithHmacSHA256");
            expect(fields["iterations"], 1000);
            expect(base64.decode(fields["salt"]), hasLength(16));
            expect(base64.decode(fields["iv"]), hasLength(12));
            expect(base64.decode(fields["ciphertext"]), hasLength(utf8.encode('{"a":"€ ✓"}').length + 16));
            expect(await BackupCrypto.decrypt(envelope, "my passphrase"), '{"a":"€ ✓"}');
            expect(BackupCrypto.readExportedAt(envelope), "2026-10-01");
        });

        test("the app's own backups use 210,000 iterations, as the Java app's do", () {
            expect(BackupCrypto.iterations, 210000);
        });

        test("a wrong passphrase", () async {
            expect(await _failure(() => BackupCrypto.decrypt(_fixture("java_backup.bujitbackup"), "wrong")),
                BackupFailure.wrongPassphraseOrCorrupt);
        });

        test("a damaged file reads like a wrong passphrase", () async {
            final Map<String, dynamic> fields = jsonDecode(_fixture("java_backup.bujitbackup"));
            final List<int> sealed = base64.decode(fields["ciphertext"]);
            sealed[5] ^= 1;
            fields["ciphertext"] = base64.encode(sealed);

            expect(await _failure(() => BackupCrypto.decrypt(jsonEncode(fields), passphrase)),
                BackupFailure.wrongPassphraseOrCorrupt);
        });

        test("files that aren't backups, and newer versions", () async {
            expect(await _failure(() => BackupCrypto.decrypt("expense,Rent,1200", passphrase)),
                BackupFailure.malformedEnvelope);
            expect(await _failure(() => BackupCrypto.decrypt('{"format":"bujit_backup"}', passphrase)),
                BackupFailure.malformedEnvelope);
            final Map<String, dynamic> fields = jsonDecode(_fixture("java_backup.bujitbackup"));
            expect(await _failure(() => BackupCrypto.decrypt(jsonEncode({...fields, "format": "other"}), passphrase)),
                BackupFailure.malformedEnvelope);
            expect(await _failure(() => BackupCrypto.decrypt(jsonEncode({...fields, "version": 2}), passphrase)),
                BackupFailure.unsupportedVersion);
        });

        test("generated passphrases: 5 groups of 4 unambiguous characters", () {
            final String generated = BackupCrypto.generatePassphrase();
            expect(generated, matches(RegExp(r"^[2-9A-HJKMNP-Z]{4}(-[2-9A-HJKMNP-Z]{4}){4}$")));
            expect(BackupCrypto.generatePassphrase(), isNot(generated));
        });
    });

    group("restoring the Java app's data", () {
        late AppData data;
        setUp(() => data = BackupJson.decode(_fixture("java_backup_payload.json"), today: today));

        test("balance, accounts and additional funds", () {
            expect(data.balance.currentBalance, 2450.75);
            expect(data.balance.lastUpdated, DateTime(2026, 9, 30)); // incomeCreditedThrough
            expect(data.balance.balanceExtra, 50.0);
            final ManualAccountModel savings = data.balance.manualAccounts.single;
            expect(savings.id, "acct-1");
            expect(savings.balance, 900.0);
            expect(savings.countsTowardBalance, isFalse); // Java kept this in its preferences
        });

        test("expenses: due dates, schedules, sources and Tasks settings", () {
            final ExpenseItem rent = _expense(data, "Rent");
            expect(rent.amount, 1200.0); // "1,200.00"
            expect(rent.currentDueDate, DateTime(2026, 10, 1));
            expect(rent.startDate, DateTime(2025, 1, 1));
            expect(rent.category, "Housing");

            final ExpenseItem gym = _expense(data, "Gym");
            expect(gym.startDate, DateTime(2026, 1, 31)); // keeps month-ends
            expect(gym.endDate, DateTime(2027, 6, 30));
            expect(gym.source, FundingSource.manualAccount);
            expect(gym.sourceId, "acct-1");
            expect(gym.googleTaskId, "task-gym");
            expect(gym.remindInTasks, isFalse);

            // No start date, anchored on the 31st and due Nov 30: Oct 31 starts it.
            final ExpenseItem insurance = _expense(data, "Insurance");
            expect(insurance.startDate, DateTime(2026, 10, 31));
            insurance.makeRecent(today: DateTime(2026, 12, 1));
            expect(insurance.currentDueDate, DateTime(2026, 12, 31));

            expect(_expense(data, "Netflix").source, FundingSource.creditCard);
            expect(_expense(data, "Netflix").sourceId, "Visa");

            // Re-dated weekly (Tuesdays -> Fridays): the schedule follows the due date.
            final ExpenseItem coffee = _expense(data, "Coffee");
            expect(coffee.frequencyUnits, FrequencyUnit.weekly);
            expect(coffee.startDate, DateTime(2026, 10, 2));
            expect(coffee.source, FundingSource.balance); // linked accounts aren't built yet
        });

        test("credit cards", () {
            final CreditModel visa = _expense(data, "Visa") as CreditModel;
            expect(visa.amount, 300.5);
            expect(visa.creditLimit, 2000.0);
            expect(visa.currentDueDate, DateTime(2026, 10, 20));
            expect(visa.category, "Credit Cards");
        });

        test("income streams, snapshots and categories", () {
            final job = data.balance.activeIncome!;
            expect(job.name, "Job");
            expect(job.startDate, DateTime(2026, 9, 10));
            expect((job.frequency, job.frequencyUnits), (2, FrequencyUnit.weekly));
            final side = data.balance.incomeStreams[1];
            expect((side.frequency, side.frequencyUnits), (1, FrequencyUnit.monthly));
            expect(side.googleTaskId, "task-side");
            expect(data.balance.snapshots.single.totalExpenses, 1300.5);
            expect(data.categories, ["Housing", "Health", "Subscriptions", "Food"]);
        });

        test("single events, newest first", () {
            final SingleEventModel dinner = data.singleEvents[0];
            expect(dinner.target, EventTarget.creditCard);
            expect(dinner.targetName, "Visa");
            expect(dinner.appliedAmount, -60.0);
            final SingleEventModel gift = data.singleEvents[1];
            expect(gift.target, EventTarget.manualAccount);
            expect(gift.targetId, "acct-1");
            expect(gift.targetDisplayName, "Savings");
        });

        test("decrypting and reading the Java backup together", () async {
            final String json = await BackupCrypto.decrypt(_fixture("java_backup.bujitbackup"), passphrase);
            expect(BackupJson.decode(json, today: today).balance.expenses, hasLength(6));
        });

        test("restoring catches up to today", () async {
            final AppState state = AppState(AppData(balance: BalanceModel(currentBalance: 0.0)));

            await state.restoreBackup(data, today: DateTime(2026, 10, 2));

            // Rent (Oct 1) was paid; Coffee (Oct 2) is due today.
            expect(state.balance.currentBalance, 2450.75 - 1200.0);
            expect(state.data.singleEvents, hasLength(2)); // not expired yet
            expect(state.data.tutorialSeen, isTrue);
        });
    });

    test("this app's backups restore everything, including what the Java app lacks", () {
        final AppData original = AppData(balance: BalanceModel(currentBalance: 0.0), includeNextCheck: true,
            singleEventExpiryDays: 14, useCommaSeparators: true);
        seedSampleData(original.balance, today: today);
        final ManualAccountModel savings = ManualAccountModel(name: "Savings", balance: 900.0, countsTowardBalance: true);
        original.balance.manualAccounts.add(savings);
        original.balance.expenses.first
            ..source = FundingSource.manualAccount
            ..sourceId = savings.id;

        final AppData restored = BackupJson.decode(BackupJson.encode(original), today: today);

        expect(restored.balance.currentBalance, original.balance.currentBalance);
        expect(restored.balance.expenses.map((e) => (e.name, e.amount, e.currentDueDate, e.startDate)),
            original.balance.expenses.map((e) => (e.name, e.amount, e.currentDueDate, e.startDate)));
        expect(restored.balance.expenses.first.sourceId, savings.id);
        expect(restored.balance.manualAccounts.single.countsTowardBalance, isTrue);
        expect(restored.includeNextCheck, isTrue);
        expect(restored.singleEventExpiryDays, 14);
        expect(restored.useCommaSeparators, isTrue);
        // Biweekly travels as 2 weeks (the Java app has no biweekly); same paydays.
        final job = restored.balance.activeIncome!;
        expect((job.frequency, job.frequencyUnits), (2, FrequencyUnit.weekly));
        expect(restored.balance.check(3, today: today).expensesDue, original.balance.check(3, today: today).expensesDue);
        expect(restored.balance.check(3, today: today).startBalance, original.balance.check(3, today: today).startBalance);
    });
}
