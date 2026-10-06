// The data inside a backup (BackupCrypto encrypts it): the Java app's
// StorageManager JSON (toJson/fromJson), so Java backups restore here -- the way
// to move from the Java app -- and backups made here use the same fields, plus a
// "flutter" section with what the Java app doesn't have.
//
// Mapping notes:
//   - Java's expense "date" is its next unpaid due date (currentDueDate here);
//     its schedule is anchored on "anchorDay". Here the start date anchors the
//     schedule, so a start date whose day or step doesn't line up with the due
//     date (Java kept the original start date after re-dating) is replaced by
//     one that does: the due date itself, or an earlier date on the anchor day.
//   - Java units are ChronoUnit names (expenses) or 0-3 = days/weeks/months/years
//     (streams); biweekly here is written as 2x weeks.
//   - Java's "incomeCreditedThrough" is lastUpdated: paychecks through it are in the balance.
//   - Which manual accounts count toward the balance lived in Java's preferences,
//     not its backups, so they don't count after restoring a Java backup.
//   - Bank links (Plaid) stay on the device that made them: access tokens aren't in
//     backups, so after restoring, what a linked account paid for or set the amount
//     of is paid from the balance and keeps its last amount until linked again.
import 'dart:convert';
import '../../navigation_items/banking/manual_account_model.dart';
import '../../navigation_items/expense_activity/balance_model.dart';
import '../../navigation_items/expense_activity/credit_model.dart';
import '../../navigation_items/expense_activity/expense_item.dart';
import '../../navigation_items/expense_activity/expense_model.dart';
import '../../navigation_items/expense_activity/funding_source.dart';
import '../../navigation_items/income_streams/income_stream_model.dart';
import '../../navigation_items/single_events/single_event_model.dart';
import '../../utils/category_manager.dart';
import '../../utils/date_utils.dart';
import '../../utils/frequency_unit.dart';
import '../../utils/projector.dart';
import '../app_data_store.dart';
import '../balance_history.dart';
import '../period_snapshot.dart';

class BackupJson {
    // ── Writing ─────────────────────────────────────────────────────────────

    static String encode(AppData data) {
        final BalanceModel balance = data.balance;
        final IncomeStreamModel? active = balance.activeIncome;
        final (int, String) checkPeriod = active == null
            ? (1, "WEEKS")
            : _javaUnit(active.frequency, active.frequencyUnits);
        final DateTime current = balance.payday(0, today: balance.lastUpdated);
        return jsonEncode({
            "currentBalance": balance.currentBalance,
            "averageCheck": active?.amount ?? 0.0,
            "checkFrequency": checkPeriod.$1,
            "checkFrequencyTag": checkPeriod.$2,
            "curCheckDate": _iso(current),
            "nextCheckDate": _iso(balance.payday(1, today: balance.lastUpdated)),
            "lastOpenedDate": _iso(balance.lastUpdated),
            "incomeCreditedThrough": _iso(balance.lastUpdated),
            "expenseList": [for (final ExpenseItem e in balance.expenses) _expenseToJson(e)],
            "incomeStreamList": [for (final IncomeStreamModel s in balance.incomeStreams) _streamToJson(s, active)],
            "periodSnapshots": [
                for (final PeriodSnapshot s in balance.snapshots)
                    {"periodStart": _iso(s.start), "incomeTotal": s.totalIncome, "expenseTotal": s.totalExpenses},
            ],
            "categoryList": data.categories,
            "singleEventList": [
                for (int i = 0; i < data.singleEvents.length; i++) _eventToJson(data.singleEvents[i], i),
            ],
            "manualBalanceAddition": balance.balanceExtra,
            "manualAccountList": [
                for (final ManualAccountModel a in balance.manualAccounts)
                    {"id": a.id, "name": a.name, "accountType": a.accountType, "balance": a.balance},
            ],
            "flutter": {
                "version": 1,
                "countedAccountIds": [for (final a in balance.manualAccounts) if (a.countsTowardBalance) a.id],
                "includeNextCheck": data.includeNextCheck,
                "singleEventExpiryDays": data.singleEventExpiryDays,
                "useCommaSeparators": data.useCommaSeparators,
                "balanceHistory": [
                    for (final BalanceHistoryEntry h in balance.history)
                        {"date": _iso(h.date), "key": h.key, "name": h.name, "amount": h.amount},
                ],
            },
        });
    }

