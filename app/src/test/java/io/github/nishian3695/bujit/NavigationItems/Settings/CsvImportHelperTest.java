package io.github.nishian3695.bujit.NavigationItems.Settings;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.StorageManagement.FinancialCalc;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import org.junit.Test;

/*
Covers expense row parsing, especially that the optional <_end_date> field (added after
<_category>) leaves every pre-existing row format importing exactly as before.
*/
public class CsvImportHelperTest {

    // Parses one CSV line as an expense row into a fresh holder and returns the added expense.
    private static ExpenseModel importExpense(String line) {
        StorageHolder h = new StorageHolder();
        CsvImportHelper.ImportResult r = new CsvImportHelper.ImportResult();
        CsvImportHelper.parseExpense(CsvImportHelper.splitCsvLine(line), h, r);
        assertEquals(1, r.expensesAdded);
        assertEquals(1, h.getExpenseList().size());
        return (ExpenseModel) h.getExpenseList().get(0);
    }

    @Test
    public void legacySixFieldRow_importsWithDefaultsAndNoEndDate() {
        ExpenseModel e = importExpense("expense,Rent,2200,2024-01-01,1,month");

        assertEquals("Rent", e.getName());
        assertEquals("2200.00", e.getCost());
        assertEquals(LocalDate.of(2024, 1, 1), e.getDate());
        assertEquals(1, e.getFrequency());
        assertEquals(ChronoUnit.MONTHS, e.getFrequencyTag());
        assertEquals("Other", e.getCategory());
        assertNull(e.getEndDate());
    }

    @Test
    public void legacySevenFieldRowWithCategory_importsWithNoEndDate() {
        ExpenseModel e = importExpense("expense,Rent,2200,2024-01-01,1,month,Housing");

        assertEquals("Housing", e.getCategory());
        assertNull(e.getEndDate());
    }

    @Test
    public void eightFieldRow_setsEndDate() {
        ExpenseModel e = importExpense("expense,Car Payment,350,2024-01-10,1,month,Transportation,2028-12-10");

        assertEquals("Transportation", e.getCategory());
        assertEquals(LocalDate.of(2028, 12, 10), e.getEndDate());
    }

    @Test
    public void blankCategoryWithEndDate_defaultsCategoryAndSetsEndDate() {
        ExpenseModel e = importExpense("expense,Gym,40,2026-11-01,1,month,,2027-06-30");

        assertEquals("Other", e.getCategory());
        assertEquals(LocalDate.of(2027, 6, 30), e.getEndDate());
    }

    @Test
    public void blankEndDate_meansNoEndDate() {
        ExpenseModel e = importExpense("expense,Rent,2200,2024-01-01,1,month,Housing,");

        assertNull(e.getEndDate());
    }

    @Test
    public void slashDateFormat_acceptedForEndDate() {
        ExpenseModel e = importExpense("expense,Gym,40,2026/11/01,1,month,Health,2027/06/30");

        assertEquals(LocalDate.of(2027, 6, 30), e.getEndDate());
    }

    @Test
    public void quotedNameWithComma_stillFindsEndDateField() {
        ExpenseModel e = importExpense("expense,\"Gym, Downtown\",40,2026-11-01,1,month,Health,2027-06-30");

        assertEquals("Gym, Downtown", e.getName());
        assertEquals(LocalDate.of(2027, 6, 30), e.getEndDate());
    }

    @Test
    public void endDateEqualToDueDate_isAccepted() {
        ExpenseModel e = importExpense("expense,One-off,99,2026-11-01,1,month,,2026-11-01");

        assertEquals(LocalDate.of(2026, 11, 1), e.getEndDate());
    }

    @Test
    public void dueDate_isSavedAsStartDate() {
        ExpenseModel e = importExpense("expense,Rent,2200,2024-01-01,1,month,Housing");

        assertEquals(LocalDate.of(2024, 1, 1), e.getStartDate());
    }

    @Test
    public void futureDueDate_notCountedInPeriodsBeforeItStarts() {
        LocalDate start = LocalDate.now().plusMonths(3).withDayOfMonth(1);
        ExpenseModel e = importExpense("expense,Streaming,15," + start + ",1,month");

        // Without a start date, stepping back from the due date would put phantom charges here.
        assertEquals(0, FinancialCalc.countExpenseOccurrences(e, start.minusMonths(2), start));
        assertEquals(1, FinancialCalc.countExpenseOccurrences(e, start, start.plusMonths(1)));
    }

    @Test
    public void endDateBeforeDueDate_isRejectedAndNothingAdded() {
        StorageHolder h = new StorageHolder();
        CsvImportHelper.ImportResult r = new CsvImportHelper.ImportResult();
        try {
            CsvImportHelper.parseExpense(
                    CsvImportHelper.splitCsvLine("expense,Gym,40,2026-11-01,1,month,Health,2026-10-01"), h, r);
            fail("expected the row to be rejected");
        } catch (IllegalArgumentException ex) {
            assertTrue(ex.getMessage().contains("before due_date"));
        }
        assertEquals(0, r.expensesAdded);
        assertTrue(h.getExpenseList().isEmpty());
    }

    @Test
    public void invalidEndDate_isRejectedWithDateError() {
        try {
            importExpense("expense,Gym,40,2026-11-01,1,month,Health,someday");
            fail("expected the row to be rejected");
        } catch (IllegalArgumentException ex) {
            assertTrue(ex.getMessage().contains("invalid date"));
        }
    }
}
