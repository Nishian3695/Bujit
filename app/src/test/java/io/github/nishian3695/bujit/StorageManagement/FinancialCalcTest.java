package io.github.nishian3695.bujit.StorageManagement;

import static org.junit.Assert.assertEquals;

import io.github.nishian3695.bujit.ExpenseActivity.CreditModel;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseItem;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamModel;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import org.junit.Test;

public class FinancialCalcTest {

    private static final DateTimeFormatter CHECK_DATE_FMT = DateTimeFormatter.ofPattern("yyyy.MM.dd");

    @Test
    public void countIncomeOccurrences_biweekly_countsEachPayInWindow() {
        LocalDate today = LocalDate.now();
        IncomeStreamModel inc = new IncomeStreamModel("Job", "1000", today.format(CHECK_DATE_FMT), 14, 0); // 0=DAYS

        int occ = FinancialCalc.countIncomeOccurrences(inc, today, today.plusDays(28));

        assertEquals(2, occ);
    }

    @Test
    public void countIncomeOccurrences_noPayInWindow_returnsZero() {
        LocalDate today = LocalDate.now();
        IncomeStreamModel inc = new IncomeStreamModel("Job", "1000", today.plusDays(5).format(CHECK_DATE_FMT), 30, 0);

        int occ = FinancialCalc.countIncomeOccurrences(inc, today, today.plusDays(1));

        assertEquals(0, occ);
    }

    @Test
    public void countExpenseOccurrences_regularExpense_countsFrequencyBased() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Netflix", "15.00", today, 7, ChronoUnit.DAYS, false);

        int occ = FinancialCalc.countExpenseOccurrences(e, today, today.plusDays(28));

