// Apple Reminders sync against an in-memory fake of the native side (the
// "bujit/reminders" channel): what the reminders look like, recovering from ones
// deleted in Reminders, refused access, switching from Google Tasks, and the
// Settings switch showing on iPhone only.
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/navigation_items/settings/apple_reminders.dart';
import 'package:bujit/navigation_items/settings/google_tasks_helper.dart';
import 'package:bujit/navigation_items/settings/settings_activity.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime today = DateTime(2026, 10, 1);

// The EventKit side, as RemindersChannel in AppDelegate.swift behaves.
class FakeReminders {
    bool granted = true;
    final Map<String, String> lists = {}; // id -> title
    final Map<String, Map<String, dynamic>> reminders = {}; // id -> fields (with "listId")
    int _next = 0;

    Future<Object?> handle(MethodCall call) async {
        final Map<Object?, Object?> args = (call.arguments as Map<Object?, Object?>?) ?? const {};
        if (call.method == "requestAccess") return granted;
        if (!granted) throw PlatformException(code: "denied");
        switch (call.method) {
            case "listExists":
                return lists.containsKey(args["listId"]);
            case "findList":
                for (final MapEntry<String, String> list in lists.entries) {
                    if (list.value == args["title"]) return list.key;
                }
                return null;
            case "insertList":
                final String id = "list${_next++}";
                lists[id] = args["title"] as String;
                return id;
            case "insertTask":
                if (!lists.containsKey(args["listId"])) throw PlatformException(code: "not_found");
                final String id = "rem${_next++}";
                reminders[id] = {...(args["task"] as Map<Object?, Object?>).cast<String, dynamic>(), "listId": args["listId"]};
                return id;
            case "patchTask":
                final String id = args["taskId"] as String;
                if (!reminders.containsKey(id)) throw PlatformException(code: "not_found");
                reminders[id] = {...(args["task"] as Map<Object?, Object?>).cast<String, dynamic>(), "listId": args["listId"]};
                return null;
            case "deleteTask":
                reminders.remove(args["taskId"]);
                return null;
        }
        throw MissingPluginException();
    }

    Map<String, dynamic> titled(String prefix) =>
        reminders.values.firstWhere((r) => (r["title"] as String).startsWith(prefix));
}

// Google Tasks as a plain in-memory store, for switching services.
class MemoryStore implements TaskStore {
    final Map<String, String> lists = {};
    final Map<String, Map<String, dynamic>> items = {};
    bool disconnected = false;
    int _next = 0;

    @override
    final TasksAccount account = _GoogleAccount();
    @override
    Future<bool> listExists(String listId) async => lists.containsKey(listId);
    @override
    Future<String?> findList(String title) async =>
        lists.entries.where((e) => e.value == title).map((e) => e.key).firstOrNull;
    @override
    Future<String> insertList(String title) async => (lists["g${_next++}"] = title, "g${_next - 1}").$2;
    @override
    Future<String> insertTask(String listId, Map<String, dynamic> task) async {
        final String id = "t${_next++}";
        items[id] = task;
        return id;
    }
    @override
    Future<void> patchTask(String listId, String taskId, Map<String, dynamic> task) async => items[taskId] = task;
    @override
    Future<void> deleteTask(String listId, String taskId) async => items.remove(taskId);
}

class _GoogleAccount implements TasksAccount {
    @override
    bool get isConfigured => true;
    @override
    Future<String?> connect() async => "me@example.com";
    @override
    Future<String> accessToken() async => "token";
    @override
    Future<void> invalidate(String token) async {}
    @override
    Future<void> disconnect() async {}
}

AppData _data() {
    final BalanceModel balance = BalanceModel(currentBalance: 1000.0, lastUpdated: today);
    balance.expenses.add(ExpenseModel(name: "Rent", amount: 1200.0, startDate: addDays(today, 14), frequency: 1,
        frequencyUnits: FrequencyUnit.monthly));
    final IncomeStreamModel job = IncomeStreamModel(name: "Job", amount: 2400.0, startDate: addDays(today, -7),
        frequency: 2, frequencyUnits: FrequencyUnit.weekly);
    balance.incomeStreams.add(job);
    balance.activeIncome = job;
    return AppData(balance: balance, tutorialSeen: true);
}

late FakeReminders native;

void main() {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() {
        native = FakeReminders();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel("bujit/reminders"), native.handle);
    });
    tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel("bujit/reminders"), null);
    });

    test("the first sync makes a Bujit list with an all-day reminder for each item", () async {
        final AppData data = _data()..tasksSyncEnabled = true..tasksProvider = AppState.appleReminders;
        final TasksSyncResult result = await TasksSync(AppleRemindersStore()).reconcile(data, today: today);

        expect(result.ok, isTrue, reason: result.summary());
        expect(native.lists.values, ["Bujit"]);
        expect(native.reminders, hasLength(2));
        final Map<String, dynamic> rent = native.titled("Rent");
        expect(rent["due"], "2026-10-15"); // date only, so iOS reminds at its all-day time
        expect(rent["completed"], isFalse);
        expect(rent["notes"], contains("Bujit Budget Expense"));
        expect(native.titled("Paycheck: Job")["due"], "2026-10-08");
    });

    test("a reminder deleted in Reminders is made again", () async {
        final AppData data = _data()..tasksSyncEnabled = true;
        final TasksSync sync = TasksSync(AppleRemindersStore());
        await sync.reconcile(data, today: today);
        native.reminders.removeWhere((id, r) => (r["title"] as String).startsWith("Rent"));
        data.balance.expenses.first.amount = 1250.0; // a change, so it's sent again

        final TasksSyncResult result = await sync.reconcile(data, today: today);

        expect(result.ok, isTrue, reason: result.summary());
        expect(native.titled("Rent")["title"], contains("1250.00"));
    });

    test("refused access says where to allow it", () async {
        native.granted = false;
        expect(() => RemindersAccess().connect(), throwsA(isA<TasksAuthException>()));
    });

    test("switching from Google Tasks to Reminders turns Google Tasks off and keeps its tasks", () async {
        final MemoryStore google = MemoryStore();
        final AppData data = _data();
        final AppState state = AppState(data)
            ..tasks = TasksSync(google)
            ..reminders = TasksSync(AppleRemindersStore());
        await state.connectTasks();
        await state.syncTasks();
        expect(google.items, hasLength(2));

        expect(await state.connectTasks(provider: AppState.appleReminders), isTrue);
        await state.syncTasks();

        expect(data.tasksProvider, AppState.appleReminders);
        expect(data.tasksAccount, RemindersAccess.label);
        expect(google.items, hasLength(2), reason: "kept, as when turning Google Tasks off and keeping tasks");
        expect(native.reminders, hasLength(2));
    });

    testWidgets("Settings offers Apple Reminders on iPhone only", (tester) async {
        final AppState state = AppState(_data())
            ..tasks = TasksSync(MemoryStore())
            ..reminders = TasksSync(AppleRemindersStore());
        await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: state)));
        expect(find.text("Sync to Apple Reminders"), findsNothing); // tests run as Android

        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: state, key: UniqueKey())));
        expect(find.text("Sync to Apple Reminders"), findsOneWidget);
        await tester.tap(find.text("Sync to Apple Reminders"));
        await tester.pumpAndSettle();
        expect(state.data.tasksProvider, AppState.appleReminders);
        expect(find.textContaining("Syncing to the \"Bujit\" list in Reminders"), findsOneWidget);
        debugDefaultTargetPlatformOverride = null;
    });
}
