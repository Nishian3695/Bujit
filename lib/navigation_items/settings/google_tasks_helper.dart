// Mirrors NavigationItems/Settings/GoogleTasksHelper.java in the original Java app:
// keeps a "Bujit" list in Google Tasks with one task per expense, credit card and
// income stream, due on its next date (so Google Tasks reminds you).
//
// Unlike the Java app, which called the API from each dialog, syncing here is a
// reconcile: compare the data with what was last sent (AppData.syncedTasks),
// then create, update and delete tasks to match. AppState runs it after every
// change and at launch, so edits from any screen (or a CSV import) sync, and due
// dates move forward as they pass.
//
// Signing in lives behind TasksAccount (google_tasks_account.dart), so this file
// is plain Dart and testable against a fake server.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../storage_management/app_data_store.dart';
import '../../utils/date_utils.dart';
import '../../utils/frequency_unit.dart';
import '../../utils/projector.dart';
import '../expense_activity/credit_model.dart';
import '../expense_activity/expense_item.dart';
import '../income_streams/income_stream_model.dart';

// The signed-in Google account that grants access to Google Tasks.
abstract class TasksAccount {
    // False when this build has no OAuth client IDs (see lib/config/google_config.dart).
    bool get isConfigured;
    // Asks the user to sign in and allow Google Tasks; returns the account's
    // email, or null if they cancelled. Throws TasksAuthException on failure.
    Future<String?> connect();
    // A current access token, without asking the user. Throws TasksAuthException
    // when permission must be granted again (connect).
    Future<String> accessToken();
    // Forgets a token the API rejected, so the next accessToken() gets a new one.
    Future<void> invalidate(String token);
    // Signs out and revokes the app's access.
    Future<void> disconnect();
}

class TasksAuthException implements Exception {
    final String message;
    const TasksAuthException(this.message);
    @override
    String toString() => message;
}

class TasksApiException implements Exception {
    final int statusCode;
    final String body;
    const TasksApiException(this.statusCode, this.body);
    bool get isNotFound => statusCode == 404;
    @override
    String toString() => "Google Tasks error $statusCode: $body";
}

// Where synced tasks live: Google Tasks (GoogleTasksApi) or, on iPhone, Apple
// Reminders (AppleRemindersStore). TasksSync does the same reconcile against
// either. Tasks are JSON-like maps in Google Tasks' shape ("title", "notes",
// "status", and "due" as "YYYY-MM-DDT00:00:00.000Z"). A missing list or task is
// a TasksApiException with isNotFound.
abstract class TaskStore {
    TasksAccount get account;
    Future<bool> listExists(String listId);
    Future<String?> findList(String title); // The first list titled [title], or null
    Future<String> insertList(String title);
    Future<String> insertTask(String listId, Map<String, dynamic> task);
    Future<void> patchTask(String listId, String taskId, Map<String, dynamic> task);
    Future<void> deleteTask(String listId, String taskId); // Already gone counts as deleted
}

// The few Google Tasks REST calls the app needs (https://developers.google.com/tasks/reference/rest).
class GoogleTasksApi implements TaskStore {
    static const String _base = "https://tasks.googleapis.com/tasks/v1";

    @override
    final TasksAccount account;
    final http.Client _client;

    GoogleTasksApi(this.account, [http.Client? client]) : _client = client ?? http.Client();

    // Sends a request with the account's token, retrying once with a fresh token
    // if it was rejected. Returns the decoded JSON body (null when empty).
    Future<Map<String, dynamic>?> _send(String method, String path, [Map<String, dynamic>? body]) async {
        String token = await account.accessToken();
        http.Response response = await _request(method, path, token, body);
        if (response.statusCode == 401) {
            await account.invalidate(token);
            token = await account.accessToken();
            response = await _request(method, path, token, body);
        }
        if (response.statusCode >= 300) throw TasksApiException(response.statusCode, response.body);
        // Always UTF-8 (JSON's encoding), whatever charset the response names.
        final String text = utf8.decode(response.bodyBytes);
        return text.isEmpty ? null : jsonDecode(text) as Map<String, dynamic>;
    }

    Future<http.Response> _request(String method, String path, String token, Map<String, dynamic>? body) {
        final http.Request request = http.Request(method, Uri.parse("$_base$path"))
            ..headers["Authorization"] = "Bearer $token";
        if (body != null) {
            request.headers["Content-Type"] = "application/json; charset=utf-8";
            request.body = jsonEncode(body);
        }
        return _client.send(request).then(http.Response.fromStream);
    }

    static String _id(String id) => Uri.encodeComponent(id);

