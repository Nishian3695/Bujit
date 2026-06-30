package io.github.nishian3695.bujit.NavigationItems.Settings;

import android.content.Context;
import android.net.Uri;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.NavigationItems.Banking.ManualAccountModel;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Locale;

/*
Imports budgeting data from a fixed-schema CSV file.

Supported row types (first field is the type, remaining fields follow):
  balance,<amount>
  manual_account,<name>,<type>,<balance>
  expense,<name>,<amount>,<frequency>,<unit>,<category>,<start_date>
  credit,<name>,<current_balance>,<credit_limit>,<due_date>

Lines starting with # are comments. Unknown row types are skipped with an error entry.
All valid rows are appended to (not replace) the existing data, except balance which overwrites.
*/
public class CsvImportHelper {

    public static class ImportResult {
        public int balanceUpdated = 0;
        public int accountsAdded = 0;
        public int expensesAdded = 0;
        public int creditsAdded = 0;
        public int skipped = 0;
        public final ArrayList<String> errors = new ArrayList<>();

        public boolean hasData() {
            return balanceUpdated + accountsAdded + expensesAdded + creditsAdded > 0;
        }

        public String summary() {
            StringBuilder sb = new StringBuilder();
            if (balanceUpdated > 0) sb.append("Additional Funds balance updated\n");
            if (accountsAdded > 0)  sb.append(accountsAdded).append(" manual account(s) added\n");
            if (expensesAdded > 0)  sb.append(expensesAdded).append(" expense(s) added\n");
            if (creditsAdded > 0)   sb.append(creditsAdded).append(" credit card(s) added\n");
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
                        case "balance":        parseBalance(parts, holder, result);        break;
                        case "manual_account": parseManualAccount(parts, holder, result);  break;
                        case "expense":        parseExpense(parts, holder, result);        break;
                        case "credit":         parseCredit(parts, holder, result);         break;
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

    // balance,<amount>
    private static void parseBalance(String[] p, StorageHolder h, ImportResult r) {
        require(p, 2, "balance,<amount>");
        h.setManualBalanceAddition(parseAmount(p[1]));
        r.balanceUpdated = 1;
    }

    // manual_account,<name>,<type>,<balance>
    private static void parseManualAccount(String[] p, StorageHolder h, ImportResult r) {
        require(p, 4, "manual_account,<name>,<type>,<balance>");
        String name = nonEmpty(p[1], "name");
        String type = p[2].trim().isEmpty() ? "Other" : p[2].trim();
        float balance = parseAmount(p[3]);
        h.getManualAccountList().add(new ManualAccountModel(name, type, balance));
        r.accountsAdded++;
    }

    // expense,<name>,<amount>,<frequency>,<unit>,<category>,<start_date>
    private static void parseExpense(String[] p, StorageHolder h, ImportResult r) {
        require(p, 7, "expense,<name>,<amount>,<frequency>,<unit>,<category>,<start_date>");
        String name     = nonEmpty(p[1], "name");
        float  amount   = parseAmount(p[2]);
        int    freq     = parseFreq(p[3]);
        ChronoUnit unit = parseUnit(p[4]);
        String category = p[5].trim().isEmpty() ? "Other" : p[5].trim();
        LocalDate date  = parseDate(p[6]);

        ExpenseModel e = new ExpenseModel(
                name, String.format(Locale.US, "%.2f", amount),
                date, freq, unit, false);
        e.setCategory(category);
        h.getExpenseList().add(e);
        r.expensesAdded++;
    }

    // credit,<name>,<current_balance>,<credit_limit>,<due_date>
    private static void parseCredit(String[] p, StorageHolder h, ImportResult r) {
        require(p, 5, "credit,<name>,<current_balance>,<credit_limit>,<due_date>");
        String name    = nonEmpty(p[1], "name");
        float  balance = parseAmount(p[2]);
        float  limit   = parseAmount(p[3]);
        if (limit <= 0) throw new IllegalArgumentException("credit limit must be > 0");
        LocalDate date = parseDate(p[4]);

        ExpenseModel c = new ExpenseModel(
                name, String.format(Locale.US, "%.2f", balance),
                date, 1, ChronoUnit.MONTHS, false);
        c.setIsCredit(true);
        c.setCreditLimit(String.format(Locale.US, "%.2f", limit));
        h.getExpenseList().add(c);
        r.creditsAdded++;
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

    private static ChronoUnit parseUnit(String s) {
        switch (s.trim().toLowerCase(Locale.US)) {
            case "daily":   case "day":   case "days":   return ChronoUnit.DAYS;
            case "weekly":  case "week":  case "weeks":  return ChronoUnit.WEEKS;
            case "monthly": case "month": case "months": return ChronoUnit.MONTHS;
            case "yearly":  case "year":  case "years":  return ChronoUnit.YEARS;
            default:
                throw new IllegalArgumentException(
                        "unit must be daily/weekly/monthly/yearly; got \"" + s.trim() + "\"");
        }
    }

    private static LocalDate parseDate(String s) {
        try {
            return LocalDate.parse(s.trim());
        } catch (Exception e) {
            throw new IllegalArgumentException(
                    "invalid date (expected YYYY-MM-DD): \"" + s.trim() + "\"");
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

    // CSV template shared with the user via "Get Template".
    public static final String TEMPLATE =
        "# Bujit CSV Import Template\n"
        + "# Lines starting with # are comments — ignored during import.\n"
        + "#\n"
        + "# ── ROW TYPES ──────────────────────────────────────\n"
        + "#\n"
        + "# balance,<amount>\n"
        + "#   Sets the Additional Funds value (money not tracked by a linked account).\n"
        + "#   Example:  balance,3000.00\n"
        + "#\n"
        + "# manual_account,<name>,<type>,<balance>\n"
        + "#   Adds an account to My Accounts in Banking.\n"
        + "#   Types: Checking / Savings / Cash / Investment / Other\n"
        + "#   Example:  manual_account,Chase Savings,Savings,12500.00\n"
        + "#\n"
        + "# expense,<name>,<amount>,<frequency>,<unit>,<category>,<start_date>\n"
        + "#   Adds a recurring expense.\n"
        + "#   Units: daily / weekly / monthly / yearly\n"
        + "#   Date format: YYYY-MM-DD\n"
        + "#   Example:  expense,Rent,1500.00,1,monthly,Housing,2024-01-01\n"
        + "#\n"
        + "# credit,<name>,<current_balance>,<credit_limit>,<due_date>\n"
        + "#   Adds a credit card entry.\n"
        + "#   Date format: YYYY-MM-DD\n"
        + "#   Example:  credit,Visa Card,1200.00,5000.00,2024-01-15\n"
        + "#\n"
        + "# ── YOUR DATA ───────────────────────────────────────\n"
        + "\n"
        + "balance,0.00\n"
        + "#manual_account,My Savings,Savings,0.00\n"
        + "#expense,Rent,0.00,1,monthly,Housing,2024-01-01\n"
        + "#credit,Card Name,0.00,1000.00,2024-01-15\n";
}
