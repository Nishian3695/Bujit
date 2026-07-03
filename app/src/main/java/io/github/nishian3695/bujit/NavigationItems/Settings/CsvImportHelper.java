package io.github.nishian3695.bujit.NavigationItems.Settings;

import android.content.Context;
import android.net.Uri;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.NavigationItems.Banking.ManualAccountModel;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamModel;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Locale;

/*
Imports budgeting data from a fixed-schema CSV file.

Supported row types (first field is the type; _ prefix = optional):
  manual_account,<name>,<type>,<balance>
  expense,<name>,<amount>,<due_date>,<frequency>,<unit>,<_category>
  credit,<name>,<balance>,<credit_limit>,<due_date>
  income_stream,<name>,<amount>,<start_date>,<frequency>,<unit>

Lines starting with # are comments. Unknown row types are skipped with an error entry.
All valid rows are appended to (not replace) existing data.
*/
public class CsvImportHelper {

    public static class ImportResult {
        public int accountsAdded = 0;
        public int expensesAdded = 0;
        public int creditsAdded = 0;
        public int streamsAdded = 0;
        public int skipped = 0;
        public final ArrayList<String> errors = new ArrayList<>();

        public boolean hasData() {
            return accountsAdded + expensesAdded + creditsAdded + streamsAdded > 0;
        }

        public String summary() {
            StringBuilder sb = new StringBuilder();
            if (accountsAdded > 0)  sb.append(accountsAdded).append(" manual account(s) added\n");
            if (expensesAdded > 0)  sb.append(expensesAdded).append(" expense(s) added\n");
            if (creditsAdded > 0)   sb.append(creditsAdded).append(" credit card(s) added\n");
            if (streamsAdded > 0)   sb.append(streamsAdded).append(" income stream(s) added\n");
            if (skipped > 0)        sb.append(skipped).append(" row(s) skipped");
            return sb.toString().trim();
        }
    }