    @override
    Future<bool> listExists(String listId) async {
        try {
            await _send("GET", "/users/@me/lists/${_id(listId)}");
            return true;
        } on TasksApiException catch (e) {
            if (e.isNotFound) return false;
            rethrow;
        }
    }

    // The id of the user's first task list titled [title], or null.
    @override
    Future<String?> findList(String title) async {
        final Map<String, dynamic>? json = await _send("GET", "/users/@me/lists?maxResults=100");
        for (final dynamic item in (json?["items"] as List<dynamic>? ?? const [])) {
            if (item["title"] == title) return item["id"] as String;
        }
        return null;
    }

    @override
    Future<String> insertList(String title) async =>
        (await _send("POST", "/users/@me/lists", {"title": title}))!["id"] as String;

    @override
    Future<String> insertTask(String listId, Map<String, dynamic> task) async =>
        (await _send("POST", "/lists/${_id(listId)}/tasks", task))!["id"] as String;

    // Replaces the given fields of a task (others, like notes the user added, stay).
    @override
    Future<void> patchTask(String listId, String taskId, Map<String, dynamic> task) =>
        _send("PATCH", "/lists/${_id(listId)}/tasks/${_id(taskId)}", task);

    // Deletes a task; one that's already gone counts as deleted.
    @override
    Future<void> deleteTask(String listId, String taskId) async {
        try {
            await _send("DELETE", "/lists/${_id(listId)}/tasks/${_id(taskId)}");
        } on TasksApiException catch (e) {
            if (!e.isNotFound) rethrow;
        }
    }
}

// What one sync did, for the Settings screen.
class TasksSyncResult {
    int created = 0;
    int updated = 0;
    int deleted = 0;
    int failed = 0;
    String? error; // The last failure's message

    bool get ok => failed == 0 && error == null;

    String summary() {
        if (!ok && created + updated + deleted == 0) return "Sync failed: $error";
        final String changes = (created + updated + deleted == 0)
            ? "Up to date"
            : "$created added, $updated updated, $deleted removed";
        return ok ? changes : "$changes; $failed failed: $error";
    }
}

class TasksSync {
    static const String listTitle = "Bujit"; // Same list as the Java app

    final TaskStore api;
    TasksSync(this.api);

    TasksAccount get account => api.account;

    // Makes the "Bujit" list match [data] as of [today] (default: now). Sets each
    // item's googleTaskId and updates data.syncedTasks; the caller saves. One
    // failing item doesn't stop the rest.
    Future<TasksSyncResult> reconcile(AppData data, {DateTime? today}) async {
        final TasksSyncResult result = TasksSyncResult();
        final DateTime day = dateOnly(today ?? todayDate());
        try {
            final String listId = await _ensureList(data);
            final Set<String> keep = {};
            for (final _Synced item in _items(data, day)) {
                try {
                    final String? id = await _push(listId, item, data, result);
                    if (id != null) keep.add(id);
                } catch (e) {
                    result.failed++;
                    result.error = "$e";
                    final String? id = item.taskId;
                    if (id != null) keep.add(id); // Not orphaned: try again next sync
                }
            }
            // Tasks whose expense or stream was deleted (or has ended).
            for (final String id in data.syncedTasks.keys.toList()) {
                if (keep.contains(id)) continue;
                try {
                    await api.deleteTask(listId, id);
                    data.syncedTasks.remove(id);
                    result.deleted++;
                } catch (e) {
                    result.failed++;
                    result.error = "$e";
                }
            }
        } catch (e) {
            result.error = "$e"; // Signing in or reaching the list failed
        }
        return result;
    }

    // Creates or updates [item]'s task as needed; returns its task id.
    Future<String?> _push(String listId, _Synced item, AppData data, TasksSyncResult result) async {
        final String? id = item.taskId;
        final String json = jsonEncode(item.task);
        if (id != null && data.syncedTasks[id] == json) return id; // Unchanged
        if (id != null) {
            try {
                await api.patchTask(listId, id, item.task);
                data.syncedTasks[id] = json;
                result.updated++;
                return id;
            } on TasksApiException catch (e) {
                if (!e.isNotFound) rethrow;
                data.syncedTasks.remove(id); // Deleted in Google Tasks: make a new one
            }
        }
        final String created = await api.insertTask(listId, item.task);
        item.taskId = created;
        data.syncedTasks[created] = json;
        result.created++;
        return created;
    }

    // The saved list if it still exists, else an existing "Bujit" list (e.g. the
    // Java app's), else a new one.
    Future<String> _ensureList(AppData data) async {
        final String? saved = data.tasksListId;
        if (saved != null) {
            if (await api.listExists(saved)) return saved;
            _forgetTasks(data); // The list was deleted, and its tasks with it
        }
        final String listId = await api.findList(listTitle) ?? await api.insertList(listTitle);
        data.tasksListId = listId;
        return listId;
    }

