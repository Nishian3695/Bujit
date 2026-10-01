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

    @Test
    public void getNextCheckPayments_multipleOccurrencesPerCheck_countsEachOne() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Coffee", "5.00", today, 1, ChronoUnit.DAYS, false);
        e.setPerPay(14, ChronoUnit.DAYS, today); // a 14-day check period containing a daily expense

        e.getNextCheckPayments(today, today.plusDays(14), NO_OTHER_EXPENSES);

        // getOccurrences' ePerPay>1 branch counts floor(daysBetween(shownDate, nextCheck) / eDaysBtwn) + 1
        // = floor(14 / 1) + 1 = 15 occurrences.
        assertEquals("75.00", e.getShownCost());
    }

    @Test
    public void getPrevCheckPayments_rewindsAndComputesShownCost() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Rent", "100.00", today.plusDays(40), 30, ChronoUnit.DAYS, false);

        e.getPrevCheckPayments(today.minusDays(1), today.plusDays(29), NO_OTHER_EXPENSES);

        assertEquals("100.00", e.getShownCost());
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
    public void getNextCheckPayments_multiplePerCheck_endingMidCheck_countsOnlyThroughEndDate() {
        LocalDate today = LocalDate.now();
        ExpenseModel e = new ExpenseModel("Coffee", "5.00", today, 1, ChronoUnit.DAYS, false);
        e.setPerPay(14, ChronoUnit.DAYS, today);
        e.setEndDate(today.plusDays(2)); // today, +1, +2

        e.getNextCheckPayments(today, today.plusDays(14), NO_OTHER_EXPENSES);

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