    public static ImportResult importFromUri(Context ctx, Uri uri) {
        ImportResult result = new ImportResult();
        StorageManager manager;
        StorageHolder holder;
        try {
            manager = new StorageManager(ctx);
            holder  = manager.getStorageHolder();
        } catch (Exception e) {
            result.errors.add("Could not load app data: " + e.getMessage());
            return result;
        }

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(ctx.getContentResolver().openInputStream(uri)))) {
            String line;
            int lineNum = 0;
            while ((line = reader.readLine()) != null) {
                lineNum++;
                line = line.trim();
                if (line.isEmpty() || line.startsWith("#")) continue;

                String[] parts = splitCsvLine(line);
                if (parts.length == 0) continue;

                String type = parts[0].trim().toLowerCase(Locale.US);
                try {
                    switch (type) {
                        case "manual_account": parseManualAccount(parts, holder, result);  break;
                        case "expense":        parseExpense(parts, holder, result);        break;
                        case "credit":         parseCredit(parts, holder, result);         break;
                        case "income_stream":  parseIncomeStream(parts, holder, result);   break;
                        default:
                            result.skipped++;
                            result.errors.add("Line " + lineNum + ": unknown type \""
                                    + parts[0].trim() + "\"");
                    }
                } catch (Exception e) {
                    result.skipped++;
                    result.errors.add("Line " + lineNum + ": " + e.getMessage());
                }
            }
        } catch (Exception e) {
            result.errors.add("Could not read file: " + e.getMessage());
            return result;
        }

        try {
            manager.writeData(holder);
        } catch (Exception e) {
            result.errors.add("Could not save data: " + e.getMessage());
        }
        return result;
    }

    // manual_account,<name>,<type>,<balance>
    private static void parseManualAccount(String[] p, StorageHolder h, ImportResult r) {
        require(p, 4, "manual_account,<name>,<type>,<balance>");
        String name    = nonEmpty(p[1], "name");
        String type    = p[2].trim().isEmpty() ? "Other" : p[2].trim();
        float  balance = parseAmount(p[3]);
        h.getManualAccountList().add(new ManualAccountModel(name, type, balance));
        r.accountsAdded++;
    }

    // expense,<name>,<amount>,<due_date>,<frequency>,<unit>,<_category>
    private static void parseExpense(String[] p, StorageHolder h, ImportResult r) {
        require(p, 6, "expense,<name>,<amount>,<due_date>,<frequency>,<unit>,<_category>");
        String     name     = nonEmpty(p[1], "name");
        float      amount   = parseAmount(p[2]);
        LocalDate  date     = parseDate(p[3]);
        int        freq     = parseFreq(p[4]);
        ChronoUnit unit     = parseUnit(p[5]);
        String     category = (p.length > 6 && !p[6].trim().isEmpty()) ? p[6].trim() : "Other";

        ExpenseModel e = new ExpenseModel(
                name, String.format(Locale.US, "%.2f", amount),
                date, freq, unit, false);
        e.setCategory(category);
        h.getExpenseList().add(e);
        r.expensesAdded++;
    }

    // credit,<name>,<balance>,<credit_limit>,<due_date>
    private static void parseCredit(String[] p, StorageHolder h, ImportResult r) {
        require(p, 5, "credit,<name>,<balance>,<credit_limit>,<due_date>");
        String    name  = nonEmpty(p[1], "name");
        float     bal   = parseAmount(p[2]);
        float     limit = parseAmount(p[3]);
        if (limit <= 0) throw new IllegalArgumentException("credit_limit must be > 0");
        LocalDate date  = parseDate(p[4]);

        ExpenseModel c = new ExpenseModel(
                name, String.format(Locale.US, "%.2f", bal),
                date, 1, ChronoUnit.MONTHS, false);
        c.setIsCredit(true);
        c.setCreditLimit(String.format(Locale.US, "%.2f", limit));
        h.getExpenseList().add(c);
        r.creditsAdded++;
    }

    // income_stream,<name>,<amount>,<start_date>,<frequency>,<unit>
    private static void parseIncomeStream(String[] p, StorageHolder h, ImportResult r) {
        require(p, 6, "income_stream,<name>,<amount>,<start_date>,<frequency>,<unit>");
        String    name  = nonEmpty(p[1], "name");
        float     amt   = parseAmount(p[2]);
        LocalDate date  = parseDate(p[3]);
        int       freq  = parseFreq(p[4]);
        int       tag   = parseUnitTag(p[5]);

        // IncomeStreamModel.checkDate is stored as "yyyy.MM.dd"
        String checkDate = date.format(DateTimeFormatter.ofPattern("yyyy.MM.dd"));

        IncomeStreamModel stream = new IncomeStreamModel(
                name,
                String.format(Locale.US, "%.2f", amt),
                checkDate, freq, tag);

        ArrayList<IncomeStreamModel> streams = h.getIncomeStreamList();
        if (streams == null) {
            streams = new ArrayList<>();
            h.setIncomeStreamList(streams);
        }
        streams.add(stream);
        r.streamsAdded++;
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static void require(String[] p, int min, String format) {
        if (p.length < min)
            throw new IllegalArgumentException("expected format: " + format);
    }

    private static String nonEmpty(String s, String field) {
        s = s.trim();
        if (s.isEmpty()) throw new IllegalArgumentException(field + " cannot be empty");
        return s;
    }

    private static float parseAmount(String s) {
        try {
            return Float.parseFloat(s.trim().replace(",", "").replace("$", ""));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("invalid amount: \"" + s.trim() + "\"");
        }
    }

    private static int parseFreq(String s) {
        try {
            int f = Integer.parseInt(s.trim());
            if (f < 1) throw new IllegalArgumentException("frequency must be >= 1");
            return f;
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("invalid frequency: \"" + s.trim() + "\"");
        }
    }

    private static LocalDate parseDate(String s) {
        // Accept YYYY-MM-DD or YYYY/MM/DD
        try {
            return LocalDate.parse(s.trim().replace('/', '-'));
        } catch (Exception e) {
            throw new IllegalArgumentException(
                    "invalid date (expected YYYY-MM-DD): \"" + s.trim() + "\"");
        }
    }

    private static ChronoUnit parseUnit(String s) {
        switch (s.trim().toLowerCase(Locale.US)) {
            case "day":   case "days":   return ChronoUnit.DAYS;
            case "week":  case "weeks":  return ChronoUnit.WEEKS;
            case "month": case "months": return ChronoUnit.MONTHS;
            case "year":  case "years":  return ChronoUnit.YEARS;
            default:
                throw new IllegalArgumentException(
                        "unit must be day/week/month/year; got \"" + s.trim() + "\"");
        }
    }

    // Returns the IncomeStreamModel integer frequency tag (0=Days,1=Weeks,2=Months,3=Years)
    private static int parseUnitTag(String s) {
        switch (s.trim().toLowerCase(Locale.US)) {
            case "day":   case "days":   return 0;
            case "week":  case "weeks":  return 1;
            case "month": case "months": return 2;
            case "year":  case "years":  return 3;
            default:
                throw new IllegalArgumentException(
                        "unit must be day/week/month/year; got \"" + s.trim() + "\"");
        }
    }

    private static String[] splitCsvLine(String line) {
        ArrayList<String> fields = new ArrayList<>();
        StringBuilder sb = new StringBuilder();
        boolean inQuotes = false;
        for (int i = 0; i < line.length(); i++) {
            char c = line.charAt(i);
            if (c == '"') {
                inQuotes = !inQuotes;
            } else if (c == ',' && !inQuotes) {
                fields.add(sb.toString());
                sb.setLength(0);
            } else {
                sb.append(c);
            }
        }
        fields.add(sb.toString());
        return fields.toArray(new String[0]);
    }

    // The minimal template shared via "Get CSV Template".
    public static final String TEMPLATE =
        "# Bujit CSV Import Template\n"
        + "# Lines starting with # are comments and are ignored during import.\n"
        + "# Each row is a tag followed by its fields. See the in-app reference for details.\n"
        + "\n"
        + "# Example\n"
        + "manual_account,My Savings,Savings,0\n"
        + "expense,Rent,2200,2024-01-01,1,month,Housing\n"
        + "credit,Card Name,156,1000,2024-01-15\n"
        + "income_stream,Hardware Store,2500.56,2022-03-15,2,week\n";
}
