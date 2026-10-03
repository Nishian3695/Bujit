import EventKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BujitReminders") {
      RemindersChannel.register(with: registrar)
    }
  }
}

// Apple Reminders for task sync (lib/navigation_items/settings/apple_reminders.dart):
// a "Bujit" list and one reminder per expense and paycheck, through EventKit, on
// the "bujit/reminders" channel. Lists and reminders are identified by EventKit's
// calendarIdentifier and calendarItemIdentifier. A missing one is a "not_found"
// error; a call without Reminders access is "denied".
class RemindersChannel {
  private let store = EKEventStore()

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "bujit/reminders", binaryMessenger: registrar.messenger())
    let instance = RemindersChannel()
    channel.setMethodCallHandler { call, result in instance.handle(call, result: result) }
    // The handler keeps the instance (and its event store) alive.
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    if call.method == "requestAccess" {
      requestAccess(result)
      return
    }
    guard hasAccess() else {
      result(FlutterError(code: "denied", message: "Reminders access was turned off", details: nil))
      return
    }
    do {
      switch call.method {
      case "listExists":
        result(store.calendar(withIdentifier: args["listId"] as? String ?? "") != nil)
      case "findList":
        let title = args["title"] as? String ?? ""
        result(store.calendars(for: .reminder).first { $0.title == title }?.calendarIdentifier)
      case "insertList":
        result(try insertList(title: args["title"] as? String ?? "Bujit"))
      case "insertTask":
        let list = try calendar(args["listId"] as? String)
        let reminder = EKReminder(eventStore: store)
        reminder.calendar = list
        apply(args["task"] as? [String: Any] ?? [:], to: reminder)
        try store.save(reminder, commit: true)
        result(reminder.calendarItemIdentifier)
      case "patchTask":
        guard let reminder = store.calendarItem(withIdentifier: args["taskId"] as? String ?? "") as? EKReminder else {
          throw RemindersError.notFound("No such reminder")
        }
        apply(args["task"] as? [String: Any] ?? [:], to: reminder)
        try store.save(reminder, commit: true)
        result(nil)
      case "deleteTask":
        // Already gone counts as deleted.
        if let reminder = store.calendarItem(withIdentifier: args["taskId"] as? String ?? "") as? EKReminder {
          try store.remove(reminder, commit: true)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch RemindersError.notFound(let message) {
      result(FlutterError(code: "not_found", message: message, details: nil))
    } catch {
      result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
    }
  }

  private enum RemindersError: Error { case notFound(String) }

  private func hasAccess() -> Bool {
    let status = EKEventStore.authorizationStatus(for: .reminder)
    if #available(iOS 17.0, *) { return status == .fullAccess }
    return status == .authorized
  }

  private func requestAccess(_ result: @escaping FlutterResult) {
    let done: (Bool, Error?) -> Void = { granted, _ in DispatchQueue.main.async { result(granted) } }
    if #available(iOS 17.0, *) {
      store.requestFullAccessToReminders(completion: done)
    } else {
      store.requestAccess(to: .reminder, completion: done)
    }
  }

  private func calendar(_ id: String?) throws -> EKCalendar {
    guard let id = id, let list = store.calendar(withIdentifier: id) else {
      throw RemindersError.notFound("No such list")
    }
    return list
  }

  // A new reminders list in the same account (iCloud, usually) as the default one.
  private func insertList(title: String) throws -> String {
    let list = EKCalendar(for: .reminder, eventStore: store)
    list.title = title
    guard let source = store.defaultCalendarForNewReminders()?.source
      ?? store.sources.first(where: { $0.sourceType == .calDAV || $0.sourceType == .local }) else {
      throw RemindersError.notFound("No account to keep reminders in")
    }
    list.source = source
    try store.saveCalendar(list, commit: true)
    return list.calendarIdentifier
  }

  // Title, notes, done or not, and the due date as an all-day date ("YYYY-MM-DD",
  // or no due date when absent).
  private func apply(_ task: [String: Any], to reminder: EKReminder) {
    reminder.title = task["title"] as? String ?? ""
    reminder.notes = task["notes"] as? String
    reminder.isCompleted = task["completed"] as? Bool ?? false
    if let due = task["due"] as? String {
      let parts = due.split(separator: "-").compactMap { Int($0) }
      if parts.count == 3 {
        reminder.dueDateComponents = DateComponents(calendar: Calendar.current, year: parts[0], month: parts[1], day: parts[2])
        return
      }
    }
    reminder.dueDateComponents = nil
  }
}
