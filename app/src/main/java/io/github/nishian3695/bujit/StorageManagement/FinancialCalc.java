package io.github.nishian3695.bujit.StorageManagement;

import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamModel;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;

/*
Shared helpers for counting income/expense occurrences within a half-open date range
[start, end). Used by both ExpenseActivity (snapshot recording) and VisualsActivity
(future/current period projection) so both sides use identical math.
*/
public final class FinancialCalc {

    private FinancialCalc() {}

    private static final DateTimeFormatter CHECK_DATE_FMT =
            DateTimeFormatter.ofPattern("yyyy.MM.dd");

    // Returns how many times this income stream pays within [start, end).
    public static int countIncomeOccurrences(IncomeStreamModel inc, LocalDate start, LocalDate end) {
        String raw = inc.getCheckDate();
        if (raw == null || raw.isEmpty()) return 0;
        LocalDate date;
        try { date = LocalDate.parse(raw, CHECK_DATE_FMT); }
        catch (Exception ex) { return 0; }
        int freq = inc.getFrequency();
        ChronoUnit unit = incomeTag(inc.getFrequencyTag());
        if (freq <= 0) return 0;
        int safety = 0;
        while (!date.isBefore(start) && safety++ < 3650) date = date.minus(freq, unit);
        int count = 0; safety = 0;
        while (date.isBefore(end) && safety++ < 3650) {
            if (!date.isBefore(start)) count++;
            date = date.plus(freq, unit);
        }
        return count;
    }

    // Returns how many times this expense falls within [start, end).
    public static int countExpenseOccurrences(ExpenseModel e, LocalDate start, LocalDate end) {
        LocalDate date = e.getDate();
        if (date == null) return 0;
        if (e.getIsCredit()) {
            return (!date.isBefore(start) && date.isBefore(end)) ? 1 : 0;
        }
        int freq = e.getFrequency();
        ChronoUnit tag = e.getFrequencyTag();
        if (freq <= 0 || tag == null) return 0;
        int safety = 0;
        while (!date.isBefore(start) && safety++ < 3650) date = date.minus(freq, tag);
        int count = 0; safety = 0;
        while (date.isBefore(end) && safety++ < 3650) {
            if (!date.isBefore(start)) count++;
            date = date.plus(freq, tag);
        }
        return count;
    }

    // Computes total income and total expenses for [start, end) from the live lists.
    // Returns float[]{incomeTotal, expenseTotal}.
    public static float[] computePeriodTotals(
            List<IncomeStreamModel> incomeList,
            List<ExpenseModel> expenseList,
            LocalDate start, LocalDate end) {
        float income = 0f, expenses = 0f;
        if (incomeList != null) {
            for (IncomeStreamModel inc : incomeList) {
                float amt;
                try { amt = Float.parseFloat(inc.getAmount()); }
                catch (NumberFormatException e) { continue; }
                if (amt <= 0) continue;
                income += countIncomeOccurrences(inc, start, end) * amt;
            }
        }
        if (expenseList != null) {
            for (ExpenseModel e : expenseList) {
                float cost;
                try { cost = Float.parseFloat(e.getCost()); }
                catch (NumberFormatException ex) { continue; }
                if (cost <= 0) continue;
                expenses += countExpenseOccurrences(e, start, end) * cost;
            }
        }
        return new float[]{income, expenses};
    }

    // IncomeStreamModel frequencyTag int codes: 0=DAYS, 1=WEEKS, 2=MONTHS, 3=YEARS
    private static ChronoUnit incomeTag(int tag) {
        switch (tag) {
            case 0:  return ChronoUnit.DAYS;
            case 1:  return ChronoUnit.WEEKS;
            case 2:  return ChronoUnit.MONTHS;
            case 3:  return ChronoUnit.YEARS;
            default: return ChronoUnit.MONTHS;
        }
    }
}
