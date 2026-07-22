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
}
