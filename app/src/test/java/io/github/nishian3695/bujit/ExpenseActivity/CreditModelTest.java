package io.github.nishian3695.bujit.ExpenseActivity;

import static org.junit.Assert.assertEquals;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.junit.Test;

/*
Covers the two-tier shownCost/displayBalance model and its deliberate one-period lag, which was
the source of several rounds of bugs this project went through: shownCost is "amount due THIS
period" (zero except in the period the due date falls in); displayBalance is the ongoing balance
for the Rate label/utilization bar, which resets one period later than shownCost does.
*/
public class CreditModelTest {

    private static final List<ExpenseItem> NO_OTHER_EXPENSES = Collections.emptyList();

    @Test
    public void makeCurrent_futureDueDate_isNoOpAndLeavesDisplayBalanceAtCost() {
        LocalDate today = LocalDate.now();
        LocalDate dueDate = today.plusMonths(3);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");

        float paid = card.makeCurrent(today, today.plusDays(14), NO_OTHER_EXPENSES);

        assertEquals(0f, paid, 0.001f);
        assertEquals("500.00", card.getCost());
        assertEquals("500.00", card.getDisplayBalance());
    }

    @Test
    public void makeCurrent_pastDueDate_laterPeriod_zeroesRealBalanceAndDisplay() {
        LocalDate dueDate = LocalDate.now().minusMonths(2);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");
        LocalDate beg = dueDate.plusMonths(1); // a check period after the one the due date fell in
        LocalDate end = dueDate.plusMonths(2);

        float paid = card.makeCurrent(beg, end, NO_OTHER_EXPENSES);

        assertEquals(500f, paid, 0.001f);
        assertEquals("0.00", card.getCost());
        assertEquals("0.00", card.getShownCost());
        assertEquals("0.00", card.getDisplayBalance());
    }

    @Test
    public void makeCurrent_pastDueDate_sameCheckPeriod_displayLagsOnePeriod() {
        LocalDate dueDate = LocalDate.now().minusMonths(2);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");
        LocalDate beg = dueDate.minusDays(1);
        LocalDate end = dueDate.plusDays(1); // the check period the due date itself fell in

        float paid = card.makeCurrent(beg, end, NO_OTHER_EXPENSES);

        assertEquals(500f, paid, 0.001f);
        assertEquals("0.00", card.getCost()); // real balance is always zeroed once passed
        assertEquals("500.00", card.getShownCost()); // but display still shows the payoff...
        assertEquals("500.00", card.getDisplayBalance()); // ...for this one transition period
    }

    @Test
    public void makeCurrent_calledAgainNextPeriod_lagResolvesToZero() {
        LocalDate dueDate = LocalDate.now().minusMonths(2);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");
        card.makeCurrent(dueDate.minusDays(1), dueDate.plusDays(1), NO_OTHER_EXPENSES); // establishes the lag

        float paid = card.makeCurrent(dueDate.plusMonths(1), dueDate.plusMonths(2), NO_OTHER_EXPENSES);

        assertEquals(0f, paid, 0.001f); // nothing new elapsed
        assertEquals("0.00", card.getShownCost());
        assertEquals("0.00", card.getDisplayBalance()); // lag has now resolved
    }

    @Test
    public void getNextCheckPayments_beforeDueDate_displayBalanceIncludesSourcedCharge() {
        LocalDate today = LocalDate.now();
        LocalDate dueDate = today.plusDays(40);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");
        LocalDate beg = today.plusDays(15);
        LocalDate end = today.plusDays(35);
        // A long frequency (200 days) guarantees this charge occurs at most once in any window
        // this test uses, keeping the expected total unambiguous.
        ExpenseModel charge = new ExpenseModel("Groceries", "50.00", end.minusDays(5), 200, ChronoUnit.DAYS, false);
        charge.setSource("CREDIT_CARD");
        charge.setSourceId(card.getName());
        List<ExpenseItem> all = new ArrayList<>();
        all.add(card);
        all.add(charge);

        card.getNextCheckPayments(beg, end, all);

        assertEquals("0.00", card.getShownCost()); // nothing due yet
        assertEquals("550.00", card.getDisplayBalance()); // $500 base + $50 sourced charge
    }

