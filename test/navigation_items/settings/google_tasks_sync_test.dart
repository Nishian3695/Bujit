// Google Tasks sync against an in-memory fake of the Tasks API: what gets
// created, updated and deleted, recovering from things changed in Google Tasks,
// expired tokens, disconnecting, and AppState running syncs after changes.
import 'dart:convert';
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/navigation_items/settings/google_tasks_helper.dart';
import 'package:bujit/navigation_items/settings/settings_activity.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final DateTime today = DateTime(2026, 10, 1);
DateTime day(int offset) => addDays(today, offset);

// Hands out "token-N"; invalidating moves to the next one. Fails like a
// revoked permission when [signedIn] is false.
class FakeAccount implements TasksAccount {
    int token = 1;
    bool signedIn = true;
    bool disconnected = false;

    @override
    bool get isConfigured => true;
    @override
    Future<String?> connect() async => "me@example.com";
    @override
    Future<String> accessToken() async {
        if (!signedIn) throw const TasksAuthException("Google Tasks needs permission again");
        return "token-$token";
    }
    @override
    Future<void> invalidate(String token) async => this.token++;
    @override
    Future<void> disconnect() async => disconnected = true;
}

// Just enough of https://tasks.googleapis.com/tasks/v1 for the sync.
class FakeTasksServer {
    final Map<String, String> lists = {}; // id -> title
    final Map<String, Map<String, Map<String, dynamic>>> tasks = {}; // list id -> task id -> task
    final List<String> calls = []; // "METHOD path" of every request
    String acceptedToken = "token-1";
    int _nextId = 0;

    String addList(String title) {
        final String id = "list${_nextId++}";
        lists[id] = title;
        tasks[id] = {};
        return id;
    }

    // Every task in the only list there is.
    Map<String, Map<String, dynamic>> get onlyList => tasks.values.single;
    Map<String, dynamic> taskTitled(String prefix) =>
        onlyList.values.singleWhere((t) => (t["title"] as String).startsWith(prefix));

    late final http.Client client = MockClient((request) async {
        final List<String> path = request.url.pathSegments.skip(2).toList(); // after tasks/v1
        calls.add("${request.method} ${path.join("/")}");
        if (request.headers["Authorization"] != "Bearer $acceptedToken") return http.Response("", 401);
        final Map<String, dynamic>? body =
            request.body.isEmpty ? null : jsonDecode(request.body) as Map<String, dynamic>;
        http.Response json(Object value) => http.Response.bytes(utf8.encode(jsonEncode(value)), 200);
        final http.Response notFound = http.Response('{"error":"not found"}', 404);

        if (path.length >= 3 && path[0] == "users") { // users/@me/lists[/id]
            if (path.length == 4) {
                return lists.containsKey(path[3]) ? json({"id": path[3], "title": lists[path[3]]}) : notFound;
            }
            if (request.method == "POST") {
                final String id = addList(body!["title"] as String);
                return json({"id": id, "title": lists[id]});
            }
            return json({"items": [for (final e in lists.entries) {"id": e.key, "title": e.value}]});
        }
        // lists/{list}/tasks[/{task}]
        final Map<String, Map<String, dynamic>>? list = tasks[path[1]];
        if (list == null) return notFound;
        if (path.length == 3) {
            final String id = "task${_nextId++}";
            list[id] = {...body!, "id": id};
            return json(list[id]!);
        }
        final String taskId = path[3];
        if (!list.containsKey(taskId)) return notFound;
        if (request.method == "DELETE") {
            list.remove(taskId);
            return http.Response("", 204);
        }
        list[taskId] = {...list[taskId]!, ...body!}; // PATCH
        return json(list[taskId]!);
    });
}

late FakeTasksServer server;
late FakeAccount account;
late GoogleTasksSync sync;

