package io.github.nishian3695.bujit.StorageManagement;

import io.github.nishian3695.bujit.ExpenseActivity.ExpenseItem;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamModel;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/*
Shared helpers for counting income/expense occurrences within a half-open date range
[start, end). Used by both ExpenseActivity (snapshot recording) and VisualsActivity
(future/current period projection) so both sides use identical math.

Note this deliberately differs from ExpenseItem.getOccurrences(), which counts an expense due ON
payday toward the check ending that day (a worst-case "lowest balance before the check lands"
for the home screen). These helpers instead record which pay period an occurrence actually fell
in, so payday belongs to the period it starts.
*/
public final class FinancialCalc {

    // Prevents instantiation — this class is a static-only utility holder.
    private FinancialCalc() {}

    private static final DateTimeFormatter CHECK_DATE_FMT =
            DateTimeFormatter.ofPattern("yyyy.MM.dd");

    /*
    Moves a recurring date by `amount` units (negative = backward). For month/year units the day
    of month snaps back to anchorDay whenever the target month is long enough: plain
    LocalDate.plus clamps Jan 31 to Feb 28, and stepping again from Feb 28 would then stay on the
    28th forever. With anchorDay 31 this gives Jan 31 -> Feb 28 -> Mar 31 -> Apr 30, and a Feb 29
    anchor returns to Feb 29 in leap years. Day/week units are unaffected. Every recurring
    schedule (expenses, credit card due dates, paydays) should step through here.
    */
    public static LocalDate stepDate(LocalDate date, long amount, ChronoUnit unit, int anchorDay) {
        LocalDate stepped = date.plus(amount, unit);
        if ((unit == ChronoUnit.MONTHS || unit == ChronoUnit.YEARS) && anchorDay > 0) {
            stepped = stepped.withDayOfMonth(Math.min(anchorDay, stepped.lengthOfMonth()));
        }
        return stepped;
    }

    // Parses an income stream's pay date (its fixed schedule anchor), or null if missing/invalid.
    public static LocalDate incomeAnchorDate(IncomeStreamModel inc) {
        String raw = inc.getCheckDate();
        if (raw == null || raw.isEmpty()) return null;
        try { return LocalDate.parse(raw, CHECK_DATE_FMT); }
        catch (Exception ex) { return null; }
    }

    // The intended payday day-of-month for the pay-period schedule: the selected income stream's
    // fixed pay date, or `fallback`'s day if no stream is selected or its date is invalid.
    public static int payAnchorDay(List<IncomeStreamModel> streams, LocalDate fallback) {
        if (streams != null) {
            for (IncomeStreamModel s : streams) {
                if (!s.isSelected()) continue;
                LocalDate anchor = incomeAnchorDate(s);
                if (anchor != null) return anchor.getDayOfMonth();
            }
        }
        return fallback.getDayOfMonth();
    }

    // Returns how many times this income stream pays within [start, end).
    public static int countIncomeOccurrences(IncomeStreamModel inc, LocalDate start, LocalDate end) {
        LocalDate date = incomeAnchorDate(inc);
        if (date == null) return 0;
        int anchorDay = date.getDayOfMonth();
        int freq = inc.getFrequency();
        ChronoUnit unit = incomeTag(inc.getFrequencyTag());
        if (freq <= 0) return 0;
        int safety = 0;
        while (!date.isBefore(start) && safety++ < 3650) date = stepDate(date, -freq, unit, anchorDay);
        int count = 0; safety = 0;
        while (date.isBefore(end) && safety++ < 3650) {
            if (!date.isBefore(start)) count++;
            date = stepDate(date, freq, unit, anchorDay);
        }
        return count;
    }

    // Returns how many times this expense falls within [start, end), ignoring any occurrence
    // outside the expense's own start/end dates.
    public static int countExpenseOccurrences(ExpenseItem e, LocalDate start, LocalDate end) {
        LocalDate date = e.getDate();
        if (date == null) return 0;
        if (e.isCredit()) {
            return (!date.isBefore(start) && date.isBefore(end)) ? 1 : 0;
        }
        int freq = e.getFrequency();
        ChronoUnit tag = e.getFrequencyTag();
        if (freq <= 0 || tag == null) return 0;
        int safety = 0;
        while (!date.isBefore(start) && safety++ < 3650) date = e.stepOccurrence(date, -1);
        int count = 0; safety = 0;
        while (date.isBefore(end) && safety++ < 3650) {
            if (!date.isBefore(start) && e.isWithinBounds(date)) count++;
            date = e.stepOccurrence(date, 1);
        }
        return count;
    }

