package io.github.nishian3695.bujit.ExpenseActivity;

import io.github.nishian3695.bujit.StorageManagement.FinancialCalc;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

/*
Data model for a credit card. expenseCost (inherited) is the current balance and creditLimit is
the card's credit limit. Credit cards always bill on a monthly cycle — no UI anywhere lets one
have a different frequency, so the constructor fixes it rather than taking it as a parameter.

Unlike a regular expense (which simply accrues its cost every occurrence), a credit card's
balance resets to zero at each due date and accumulates in between from any expenses whose
funding Source points at it (see ExpenseActivity.applySourcedPayment). displayBalance tracks
that ongoing balance for display (Rate label / utilization bar) separately from shownCost, which
represents "amount due this specific period" (0 except in the period the due date falls in) —
see the class-level comment on creditAmountDueWithin/projectedBalanceAsOf below for why those
two deliberately reset on a one-period lag from each other.
*/
public class CreditModel extends ExpenseItem {

    private static final long serialVersionUID = 1L;

    private String creditLimit;
    // In-memory/not persisted: the ongoing standing balance as of whichever period is currently
    // displayed (real or projected via paging), for the Rate label and utilization bar.
    // Deliberately separate from shownCost — see class comment above.
    private transient String displayBalance;

    // Creates a new credit card with its current balance and limit; the billing cycle is always
    // monthly, anchored at the given date.
    public CreditModel(String name, String cost, LocalDate date, String creditLimit) {
        super(name, cost, date, 1, ChronoUnit.MONTHS);
        this.creditLimit = creditLimit;
    }

    @Override
    public boolean isCredit() { return true; }

    public void setCreditLimit(String creditLimit) {
        this.creditLimit = creditLimit;
    }
    public String getCreditLimit() {
        return this.creditLimit;
    }

    // This card's ongoing balance for the currently displayed period (see class comment above).
    // Falls back to getCost() when unset (e.g. a freshly loaded card that hasn't been through
    // makeCurrent()/getNextCheckPayments()/getPrevCheckPayments() yet this session).
    public String getDisplayBalance() {
        if (this.displayBalance == null || this.displayBalance.isEmpty()) return getCost();
        try { return currencyFormat.formatToString(this.displayBalance); }
        catch (NumberFormatException e) { return getCost(); }
    }
    private void setDisplayBalance(float balance) {
        this.displayBalance = currencyFormat.formatToString(balance);
    }

    // Directly sets the current balance from a source of truth -- a manual edit, or a fresh sync
    // from a linked bank account -- resetting shownCost and displayBalance to match rather than
    // offsetting them by a delta. Unlike applyCharge(), this represents a full correction ("this
    // is the balance right now"), which should clear out any stale in-between projection.
    public void setBalance(String newCost) {
        setCost(newCost);
        setShownCost(getCost());
        float cost;
        try { cost = Float.parseFloat(getCost()); } catch (NumberFormatException e) { cost = 0f; }
        setDisplayBalance(cost);
    }

    // Applies a signed balance delta from an occurred sourced expense or a manual single-event
    // debit/credit (see ExpenseActivity.applySourcedPayment / showAddSingleEventDialog's
    // CREDIT_CARD case). A card's own makeCurrent()/getNextCheckPayments()/getPrevCheckPayments()
    // won't run again until the next check-period navigation, so callers must go through this
    // method rather than setCost()/setShownCost() directly -- otherwise displayBalance (the Rate
    // label/utilization bar) keeps showing the pre-charge balance until then.
    public void applyCharge(float delta) {
        // Read both "before" values up front -- getDisplayBalance() falls back to getCost() when
        // displayBalance hasn't been set yet, so reading it after setCost() below would silently
        // pick up the already-updated cost and double-apply delta.
        float base;
        try { base = Float.parseFloat(getCost()); } catch (NumberFormatException e) { base = 0f; }
        float displayBase;
        try { displayBase = Float.parseFloat(getDisplayBalance()); } catch (NumberFormatException e) { displayBase = 0f; }

        String costStr = currencyFormat.formatToString(Math.max(0f, base + delta));
        setCost(costStr);
        setShownCost(costStr);
        setDisplayBalance(Math.max(0f, displayBase + delta));
    }