    @Test
    public void getPrevCheckPayments_beforeDueDate_matchesGetNextCheckPaymentsResult() {
        LocalDate today = LocalDate.now();
        LocalDate dueDate = today.plusDays(40);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");
        LocalDate beg = today.plusDays(15);
        LocalDate end = today.plusDays(35);
        ExpenseModel charge = new ExpenseModel("Groceries", "50.00", end.minusDays(5), 200, ChronoUnit.DAYS, false);
        charge.setSource("CREDIT_CARD");
        charge.setSourceId(card.getName());
        List<ExpenseItem> all = new ArrayList<>();
        all.add(card);
        all.add(charge);

        card.getPrevCheckPayments(beg, end, all);

        assertEquals("0.00", card.getShownCost());
        assertEquals("550.00", card.getDisplayBalance());
    }

    @Test
    public void getNextCheckPayments_windowStartsExactlyOnDueDate_displayStillShowsPreResetBalance() {
        // Regression test for the reset-lag boundary fix: projectedBalanceAsOf searches for a
        // reset using mostRecentDueDateAtOrBefore(beg.minusDays(1)), not beg itself. If beg lands
        // exactly on a due-date instance, the balance display must NOT treat that as an
        // already-happened reset -- the visible reset only takes effect starting the period
        // after, once beg has advanced past the due date.
        LocalDate today = LocalDate.now();
        LocalDate dueDate = today.plusDays(15);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");

        card.getNextCheckPayments(dueDate, dueDate.plusDays(10), NO_OTHER_EXPENSES);

        assertEquals("500.00", card.getDisplayBalance());
    }

    @Test
    public void getNextCheckPayments_dueDatePeriod_shownCostMatchesDisplayBalance() {
        LocalDate today = LocalDate.now();
        LocalDate dueDate = today.plusDays(15);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");

        card.getNextCheckPayments(dueDate.minusDays(3), dueDate.plusDays(3), NO_OTHER_EXPENSES);

        assertEquals("500.00", card.getShownCost());
        assertEquals("500.00", card.getDisplayBalance());
    }

    @Test
    public void getNextCheckPayments_afterDueDate_nothingDueButBalanceAccumulatesAgain() {
        LocalDate today = LocalDate.now();
        LocalDate dueDate = today.plusDays(15);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");
        LocalDate beg = dueDate.plusDays(5);
        LocalDate end = dueDate.plusDays(10);
        ExpenseModel charge = new ExpenseModel("Groceries", "40.00", dueDate.plusDays(7), 200, ChronoUnit.DAYS, false);
        charge.setSource("CREDIT_CARD");
        charge.setSourceId(card.getName());
        List<ExpenseItem> all = new ArrayList<>();
        all.add(card);
        all.add(charge);

        card.getNextCheckPayments(beg, end, all);

        assertEquals("0.00", card.getShownCost()); // nothing due until the next due date
        assertEquals("40.00", card.getDisplayBalance()); // but the new charge is already accruing
    }

    @Test
    public void sourcedChargesBetween_ignoresChargeWithMismatchedSourceId() {
        LocalDate today = LocalDate.now();
        LocalDate dueDate = today.plusDays(40);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");
        LocalDate beg = today.plusDays(15);
        LocalDate end = today.plusDays(35);
        ExpenseModel charge = new ExpenseModel("Groceries", "50.00", end.minusDays(5), 200, ChronoUnit.DAYS, false);
        charge.setSource("CREDIT_CARD");
        charge.setSourceId("SomeOtherCard"); // does not match card.getName()
        List<ExpenseItem> all = new ArrayList<>();
        all.add(card);
        all.add(charge);

        card.getNextCheckPayments(beg, end, all);

        assertEquals("500.00", card.getDisplayBalance()); // charge not attributed to this card
    }