AppData _data() {
    final BalanceModel balance = BalanceModel(currentBalance: 1000.0, lastUpdated: today);
    balance.expenses.addAll([
        ExpenseModel(name: "Rent", amount: 1200.0, startDate: day(14), frequency: 1,
            frequencyUnits: FrequencyUnit.monthly),
        ExpenseModel(name: "Gym", amount: 40.0, startDate: day(3), frequency: 1,
            frequencyUnits: FrequencyUnit.monthly, endDate: DateTime(2027, 3, 31)),
        CreditModel(name: "Visa", amount: 300.5, startDate: day(5), frequency: 1,
            frequencyUnits: FrequencyUnit.monthly, creditLimit: 2000.0),
    ]);
    final IncomeStreamModel job = IncomeStreamModel(name: "Job", amount: 2400.0, startDate: day(-7),
        frequency: 2, frequencyUnits: FrequencyUnit.weekly);
    balance.incomeStreams.add(job);
    balance.activeIncome = job;
    return AppData(balance: balance, tasksSyncEnabled: true);
}

Future<TasksSyncResult> _sync(AppData data, {DateTime? on}) => sync.reconcile(data, today: on ?? today);

void main() {
    setUp(() {
        server = FakeTasksServer();
        account = FakeAccount();
        sync = GoogleTasksSync(GoogleTasksApi(account, server.client));
    });

    test("the first sync makes a Bujit list with a task for each expense, card and stream", () async {
        final AppData data = _data();
        final TasksSyncResult result = await _sync(data);

        expect(result.ok, isTrue);
        expect(result.created, 4);
        expect(server.lists.values, ["Bujit"]);
        expect(data.tasksListId, server.lists.keys.single);

        final rent = server.taskTitled("Rent");
        expect(rent["title"], "Rent — \$1200.00");
        expect(rent["notes"], "Every 1 month\nBujit Budget Expense");
        expect(rent["due"], "2026-10-15T00:00:00.000Z");
        expect(rent["status"], "needsAction");
        expect(server.taskTitled("Gym")["notes"], "Every 1 month until 2027-03-31\nBujit Budget Expense");
        expect(server.taskTitled("Visa")["title"], "Visa — \$300.50");
        expect(server.taskTitled("Visa")["due"], "2026-10-06T00:00:00.000Z");
        final paycheck = server.taskTitled("Paycheck: Job");
        expect(paycheck["title"], "Paycheck: Job — \$2400.00");
        expect(paycheck["due"], "2026-10-08T00:00:00.000Z"); // next payday on or after today
        expect(paycheck["notes"], "Every 2 weeks\nBujit Income Stream");

        // Each item knows its task, and what was sent is remembered.
        expect(data.balance.expenses.map((e) => e.googleTaskId), everyElement(isNotNull));
        expect(data.balance.incomeStreams.single.googleTaskId, isNotNull);
        expect(data.syncedTasks, hasLength(4));
    });

    test("syncing again with nothing changed sends nothing but the list check", () async {
        final AppData data = _data();
        await _sync(data);
        server.calls.clear();

        final TasksSyncResult result = await _sync(data);

        expect(result.summary(), "Up to date");
        expect(server.calls, ["GET users/@me/lists/${data.tasksListId}"]);
    });

    test("editing an expense updates just its task", () async {
        final AppData data = _data();
        await _sync(data);
        server.calls.clear();
        final rent = data.balance.expenses[0];
        rent.amount = 1250.0;

        final TasksSyncResult result = await _sync(data);

        expect(result.updated, 1);
        expect(server.calls.where((c) => c.startsWith("PATCH")), ["PATCH lists/${data.tasksListId}/tasks/${rent.googleTaskId}"]);
        expect(server.taskTitled("Rent")["title"], "Rent — \$1250.00");
    });

    test("an edited copy from a dialog keeps its task", () async {
        final AppData data = _data();
        await _sync(data);
        final old = data.balance.expenses[0] as ExpenseModel;
        data.balance.expenses[0] = ExpenseModel(name: "Rent", amount: 1300.0, startDate: old.startDate,
            frequency: 1, frequencyUnits: FrequencyUnit.monthly, googleTaskId: old.googleTaskId);

        final TasksSyncResult result = await _sync(data);

        expect(result.created, 0);
        expect(result.updated, 1);
        expect(server.onlyList, hasLength(4));
    });

    test("deleting an expense or stream deletes its task", () async {
        final AppData data = _data();
        await _sync(data);
        data.balance.expenses.removeAt(1); // Gym
        data.balance.incomeStreams.clear();

        final TasksSyncResult result = await _sync(data);

        expect(result.deleted, 2);
        expect(server.onlyList.values.map((t) => t["title"]), ["Rent — \$1200.00", "Visa — \$300.50"]);
        expect(data.syncedTasks, hasLength(2));
    });

    test("due dates move forward as they pass", () async {
        final AppData data = _data();
        await _sync(data);
        data.balance.makeRecent(today: day(20)); // Rent (Oct 15) was paid

        final TasksSyncResult result = await _sync(data, on: day(20));

        expect(server.taskTitled("Rent")["due"], "2026-11-15T00:00:00.000Z");
        expect(server.taskTitled("Paycheck")["due"], "2026-10-22T00:00:00.000Z");
        expect(result.updated, greaterThanOrEqualTo(2));
    });

    test("an ended expense's task is removed", () async {
        final AppData data = _data();
        await _sync(data);
        data.balance.makeRecent(today: DateTime(2027, 4, 5)); // Gym ended Mar 31

        await _sync(data, on: DateTime(2027, 4, 5));

        expect(server.onlyList.values.where((t) => (t["title"] as String).startsWith("Gym")), isEmpty);
        expect(data.balance.expenses[1].googleTaskId, isNull);
    });

    test("turning off the reminder leaves the task without a due date", () async {
        final AppData data = _data();
        data.balance.expenses[0].remindInTasks = false;

        await _sync(data);

        expect(server.taskTitled("Rent").containsKey("due"), isFalse);
    });

    test("a task deleted in Google Tasks is made again", () async {
        final AppData data = _data();
        await _sync(data);
        final String oldId = data.balance.expenses[0].googleTaskId!;
        server.onlyList.remove(oldId);
        data.balance.expenses[0].amount = 1000.0; // Next sync sends Rent again

        final TasksSyncResult result = await _sync(data);

        expect(result.ok, isTrue);
        expect(result.created, 1);
        expect(data.balance.expenses[0].googleTaskId, isNot(oldId));
        expect(data.syncedTasks.containsKey(oldId), isFalse);
        expect(server.taskTitled("Rent")["title"], "Rent — \$1000.00");
    });

    test("if the Bujit list was deleted, a new one gets every task", () async {
        final AppData data = _data();
        await _sync(data);
        final String oldList = data.tasksListId!;
        server.lists.remove(oldList);
        server.tasks.remove(oldList);

        final TasksSyncResult result = await _sync(data);

        expect(result.created, 4);
        expect(data.tasksListId, isNot(oldList));
        expect(server.onlyList, hasLength(4));
    });

    test("an existing Bujit list (e.g. the Java app's) is reused", () async {
        final String javaList = server.addList("Bujit");
        server.addList("Groceries");

        await _sync(_data());

        expect(server.tasks[javaList], hasLength(4));
        expect(server.lists, hasLength(2));
    });

    test("an expired token is replaced and the request retried", () async {
        final AppData data = _data();
        server.acceptedToken = "token-2";

        final TasksSyncResult result = await _sync(data);

        expect(result.ok, isTrue);
        expect(account.token, 2);
        expect(server.onlyList, hasLength(4));
    });

    test("without permission nothing changes and the error is reported", () async {
        final AppData data = _data();
        account.signedIn = false;

        final TasksSyncResult result = await _sync(data);

        expect(result.ok, isFalse);
        expect(result.summary(), "Sync failed: Google Tasks needs permission again");
        expect(data.balance.expenses.map((e) => e.googleTaskId), everyElement(isNull));
        expect(server.calls, isEmpty);
    });

    test("disconnecting can remove Bujit's tasks, and forgets them either way", () async {
        final AppData data = _data();
        await _sync(data);
        server.onlyList["mine"] = {"id": "mine", "title": "My own task"};

        await sync.disconnect(data, removeTasks: true);

        expect(server.onlyList.keys, ["mine"]); // The user's own task stays
        expect(data.tasksSyncEnabled, isFalse);
        expect(data.tasksListId, isNull);
        expect(data.syncedTasks, isEmpty);
        expect(data.balance.expenses.map((e) => e.googleTaskId), everyElement(isNull));
        expect(account.disconnected, isTrue);
    });

    test("disconnecting can keep the tasks", () async {
        final AppData data = _data();
        await _sync(data);

        await sync.disconnect(data, removeTasks: false);

        expect(server.onlyList, hasLength(4));
        expect(data.syncedTasks, isEmpty);
    });

    group("AppState", () {
        test("changes sync while sync is on, and not while it's off", () async {
            final AppData data = _data();
            final AppState state = AppState(data)..tasks = sync;
            await state.changed(); // Syncs as of the real today
            await state.syncTasks();
            final int synced = server.onlyList.length;
            expect(synced, greaterThanOrEqualTo(3));
            expect(state.lastTasksSync!.ok, isTrue);

            data.tasksSyncEnabled = false;
            data.balance.expenses.clear();
            await state.changed();
            await state.syncTasks();
            expect(server.onlyList, hasLength(synced));
        });

        test("a change during a sync gets one more sync after it", () async {
            final AppData data = _data();
            final AppState state = AppState(data)..tasks = sync;
            final Future<void> first = state.syncTasks(today: today);
            data.balance.expenses.removeAt(0); // While the first sync is in flight
            await state.changed();
            await first;

            expect(server.onlyList.values.where((t) => (t["title"] as String).startsWith("Rent")), isEmpty);
            expect(state.tasksSyncing, isFalse);
        });

        test("connecting turns sync on and syncs", () async {
            final AppData data = _data()..tasksSyncEnabled = false;
            final AppState state = AppState(data)..tasks = sync;

            expect(await state.connectTasks(), isTrue);
            await state.syncTasks();

            expect(data.tasksSyncEnabled, isTrue);
            expect(data.tasksAccount, "me@example.com");
            expect(server.onlyList, isNotEmpty);
        });

        test("disconnecting waits for a running sync, then removes everything", () async {
            final AppData data = _data();
            final AppState state = AppState(data)..tasks = sync;
            state.syncTasks();

            await state.disconnectTasks(removeTasks: true);

            expect(server.onlyList, isEmpty);
            expect(data.tasksSyncEnabled, isFalse);
        });
    });

    group("Settings", () {
        testWidgets("shows sync as not set up without client IDs", (tester) async {
            final AppState state = AppState(_data()..tasksSyncEnabled = false..tutorialSeen = true);
            await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: state)));

            expect(find.text("Not set up in this build"), findsOneWidget);
        });

        testWidgets("turning the switch on connects and syncs", (tester) async {
            final AppData data = _data()..tasksSyncEnabled = false..tutorialSeen = true;
            final AppState state = AppState(data)..tasks = sync;
            await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: state)));

            await tester.tap(find.text("Sync to Google Tasks"));
            await tester.pumpAndSettle();

            expect(data.tasksSyncEnabled, isTrue);
            expect(find.textContaining("Connected as me@example.com"), findsOneWidget);
            expect(find.text("Sync now"), findsOneWidget);
            expect(server.onlyList, isNotEmpty);
        });
    });
}