    /*
    Advances shownDate forward until it falls within [beg, end), and sets shownCost/displayBalance
    for that future check period. allExpenses is the full item list, used to project any
    not-yet-applied Source-attributed charges (see sourcedChargesBetween).
    */
    @Override
    public void getNextCheckPayments(LocalDate beg, LocalDate end, List<ExpenseItem> allExpenses) {
        while (this.shownDate.isBefore(beg)) {
            this.shownDate = this.shownDate.plus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        setShownCost(creditAmountDueWithin(beg, end, allExpenses));
        setDisplayBalance(projectedBalanceAsOf(allExpenses, beg, end));
    }

    /*
    Rewinds shownDate backward until it falls within [beg, end), and sets shownCost/displayBalance
    for that past check period. allExpenses is the full item list, used to project any
    not-yet-applied Source-attributed charges (see sourcedChargesBetween).
    */
    @Override
    public void getPrevCheckPayments(LocalDate beg, LocalDate end, List<ExpenseItem> allExpenses) {
        while (beg.isBefore(this.shownDate.minus(this.expenseFrequency, this.expenseFrequencyTag))) {
            this.shownDate = this.shownDate.minus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        setShownCost(creditAmountDueWithin(beg, end, allExpenses));
        setDisplayBalance(projectedBalanceAsOf(allExpenses, beg, end));
    }

    /*
    Advances the card's base due date forward until it is in the future (today or later), and
    resets shownDate to match. expenseCost (the real, applied balance) is zeroed the moment the
    due date passes — that part drives the real curBalance-or-Source deduction and is unaffected
    by display lag. shownCost/displayBalance, however, lag one check period behind that reset (see
    creditAmountDueWithin/projectedBalanceAsOf) so the home screen and paged views agree: if the
    just-passed due date fell within [beg, end) (this check period), the display still shows what
    was paid off through this period rather than jumping straight to $0 — that only happens
    starting next period. allExpenses is the full item list, needed for the not-yet-due branch's
    display computation.
    */
    @Override
    public float makeCurrent(LocalDate beg, LocalDate end, List<ExpenseItem> allExpenses) {
        LocalDate dueBeforeAdvance = this.expenseDate;
        int passedExpenses = 0;
        while (LocalDate.now().isAfter(this.expenseDate)) {
            this.expenseDate = this.expenseDate.plus(this.expenseFrequency, this.expenseFrequencyTag);
            passedExpenses++;
        }
        setShownDate(this.expenseDate);
        if (passedExpenses > 0) {
            float paid = Float.parseFloat(this.expenseCost);
            this.expenseCost = "0.00";
            boolean dueThisCheck = !dueBeforeAdvance.isBefore(beg) && dueBeforeAdvance.isBefore(end);
            setShownCost(dueThisCheck ? paid : 0f);
            setDisplayBalance(dueThisCheck ? paid : 0f);
            return paid;
        }
        setShownCost(creditAmountDueWithin(beg, end, allExpenses));
        setDisplayBalance(projectedBalanceAsOf(allExpenses, beg, end));
        return 0f;
    }

    /*
    Two distinct questions, deliberately kept separate:

    creditAmountDueWithin(beg, end) answers "is this card's due date in this specific window, and
    if so what's owed?" — the Amount column. It's 0 in every period except the one the due date
    actually falls in, where it's the balance accumulated since the PRECEDING due date (i.e. what
    gets paid off/reset at this due date) — not the ongoing balance as of `end`.

    projectedBalanceAsOf(beg, end) answers "what does this card currently stand at, as of this
    period?" — the Rate label / utilization bar. It carries forward regardless of whether
    anything is due this period, but its reset lags creditAmountDueWithin's by exactly one
    period: if this card's due date falls within [beg, end) itself, the balance still reflects
    what's being paid off THIS period (matching the Amount column) rather than jumping straight
    to the post-payoff figure — the reset only takes visible effect starting the NEXT period,
    once `beg` has advanced past the due date. That's why the reset lookup below is bounded by
    `beg` (exclusive of this period), not `end`.

    Both use dueDateWithin/mostRecentDueDateAtOrBefore, which search purely from this card's real,
    fixed expenseDate/expenseFrequency — not the mutable shownDate paging state, which steps by
    the CARD's own frequency while beg/end step by the pay period's frequency and so can't be
    relied on to land exactly on a due-date instance.
    */
    private float creditAmountDueWithin(LocalDate beg, LocalDate end, List<ExpenseItem> allExpenses) {
        LocalDate due = dueDateWithin(beg, end);
        if (due == null) return 0f;
        LocalDate precedingDue = due.minus(this.expenseFrequency, this.expenseFrequencyTag);
        return projectedBalanceUpTo(allExpenses, precedingDue, due);
    }

    private float projectedBalanceAsOf(List<ExpenseItem> allExpenses, LocalDate beg, LocalDate end) {
        LocalDate reset = mostRecentDueDateAtOrBefore(beg.minusDays(1));
        return projectedBalanceUpTo(allExpenses, reset, end);
    }

    // Shared by both projections above: the balance at `asOf`, starting from whichever is later
    // — today's real, persisted expenseCost (nothing has reset since), or zero as of a due-date
    // reset that falls after today but at/before asOf — plus any Source-attributed charges
    // between that starting point and asOf. bringDataUpToDate()/makeCurrent() only ever applies
    // occurrences up through today, so charges from today onward haven't been added to
    // expenseCost yet and must be simulated here instead.
    private float projectedBalanceUpTo(List<ExpenseItem> allExpenses, LocalDate resetPoint, LocalDate asOf) {
        LocalDate today = LocalDate.now();
        float base;
        LocalDate from;
        if (resetPoint != null && resetPoint.isAfter(today)) {
            base = 0f;
            from = resetPoint;
        } else {
            try { base = Float.parseFloat(this.expenseCost); } catch (NumberFormatException e) { base = 0f; }
            from = today;
        }
        return base + sourcedChargesBetween(allExpenses, from, asOf);
    }

    // Sums the cost of every non-credit expense whose funding Source points at this credit card
    // (by name, matching applySourcedPayment's convention) that occurs in [from, to).
    private float sourcedChargesBetween(List<ExpenseItem> allExpenses, LocalDate from, LocalDate to) {
        if (allExpenses == null || !from.isBefore(to)) return 0f;
        float total = 0f;
        for (ExpenseItem e : allExpenses) {
            if (e == this || e.isCredit()) continue;
            if (!"CREDIT_CARD".equals(e.getSource())) continue;
            if (e.getSourceId() == null || !e.getSourceId().equals(this.expenseName)) continue;
            int occ = FinancialCalc.countExpenseOccurrences(e, from, to);
            if (occ <= 0) continue;
            try { total += occ * Float.parseFloat(e.getCost()); } catch (NumberFormatException ignored) {}
        }
        return total;
    }

    // Finds this card's due-date instance (if any) that falls within [beg, end), searching from
    // its real, fixed expenseDate — independent of the shownDate navigation state, which steps
    // by this card's frequency while beg/end step by the (possibly different) pay-period
    // frequency and so can't be assumed to already be in sync with the window.
    private LocalDate dueDateWithin(LocalDate beg, LocalDate end) {
        LocalDate candidate = this.expenseDate;
        int safety = 0;
        while (!candidate.isBefore(end) && safety++ < 3650) {
            candidate = candidate.minus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        safety = 0;
        while (candidate.isBefore(beg) && safety++ < 3650) {
            candidate = candidate.plus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        return (!candidate.isBefore(beg) && candidate.isBefore(end)) ? candidate : null;
    }

    // Finds the latest due-date instance of this card (starting from its real, fixed expenseDate
    // and stepping forward by its own frequency) that falls at or before `end` — i.e. the most
    // recent point up to `end` where the balance would reset to zero. Returns null if the due
    // date hasn't been reached within the window at all.
    private LocalDate mostRecentDueDateAtOrBefore(LocalDate end) {
        LocalDate candidate = this.expenseDate;
        LocalDate mostRecent = null;
        int safety = 0;
        while (!candidate.isAfter(end) && safety++ < 3650) {
            mostRecent = candidate;
            candidate = candidate.plus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        return mostRecent;
    }
}
