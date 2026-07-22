package io.github.nishian3695.bujit.ExpenseActivity;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

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
