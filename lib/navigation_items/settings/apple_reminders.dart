// Task sync with Apple Reminders on iPhone: the same "Bujit" list and the same
// reconcile as Google Tasks (TasksSync), kept in Reminders through Apple's
// EventKit, which syncs it over iCloud to the user's other Apple devices. No
// account to sign in to: the app only needs permission to use Reminders.
//
// The native side is RemindersChannel in ios/Runner/AppDelegate.swift, on the
// "bujit/reminders" method channel. Reminders get the task's title and notes,
// and its due date as an all-day due date (iOS reminds at the time set in
// Settings > Reminders).
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'google_tasks_helper.dart';

const MethodChannel _channel = MethodChannel("bujit/reminders");

// Permission to use Reminders, standing in for a signed-in account.
class RemindersAccess implements TasksAccount {
    static const String label = "Apple Reminders"; // Shown where Google Tasks shows the email

    @override
    bool get isConfigured => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    // Asks for Reminders access (iOS asks once; after a refusal it's only in the
    // Settings app). Returns the label, or throws TasksAuthException if refused.
    @override
    Future<String?> connect() async {
        final bool granted = await _channel.invokeMethod<bool>("requestAccess") ?? false;
        if (!granted) {
            throw const TasksAuthException(
                "Bujit can't use Reminders. Allow it in the Settings app: Bujit > Reminders > Full Access.");
        }
        return label;
    }

    // No token: access is checked when each change is saved.
    @override
    Future<String> accessToken() async => "";

    @override
    Future<void> invalidate(String token) async {}

    // Nothing to sign out of; access can be removed in the Settings app.
    @override
    Future<void> disconnect() async {}
}

class AppleRemindersStore implements TaskStore {
    @override
    final TasksAccount account;
    AppleRemindersStore([TasksAccount? account]) : account = account ?? RemindersAccess();

    // Runs a channel call, turning the native side's errors into the exceptions
    // TasksSync expects ("not_found" is a missing list or reminder).
    Future<T?> _call<T>(String method, Map<String, dynamic> args) async {
        try {
            return await _channel.invokeMethod<T>(method, args);
        } on PlatformException catch (e) {
            if (e.code == "not_found") throw TasksApiException(404, e.message ?? "Not found");
            if (e.code == "denied") throw TasksAuthException(e.message ?? "Reminders access was turned off");
            throw TasksApiException(500, e.message ?? e.code);
        }
    }

    @override
    Future<bool> listExists(String listId) async => await _call<bool>("listExists", {"listId": listId}) ?? false;

    @override
    Future<String?> findList(String title) => _call<String>("findList", {"title": title});

    @override
    Future<String> insertList(String title) async => (await _call<String>("insertList", {"title": title}))!;

    @override
    Future<String> insertTask(String listId, Map<String, dynamic> task) async =>
        (await _call<String>("insertTask", {"listId": listId, "task": _forNative(task)}))!;

    @override
    Future<void> patchTask(String listId, String taskId, Map<String, dynamic> task) =>
        _call<void>("patchTask", {"listId": listId, "taskId": taskId, "task": _forNative(task)});

    @override
    Future<void> deleteTask(String listId, String taskId) =>
        _call<void>("deleteTask", {"listId": listId, "taskId": taskId});

    // Google Tasks' task shape as the native side reads it: "due" as "YYYY-MM-DD"
    // (date only), and done or not.
    static Map<String, dynamic> _forNative(Map<String, dynamic> task) {
        final Object? due = task["due"];
        return {
            "title": task["title"],
            "notes": task["notes"],
            "completed": task["status"] == "completed",
            if (due is String) "due": due.substring(0, 10),
        };
    }
}
