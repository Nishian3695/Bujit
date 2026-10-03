// Loads and saves everything the app persists, against the encrypted database.
// Kept free of platform code (no secure storage, no file paths) so it can be
// tested with an in-memory database; StorageManager does the platform setup.
import 'package:drift/drift.dart';
import '../navigation_items/banking/bank_account_model.dart';
import '../navigation_items/banking/manual_account_model.dart';
import '../navigation_items/expense_activity/credit_model.dart';
import '../navigation_items/expense_activity/expense_item.dart';
import '../navigation_items/expense_activity/balance_model.dart';
import '../navigation_items/income_streams/income_stream_model.dart';
import '../utils/category_manager.dart';
import 'database/app_database.dart';
import 'database/mappers/expense_mapper.dart';
import 'database/mappers/income_stream_mapper.dart';
import 'database/mappers/single_event_mapper.dart';
import '../navigation_items/single_events/single_event_model.dart';
import '../navigation_items/single_events/single_events_ledger.dart';
import 'period_snapshot.dart';

// Everything the app persists, in domain form.
class AppData {
    final BalanceModel balance;
    final List<String> categories; // User categories (getCategories() adds "Other")
    final List<SingleEventModel> singleEvents; // Newest-changed first
    bool includeNextCheck; // Settings: show "Next Check" instead of "After This Check"
    int singleEventExpiryDays; // Settings: days after its last change a single event is cleared
    int tutorialStep; // Next tutorial step to show
    bool tutorialSeen; // Tutorial finished or skipped
    bool useCommaSeparators; // Settings: "$1,234.56" instead of "$1234.56"
    bool appLockEnabled; // Settings: unlock with biometrics/device credential on opening
    // The first-launch disclaimer was accepted (AppState.open asks on a fresh install).
    bool disclaimerAccepted;
    bool tasksSyncEnabled; // Settings: sync expenses and paychecks to Google Tasks
    String? tasksListId; // The "Bujit" list in Google Tasks
    String? tasksAccount; // Email of the Google account synced to (for display)
    String themeMode; // Settings: "system", "light" or "dark"
    String accentColor; // Settings: an AccentColor's name
    int customAccent; // Settings: the custom accent color (ARGB)
    String tasksProvider; // Task sync's service: "google" (Google Tasks) or "apple" (Apple Reminders)
    int launchCount; // Times the app has been opened (for the review prompt)
    bool reviewRequested; // The store's review prompt was asked for (it's asked once)
    // Google Task id -> the JSON last sent for it, for every task the app created
    // (see TasksSync).
    final Map<String, String> syncedTasks;
    final List<LinkedItem> linkedItems; // Linked bank logins (see BankingService)
    DateTime? lastBankSync;
    // Bank account ids to count toward the balance once a sync lists them (the
    // Java app's picks, imported before their accounts were fetched).
    final Set<String> pendingLinkedBalanceIds;

    AppData({
        required this.balance,
        List<String>? categories,
        List<SingleEventModel>? singleEvents,
        this.includeNextCheck = false,
        this.singleEventExpiryDays = 30,
        this.tutorialStep = 0,
        this.tutorialSeen = false,
        this.useCommaSeparators = false,
        this.appLockEnabled = false,
        this.disclaimerAccepted = true,
        this.tasksSyncEnabled = false,
        this.tasksListId,
        this.tasksAccount,
        this.themeMode = "system",
        this.accentColor = "blue",
        this.customAccent = 0xFF2979FF,
        this.tasksProvider = "google",
        this.launchCount = 0,
        this.reviewRequested = false,
        Map<String, String>? syncedTasks,
        List<LinkedItem>? linkedItems,
        this.lastBankSync,
        Set<String>? pendingLinkedBalanceIds,
    }) : pendingLinkedBalanceIds = pendingLinkedBalanceIds ?? {},
         categories = categories ?? defaultCategories(),
         singleEvents = singleEvents ?? [],
         syncedTasks = syncedTasks ?? {},
         linkedItems = linkedItems ?? [];