    // Turns sync off. With [removeTasks], first deletes every task the app made
    // (best effort: the account may already be unreachable).
    Future<void> disconnect(AppData data, {required bool removeTasks}) async {
        final String? listId = data.tasksListId;
        if (removeTasks && listId != null) {
            final Set<String> ids = {
                ...data.syncedTasks.keys,
                for (final ExpenseItem e in data.balance.expenses) ?e.googleTaskId,
                for (final IncomeStreamModel s in data.balance.incomeStreams) ?s.googleTaskId,
            };
            for (final String id in ids) {
                try {
                    await api.deleteTask(listId, id);
                } catch (_) {
                    break; // Can't reach Google: leave the rest
                }
            }
        }
        _forgetTasks(data);
        data.tasksListId = null;
        data.tasksSyncEnabled = false;
        data.tasksAccount = null;
        try {
            await account.disconnect();
        } catch (_) {
            // Already signed out or offline; access can also be removed from the Google account.
        }
    }

    static void _forgetTasks(AppData data) {
        data.syncedTasks.clear();
        for (final ExpenseItem e in data.balance.expenses) {
            e.googleTaskId = null;
        }
        for (final IncomeStreamModel s in data.balance.incomeStreams) {
            s.googleTaskId = null;
        }
    }

    // Everything that should have a task as of [day]. Ended expenses and one-off
    // items whose date has passed don't; clearing their ids lets reconcile delete
    // their tasks.
    static List<_Synced> _items(AppData data, DateTime day) {
        final List<_Synced> items = [];
        for (final ExpenseItem expense in data.balance.expenses) {
            final Map<String, dynamic>? task = expenseTask(expense);
            if (task == null) {
                expense.googleTaskId = null;
            } else {
                items.add(_Synced(task, () => expense.googleTaskId, (id) => expense.googleTaskId = id));
            }
        }
        for (final IncomeStreamModel stream in data.balance.incomeStreams) {
            final Map<String, dynamic>? task = incomeTask(stream, day);
            if (task == null) {
                stream.googleTaskId = null;
            } else {
                items.add(_Synced(task, () => stream.googleTaskId, (id) => stream.googleTaskId = id));
            }
        }
        return items;
    }

    // The task for an expense or card, due on its next unpaid date (when
    // remindInTasks), or null once it has no dates left. Titles and notes follow
    // the Java app's.
    static Map<String, dynamic>? expenseTask(ExpenseItem expense) {
        final DateTime next = expense.currentDueDate;
        if (expense.hasEnded || !next.isBefore(Projector.never)) return null;
        final DateTime? end = expense.endDate;
        final String notes = expense is CreditModel
            ? "Credit card balance, due monthly\nBujit Credit Card"
            : "${describeFrequency(expense.frequency, expense.frequencyUnits, days: expense.monthDays,
                weekendToFriday: expense.weekendToFriday)}"
                "${end == null ? "" : " until ${_isoDate(end)}"}\nBujit Budget Expense";
        return {
            "title": "${expense.name} — \$${expense.amount.toStringAsFixed(2)}",
            "notes": notes,
            "status": "needsAction", // Reopens a task ticked off for an earlier date
            if (expense.remindInTasks) "due": _dueDate(next),
        };
    }

    // The task for an income stream, due on its next payday on or after [day],
    // or null when it has none left (a one-off that already came).
    static Map<String, dynamic>? incomeTask(IncomeStreamModel stream, DateTime day) {
        final DateTime next = stream.paydayAfter(addDays(day, -1));
        if (!next.isBefore(Projector.never)) return null;
        return {
            "title": "Paycheck: ${stream.name} — \$${stream.amount.toStringAsFixed(2)}",
            "notes": "${stream.displayString()}\nBujit Income Stream",
            "status": "needsAction",
            "due": _dueDate(next),
        };
    }

    static String _isoDate(DateTime date) =>
        "${date.year.toString().padLeft(4, "0")}-${date.month.toString().padLeft(2, "0")}"
        "-${date.day.toString().padLeft(2, "0")}";

    // Google Tasks keeps only the date part of "due" (RFC 3339).
    static String _dueDate(DateTime date) => "${_isoDate(date)}T00:00:00.000Z";
}

// An expense or stream as reconcile sees it: its task body and its task id.
class _Synced {
    final Map<String, dynamic> task;
    final String? Function() _getId;
    final void Function(String?) _setId;
    _Synced(this.task, this._getId, this._setId);

    String? get taskId => _getId();
    set taskId(String? id) => _setId(id);
}
