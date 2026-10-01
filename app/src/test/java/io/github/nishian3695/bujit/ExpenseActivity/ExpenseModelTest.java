package io.github.nishian3695.bujit.ExpenseActivity;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;
import org.junit.Test;

public class ExpenseModelTest {

    private static final List<ExpenseItem> NO_OTHER_EXPENSES = Collections.emptyList();

    @Test
    public void makeCurrent_futureDate_isNoOp() {
        LocalDate today = LocalDate.now();
        LocalDate future = today.plusDays(10);
        ExpenseModel e = new ExpenseModel("Rent", "1000.00", future, 30, ChronoUnit.DAYS, false);

        float paid = e.makeCurrent(today, today.plusDays(30), NO_OTHER_EXPENSES);

        assertEquals(0f, paid, 0.001f);
        assertEquals(future, e.getDate());
    }

    @Test
    public void makeCurrent_twoElapsedOccurrences_returnsTotalPaidAndAdvancesDate() {
        LocalDate today = LocalDate.now();
        LocalDate start = today.minusDays(60); // exactly 2 x 30-day periods ago
        ExpenseModel e = new ExpenseModel("Rent", "100.00", start, 30, ChronoUnit.DAYS, false);

        float paid = e.makeCurrent(today, today.plusDays(30), NO_OTHER_EXPENSES);

        assertEquals(200f, paid, 0.001f);
        assertFalse(today.isAfter(e.getDate())); // advanced to today or later
    }

    @Test
    public void getNextCheckPayments_singleOccurrenceInWindow_setsShownCostToOneOccurrence() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Netflix", "15.00", today.plusDays(5), 30, ChronoUnit.DAYS, false);

        e.getNextCheckPayments(today, today.plusDays(14), NO_OTHER_EXPENSES);