    // Single events applied against this data's balance, accounts and cards.
    SingleEventsLedger get singleEventsLedger => SingleEventsLedger(balance, singleEvents);

    // Replaces everything with [other]'s data (restoring a backup, clearing data),
    // keeping this device's Google Tasks connection, bank links and app lock.
    void replaceWith(AppData other) {
        final BalanceModel b = other.balance;
        balance
            ..currentBalance = b.currentBalance
            ..lastUpdated = b.lastUpdated
            ..balanceExtra = b.balanceExtra
            ..activeIncome = b.activeIncome
            ..projection = null;
        balance.expenses
            ..clear()
            ..addAll(b.expenses);
        balance.incomeStreams
            ..clear()
            ..addAll(b.incomeStreams);
        balance.snapshots
            ..clear()
            ..addAll(b.snapshots);
        balance.manualAccounts
            ..clear()
            ..addAll(b.manualAccounts);
        categories
            ..clear()
            ..addAll(other.categories);
        singleEvents
            ..clear()
            ..addAll(other.singleEvents);
        includeNextCheck = other.includeNextCheck;
        singleEventExpiryDays = other.singleEventExpiryDays;
        useCommaSeparators = other.useCommaSeparators;
        tutorialStep = other.tutorialStep;
        tutorialSeen = other.tutorialSeen;
    }

    // Categories (the Java app's category manager). Names are unique ignoring
    // case, and "Other" is built in.
    bool hasCategory(String name) =>
        name.toLowerCase() == otherCategory.toLowerCase() ||
        categories.any((c) => c.toLowerCase() == name.toLowerCase());

    // Removes a category; expenses in it move to "Other".
    void removeCategory(String name) {
        categories.remove(name);
        for (final ExpenseItem expense in balance.expenses) {
            if (expense is! CreditModel && expense.category.toLowerCase() == name.toLowerCase()) {
                expense.category = otherCategory;
            }
        }
    }

    // After a card is renamed: what's charged to it and single events on it follow.
    void renameCard(String oldName, String newName) {
        balance.renameCard(oldName, newName);
        for (final SingleEventModel event in singleEvents) {
            if (event.target == EventTarget.creditCard && event.targetName == oldName) event.targetName = newName;
        }
    }

    // After an account is renamed: single events on it show the new name.
    void accountRenamed(ManualAccountModel account) {
        for (final SingleEventModel event in singleEvents) {
            if (event.target == EventTarget.manualAccount && event.targetId == account.id) {
                event.targetName = account.name;
            }
        }
    }
}

class AppDataStore {
    final AppDatabase db;
    AppDataStore(this.db);