    static Map<String, Object?> _expenseToJson(ExpenseItem e) {
        final (int, String) unit = _javaUnit(e.frequency, e.frequencyUnits);
        final String cost = e.amount.toStringAsFixed(2);
        return {
            "name": e.name,
            "cost": cost,
            "date": _iso(e.currentDueDate),
            "frequency": unit.$1,
            "frequencyTag": unit.$2,
            "shownDate": _iso(e.currentDueDate),
            "shownCost": cost,
            "isCredit": e is CreditModel,
            "linkedAccountId": null,
            "linkedAccountDisplay": null,
            "googleTaskId": e.googleTaskId,
            "calendarNotif": e.remindInTasks,
            "source": switch (e.source) {
                FundingSource.balance => "BALANCE",
                FundingSource.manualAccount => "MANUAL_ACCOUNT",
                FundingSource.creditCard => "CREDIT_CARD",
                FundingSource.linkedAccount => "LINKED_ACCOUNT",
            },
            "sourceId": e.sourceId,
            "sourceDisplayName": null,
            "startDate": _iso(e.startDate),
            "endDate": e.endDate == null ? null : _iso(e.endDate!),
            "anchorDay": e.startDate.day,
            if (e is CreditModel) "creditLimit": e.creditLimit.toStringAsFixed(2),
            if (e is! CreditModel) ...{
                "isVariable": false,
                "status": -1,
                "partPaid": 0,
                "shownStatus": -1,
                "category": e.category,
            },
        };
    }

    static Map<String, Object?> _streamToJson(IncomeStreamModel s, IncomeStreamModel? active) {
        final (int, String) unit = _javaUnit(s.frequency, s.frequencyUnits);
        return {
            "name": s.name,
            "amount": s.amount.toStringAsFixed(2),
            "checkDate": "${s.startDate.year.toString().padLeft(4, "0")}.${_two(s.startDate.month)}.${_two(s.startDate.day)}",
            "frequency": unit.$1,
            "frequencyTag": const ["DAYS", "WEEKS", "MONTHS", "YEARS"].indexOf(unit.$2),
            "selected": identical(s, active),
            "googleTaskId": s.googleTaskId,
        };
    }

    static Map<String, Object?> _eventToJson(SingleEventModel e, int index) => {
        "id": "flutter-${e.id ?? index}",
        "name": e.name,
        "amount": e.amount,
        "isDebit": e.isDebit,
        "createdDate": _iso(e.createdDate),
        "lastModifiedDate": _iso(e.lastModifiedDate),
        "appliedAmount": e.appliedAmount,
        "targetType": switch (e.target) {
            EventTarget.balance => "BALANCE",
            EventTarget.manualAccount => "MANUAL_ACCOUNT",
            EventTarget.creditCard => "CREDIT_CARD",
        },
        // Java finds cards by name in targetId too.
        if (e.target == EventTarget.manualAccount && e.targetId != null) "targetId": e.targetId,
        if (e.target == EventTarget.creditCard && e.targetName != null) "targetId": e.targetName,
        if (e.target == EventTarget.manualAccount && e.targetName != null) "targetDisplayName": e.targetName,
        if (e.target == EventTarget.creditCard && e.targetName != null) "targetDisplayName": "${e.targetName} (card)",
    };

    // A frequency in Java's terms: biweekly becomes 2x weeks.
    static (int, String) _javaUnit(int frequency, FrequencyUnit unit) => switch (unit) {
        FrequencyUnit.daily => (frequency, "DAYS"),
        FrequencyUnit.weekly => (frequency, "WEEKS"),
        FrequencyUnit.biweekly => (frequency * 2, "WEEKS"),
        FrequencyUnit.monthly => (frequency, "MONTHS"),
        FrequencyUnit.yearly => (frequency, "YEARS"),
    };

