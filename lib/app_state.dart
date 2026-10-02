// The app's live data, shared by every screen. Screens change data through it
// and call changed(), which rebuilds listeners (e.g. the home screen) and saves.
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'navigation_items/banking/bank_account_model.dart';
import 'navigation_items/banking/banking_prefs.dart';
import 'navigation_items/expense_activity/balance_model.dart';
import 'navigation_items/expense_activity/credit_model.dart';
import 'navigation_items/expense_activity/expense_item.dart';
import 'navigation_items/settings/google_tasks_helper.dart';
import 'navigation_items/settings/tip_jar.dart';
import 'prefs/app_lock_prefs.dart';
import 'storage_management/app_data_store.dart';
import 'tutorial/tutorial_manager.dart';
import 'utils/money.dart';
import 'utils/sample_data.dart';

class AppState extends ChangeNotifier {
    static final Logger _logger = Logger("BujitAppState");

    final AppData data;
    final AppDataStore? _store; // null = nothing is saved (tests, or storage failed to open)

    // Google Tasks sync; null = not available (tests, or storage failed to open).
    GoogleTasksSync? tasks;
    // Asks for the fingerprint/face/PIN (the app lock); null in tests unless faked.
    DeviceAuth? deviceAuth;
    // Linked banks through Plaid; null = not available (tests, or storage failed to open).
    BankingService? banking;
    // The tip jar (Settings); null = not available (tests).
    TipJar? tipJar;

    AppState(this.data, [this._store]) {
        Money.useCommaSeparators = data.useCommaSeparators;
    }

    BalanceModel get balance => data.balance;

    // False when changes can't be saved (storage failed to open).
    bool get isSaving => _store != null;

    // Loads saved data and brings it up to [today] (default: now), paying what came
    // due and crediting paychecks that arrived, then saves the result. On the very
    // first launch there's nothing saved, so the tutorial's sample data is loaded
    // instead, as the Java app does.
    static Future<AppState> open(AppDataStore store,
            {DateTime? today, GoogleTasksSync? tasks, BankingService? banking}) async {
        AppData? data = await store.load();
        if (data == null) {
            // A fresh install: the disclaimer comes first, then the tutorial.
            data = AppData(balance: BalanceModel(currentBalance: 0.00), disclaimerAccepted: false);
            seedSampleData(data.balance, today: today);
        } else {
            data.balance.makeRecent(today: today);
            // Expired single events leave the list; their effects stay (they happened).
            data.singleEventsLedger.clearExpired(data.singleEventExpiryDays, today: today);
        }
        final AppState state = AppState(data, store)
            ..tasks = tasks
            ..banking = banking;
        await state.save();
        state.syncTasks(today: today); // Due dates may have moved on; runs in the background
        state.refreshBanks(); // Linked balances, unless synced in the last 15 minutes
        return state;
    }

    // Saves everything. Failures are logged rather than thrown, so a storage
    // problem never crashes a screen mid-edit.
    Future<void> save() async {
        final AppDataStore? store = _store;
        if (store == null) return;
        try {
            await store.save(data);
        } catch (e, stack) {
            _logger.severe("Saving failed", e, stack);
        }
    }

    // Call after changing anything in [data]: rebuilds listening screens and saves.
    Future<void> changed() {
        Money.useCommaSeparators = data.useCommaSeparators;
        notifyListeners();
        syncTasks();
        return save();
    }

    // ── Expenses and cards ──────────────────────────────────────────────────

    // Swaps in an edited copy of an expense or card (dialogs return new objects).
    // A date entered in the past rolls forward to the next one without paying
    // anything, as when adding. A renamed card keeps what's charged to it.
    Future<void> replaceItem(ExpenseItem old, ExpenseItem edited) {
        edited.skipToNextDueDate();
        if (old is CreditModel) data.renameCard(old.name, edited.name);
        final int index = balance.expenses.indexOf(old);
        if (index >= 0) balance.expenses[index] = edited;
        return changed();
    }

    // Deletes an expense or card. What was charged to a deleted card is paid from
    // the balance from then on.
    Future<void> removeItem(ExpenseItem item) => removeItems([item]);

    // Deletes several (the home screen's multi-select Delete).
    Future<void> removeItems(Iterable<ExpenseItem> items) {
        for (final ExpenseItem item in items.toList()) {
            balance.expenses.remove(item);
            if (item is CreditModel) balance.cardRemoved(item.name);
        }
        return changed();
    }

    // ── Linked banks ────────────────────────────────────────────────────────

    bool get canLinkBanks => banking?.isConfigured ?? false;
    bool bankSyncing = false;
    BankSyncResult? lastBankSync; // For the screens: expired connections, errors

    // Links a bank through Plaid (or reconnects [replacing]); returns its name,
    // or null if the user left Plaid Link. Throws if the backend fails.
    Future<String?> linkBank({LinkedItem? replacing}) async {
        final BankingService? service = banking;
        if (service == null) return null;
        final String? institution = await service.linkBank(data, replacing: replacing);
        if (institution != null) await changed();
        return institution;
    }

    // Syncs linked banks' balances (at most every 15 minutes unless [force]).
    // Never throws; problems are in the result.
    Future<BankSyncResult?> refreshBanks({bool force = false}) async {
        final BankingService? service = banking;
        if (service == null || !service.isConfigured || data.linkedItems.isEmpty || bankSyncing) return null;
        bankSyncing = true;
        notifyListeners();
        try {
            final BankSyncResult result = await service.refresh(data, force: force);
            lastBankSync = result;
            if (result.synced || result.needsRelink.isNotEmpty) await changed();
            return result;
        } finally {
            bankSyncing = false;
            notifyListeners();
        }
    }

