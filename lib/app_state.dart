// The app's live data, shared by every screen. Screens change data through it
// and call changed(), which rebuilds listeners (e.g. the home screen) and saves.
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'navigation_items/expense_activity/balance_model.dart';
import 'navigation_items/expense_activity/credit_model.dart';
import 'navigation_items/expense_activity/expense_item.dart';
import 'navigation_items/settings/google_tasks_helper.dart';
import 'storage_management/app_data_store.dart';
import 'tutorial/tutorial_manager.dart';
import 'utils/sample_data.dart';

class AppState extends ChangeNotifier {
    static final Logger _logger = Logger("BujitAppState");

    final AppData data;
    final AppDataStore? _store; // null = nothing is saved (tests, or storage failed to open)

    // Google Tasks sync; null = not available (tests, or storage failed to open).
    GoogleTasksSync? tasks;

    AppState(this.data, [this._store]);

    BalanceModel get balance => data.balance;

    // False when changes can't be saved (storage failed to open).
    bool get isSaving => _store != null;

    // Loads saved data and brings it up to [today] (default: now), paying what came
    // due and crediting paychecks that arrived, then saves the result. On the very
    // first launch there's nothing saved, so the tutorial's sample data is loaded
    // instead, as the Java app does.
    static Future<AppState> open(AppDataStore store, {DateTime? today, GoogleTasksSync? tasks}) async {
        AppData? data = await store.load();
        if (data == null) {
            data = AppData(balance: BalanceModel(currentBalance: 0.00));
            seedSampleData(data.balance, today: today);
        } else {
            data.balance.makeRecent(today: today);
            // Expired single events leave the list; their effects stay (they happened).
            data.singleEventsLedger.clearExpired(data.singleEventExpiryDays, today: today);
        }
        final AppState state = AppState(data, store)..tasks = tasks;
        await state.save();
        state.syncTasks(today: today); // Due dates may have moved on; runs in the background
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
    Future<void> removeItem(ExpenseItem item) {
        balance.expenses.remove(item);
        if (item is CreditModel) balance.cardRemoved(item.name);
        return changed();
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

    // The tutorial step to show now, or null once it's finished or skipped.
    TutorialStep? get tutorialStep {
        if (data.tutorialSeen) return null;
        final int index = data.tutorialStep;
        return (index >= 0 && index < TutorialManager.steps.length) ? TutorialManager.steps[index] : null;
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

    // Replaces everything with the tutorial's sample data (Settings).
    Future<void> resetToSampleData({DateTime? today}) {
        seedSampleData(data.balance, today: today);
        data.singleEvents.clear();
        return changed();
    }
}
