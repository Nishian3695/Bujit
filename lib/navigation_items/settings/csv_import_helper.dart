// Mirrors NavigationItems/Settings/CsvImportHelper.java in the original Java app.
//
// Imports budgeting data from a fixed-schema CSV file. Supported row types
// (first field is the type; _ prefix = optional):
//   expense,<name>,<amount>,<due_date>,<frequency>,<unit>,<_category>,<_end_date>
//   credit,<name>,<balance>,<credit_limit>,<due_date>
//   income_stream,<name>,<amount>,<start_date>,<frequency>,<unit>
//   manual_account,<name>,<type>,<balance>   (skipped until Linked Accounts exists)
// Lines starting with # are comments. Rows are appended to (not merged with)
// existing data. A malformed row is skipped with a line-numbered error; the
// rest of the file still imports.
//
// Dates: YYYY-MM-DD or YYYY/MM/DD. An expense's due_date is also its start
// date (nothing before it is counted). A past due date means earlier payments
// already happened outside the app: it moves to the next upcoming date without
// charging anything, and a card keeps its imported balance. An income stream's
// start date follows the usual crediting rule (a past one is already in the
// balance; a future one is credited when it arrives).
import '../../storage_management/app_data_store.dart';
import '../../utils/category_manager.dart';
import '../../utils/date_utils.dart';
import '../../utils/frequency_unit.dart';
import '../expense_activity/credit_model.dart';
import '../expense_activity/expense_model.dart';
import '../income_streams/income_stream_model.dart';

// Tallies what was imported/skipped plus per-line errors, for the summary shown afterwards.
class CsvImportResult {
    int expensesAdded = 0;
    int creditsAdded = 0;
    int streamsAdded = 0;
    int skipped = 0;
    final List<String> errors = [];

    bool get hasData => expensesAdded + creditsAdded + streamsAdded > 0;

    String summary() {
        final List<String> lines = [
            if (expensesAdded > 0) "$expensesAdded expense(s) added",
            if (creditsAdded > 0) "$creditsAdded credit card(s) added",
            if (streamsAdded > 0) "$streamsAdded income stream(s) added",
            if (skipped > 0) "$skipped row(s) skipped",
        ];
        return lines.join("\n");
    }
}

class CsvImportHelper {
    // Parses [csv] and appends every valid row to [data]. Doesn't save: the caller does.
    static CsvImportResult importInto(AppData data, String csv, {DateTime? today}) {
        final DateTime day = dateOnly(today ?? todayDate());
        final CsvImportResult result = CsvImportResult();
        final List<String> lines = csv.split(RegExp(r'\r?\n'));
        for (int i = 0; i < lines.length; i++) {
            final String line = lines[i].trim();
            if (line.isEmpty || line.startsWith("#")) continue;
            final List<String> parts = splitCsvLine(line);
            final String type = parts[0].trim().toLowerCase();
            try {
                switch (type) {
                    case "expense": parseExpense(parts, data, result, day);
                    case "credit": parseCredit(parts, data, result, day);
                    case "income_stream": parseIncomeStream(parts, data, result);
                    case "manual_account":
                        throw const FormatException("manual accounts aren't supported yet (coming with Linked Accounts)");
                    default:
                        throw FormatException("unknown type \"${parts[0].trim()}\"");
                }
            } on FormatException catch (e) {
                result.skipped++;
                result.errors.add("Line ${i + 1}: ${e.message}");
            }
        }
        return result;
    }

    // expense,<name>,<amount>,<due_date>,<frequency>,<unit>,<_category>,<_end_date>
    // Both trailing fields are optional and may be omitted or left blank; a blank
    // category with an end date is written as ",,<end_date>".
    static void parseExpense(List<String> p, AppData data, CsvImportResult r, DateTime today) {
        _require(p, 6, "expense,<name>,<amount>,<due_date>,<frequency>,<unit>,<_category>,<_end_date>");
        final String name = _nonEmpty(p[1], "name");
        final double amount = _parseAmount(p[2]);
        final DateTime date = _parseDate(p[3]);
        final int frequency = _parseFrequency(p[4]);
        final FrequencyUnit unit = _parseUnit(p[5]);
        final String category = (p.length > 6 && p[6].trim().isNotEmpty) ? p[6].trim() : otherCategory;
        final DateTime? endDate = (p.length > 7 && p[7].trim().isNotEmpty) ? _parseDate(p[7]) : null;
        if (endDate != null && endDate.isBefore(date)) {
            throw FormatException("end_date ${_format(endDate)} is before due_date ${_format(date)}");
        }
        final ExpenseModel expense = ExpenseModel(
            name: name,
            amount: amount,
            startDate: date,
            frequency: frequency,
            frequencyUnits: unit,
            category: category,
            endDate: endDate,
        );
        expense.skipToNextDueDate(today: today);
        data.balance.expenses.add(expense);
        if (category != otherCategory && !data.categories.contains(category)) data.categories.add(category);
        r.expensesAdded++;
    }