        assertEquals("15.00", e.getShownCost());
    }

    @Test
    public void getNextCheckPayments_noOccurrenceInWindow_setsShownCostToZero() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Netflix", "15.00", today.plusDays(20), 30, ChronoUnit.DAYS, false);

        e.getNextCheckPayments(today, today.plusDays(14), NO_OTHER_EXPENSES);

        assertEquals("0.00", e.getShownCost());
    }

    // --- Check windows: the current check is [today, payday]; a projected check is
    // (previous payday, payday]. An occurrence on payday counts toward the check ending that day
    // (it may clear before the paycheck lands) and is never counted again in the next one.

    @Test
    public void makeCurrent_dailyExpense_currentCheckIncludesPayday() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Coffee", "5.00", today, 1, ChronoUnit.DAYS, false);

        e.makeCurrent(today, today.plusDays(14), NO_OTHER_EXPENSES);

        assertEquals("75.00", e.getShownCost()); // days 0..14 inclusive = 15
    }

    @Test
    public void getNextCheckPayments_dailyExpense_doesNotRecountPreviousPayday() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Coffee", "5.00", today, 1, ChronoUnit.DAYS, false);
        e.makeCurrent(today, today.plusDays(14), NO_OTHER_EXPENSES);

        e.getNextCheckPayments(today.plusDays(14), today.plusDays(28), NO_OTHER_EXPENSES);

        assertEquals("70.00", e.getShownCost()); // days 15..28 = 14
        assertEquals(today.plusDays(15), e.getShownDate());
    }

    @Test
    public void weeklyExpenseAlignedWithBiweeklyPayday_isCountedOncePerOccurrence() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Gas", "40.00", today, 7, ChronoUnit.DAYS, false);

        e.makeCurrent(today, today.plusDays(14), NO_OTHER_EXPENSES);
        assertEquals("120.00", e.getShownCost()); // days 0, 7, 14

        e.getNextCheckPayments(today.plusDays(14), today.plusDays(28), NO_OTHER_EXPENSES);
        assertEquals("80.00", e.getShownCost()); // days 21, 28

        e.getNextCheckPayments(today.plusDays(28), today.plusDays(42), NO_OTHER_EXPENSES);
        assertEquals("80.00", e.getShownCost()); // days 35, 42

        e.getPrevCheckPayments(today.plusDays(14), today.plusDays(28), NO_OTHER_EXPENSES);
        assertEquals("80.00", e.getShownCost()); // back to days 21, 28
    }

    @Test
    public void monthlyExpenseDueOnPayday_countsInCurrentCheckNotNext() {
        LocalDate today = LocalDate.now();
        LocalDate payday = today.plusDays(14);
        ExpenseModel rent = new ExpenseModel("Rent", "1000.00", payday, 1, ChronoUnit.MONTHS, false);

        rent.makeCurrent(today, payday, NO_OTHER_EXPENSES);
        assertEquals("1000.00", rent.getShownCost());

        rent.getNextCheckPayments(payday, payday.plusDays(14), NO_OTHER_EXPENSES);
        assertEquals("0.00", rent.getShownCost());
    }

    @Test
    public void getOccurrences_monthlyExpense_usesCalendarMonths() {
        LocalDate jan31 = LocalDate.of(2027, 1, 31);
        ExpenseModel e = new ExpenseModel("Sub", "10.00", jan31, 1, ChronoUnit.MONTHS, false);

        // Jan 31, Feb 28, Mar 31 — calendar months, not a fixed 30-day approximation.
        e.getNextCheckPayments(jan31.minusDays(1), LocalDate.of(2027, 3, 31), NO_OTHER_EXPENSES);

        assertEquals("30.00", e.getShownCost());
    }

    @Test
    public void getPrevCheckPayments_rewindsAndComputesShownCost() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Rent", "100.00", today.plusDays(40), 30, ChronoUnit.DAYS, false);

        e.getPrevCheckPayments(today.minusDays(1), today.plusDays(29), NO_OTHER_EXPENSES);

        assertEquals("100.00", e.getShownCost());
    }

    // --- Month-end dates: a 31st expense falls on the last day of short months and returns to
    // the 31st afterwards, instead of drifting to the 28th forever ---

    @Test
    public void stepOccurrence_monthly31st_snapsBackAfterShortMonths() {
        ExpenseModel e = new ExpenseModel("Rent", "100.00", LocalDate.of(2027, 1, 31), 1, ChronoUnit.MONTHS, false);

        LocalDate feb = e.stepOccurrence(LocalDate.of(2027, 1, 31), 1);
        LocalDate mar = e.stepOccurrence(feb, 1);
        LocalDate apr = e.stepOccurrence(mar, 1);
        LocalDate may = e.stepOccurrence(apr, 1);

        assertEquals(LocalDate.of(2027, 2, 28), feb);
        assertEquals(LocalDate.of(2027, 3, 31), mar);
        assertEquals(LocalDate.of(2027, 4, 30), apr);
        assertEquals(LocalDate.of(2027, 5, 31), may);
    }

    @Test
    public void stepOccurrence_monthly31st_backwardAlsoSnapsBack() {
        ExpenseModel e = new ExpenseModel("Rent", "100.00", LocalDate.of(2027, 3, 31), 1, ChronoUnit.MONTHS, false);

        LocalDate feb = e.stepOccurrence(LocalDate.of(2027, 3, 31), -1);

        assertEquals(LocalDate.of(2027, 2, 28), feb);
        assertEquals(LocalDate.of(2027, 1, 31), e.stepOccurrence(feb, -1));
    }

    @Test
    public void stepOccurrence_yearlyLeapDay_returnsToFeb29InLeapYears() {
        ExpenseModel e = new ExpenseModel("Renewal", "50.00", LocalDate.of(2028, 2, 29), 1, ChronoUnit.YEARS, false);

        LocalDate d = LocalDate.of(2028, 2, 29);
        for (int i = 0; i < 3; i++) {
            d = e.stepOccurrence(d, 1);
            assertEquals(28, d.getDayOfMonth()); // 2029-2031
        }
        assertEquals(LocalDate.of(2032, 2, 29), e.stepOccurrence(d, 1));
    }

    @Test
    public void makeCurrent_monthly31st_overManyMonths_landsOnMonthEnd() {
        LocalDate m = LocalDate.now().minusMonths(13);
        while (m.lengthOfMonth() != 31) m = m.minusMonths(1);
        ExpenseModel e = new ExpenseModel("Rent", "100.00", m.withDayOfMonth(31), 1, ChronoUnit.MONTHS, false);

        e.makeCurrent(LocalDate.now(), LocalDate.now().plusDays(14), NO_OTHER_EXPENSES);

        LocalDate next = e.getDate();
        assertEquals(next.lengthOfMonth(), next.getDayOfMonth()); // always the last day of its month
    }

    @Test
    public void setDate_reanchorsTheScheduleDay() {
        ExpenseModel e = new ExpenseModel("Rent", "100.00", LocalDate.of(2027, 1, 31), 1, ChronoUnit.MONTHS, false);

        e.setDate(LocalDate.of(2027, 1, 15));

        assertEquals(15, e.getAnchorDay());
        assertEquals(LocalDate.of(2027, 2, 15), e.stepOccurrence(e.getDate(), 1));
    }

    // --- End dates ---

    @Test
    public void makeCurrent_endDatePassed_onlyPaysOccurrencesUpToEndDate() {
        LocalDate today = LocalDate.now();
        // Occurrences at -60 and -30; the expense ended at -45, so only -60 was paid.
        ExpenseModel e = new ExpenseModel("Gym", "100.00", today.minusDays(60), 30, ChronoUnit.DAYS, false);
        e.setEndDate(today.minusDays(45));

        float paid = e.makeCurrent(today, today.plusDays(30), NO_OTHER_EXPENSES);

        assertEquals(100f, paid, 0.001f);
        assertTrue(e.hasEnded());
        assertEquals("0.00", e.getShownCost());
    }

    @Test
    public void makeCurrent_occurrenceOnEndDate_isPaid() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Gym", "100.00", today.minusDays(60), 30, ChronoUnit.DAYS, false);
        e.setEndDate(today.minusDays(30)); // inclusive

        float paid = e.makeCurrent(today, today.plusDays(30), NO_OTHER_EXPENSES);

        assertEquals(200f, paid, 0.001f);
    }

    @Test
    public void makeCurrent_appReopenedLongAfterEnd_doesNotKeepPaying() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Trial", "10.00", today.minusDays(365), 7, ChronoUnit.DAYS, false);
        e.setEndDate(today.minusDays(351)); // occurrences at -365, -358, -351

        float paid = e.makeCurrent(today, today.plusDays(14), NO_OTHER_EXPENSES);

        assertEquals(30f, paid, 0.001f);
        // A second open must not pay anything more.
        assertEquals(0f, e.makeCurrent(today, today.plusDays(14), NO_OTHER_EXPENSES), 0.001f);
    }

    @Test
    public void makeCurrent_endDateInFuture_behavesAsUnbounded() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Rent", "100.00", today.minusDays(60), 30, ChronoUnit.DAYS, false);
        e.setEndDate(today.plusDays(100));

        float paid = e.makeCurrent(today, today.plusDays(30), NO_OTHER_EXPENSES);

        assertEquals(200f, paid, 0.001f);
        assertFalse(e.hasEnded());
    }

    @Test
    public void getNextCheckPayments_occurrenceAfterEndDate_isZero() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Netflix", "15.00", today.plusDays(5), 30, ChronoUnit.DAYS, false);
        e.setEndDate(today.plusDays(2));

        e.getNextCheckPayments(today, today.plusDays(14), NO_OTHER_EXPENSES);

        assertEquals("0.00", e.getShownCost());
    }

    @Test
    public void getNextCheckPayments_occurrenceOnEndDate_counts() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Netflix", "15.00", today.plusDays(5), 30, ChronoUnit.DAYS, false);
        e.setEndDate(today.plusDays(5));

        e.getNextCheckPayments(today, today.plusDays(14), NO_OTHER_EXPENSES);

        assertEquals("15.00", e.getShownCost());
    }

    @Test
    public void makeCurrent_multiplePerCheck_endingMidCheck_countsOnlyThroughEndDate() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Coffee", "5.00", today, 1, ChronoUnit.DAYS, false);
        e.setEndDate(today.plusDays(2)); // today, +1, +2

        e.makeCurrent(today, today.plusDays(14), NO_OTHER_EXPENSES);

        assertEquals("15.00", e.getShownCost());
    }

    @Test
    public void category_defaultsToOther() {
        ExpenseModel e = new ExpenseModel("Rent", "100.00", LocalDate.now(), 30, ChronoUnit.DAYS, false);
        assertEquals("Other", e.getCategory());
    }

    @Test
    public void isCredit_isFalse() {
        ExpenseModel e = new ExpenseModel("Rent", "100.00", LocalDate.now(), 30, ChronoUnit.DAYS, false);
        assertFalse(e.isCredit());
    }
}