    // ── Reading ─────────────────────────────────────────────────────────────

    // Reads a backup's data JSON (from this app or the Java app). Like Java's
    // fromJson, a malformed item is skipped rather than failing the whole restore;
    // anything that isn't this JSON at all throws FormatException. The caller
    // brings the result up to today (BalanceModel.makeRecent).
    // [keepBankLinks]: keep expenses' links to bank accounts and LINKED_ACCOUNT
    // sources -- for importing the Java app's data on the same device, where its
    // bank logins come along too (see JavaMigration). A backup file has no bank
    // logins, so those fall back to the balance.
    static AppData decode(String json, {DateTime? today, bool keepBankLinks = false}) {
        final Object? root = jsonDecode(json);
        if (root is! Map<String, dynamic>) throw const FormatException("Not Bujit data");
        final DateTime day = dateOnly(today ?? todayDate());
        final Map<String, dynamic> flutter = root["flutter"] is Map<String, dynamic> ? root["flutter"] : const {};

        final BalanceModel balance = BalanceModel(
            currentBalance: _double(root["currentBalance"]),
            lastUpdated: _date(root["incomeCreditedThrough"]) ?? _date(root["lastOpenedDate"]) ?? day,
            balanceExtra: _double(root["manualBalanceAddition"]),
        );
        final Set<String> counted = {for (final id in _list(flutter["countedAccountIds"])) if (id is String) id};
        for (final Map<String, dynamic> o in _objects(root["manualAccountList"])) {
            final String name = _string(o["name"]) ?? "";
            if (name.isEmpty) continue;
            final String? id = _string(o["id"]);
            balance.manualAccounts.add(ManualAccountModel(
                id: id == null || id.isEmpty ? null : id,
                name: name,
                accountType: _string(o["accountType"]) ?? "Other",
                balance: _double(o["balance"]),
                countsTowardBalance: counted.contains(id),
            ));
        }
        for (final Map<String, dynamic> o in _objects(root["expenseList"])) {
            final ExpenseItem? item = _expenseFromJson(o, day, keepBankLinks);
            if (item != null) balance.expenses.add(item);
        }
        for (final Map<String, dynamic> o in _objects(root["incomeStreamList"])) {
            final IncomeStreamModel? stream = _streamFromJson(o);
            if (stream == null) continue;
            balance.incomeStreams.add(stream);
            if (o["selected"] == true && balance.activeIncome == null) balance.activeIncome = stream;
        }
        if (balance.activeIncome == null && balance.incomeStreams.isNotEmpty) {
            balance.activeIncome = balance.incomeStreams.first;
        }
        for (final Map<String, dynamic> o in _objects(root["periodSnapshots"])) {
            final DateTime? start = _date(o["periodStart"]);
            if (start == null || balance.snapshots.any((s) => s.start == start)) continue;
            balance.snapshots.add(PeriodSnapshot(
                start: start, totalIncome: _double(o["incomeTotal"]), totalExpenses: _double(o["expenseTotal"])));
        }
        final Set<String> recorded = {};
        for (final Map<String, dynamic> o in _objects(flutter["balanceHistory"])) {
            final DateTime? date = _date(o["date"]);
            final String? key = _string(o["key"]);
            if (date == null || key == null || key.isEmpty) continue;
            if (!recorded.add("${_iso(date)} $key")) continue;
            balance.history.add(BalanceHistoryEntry(
                date: date, key: key, name: _string(o["name"]) ?? "", amount: _double(o["amount"])));
        }

        final List<String> categories = [
            for (final c in _list(root["categoryList"]))
                if (c is String && c.isNotEmpty && c != otherCategory) c,
        ];
        final List<SingleEventModel> events = [];
        for (final Map<String, dynamic> o in _objects(root["singleEventList"])) {
            final SingleEventModel? event = _eventFromJson(o, day);
            if (event != null) events.add(event);
        }
        events.sort((a, b) => b.lastModifiedDate.compareTo(a.lastModifiedDate));

        return AppData(
            balance: balance,
            categories: categories.isEmpty ? defaultCategories() : categories,
            singleEvents: events,
            includeNextCheck: flutter["includeNextCheck"] == true,
            singleEventExpiryDays: flutter["singleEventExpiryDays"] is int && flutter["singleEventExpiryDays"] > 0
                ? flutter["singleEventExpiryDays"] as int
                : 30,
            useCommaSeparators: flutter["useCommaSeparators"] == true,
            tutorialSeen: true,
        );
    }