    Future<void> disconnectBanks(Set<String> itemKeys) async {
        final BankingService? service = banking;
        if (service == null) return;
        await service.disconnect(data, itemKeys);
        await changed();
    }

    // ── Google Tasks ────────────────────────────────────────────────────────

    bool get canSyncTasks => tasks != null && data.tasksSyncEnabled;
    bool tasksSyncing = false;
    TasksSyncResult? lastTasksSync; // Shown in Settings
    Future<void>? _tasksRun;
    bool _tasksAgain = false;

    // Brings Google Tasks up to date in the background. If a sync is running, one
    // more runs after it (the data may have changed since it started). Completes
    // when syncing is done; never throws.
    Future<void> syncTasks({DateTime? today}) {
        if (!canSyncTasks) return Future.value();
        final Future<void>? running = _tasksRun;
        if (running != null) {
            _tasksAgain = true;
            return running;
        }
        final Future<void> run = _runTasksSync(today).whenComplete(() => _tasksRun = null);
        _tasksRun = run;
        return run;
    }

    Future<void> _runTasksSync(DateTime? today) async {
        tasksSyncing = true;
        notifyListeners();
        do {
            _tasksAgain = false;
            lastTasksSync = await tasks!.reconcile(data, today: today);
            await save(); // Task ids (not changed(): that would sync again)
        } while (_tasksAgain && canSyncTasks);
        tasksSyncing = false;
        notifyListeners();
    }

    // Signs in to Google and turns sync on (Settings). Returns false if the user
    // cancelled; throws TasksAuthException if signing in failed.
    Future<bool> connectTasks() async {
        final GoogleTasksSync? sync = tasks;
        if (sync == null) return false;
        final String? email = await sync.account.connect();
        if (email == null) return false;
        data.tasksSyncEnabled = true;
        data.tasksAccount = email;
        await changed();
        return true;
    }

    // Turns sync off and signs out; with [removeTasks], deletes Bujit's tasks first.
    Future<void> disconnectTasks({required bool removeTasks}) async {
        final GoogleTasksSync? sync = tasks;
        if (sync == null) return;
        await _tasksRun; // Let a running sync finish, so it can't recreate tasks after
        await sync.disconnect(data, removeTasks: removeTasks);
        lastTasksSync = null;
        await changed();
    }

    // The tutorial step to show now, or null once it's finished or skipped (or
    // while the first-launch disclaimer is still waiting, as in the Java app).
    TutorialStep? get tutorialStep {
        if (data.tutorialSeen || !data.disclaimerAccepted) return null;
        final int index = data.tutorialStep;
        return (index >= 0 && index < TutorialManager.steps.length) ? TutorialManager.steps[index] : null;
    }

    // "I Understand" on the first-launch disclaimer; the tutorial starts after it.
    Future<void> acceptDisclaimer() {
        data.disclaimerAccepted = true;
        return changed();
    }

    // Moves to the next step; finishing the last one marks the tutorial seen.
    Future<void> advanceTutorial() {
        data.tutorialStep++;
        if (data.tutorialStep >= TutorialManager.steps.length) data.tutorialSeen = true;
        return changed();
    }

    // Skips the rest of the tutorial.
    Future<void> skipTutorial() {
        data.tutorialSeen = true;
        return changed();
    }

    // Starts the tutorial over from the first step (Settings: Replay tutorial).
    Future<void> replayTutorial() {
        data.tutorialStep = 0;
        data.tutorialSeen = false;
        return changed();
    }

    // Replaces everything with a restored backup's data (Settings), then brings it
    // up to [today] -- paying what came due since the backup and crediting
    // paychecks -- as opening the app does.
    Future<void> restoreBackup(AppData restored, {DateTime? today}) {
        data.replaceWith(restored);
        data.balance.makeRecent(today: today);
        data.singleEventsLedger.clearExpired(data.singleEventExpiryDays, today: today);
        return changed();
    }

    // Settings' Clear All Data (the Java app's performClearData): every setting
    // back to its default, Google Tasks disconnected (its tasks are left alone) and
    // the app lock off, then the tutorial's sample data and the tutorial again --
    // what the Java app shows after clearing.
    Future<void> clearAllData({DateTime? today}) async {
        if (tasks != null && data.tasksSyncEnabled) await disconnectTasks(removeTasks: false);
        // Banks too, revoking their access as the Java app's BankingPrefs.clear path did.
        await banking?.disconnect(data, {for (final item in data.linkedItems) item.key});
        data.linkedItems.clear();
        data.balance.linkedAccountsRemoved({for (final a in data.balance.linkedAccounts) a.id});
        data.lastBankSync = null;
        final AppData fresh = AppData(balance: BalanceModel(currentBalance: 0.00));
        seedSampleData(fresh.balance, today: today);
        data.replaceWith(fresh);
        data
            ..appLockEnabled = false
            ..tasksSyncEnabled = false
            ..tasksListId = null
            ..tasksAccount = null
            ..syncedTasks.clear();
        lastTasksSync = null;
        return changed();
    }

    // Replaces everything with the tutorial's sample data (Settings).
    Future<void> resetToSampleData({DateTime? today}) {
        seedSampleData(data.balance, today: today);
        data.singleEvents.clear();
        return changed();
    }
}