        assertEquals(4, occ);
    }

    @Test
    public void countExpenseOccurrences_creditCard_countsAtMostOneDueDateInWindow() {
        LocalDate today = LocalDate.now();
        CreditModel card = new CreditModel("Card", "500.00", today.plusDays(10), "2000.00");

        int occ = FinancialCalc.countExpenseOccurrences(card, today, today.plusDays(20));

        assertEquals(1, occ);
    }

    @Test
    public void computePeriodTotals_sumsIncomeAndExpenses_skippingInvalidAmounts() {
        LocalDate today = LocalDate.now();
        List<IncomeStreamModel> income = new ArrayList<>();
        income.add(new IncomeStreamModel("Job", "1000", today.format(CHECK_DATE_FMT), 14, 0));
        income.add(new IncomeStreamModel("Bad", "not-a-number", today.format(CHECK_DATE_FMT), 14, 0));

        List<ExpenseItem> expenses = new ArrayList<>();
        expenses.add(new ExpenseModel("Netflix", "15.00", today, 14, ChronoUnit.DAYS, false));
        expenses.add(new ExpenseModel("Free trial", "0.00", today, 14, ChronoUnit.DAYS, false));

        float[] totals = FinancialCalc.computePeriodTotals(income, expenses, today, today.plusDays(14));

        assertEquals(1000f, totals[0], 0.001f);
        assertEquals(15f, totals[1], 0.001f);
    }

    // --- rollCheckDateForward: regression coverage for the "income re-credited on every app
    // open" bug. handleStorage(READ) used to re-derive curCheckDate/nextCheckDate from the income
    // stream's static anchor date on every load, discarding already-credited progress. The fix was
    // to always feed rollCheckDateForward the previously-persisted dates. These tests assert the
    // roll-forward math itself is correct and, critically, idempotent when fed its own prior output.

    @Test
    public void rollCheckDateForward_dueToday_creditsExactlyOnePeriod() {
        LocalDate today = LocalDate.now();
        FinancialCalc.CheckRollResult result = FinancialCalc.rollCheckDateForward(
                today, today, today, 14, ChronoUnit.DAYS, 1000f);

        assertEquals(1000f, result.creditedIncome, 0.001f);
        assertEquals(1, result.rolledPeriods.size());
        assertEquals(today.plusDays(14), result.nextCheckDate);
        assertEquals(today.plusDays(14), result.curCheckDate);
    }

    @Test
    public void rollCheckDateForward_calledAgainSameDayWithPriorOutput_doesNotDoubleCredit() {
        // Simulates opening the app on payday (first credit), then reopening the app again later
        // the same day. The second call MUST be fed the first call's output dates -- exactly what
        // the fixed handleStorage(READ) now does by trusting the persisted dates instead of
        // re-deriving them from the income stream's anchor date on every load.
        LocalDate today = LocalDate.now();
        FinancialCalc.CheckRollResult firstOpen = FinancialCalc.rollCheckDateForward(
                today, today, today, 14, ChronoUnit.DAYS, 1000f);
        assertEquals(1000f, firstOpen.creditedIncome, 0.001f);

        FinancialCalc.CheckRollResult secondOpen = FinancialCalc.rollCheckDateForward(
                today, firstOpen.curCheckDate, firstOpen.nextCheckDate, 14, ChronoUnit.DAYS, 1000f);

        assertEquals("Reopening the app on the same day must not re-credit income",
                0f, secondOpen.creditedIncome, 0.001f);
        assertEquals(0, secondOpen.rolledPeriods.size());
    }

    @Test
    public void rollCheckDateForward_reRunManyTimes_totalCreditedNeverExceedsOnePerPeriod() {
        // Directly simulates "user force-quits and reopens the app repeatedly on payday" --
        // the exact scenario reported as the infinite-money glitch.
        LocalDate today = LocalDate.now();
        LocalDate curCheckDate = today;
        LocalDate nextCheckDate = today;
        float balance = 0f;

        for (int reopen = 0; reopen < 20; reopen++) {
            FinancialCalc.CheckRollResult result = FinancialCalc.rollCheckDateForward(
                    today, curCheckDate, nextCheckDate, 14, ChronoUnit.DAYS, 1000f);
            balance += result.creditedIncome;
            curCheckDate = result.curCheckDate;
            nextCheckDate = result.nextCheckDate;
        }

        assertEquals("20 simulated app reopens on the same payday must credit income only once",
                1000f, balance, 0.001f);
    }

    @Test
    public void rollCheckDateForward_multipleMissedPeriods_creditsEachExactlyOnce() {
        // App wasn't opened for 6 weeks; biweekly pay should catch up exactly 3 periods, then
        // settle into a non-credited state on the next call (mirroring the previous test).
        LocalDate today = LocalDate.now();
        LocalDate anchor = today.minusDays(42);

        FinancialCalc.CheckRollResult caughtUp = FinancialCalc.rollCheckDateForward(
                today, anchor, anchor.plusDays(14), 14, ChronoUnit.DAYS, 500f);

        assertEquals(3, caughtUp.rolledPeriods.size());
        assertEquals(1500f, caughtUp.creditedIncome, 0.001f);
        assertEquals(anchor.plusDays(56), caughtUp.nextCheckDate);

        FinancialCalc.CheckRollResult reopenAfterCatchUp = FinancialCalc.rollCheckDateForward(
                today, caughtUp.curCheckDate, caughtUp.nextCheckDate, 14, ChronoUnit.DAYS, 500f);
        assertEquals(0f, reopenAfterCatchUp.creditedIncome, 0.001f);
    }

    @Test
    public void bugRepro_rederivingFromAnchorEveryOpen_wouldHaveDoubleCredited() {
        // Reproduces the ORIGINAL bug for contrast: the old handleStorage(READ) re-derived
        // curCheckDate/nextCheckDate from the income stream's static anchor date on every app
        // open, instead of using the persisted, already-advanced dates. This test deliberately
        // does that (anchorCheckDate never changes) to prove it really does over-credit, which is
        // exactly what the fix (always passing the persisted dates, as in the tests above) avoids.
        LocalDate today = LocalDate.now();
        LocalDate anchorCheckDate = today; // the stream's fixed, never-advancing pay date
        float balance = 0f;

        for (int reopen = 0; reopen < 5; reopen++) {
            LocalDate rederivedNext = anchorCheckDate.plus(14, ChronoUnit.DAYS);
            // Simulates the bug: curCheckDate reset to the anchor before every roll, so nextCheckDate
            // is "today" (or earlier) again on every single open.
            FinancialCalc.CheckRollResult result = FinancialCalc.rollCheckDateForward(
                    today, anchorCheckDate, anchorCheckDate, 14, ChronoUnit.DAYS, 1000f);
            balance += result.creditedIncome;
        }

        assertEquals("Demonstrates the bug: re-deriving from a static anchor on every open "
                + "credited income " + (balance / 1000f) + " times for a single payday",
                5000f, balance, 0.001f);
    }

    // --- resolveIncomeState: exercises the ACTUAL production code that had the bug (the
    // income-stream-sync block of ExpenseActivity.handleStorage(READ), extracted verbatim into
    // FinancialCalc so it's callable without an Activity). Uses real StorageHolder/IncomeStreamModel
    // objects to simulate the on-disk state across repeated "app opens."

    @Test
    public void resolveIncomeState_usesPersistedDates_notStreamAnchor() {
        // The stream's anchor checkDate is 60 days in the past -- if resolveIncomeState re-derived
        // curCheckDate/nextCheckDate from it (the pre-fix bug), the resolved nextCheckDate would be
        // ~46 days in the past (clearly "overdue"). The persisted curCheckDate/nextCheckDate say the
        // period is due exactly today instead -- that's what must win.
        LocalDate today = LocalDate.now();
        LocalDate anchor = today.minusDays(60);

        IncomeStreamModel stream = new IncomeStreamModel(
                "Job", "1000.00", anchor.format(CHECK_DATE_FMT), 14, 0); // 0 = DAYS
        stream.setSelected(true);
        ArrayList<IncomeStreamModel> streams = new ArrayList<>();
        streams.add(stream);

        StorageHolder holder = new StorageHolder();
        holder.setIncomeStreamList(streams);
        holder.setCurCheckDate(today);
        holder.setNextCheckDate(today);

        FinancialCalc.ResolvedIncomeState resolved = FinancialCalc.resolveIncomeState(holder);

        assertEquals("curCheckDate must come from persisted storage, not the stream's anchor date",
                today, resolved.curCheckDate);
        assertEquals("nextCheckDate must come from persisted storage, not the stream's anchor date",
                today, resolved.nextCheckDate);
        assertEquals(1000f, resolved.averageCheck, 0.001f);
        assertEquals(14, resolved.checkFrequency);
        assertEquals(ChronoUnit.DAYS, resolved.checkFrequencyTag);
    }

    @Test
    public void reopenSimulation_resolveThenRoll_repeatedSameDayReopens_creditIncomeExactlyOnce() {
        // End-to-end simulation of the reported bug using the real production path: build a
        // StorageHolder as it would exist on disk, resolve it, roll forward, write the result back
        // into a fresh StorageHolder (as ExpenseActivity's WRITE case would), and repeat -- exactly
        // what happens each time a user force-quits and reopens the app. The stream's anchor date is
        // deliberately far in the past and NEVER changes across "opens" (nothing in production code
        // updates it either), which is what exposed the original bug.
        LocalDate today = LocalDate.now();
        LocalDate anchor = today.minusDays(90);

        IncomeStreamModel stream = new IncomeStreamModel(
                "Job", "1000.00", anchor.format(CHECK_DATE_FMT), 14, 0);
        stream.setSelected(true);
        ArrayList<IncomeStreamModel> streams = new ArrayList<>();
        streams.add(stream);

        StorageHolder holder = new StorageHolder();
        holder.setIncomeStreamList(streams);
        holder.setCurCheckDate(today);
        holder.setNextCheckDate(today);

        float balance = 0f;
        for (int reopen = 0; reopen < 10; reopen++) {
            FinancialCalc.ResolvedIncomeState resolved = FinancialCalc.resolveIncomeState(holder);
            FinancialCalc.CheckRollResult roll = FinancialCalc.rollCheckDateForward(
                    today, resolved.curCheckDate, resolved.nextCheckDate,
                    resolved.checkFrequency, resolved.checkFrequencyTag, resolved.averageCheck);
            balance += roll.creditedIncome;

            // Simulate handleStorage(WRITE) followed by a fresh handleStorage(READ) on the next
            // open: persist the rolled dates, but the stream itself (and its anchor) is untouched.
            holder = new StorageHolder();
            holder.setIncomeStreamList(streams);
            holder.setCurCheckDate(roll.curCheckDate);
            holder.setNextCheckDate(roll.nextCheckDate);
        }

        assertEquals("10 simulated force-quit/reopen cycles on the same payday must credit income "
                + "exactly once, not " + (balance / 1000f) + " times",
                1000f, balance, 0.001f);
    }

    @Test
    public void rollCheckDateForward_notYetDue_creditsNothing() {
        LocalDate today = LocalDate.now();
        FinancialCalc.CheckRollResult result = FinancialCalc.rollCheckDateForward(
                today, today, today.plusDays(1), 14, ChronoUnit.DAYS, 1000f);

        assertEquals(0f, result.creditedIncome, 0.001f);
        assertEquals(0, result.rolledPeriods.size());
        assertEquals(today, result.curCheckDate);
        assertEquals(today.plusDays(1), result.nextCheckDate);
    }
}