    // Reads everything, or returns null if nothing was ever saved (first launch).
    // Doesn't catch up to today: callers run BalanceModel.makeRecent() after.
    Future<AppData?> load() async {
        final AppMetaRow? meta = await (db.select(db.appMetaRows)
              ..where((t) => t.id.equals(0)))
            .getSingleOrNull();
        if (meta == null) return null;

        final BalanceModel balance = BalanceModel(
            currentBalance: meta.currentBalance,
            lastUpdated: meta.lastUpdated,
            balanceExtra: meta.balanceExtra,
        );
        final accountRows = await (db.select(db.manualAccountRows)
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
        balance.manualAccounts.addAll(accountRows.map((row) => ManualAccountModel(
            id: row.id,
            name: row.name,
            accountType: row.accountType,
            balance: row.balance,
            countsTowardBalance: row.countsTowardBalance,
        )));
        final expenseRows = await (db.select(db.expenseItemRows)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
        balance.expenses.addAll(expenseRows.map((row) => row.toDomain()));
        final streamRows = await (db.select(db.incomeStreamModelRows)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
        balance.incomeStreams.addAll(streamRows.map((row) => row.toDomain()));
        balance.activeIncome = _activeStream(balance.incomeStreams);
        final snapshotRows = await (db.select(db.periodSnapshotRows)
              ..orderBy([(t) => OrderingTerm.asc(t.start)]))
            .get();
        balance.snapshots.addAll(snapshotRows.map((row) => PeriodSnapshot(
            start: row.start, totalIncome: row.totalIncome, totalExpenses: row.totalExpenses)));

        final categoryRows = await (db.select(db.categoryRows)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
        final eventRows = await (db.select(db.singleEventRows)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
        final syncedRows = await db.select(db.syncedTaskRows).get();
        final itemRows = await db.select(db.linkedItemRows).get();
        final linkedRows = await (db.select(db.linkedAccountRows)
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
        balance.linkedAccounts.addAll(linkedRows.map((row) => BankAccountModel(
            id: row.id,
            itemKey: row.itemKey,
            name: row.name,
            type: row.type,
            subtype: row.subtype,
            mask: row.mask,
            institution: row.institution,
            ledger: row.ledger,
            available: row.available,
            limit: row.creditLimit,
            countsTowardBalance: row.countsTowardBalance,
        )));
        return AppData(
            balance: balance,
            categories: categoryRows.map((row) => row.name).toList(),
            singleEvents: eventRows.map((row) => row.toDomain()).toList(),
            includeNextCheck: meta.includeNextCheck,
            singleEventExpiryDays: meta.singleEventExpiryDays,
            tutorialStep: meta.tutorialStep,
            tutorialSeen: meta.tutorialSeen,
            useCommaSeparators: meta.useCommaSeparators,
            appLockEnabled: meta.appLockEnabled,
            disclaimerAccepted: meta.disclaimerAccepted,
            tasksSyncEnabled: meta.tasksSyncEnabled,
            tasksListId: meta.tasksListId,
            tasksAccount: meta.tasksAccount,
            themeMode: meta.themeMode,
            accentColor: meta.accentColor,
            customAccent: meta.customAccent,
            tasksProvider: meta.tasksProvider,
            launchCount: meta.launchCount,
            reviewRequested: meta.reviewRequested,
            syncedTasks: {for (final row in syncedRows) row.taskId: row.body},
            linkedItems: [
                for (final row in itemRows)
                    LinkedItem(key: row.key, accessToken: row.accessToken,
                        institution: row.institution, needsRelink: row.needsRelink),
            ],
            lastBankSync: meta.lastBankSync,
            pendingLinkedBalanceIds: {
                for (final String id in meta.pendingLinkedBalanceIds.split(",")) if (id.isNotEmpty) id,
            },
        );
    }

    // Replaces everything stored with [data], in one transaction (all or nothing).
    // Sets each saved item's id to its new row id.
    Future<void> save(AppData data) {
        final BalanceModel balance = data.balance;
        return db.transaction(() async {
            await db.delete(db.expenseItemRows).go();
            for (final expense in balance.expenses) {
                expense.id = await db.into(db.expenseItemRows).insert(expense.toInsertCompanion());
            }
            await db.delete(db.incomeStreamModelRows).go();
            for (final IncomeStreamModel stream in balance.incomeStreams) {
                stream.isActive = identical(stream, balance.activeIncome);
                stream.id = await db.into(db.incomeStreamModelRows).insert(stream.toInsertCompanion());
            }
            await db.delete(db.categoryRows).go();
            for (final String name in data.categories.toSet()) {
                if (name == otherCategory || name == newCategory) continue;
                await db.into(db.categoryRows).insert(CategoryRowsCompanion.insert(name: name));
            }
            await db.delete(db.periodSnapshotRows).go();
            for (final PeriodSnapshot snapshot in balance.snapshots) {
                await db.into(db.periodSnapshotRows).insert(PeriodSnapshotRowsCompanion.insert(
                    start: snapshot.start,
                    totalIncome: snapshot.totalIncome,
                    totalExpenses: snapshot.totalExpenses,
                ), mode: InsertMode.insertOrReplace);
            }
            await db.delete(db.singleEventRows).go();
            for (final SingleEventModel event in data.singleEvents) {
                event.id = await db.into(db.singleEventRows).insert(event.toInsertCompanion());
            }
            await db.delete(db.manualAccountRows).go();
            for (int i = 0; i < balance.manualAccounts.length; i++) {
                final ManualAccountModel account = balance.manualAccounts[i];
                await db.into(db.manualAccountRows).insert(ManualAccountRowsCompanion.insert(
                    id: account.id,
                    position: i,
                    name: account.name,
                    accountType: account.accountType,
                    balance: account.balance,
                    countsTowardBalance: Value(account.countsTowardBalance),
                ));
            }
            await db.delete(db.linkedItemRows).go();
            for (final LinkedItem item in data.linkedItems) {
                await db.into(db.linkedItemRows).insert(LinkedItemRowsCompanion.insert(
                    key: item.key,
                    accessToken: item.accessToken,
                    institution: Value(item.institution),
                    needsRelink: Value(item.needsRelink),
                ));
            }
            await db.delete(db.linkedAccountRows).go();
            for (int i = 0; i < balance.linkedAccounts.length; i++) {
                final BankAccountModel a = balance.linkedAccounts[i];
                await db.into(db.linkedAccountRows).insert(LinkedAccountRowsCompanion.insert(
                    id: a.id,
                    itemKey: a.itemKey,
                    position: i,
                    name: a.name,
                    type: a.type,
                    subtype: a.subtype,
                    mask: a.mask,
                    institution: a.institution,
                    ledger: Value(a.ledger),
                    available: Value(a.available),
                    creditLimit: Value(a.limit),
                    countsTowardBalance: Value(a.countsTowardBalance),
                ));
            }
            await db.delete(db.syncedTaskRows).go();
            for (final MapEntry<String, String> task in data.syncedTasks.entries) {
                await db.into(db.syncedTaskRows).insert(
                    SyncedTaskRowsCompanion.insert(taskId: task.key, body: task.value));
            }
            await db.into(db.appMetaRows).insertOnConflictUpdate(AppMetaRowsCompanion.insert(
                id: const Value(0),
                currentBalance: Value(balance.currentBalance),
                balanceExtra: Value(balance.balanceExtra),
                lastUpdated: balance.lastUpdated,
                includeNextCheck: Value(data.includeNextCheck),
                singleEventExpiryDays: Value(data.singleEventExpiryDays),
                tutorialStep: Value(data.tutorialStep),
                tutorialSeen: Value(data.tutorialSeen),
                useCommaSeparators: Value(data.useCommaSeparators),
                appLockEnabled: Value(data.appLockEnabled),
                disclaimerAccepted: Value(data.disclaimerAccepted),
                lastBankSync: Value(data.lastBankSync),
                pendingLinkedBalanceIds: Value(data.pendingLinkedBalanceIds.join(",")),
                tasksSyncEnabled: Value(data.tasksSyncEnabled),
                tasksListId: Value(data.tasksListId),
                tasksAccount: Value(data.tasksAccount),
                themeMode: Value(data.themeMode),
                accentColor: Value(data.accentColor),
                customAccent: Value(data.customAccent),
                tasksProvider: Value(data.tasksProvider),
                launchCount: Value(data.launchCount),
                reviewRequested: Value(data.reviewRequested),
            ));
        });
    }

    // The stream marked active, or the first one if none is (there should always
    // be one while any stream exists, as in the Java app).
    static IncomeStreamModel? _activeStream(List<IncomeStreamModel> streams) {
        for (final IncomeStreamModel stream in streams) {
            if (stream.isActive) return stream;
        }
        return streams.isEmpty ? null : streams.first;
    }
}