    // credit,<name>,<balance>,<credit_limit>,<due_date>
    static void parseCredit(List<String> p, AppData data, CsvImportResult r, DateTime today) {
        _require(p, 5, "credit,<name>,<balance>,<credit_limit>,<due_date>");
        final String name = _nonEmpty(p[1], "name");
        final double balance = _parseAmount(p[2]);
        final double limit = _parseAmount(p[3]);
        if (limit <= 0) throw const FormatException("credit_limit must be > 0");
        final DateTime date = _parseDate(p[4]);
        final CreditModel card = CreditModel(
            name: name,
            amount: balance,
            creditLimit: limit,
            startDate: date,
            frequency: 1,
            frequencyUnits: FrequencyUnit.monthly,
        );
        card.skipToNextDueDate(today: today);
        data.balance.expenses.add(card);
        r.creditsAdded++;
    }

    // income_stream,<name>,<amount>,<start_date>,<frequency>,<unit>
    // The first stream becomes active if there isn't one yet.
    static void parseIncomeStream(List<String> p, AppData data, CsvImportResult r) {
        _require(p, 6, "income_stream,<name>,<amount>,<start_date>,<frequency>,<unit>");
        final IncomeStreamModel stream = IncomeStreamModel(
            name: _nonEmpty(p[1], "name"),
            amount: _parseAmount(p[2]),
            startDate: _parseDate(p[3]),
            frequency: _parseFrequency(p[4]),
            frequencyUnits: _parseUnit(p[5]),
        );
        data.balance.incomeStreams.add(stream);
        data.balance.activeIncome ??= stream;
        r.streamsAdded++;
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    static void _require(List<String> p, int min, String format) {
        if (p.length < min) throw FormatException("expected format: $format");
    }

    static String _nonEmpty(String s, String field) {
        final String trimmed = s.trim();
        if (trimmed.isEmpty) throw FormatException("$field cannot be empty");
        return trimmed;
    }

    // A dollar amount, ignoring commas and a leading "$".
    static double _parseAmount(String s) {
        final double? value = double.tryParse(s.trim().replaceAll(",", "").replaceAll("\$", ""));
        if (value == null || !value.isFinite) throw FormatException("invalid amount: \"${s.trim()}\"");
        return value;
    }

    // A recurrence count of at least 1.
    static int _parseFrequency(String s) {
        final int? value = int.tryParse(s.trim());
        if (value == null) throw FormatException("invalid frequency: \"${s.trim()}\"");
        if (value < 1) throw const FormatException("frequency must be >= 1");
        return value;
    }

    // YYYY-MM-DD or YYYY/MM/DD, as a real calendar date (2026-02-30 is rejected).
    static DateTime _parseDate(String s) {
        final String trimmed = s.trim();
        final RegExpMatch? m = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$').firstMatch(trimmed);
        if (m != null) {
            final int year = int.parse(m.group(1)!);
            final int month = int.parse(m.group(2)!);
            final int dayOfMonth = int.parse(m.group(3)!);
            final DateTime date = DateTime(year, month, dayOfMonth);
            if (date.year == year && date.month == month && date.day == dayOfMonth) return date;
        }
        throw FormatException("invalid date (expected YYYY-MM-DD): \"$trimmed\"");
    }

    // day/week/biweek/month/year, singular or plural, any case ("biweekly" too).
    static FrequencyUnit _parseUnit(String s) {
        return switch (s.trim().toLowerCase()) {
            "day" || "days" => FrequencyUnit.daily,
            "week" || "weeks" => FrequencyUnit.weekly,
            "biweek" || "biweeks" || "biweekly" => FrequencyUnit.biweekly,
            "month" || "months" => FrequencyUnit.monthly,
            "year" || "years" => FrequencyUnit.yearly,
            _ => throw FormatException("unit must be day/week/month/year; got \"${s.trim()}\""),
        };
    }

    static String _format(DateTime date) => date.toString().split(' ')[0];

    // Splits one CSV line on commas, honoring double-quoted fields so a quoted
    // value can itself contain a comma.
    static List<String> splitCsvLine(String line) {
        final List<String> fields = [];
        final StringBuffer field = StringBuffer();
        bool inQuotes = false;
        for (int i = 0; i < line.length; i++) {
            final String c = line[i];
            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (c == ',' && !inQuotes) {
                fields.add(field.toString());
                field.clear();
            } else {
                field.write(c);
            }
        }
        fields.add(field.toString());
        return fields;
    }

    // The template offered from Settings, matching the Java app's.
    static const String template =
        "# Bujit CSV Import Template\n"
        "# Lines starting with # are comments and are ignored during import.\n"
        "# Each row is a tag followed by its fields. See the in-app reference for details.\n"
        "\n"
        "# Example\n"
        "manual_account,My Savings,Savings,0\n"
        "expense,Rent,2200,2024-01-01,1,month,Housing\n"
        "# Optional last field: an end date, after which the expense stops (inclusive)\n"
        "expense,Car Payment,350,2024-01-10,1,month,Transportation,2028-12-10\n"
        "credit,Card Name,156,1000,2024-01-15\n"
        "income_stream,Hardware Store,2500.56,2022-03-15,2,week\n";
}
