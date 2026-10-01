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

    // --- Month-end paydays: a pay date on the 31st falls on the last day of short months and
    // returns to the 31st afterwards, instead of drifting to the 28th forever ---

    @Test
    public void stepDate_monthlyAnchor31_snapsBackForwardAndBackward() {
        LocalDate feb = FinancialCalc.stepDate(LocalDate.of(2027, 1, 31), 1, ChronoUnit.MONTHS, 31);
        assertEquals(LocalDate.of(2027, 2, 28), feb);
        assertEquals(LocalDate.of(2027, 3, 31), FinancialCalc.stepDate(feb, 1, ChronoUnit.MONTHS, 31));
        assertEquals(LocalDate.of(2027, 1, 31), FinancialCalc.stepDate(feb, -1, ChronoUnit.MONTHS, 31));
    }

    @Test
    public void stepDate_weeks_ignoresAnchor() {
        assertEquals(LocalDate.of(2027, 2, 14),
                FinancialCalc.stepDate(LocalDate.of(2027, 1, 31), 2, ChronoUnit.WEEKS, 31));
    }

    @Test
    public void countIncomeOccurrences_monthlyPayOn31st_findsMarch31() {
        IncomeStreamModel inc = new IncomeStreamModel("Job", "1000", "2027.01.31", 1, 2); // 2=MONTHS

        assertEquals(1, FinancialCalc.countIncomeOccurrences(inc, LocalDate.of(2027, 3, 31), LocalDate.of(2027, 4, 1)));
        assertEquals(0, FinancialCalc.countIncomeOccurrences(inc, LocalDate.of(2027, 3, 28), LocalDate.of(2027, 3, 29)));
    }

    @Test
    public void rollCheckDateForward_monthlyPayOn31st_landsOnMonthEnds() {
        FinancialCalc.CheckRollResult result = FinancialCalc.rollCheckDateForward(
                LocalDate.of(2027, 5, 1), LocalDate.of(2027, 1, 31), LocalDate.of(2027, 2, 28),
                1, ChronoUnit.MONTHS, 31);

        assertEquals(3, result.rolledPeriods.size()); // paid Feb 28, Mar 31, Apr 30
        assertEquals(LocalDate.of(2027, 3, 31), result.rolledPeriods.get(1)[1]);
        assertEquals(LocalDate.of(2027, 4, 30), result.curCheckDate);
        assertEquals(LocalDate.of(2027, 5, 31), result.nextCheckDate);
    }

    @Test
    public void incomeArrivedSince_monthlyPayOn31st_creditsMonthEnds() {
        List<IncomeStreamModel> streams = new ArrayList<>();
        streams.add(new IncomeStreamModel("Job", "1000", "2027.01.31", 1, 2)); // 2=MONTHS

        // Feb 28, Mar 31, Apr 30
        assertEquals(3000f, FinancialCalc.incomeArrivedSince(
                streams, LocalDate.of(2027, 1, 31), LocalDate.of(2027, 5, 1)), 0.001f);
    }

    @Test
    public void rollCheckDateForward_alreadyDriftedDates_healToAnchorDay() {
        // Dates saved by an older build that drifted to the 28th.
        FinancialCalc.CheckRollResult result = FinancialCalc.rollCheckDateForward(
                LocalDate.of(2027, 4, 28), LocalDate.of(2027, 3, 28), LocalDate.of(2027, 4, 28),
                1, ChronoUnit.MONTHS, 31);

        assertEquals(LocalDate.of(2027, 4, 30), result.curCheckDate);
        assertEquals(LocalDate.of(2027, 5, 31), result.nextCheckDate);
    }

    @Test
    public void payAnchorDay_usesSelectedStreamElseFallback() {
        List<IncomeStreamModel> streams = new ArrayList<>();
        IncomeStreamModel other = new IncomeStreamModel("Side", "100", "2027.01.15", 1, 2);
        IncomeStreamModel main = new IncomeStreamModel("Main", "1000", "2027.01.31", 1, 2);
        main.setSelected(true);
        streams.add(other);
        streams.add(main);

        assertEquals(31, FinancialCalc.payAnchorDay(streams, LocalDate.of(2027, 2, 28)));
        main.setSelected(false);
        assertEquals(28, FinancialCalc.payAnchorDay(streams, LocalDate.of(2027, 2, 28)));
    }

    @Test
    public void countExpenseOccurrences_regularExpense_countsFrequencyBased() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Netflix", "15.00", today, 7, ChronoUnit.DAYS, false);

        int occ = FinancialCalc.countExpenseOccurrences(e, today, today.plusDays(28));

        assertEquals(4, occ);
    }

    @Test
    public void countExpenseOccurrences_endDate_stopsCountingAfterIt() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Gym", "15.00", today, 7, ChronoUnit.DAYS, false);
        e.setEndDate(today.plusDays(14)); // today, +7, +14 (inclusive)

        int occ = FinancialCalc.countExpenseOccurrences(e, today, today.plusDays(28));

        assertEquals(3, occ);
    }

    @Test
    public void countExpenseOccurrences_futureStartDate_doesNotCountEarlierPeriods() {
        LocalDate today = LocalDate.now();
        LocalDate start = today.plusDays(14);
        ExpenseModel e = new ExpenseModel("Gym", "15.00", start, 7, ChronoUnit.DAYS, false);
        e.setStartDate(start);

        // Without startDate this rewinds to count -14, -7, 0, +7 as well.
        int occ = FinancialCalc.countExpenseOccurrences(e, today.minusDays(14), today.plusDays(28));

        assertEquals(2, occ); // +14, +21
    }

    @Test
    public void countExpenseOccurrences_noStartDate_keepsLegacyRewindBehavior() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Gym", "15.00", today.plusDays(14), 7, ChronoUnit.DAYS, false);

        int occ = FinancialCalc.countExpenseOccurrences(e, today.minusDays(14), today.plusDays(28));

        assertEquals(6, occ);
    }

    @Test
    public void countExpenseOccurrences_monthly31st_findsMarch31AfterFebruary() {
        ExpenseModel e = new ExpenseModel("Rent", "100.00", LocalDate.of(2027, 1, 31), 1, ChronoUnit.MONTHS, false);

        // Drifting stepping would give Feb 28 -> Mar 28 and miss Mar 31 entirely.
        int occ = FinancialCalc.countExpenseOccurrences(e, LocalDate.of(2027, 3, 31), LocalDate.of(2027, 4, 1));

        assertEquals(1, occ);
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

    // --- Income crediting: regression coverage for the "income re-credited on every app open"
    // (infinite-money) bug. Income used to be credited by rollCheckDateForward per rolled pay
    // period, so re-deriving the period dates from a stream's static anchor re-credited it. Income
    // is now credited by incomeArrivedSince from the persisted incomeCreditedThrough date, which
    // advances to today on every open; these tests simulate reopens exactly that way.

    private static List<IncomeStreamModel> biweeklyJob(LocalDate anchor, String amount) {
        List<IncomeStreamModel> streams = new ArrayList<>();
        streams.add(new IncomeStreamModel("Job", amount, anchor.format(CHECK_DATE_FMT), 14, 0));
        return streams;
    }

    @Test
    public void incomeArrivedSince_paydayToday_creditsItOnce() {
        LocalDate today = LocalDate.now();
        // Last payday 14 days ago (already credited), the next one is today.
        float credited = FinancialCalc.incomeArrivedSince(
                biweeklyJob(today.minusDays(14), "1000"), today.minusDays(14), today);

        assertEquals(1000f, credited, 0.001f);
    }

    @Test
    public void incomeArrivedSince_calledAgainSameDay_doesNotDoubleCredit() {
        // Opening on payday credits it and advances creditedThrough to today; reopening later the
        // same day must credit nothing.
        LocalDate today = LocalDate.now();
        List<IncomeStreamModel> streams = biweeklyJob(today.minusDays(14), "1000");
        assertEquals(1000f, FinancialCalc.incomeArrivedSince(streams, today.minusDays(14), today), 0.001f);

        assertEquals("Reopening the app on the same day must not re-credit income",
                0f, FinancialCalc.incomeArrivedSince(streams, today, today), 0.001f);
    }

    @Test
    public void incomeArrivedSince_reopenManyTimes_creditsEachPaycheckOnce() {
        // Directly simulates "user force-quits and reopens the app repeatedly on payday" --
        // the exact scenario reported as the infinite-money glitch -- with creditedThrough
        // persisted between opens as ExpenseActivity does.
        LocalDate today = LocalDate.now();
        List<IncomeStreamModel> streams = biweeklyJob(today.minusDays(14), "1000");
        LocalDate creditedThrough = today.minusDays(14);
        float balance = 0f;

        for (int reopen = 0; reopen < 20; reopen++) {
            balance += FinancialCalc.incomeArrivedSince(streams, creditedThrough, today);
            creditedThrough = today;
        }

        assertEquals("20 simulated app reopens on the same payday must credit income only once",
                1000f, balance, 0.001f);
    }

    @Test
    public void incomeArrivedSince_multipleMissedPaydays_creditsEachExactlyOnce() {
        // App wasn't opened for 6 weeks; biweekly pay catches up 3 paychecks, then nothing more.
        LocalDate today = LocalDate.now();
        LocalDate anchor = today.minusDays(42);
        List<IncomeStreamModel> streams = biweeklyJob(anchor, "500");

        assertEquals(1500f, FinancialCalc.incomeArrivedSince(streams, anchor, today), 0.001f);
        assertEquals(0f, FinancialCalc.incomeArrivedSince(streams, today, today), 0.001f);
    }

    @Test
    public void incomeArrivedSince_creditsEveryStream() {
        // A side job (paydays -35 and -5) is credited too, not only the selected stream.
        LocalDate today = LocalDate.now();
        List<IncomeStreamModel> streams = biweeklyJob(today.minusDays(14), "1000");
        streams.add(new IncomeStreamModel("Side", "250", today.minusDays(35).format(CHECK_DATE_FMT), 30, 0));

        assertEquals(1250f, FinancialCalc.incomeArrivedSince(streams, today.minusDays(14), today), 0.001f);
    }

    @Test
    public void incomeArrivedSince_ignoresPaychecksBeforeCreditedThrough() {
        // A stream with an anchor far in the past (paydays ..., -13, +1): only paychecks after
        // the last credit count. Editing or re-selecting a stream resets curCheckDate to its
        // anchor; crediting no longer depends on curCheckDate, so that can't re-credit old ones.
        LocalDate today = LocalDate.now();
        List<IncomeStreamModel> streams = biweeklyJob(today.minusDays(97), "1000");

        assertEquals(0f, FinancialCalc.incomeArrivedSince(streams, today.minusDays(1), today), 0.001f);
        assertEquals(1000f, FinancialCalc.incomeArrivedSince(streams, today.minusDays(14), today), 0.001f);
    }

    @Test
    public void incomeArrivedSince_streamStartingInTheFuture_creditsNothing() {
        // The schedule extrapolates backward past its anchor for projections; crediting must not.
        LocalDate today = LocalDate.now();
        List<IncomeStreamModel> streams = biweeklyJob(today.plusDays(10), "1000");

        assertEquals(0f, FinancialCalc.incomeArrivedSince(streams, today.minusDays(60), today), 0.001f);
    }

    @Test
    public void incomeArrivedSince_startingDatesOwnPaycheck_isAlreadyInTheBalance() {
        // Same as the selected stream always worked: its pay period starts on the starting date.
        LocalDate today = LocalDate.now();
        List<IncomeStreamModel> streams = biweeklyJob(today, "1000");

        assertEquals(0f, FinancialCalc.incomeArrivedSince(streams, today.minusDays(5), today), 0.001f);
    }

    @Test
    public void initialIncomeCreditedThrough_alignedDates_isCurCheckDate() {
        LocalDate today = LocalDate.now();
        List<IncomeStreamModel> streams = biweeklyJob(today.minusDays(84), "1000");
        streams.get(0).setSelected(true);

        assertEquals(today.minusDays(14), FinancialCalc.initialIncomeCreditedThrough(
                streams, today.minusDays(14), today));
    }

    @Test
    public void initialIncomeCreditedThrough_driftedDates_doesNotCreditAPaycheckTwice() {
        // An older build drifted a 31st payday to the 28th: it credited March's paycheck on Mar 28
        // and stored the period [Mar 28, Apr 28). The stream's real March payday is Mar 31, which
        // must not be credited again; April's (Apr 30) still is.
        List<IncomeStreamModel> streams = new ArrayList<>();
        IncomeStreamModel job = new IncomeStreamModel("Job", "1000", "2027.01.31", 1, 2);
        job.setSelected(true);
        streams.add(job);

        LocalDate start = FinancialCalc.initialIncomeCreditedThrough(
                streams, LocalDate.of(2027, 3, 28), LocalDate.of(2027, 4, 28));

        assertEquals(LocalDate.of(2027, 3, 31), start);
        assertEquals(0f, FinancialCalc.incomeArrivedSince(streams, start, LocalDate.of(2027, 4, 29)), 0.001f);
        assertEquals(1000f, FinancialCalc.incomeArrivedSince(streams, start, LocalDate.of(2027, 4, 30)), 0.001f);
    }

    @Test
    public void incomeArrivedSince_skipsInvalidAmounts() {
        LocalDate today = LocalDate.now();
        List<IncomeStreamModel> streams = biweeklyJob(today, "not-a-number");
        streams.add(new IncomeStreamModel("Zero", "0", today.format(CHECK_DATE_FMT), 14, 0));

        assertEquals(0f, FinancialCalc.incomeArrivedSince(streams, today.minusDays(1), today), 0.001f);
    }

    // --- rollCheckDateForward: now only advances the pay-period dates (and reports ended periods
    // for history), but must still be idempotent when fed its own prior output.

    @Test
    public void rollCheckDateForward_dueToday_rollsExactlyOnePeriod() {
        LocalDate today = LocalDate.now();
        FinancialCalc.CheckRollResult result = FinancialCalc.rollCheckDateForward(
                today, today, today, 14, ChronoUnit.DAYS, 0);

        assertEquals(1, result.rolledPeriods.size());
        assertEquals(today.plusDays(14), result.nextCheckDate);
        assertEquals(today.plusDays(14), result.curCheckDate);
    }

    @Test
    public void rollCheckDateForward_calledAgainSameDayWithPriorOutput_rollsNothing() {
        LocalDate today = LocalDate.now();
        FinancialCalc.CheckRollResult firstOpen = FinancialCalc.rollCheckDateForward(
                today, today, today, 14, ChronoUnit.DAYS, 0);

        FinancialCalc.CheckRollResult secondOpen = FinancialCalc.rollCheckDateForward(
                today, firstOpen.curCheckDate, firstOpen.nextCheckDate, 14, ChronoUnit.DAYS, 0);

        assertEquals(0, secondOpen.rolledPeriods.size());
        assertEquals(firstOpen.nextCheckDate, secondOpen.nextCheckDate);
    }

    @Test
    public void rollCheckDateForward_multipleMissedPeriods_rollsEachOnce() {
        LocalDate today = LocalDate.now();
        LocalDate anchor = today.minusDays(42);

        FinancialCalc.CheckRollResult caughtUp = FinancialCalc.rollCheckDateForward(
                today, anchor, anchor.plusDays(14), 14, ChronoUnit.DAYS, 0);

        assertEquals(3, caughtUp.rolledPeriods.size());
        assertEquals(anchor.plusDays(56), caughtUp.nextCheckDate);
        assertEquals(0, FinancialCalc.rollCheckDateForward(
                today, caughtUp.curCheckDate, caughtUp.nextCheckDate, 14, ChronoUnit.DAYS, 0)
                .rolledPeriods.size());
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
        LocalDate anchor = today.minusDays(84); // paydays every 14 days: ..., -14, today

        IncomeStreamModel stream = new IncomeStreamModel(
                "Job", "1000.00", anchor.format(CHECK_DATE_FMT), 14, 0);
        stream.setSelected(true);
        ArrayList<IncomeStreamModel> streams = new ArrayList<>();
        streams.add(stream);

        // Saved before incomeCreditedThrough existed: the last roll-over credited the -14 payday.
        StorageHolder holder = new StorageHolder();
        holder.setIncomeStreamList(streams);
        holder.setCurCheckDate(today.minusDays(14));
        holder.setNextCheckDate(today);

        float balance = 0f;
        for (int reopen = 0; reopen < 10; reopen++) {
            // Mirrors ExpenseActivity.checkForNextCheck: credit from incomeCreditedThrough (or its
            // initial value for data saved before it existed), then roll the period dates.
            FinancialCalc.ResolvedIncomeState resolved = FinancialCalc.resolveIncomeState(holder);
            LocalDate creditedThrough = holder.getIncomeCreditedThrough() != null
                    ? holder.getIncomeCreditedThrough()
                    : FinancialCalc.initialIncomeCreditedThrough(
                            resolved.incomeStreamList, resolved.curCheckDate, resolved.nextCheckDate);
            balance += FinancialCalc.incomeArrivedSince(resolved.incomeStreamList, creditedThrough, today);
            FinancialCalc.CheckRollResult roll = FinancialCalc.rollCheckDateForward(
                    today, resolved.curCheckDate, resolved.nextCheckDate,
                    resolved.checkFrequency, resolved.checkFrequencyTag, 0);

            // Simulate handleStorage(WRITE) followed by a fresh handleStorage(READ) on the next
            // open: persist the rolled dates and creditedThrough, but the stream itself (and its
            // anchor) is untouched.
            holder = new StorageHolder();
            holder.setIncomeStreamList(streams);
            holder.setCurCheckDate(roll.curCheckDate);
            holder.setNextCheckDate(roll.nextCheckDate);
            holder.setIncomeCreditedThrough(today.isAfter(creditedThrough) ? today : creditedThrough);
        }

        assertEquals("10 simulated force-quit/reopen cycles on the same payday must credit income "
                + "exactly once, not " + (balance / 1000f) + " times",
                1000f, balance, 0.001f);
    }

    // --- Regressions for two bugs confirmed against the previous code (each test failed there) ---

    @Test
    public void openingTheApp_creditsEveryStreamsPaychecks_includingOnFirstOpenAfterUpdate() {
        // Selected job pays $1000 every 14 days (last payday 14 days ago, so one is due today);
        // a side job (paydays -35 and -5) paid $250 five days ago. Opening today should credit
        // both: $1250. Previously only the selected stream's averageCheck was credited ($1000).
        // This is data saved before incomeCreditedThrough existed, so crediting starts from its
        // initial value, as in ExpenseActivity.checkForNextCheck.
        LocalDate today = LocalDate.now();
        IncomeStreamModel job = new IncomeStreamModel(
                "Job", "1000.00", today.minusDays(14).format(CHECK_DATE_FMT), 14, 0);
        job.setSelected(true);
        IncomeStreamModel side = new IncomeStreamModel(
                "Side", "250.00", today.minusDays(35).format(CHECK_DATE_FMT), 30, 0);
        ArrayList<IncomeStreamModel> streams = new ArrayList<>();
        streams.add(job);
        streams.add(side);
        StorageHolder holder = new StorageHolder();
        holder.setIncomeStreamList(streams);
        holder.setCurCheckDate(today.minusDays(14));
        holder.setNextCheckDate(today);

        FinancialCalc.ResolvedIncomeState resolved = FinancialCalc.resolveIncomeState(holder);
        LocalDate creditedThrough = holder.getIncomeCreditedThrough() != null
                ? holder.getIncomeCreditedThrough()
                : FinancialCalc.initialIncomeCreditedThrough(
                        resolved.incomeStreamList, resolved.curCheckDate, resolved.nextCheckDate);

        assertEquals(1250f, FinancialCalc.incomeArrivedSince(
                resolved.incomeStreamList, creditedThrough, today), 0.001f);
    }

    @Test
    public void creditCardPaidThisCheck_isNotSubtractedTwice() {
        // $1000 balance; a $500 card was due 3 days ago, inside the current check. Opening the app
        // pays it (balance -> $500) exactly as ExpenseActivity.bringDataUpToDate does, then After
        // This Check is balance - checkExpensesTotal(), as in ExpenseActivity.setFinalBalance.
        // It should be $500: the card is already paid.
        LocalDate today = LocalDate.now();
        LocalDate beg = today.minusDays(5);
        LocalDate end = today.plusDays(9);
        CreditModel card = new CreditModel("Card", "500.00", today.minusDays(3), "2000.00");
        List<ExpenseItem> expenses = new ArrayList<>();
        expenses.add(card);

        float balance = 1000f;
        balance -= card.makeCurrent(beg, end, expenses);
        float afterThisCheck = balance - FinancialCalc.checkExpensesTotal(expenses);

        assertEquals(500f, balance, 0.001f);
        assertEquals(500f, afterThisCheck, 0.001f);
    }

    @Test
    public void creditCardPaidThisCheck_rowStillShowsThePayoff() {
        // The fix only changes the total: the row keeps showing what was paid this check.
        LocalDate today = LocalDate.now();
        CreditModel card = new CreditModel("Card", "500.00", today.minusDays(3), "2000.00");
        List<ExpenseItem> expenses = new ArrayList<>();
        expenses.add(card);

        card.makeCurrent(today.minusDays(5), today.plusDays(9), expenses);

        assertEquals("500.00", card.getShownCost());
        assertEquals(0f, card.getUnpaidShownCost(), 0.001f);
    }

    @Test
    public void creditCardNotYetDue_isStillSubtracted() {
        // A card whose due date is still ahead in this check owes its balance.
        LocalDate today = LocalDate.now();
        CreditModel card = new CreditModel("Card", "500.00", today.plusDays(3), "2000.00");
        List<ExpenseItem> expenses = new ArrayList<>();
        expenses.add(card);

        card.makeCurrent(today.minusDays(5), today.plusDays(9), expenses);

        assertEquals(500f, FinancialCalc.checkExpensesTotal(expenses), 0.001f);
    }

    @Test
    public void rollCheckDateForward_notYetDue_rollsNothing() {
        LocalDate today = LocalDate.now();
        FinancialCalc.CheckRollResult result = FinancialCalc.rollCheckDateForward(
                today, today, today.plusDays(1), 14, ChronoUnit.DAYS, 0);

        assertEquals(0, result.rolledPeriods.size());
        assertEquals(today, result.curCheckDate);
        assertEquals(today.plusDays(1), result.nextCheckDate);
    }
}