    // Computes total income and total expenses for [start, end) from the live lists.
    // Returns float[]{incomeTotal, expenseTotal}.
    public static float[] computePeriodTotals(
            List<IncomeStreamModel> incomeList,
            List<ExpenseItem> expenseList,
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
            for (ExpenseItem e : expenseList) {
                float cost;
                try { cost = Float.parseFloat(e.getCost()); }
                catch (NumberFormatException ex) { continue; }
                if (cost <= 0) continue;
                expenses += countExpenseOccurrences(e, start, end) * cost;
            }
        }
        return new float[]{income, expenses};
    }

    // Result of rolling curCheckDate/nextCheckDate forward to the current pay period.
    public static final class CheckRollResult {
        public final LocalDate curCheckDate;
        public final LocalDate nextCheckDate;
        public final float creditedIncome;
        // {periodStart, periodEnd} for each pay period that rolled into the past, in order.
        public final List<LocalDate[]> rolledPeriods;

        CheckRollResult(LocalDate curCheckDate, LocalDate nextCheckDate,
                float creditedIncome, List<LocalDate[]> rolledPeriods) {
            this.curCheckDate = curCheckDate;
            this.nextCheckDate = nextCheckDate;
            this.creditedIncome = creditedIncome;
            this.rolledPeriods = rolledPeriods;
        }
    }

    // Advances curCheckDate/nextCheckDate past any pay periods that have fully elapsed as of
    // "today", crediting one averageCheck per period rolled. Callers must pass the *persisted*
    // curCheckDate/nextCheckDate (i.e. wherever pay-period tracking last left off) rather than
    // re-deriving them from an income stream's static anchor date -- doing the latter discards
    // already-credited progress and causes periods to be re-credited on every call. Idempotent
    // when called again with its own output and an unchanged "today": rolledPeriods is empty and
    // creditedIncome is 0. payAnchorDay is the pay schedule's intended day of month (see
    // stepDate), so monthly paydays on the 31st don't drift to the 28th after February.
    public static CheckRollResult rollCheckDateForward(
            LocalDate today, LocalDate curCheckDate, LocalDate nextCheckDate,
            int checkFrequency, ChronoUnit checkFrequencyTag, float averageCheck, int payAnchorDay) {
        List<LocalDate[]> rolledPeriods = new ArrayList<>();
        float credited = 0f;
        int safety = 0;
        while (!today.isBefore(nextCheckDate) && safety++ < 3650) {
            rolledPeriods.add(new LocalDate[]{curCheckDate, nextCheckDate});
            curCheckDate = stepDate(curCheckDate, checkFrequency, checkFrequencyTag, payAnchorDay);
            nextCheckDate = stepDate(nextCheckDate, checkFrequency, checkFrequencyTag, payAnchorDay);
            credited += averageCheck;
        }
        return new CheckRollResult(curCheckDate, nextCheckDate, credited, rolledPeriods);
    }

    // Resolved pay-period/income-stream state produced by resolveIncomeState().
    public static final class ResolvedIncomeState {
        public final ArrayList<IncomeStreamModel> incomeStreamList;
        public final float averageCheck;
        public final int checkFrequency;
        public final ChronoUnit checkFrequencyTag;
        public final LocalDate curCheckDate;
        public final LocalDate nextCheckDate;

        ResolvedIncomeState(ArrayList<IncomeStreamModel> incomeStreamList, float averageCheck,
                int checkFrequency, ChronoUnit checkFrequencyTag,
                LocalDate curCheckDate, LocalDate nextCheckDate) {
            this.incomeStreamList = incomeStreamList;
            this.averageCheck = averageCheck;
            this.checkFrequency = checkFrequency;
            this.checkFrequencyTag = checkFrequencyTag;
            this.curCheckDate = curCheckDate;
            this.nextCheckDate = nextCheckDate;
        }
    }

    // Resolves the active income stream's amount/frequency and pay-period tracking dates from a
    // StorageHolder loaded from disk. Migrates legacy single-stream fields into an IncomeStreamModel
    // on first load if needed, and guarantees exactly one stream is marked selected. Mirrors the
    // income-stream handling half of ExpenseActivity.handleStorage(READ) so it can be exercised
    // without an Activity.
    //
    // Deliberately reuses curCheckDate/nextCheckDate as already persisted in the StorageHolder
    // rather than re-deriving them from the selected stream's static checkDate (anchor) field --
    // the anchor never advances, so doing that discards already-credited pay periods and causes
    // checkForNextCheck()/rollCheckDateForward() to re-credit them on every load. This was the root
    // cause of income being re-credited on every app open; see FinancialCalcTest for the regression
    // coverage.
    public static ResolvedIncomeState resolveIncomeState(StorageHolder storageHolder) {
        float averageCheck = storageHolder.getAverageCheck();
        int checkFrequency = storageHolder.getCheckFrequency();
        ChronoUnit checkFrequencyTag = storageHolder.getCheckFrequencyTag();
        if (checkFrequencyTag == null) checkFrequencyTag = ChronoUnit.WEEKS;
        if (checkFrequency <= 0) checkFrequency = 1;

        LocalDate curCheckDate = storageHolder.getCurCheckDate();
        LocalDate nextCheckDate = storageHolder.getNextCheckDate();
        if (curCheckDate == null) curCheckDate = LocalDate.now();
        if (nextCheckDate == null) nextCheckDate = curCheckDate.plus(checkFrequency, checkFrequencyTag);

        ArrayList<IncomeStreamModel> incomeStreamList = storageHolder.getIncomeStreamList();
        if (incomeStreamList == null || incomeStreamList.isEmpty()) {
            incomeStreamList = new ArrayList<>();
            if (averageCheck > 0) {
                int legacyTag = 1; // WEEK
                if (checkFrequencyTag == ChronoUnit.DAYS)        legacyTag = 0;
                else if (checkFrequencyTag == ChronoUnit.MONTHS) legacyTag = 2;
                else if (checkFrequencyTag == ChronoUnit.YEARS)  legacyTag = 3;
                IncomeStreamModel legacy = new IncomeStreamModel(
                        "Primary Income",
                        String.format(Locale.US, "%.2f", averageCheck),
                        curCheckDate.format(CHECK_DATE_FMT),
                        checkFrequency,
                        legacyTag);
                legacy.setSelected(true);
                incomeStreamList.add(legacy);
            }
        }

        boolean anySelected = false;
        for (IncomeStreamModel s : incomeStreamList) {
            if (s.isSelected()) { anySelected = true; break; }
        }
        if (!anySelected && !incomeStreamList.isEmpty()) {
            incomeStreamList.get(0).setSelected(true);
        }

        for (IncomeStreamModel s : incomeStreamList) {
            if (s.isSelected()) {
                averageCheck = s.getAmountFloat();
                checkFrequency = s.getFrequency();
                ChronoUnit resolvedTag = frequencyTagToChronoUnitOrNull(s.getFrequencyTag());
                checkFrequencyTag = resolvedTag != null ? resolvedTag : ChronoUnit.WEEKS;
                // curCheckDate/nextCheckDate intentionally left untouched -- see method doc above.
                break;
            }
        }

        return new ResolvedIncomeState(
                incomeStreamList, averageCheck, checkFrequency, checkFrequencyTag,
                curCheckDate, nextCheckDate);
    }

    // Matches ExpenseActivity.intFreqTagToChronoUnit(): 0=DAYS, 1=WEEKS, 2=MONTHS, 3=YEARS, else null.
    private static ChronoUnit frequencyTagToChronoUnitOrNull(int freqTag) {
        switch (freqTag) {
            case 0:  return ChronoUnit.DAYS;
            case 1:  return ChronoUnit.WEEKS;
            case 2:  return ChronoUnit.MONTHS;
            case 3:  return ChronoUnit.YEARS;
            default: return null;
        }
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