    static ExpenseItem? _expenseFromJson(Map<String, dynamic> o, DateTime today, bool keepBankLinks) {
        try {
            final String name = _string(o["name"])?.trim() ?? "";
            if (name.isEmpty) return null;
            final DateTime due = _date(o["date"]) ?? today;
            final double amount = _money(o["cost"]);
            final bool isCredit = o["isCredit"] == true;
            final (FrequencyUnit, int) unit = isCredit
                ? (FrequencyUnit.monthly, 1)
                : _unitFromChrono(_string(o["frequencyTag"]) ?? "MONTHS", _int(o["frequency"], 1));
            final DateTime start = _alignedStart(_date(o["startDate"]), due, unit.$2, unit.$1, _int(o["anchorDay"], 0));
            final (FundingSource, String?) source = switch (_string(o["source"])) {
                "MANUAL_ACCOUNT" => (FundingSource.manualAccount, _string(o["sourceId"])),
                "CREDIT_CARD" when !isCredit => (FundingSource.creditCard, _string(o["sourceId"])),
                "LINKED_ACCOUNT" when keepBankLinks => (FundingSource.linkedAccount, _string(o["sourceId"])),
                _ => (FundingSource.balance, null), // BALANCE, and LINKED_ACCOUNT without the bank login
            };
            final String? taskId = _string(o["googleTaskId"]);
            final String? linkedAccountId = keepBankLinks ? _string(o["linkedAccountId"]) : null;
            final bool remind = o["calendarNotif"] != false;
            if (isCredit) {
                return CreditModel(
                    name: name,
                    amount: amount,
                    creditLimit: _money(o["creditLimit"], fallback: 1.0),
                    startDate: start,
                    currentDueDate: due,
                    frequency: 1,
                    frequencyUnits: FrequencyUnit.monthly,
                    googleTaskId: taskId,
                    remindInTasks: remind,
                    source: source.$1,
                    sourceId: source.$2,
                    linkedAccountId: linkedAccountId,
                );
            }
            final DateTime? end = _date(o["endDate"]);
            final String category = _string(o["category"]) ?? otherCategory;
            return ExpenseModel(
                name: name,
                amount: amount,
                startDate: start,
                currentDueDate: due,
                endDate: end != null && end.isBefore(start) ? start : end,
                frequency: unit.$2,
                frequencyUnits: unit.$1,
                category: category.isEmpty ? otherCategory : category,
                googleTaskId: taskId,
                remindInTasks: remind,
                source: source.$1,
                sourceId: source.$2,
                linkedAccountId: linkedAccountId,
            );
        } catch (_) {
            return null;
        }
    }

    // A start date whose schedule goes through [due] (see the notes at the top).
    static DateTime _alignedStart(DateTime? start, DateTime due, int frequency, FrequencyUnit unit, int anchorDay) {
        bool reachesDue(DateTime from) =>
            !from.isAfter(due) &&
            Projector(baseDate: from, frequency: frequency, frequencyUnits: unit).firstOnOrAfter(due) == due;
        final bool monthsOrYears = unit == FrequencyUnit.monthly || unit == FrequencyUnit.yearly;
        if (start != null && reachesDue(start) && (!monthsOrYears || anchorDay <= 0 || start.day == anchorDay)) {
            return start;
        }
        // A month-end anchor clamped in a short month (Jan 31 -> Feb 28): start on the
        // last earlier date that has the anchor day, so later months return to it.
        if (monthsOrYears && anchorDay > due.day && frequency > 0) {
            final int months = unit == FrequencyUnit.yearly ? 12 * frequency : frequency;
            for (int k = 1; k <= 12; k++) {
                final DateTime candidate = DateTime(due.year, due.month - months * k, anchorDay);
                if (candidate.day == anchorDay && reachesDue(candidate)) return candidate;
            }
        }
        return due;
    }