    @Test
    public void sourcedChargesBetween_ignoresOtherCreditCardsEvenWithMatchingSource() {
        LocalDate today = LocalDate.now();
        LocalDate dueDate = today.plusDays(40);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");
        LocalDate beg = today.plusDays(15);
        LocalDate end = today.plusDays(35);
        CreditModel otherCard = new CreditModel("Card", "50.00", end.minusDays(5), "1000.00");
        otherCard.setSource("CREDIT_CARD");
        otherCard.setSourceId(card.getName());
        List<ExpenseItem> all = new ArrayList<>();
        all.add(card);
        all.add(otherCard);

        card.getNextCheckPayments(beg, end, all);

        assertEquals("500.00", card.getDisplayBalance()); // credit cards never count as sourced charges
    }

    @Test
    public void getDisplayBalance_beforeAnyPaging_fallsBackToCost() {
        CreditModel card = new CreditModel("Card", "500.00", LocalDate.now().plusMonths(1), "2000.00");
        assertEquals(card.getCost(), card.getDisplayBalance());
    }

    @Test
    public void applyCharge_positiveDelta_whenDisplayBalanceUnset_addsToBothCostAndDisplay() {
        CreditModel card = new CreditModel("Card", "500.00", LocalDate.now().plusMonths(1), "2000.00");

        card.applyCharge(50f);

        assertEquals("550.00", card.getCost());
        assertEquals("550.00", card.getShownCost());
        assertEquals("550.00", card.getDisplayBalance());
    }

    @Test
    public void applyCharge_whenDisplayBalanceHasAlreadyDiverged_offsetsItsOwnPriorValue() {
        // Regression test for a bug caught while writing this test: applyCharge() must read
        // getDisplayBalance()'s CURRENT value before touching cost, since getDisplayBalance()
        // falls back to getCost() when unset -- reading it after setCost() would silently pick
        // up the already-updated cost and double-count delta.
        LocalDate today = LocalDate.now();
        LocalDate dueDate = today.plusDays(15);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");
        ExpenseModel charge = new ExpenseModel("Groceries", "40.00", dueDate.plusDays(7), 200, ChronoUnit.DAYS, false);
        charge.setSource("CREDIT_CARD");
        charge.setSourceId(card.getName());
        List<ExpenseItem> all = new ArrayList<>();
        all.add(card);
        all.add(charge);
        // Paging to just after the due date sets displayBalance ("40.00") without touching the
        // real cost ("500.00") at all -- establishing a genuine divergence between the two.
        card.getNextCheckPayments(dueDate.plusDays(5), dueDate.plusDays(10), all);
        assertEquals("500.00", card.getCost());
        assertEquals("40.00", card.getDisplayBalance());

        card.applyCharge(10f);

        assertEquals("510.00", card.getCost());
        assertEquals("50.00", card.getDisplayBalance());
    }

    @Test
    public void applyCharge_negativeDelta_clampsAtZero() {
        CreditModel card = new CreditModel("Card", "30.00", LocalDate.now().plusMonths(1), "2000.00");

        card.applyCharge(-100f);

        assertEquals("0.00", card.getCost());
        assertEquals("0.00", card.getShownCost());
        assertEquals("0.00", card.getDisplayBalance());
    }

    @Test
    public void setBalance_overridesCostShownCostAndDisplayBalance_ignoringPriorDivergence() {
        LocalDate today = LocalDate.now();
        LocalDate dueDate = today.plusDays(15);
        CreditModel card = new CreditModel("Card", "500.00", dueDate, "2000.00");
        ExpenseModel charge = new ExpenseModel("Groceries", "40.00", dueDate.plusDays(7), 200, ChronoUnit.DAYS, false);
        charge.setSource("CREDIT_CARD");
        charge.setSourceId(card.getName());
        List<ExpenseItem> all = new ArrayList<>();
        all.add(card);
        all.add(charge);
        card.getNextCheckPayments(dueDate.plusDays(5), dueDate.plusDays(10), all);
        assertEquals("40.00", card.getDisplayBalance()); // diverged from cost, as in the test above

        card.setBalance("200.00");

        assertEquals("200.00", card.getCost());
        assertEquals("200.00", card.getShownCost());
        assertEquals("200.00", card.getDisplayBalance());
    }

    @Test
    public void isCredit_isTrue() {
        CreditModel card = new CreditModel("Card", "500.00", LocalDate.now(), "2000.00");
        assertEquals(true, card.isCredit());
    }
}