    static IncomeStreamModel? _streamFromJson(Map<String, dynamic> o) {
        try {
            final String name = _string(o["name"])?.trim() ?? "";
            final DateTime? start = _date(_string(o["checkDate"])?.replaceAll(".", "-"));
            if (name.isEmpty || start == null) return null;
            final int tag = _int(o["frequencyTag"], 1);
            final (FrequencyUnit, int) unit = _unitFromChrono(
                const ["DAYS", "WEEKS", "MONTHS", "YEARS"][tag >= 0 && tag <= 3 ? tag : 1], _int(o["frequency"], 1));
            return IncomeStreamModel(
                name: name,
                amount: _money(o["amount"]),
                startDate: start,
                frequency: unit.$2,
                frequencyUnits: unit.$1,
                isActive: o["selected"] == true,
                googleTaskId: _string(o["googleTaskId"]),
            );
        } catch (_) {
            return null;
        }
    }

    static SingleEventModel? _eventFromJson(Map<String, dynamic> o, DateTime today) {
        try {
            final String name = _string(o["name"]) ?? "";
            final double amount = _double(o["amount"]).abs();
            final bool isDebit = o["isDebit"] != false;
            final String? targetId = _string(o["targetId"]);
            final String? display = _string(o["targetDisplayName"]);
            final EventTarget target = switch (_string(o["targetType"])) {
                "MANUAL_ACCOUNT" => EventTarget.manualAccount,
                "CREDIT_CARD" => EventTarget.creditCard,
                _ => EventTarget.balance,
            };
            final DateTime created = _date(o["createdDate"]) ?? today;
            return SingleEventModel(
                name: name,
                amount: amount,
                isDebit: isDebit,
                target: target,
                targetName: switch (target) {
                    EventTarget.balance => null,
                    EventTarget.creditCard => targetId,
                    EventTarget.manualAccount => display,
                },
                targetId: target == EventTarget.manualAccount ? targetId : null,
                createdDate: created,
                lastModifiedDate: _date(o["lastModifiedDate"]) ?? created,
                appliedAmount: o["appliedAmount"] is num ? (o["appliedAmount"] as num).toDouble() : null,
            );
        } catch (_) {
            return null;
        }
    }

    // A Java ChronoUnit name and count as a unit here (unknown -> months).
    static (FrequencyUnit, int) _unitFromChrono(String name, int frequency) => switch (name) {
        "DAYS" => (FrequencyUnit.daily, frequency),
        "WEEKS" => (FrequencyUnit.weekly, frequency),
        "YEARS" => (FrequencyUnit.yearly, frequency),
        _ => (FrequencyUnit.monthly, frequency),
    };

    // ── Field helpers ───────────────────────────────────────────────────────

    static String _two(int n) => n.toString().padLeft(2, "0");
    static String _iso(DateTime d) => "${d.year.toString().padLeft(4, "0")}-${_two(d.month)}-${_two(d.day)}";

    static DateTime? _date(Object? value) {
        if (value is! String || value.isEmpty || value == "null") return null;
        final DateTime? parsed = DateTime.tryParse(value);
        return parsed == null ? null : dateOnly(parsed);
    }

    static String? _string(Object? value) => value is String ? value : null;
    static int _int(Object? value, int fallback) => value is int ? value : (value is num ? value.toInt() : fallback);
    static double _double(Object? value) => value is num ? value.toDouble() : (double.tryParse("$value") ?? 0.0);

    // Java stores money as strings ("1234.56", or "1,234.56" with separators on).
    static double _money(Object? value, {double fallback = 0.0}) {
        if (value is num) return value.toDouble();
        if (value is! String) return fallback;
        return double.tryParse(value.replaceAll(",", "").trim()) ?? fallback;
    }

    static List<dynamic> _list(Object? value) => value is List ? value : const [];
    static Iterable<Map<String, dynamic>> _objects(Object? value) => _list(value).whereType<Map<String, dynamic>>();
}
