package io.github.nishian3695.bujit.ExpenseActivity;

import io.github.nishian3695.bujit.CustomListeners.CurrencyFormat;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

/*
Abstract base for the two kinds of recurring balance entries Bujit tracks: a regular expense
(ExpenseModel) and a credit card (CreditModel). Holds every field/behavior genuinely shared by
both — recurrence timing, the currently-displayed check period's values, bank-account linking,
Google Tasks sync, and funding Source (where the money for an occurrence comes from). Each
subclass implements makeCurrent()/getNextCheckPayments()/getPrevCheckPayments() with only its
own logic — a regular expense's occurrence-counted amount, or a credit card's due-date-reset
balance — instead of one class branching on a boolean flag for every method.
*/
public abstract class ExpenseItem implements Serializable {

    private static final long serialVersionUID = 1L;
    protected static final CurrencyFormat currencyFormat = new CurrencyFormat();

    // Base (persisted) recurrence fields
    protected LocalDate expenseDate;
    protected int expenseFrequency;
    protected ChronoUnit expenseFrequencyTag;
    protected String expenseCost;
    protected String expenseName;

    // Optional bounds on the recurrence (null = unbounded). expenseDate above advances to the next
    // due date as occurrences pass, so startDate separately remembers the first occurrence — it
    // keeps history math (FinancialCalc) from extrapolating occurrences before the expense began.
    // endDate is inclusive: an occurrence falling on it still counts.
    protected LocalDate startDate = null;
    protected LocalDate endDate = null;

    // Intended day of month for monthly/yearly schedules (e.g. 31). Stepping a date by months
    // clamps it in short months (Jan 31 -> Feb 28), so every step snaps back to this day when the
    // month allows it — see stepOccurrence(). Set whenever the user sets the date, never by the
    // automatic advancing. 0 = unknown (data from before this existed): use expenseDate's day.
    protected int anchorDay;

    // Display fields for the currently viewed check period
    protected LocalDate shownDate;
    protected String shownCost;

    // Linked Teller/Plaid account (null = not linked) — drives the loan/credit cost-sync feature
    protected String linkedAccountId      = null;
    protected transient String linkedAccountToken = null;
    protected String linkedAccountDisplay = null;

    // Google Tasks sync (null = not synced)
    protected String googleTaskId = null;
    protected boolean calendarNotificationsEnabled = true;

    // Funding source for this item, distinct from linkedAccountId/isLinkedToBank() above. "BALANCE"
    // (default) means occurrences deduct from Current Balance as before; "MANUAL_ACCOUNT"/
    // "CREDIT_CARD" redirect the deduction to a specific manual account or manual credit card;
    // "LINKED_ACCOUNT" means a Plaid/Teller account already reflects the debit on its own, so
    // nothing should be deducted. A CreditModel's own editing UI never offers "CREDIT_CARD".
    protected String source = "BALANCE";
    protected String sourceId = null;
    protected String sourceDisplayName = null;

    protected ExpenseItem(String expenseName, String expenseCost, LocalDate expenseDate,
                          int expenseFrequency, ChronoUnit expenseFrequencyTag) {
        this.expenseName = expenseName;
        this.expenseDate = expenseDate;
        this.anchorDay = expenseDate.getDayOfMonth();
        this.expenseFrequency = expenseFrequency;
        this.expenseFrequencyTag = expenseFrequencyTag;
        this.shownDate = expenseDate;
        setCost(expenseCost);
        setShownCost(expenseCost);
    }

    // True for CreditModel, false for ExpenseModel — a simple, cheap check for the many call
    // sites elsewhere in the app that just need to know which kind of item this is (filtering,
    // choosing a display field) without needing the subclass's own members.
    public boolean isCredit() { return false; }

    // Define setters
    // User-chosen date: also resets the schedule's intended day of month to match.
    public void setDate(LocalDate expenseDate) {
        this.expenseDate = expenseDate;
        this.anchorDay = expenseDate.getDayOfMonth();
    }
    public void setShownDate(LocalDate calendar) {
        this.shownDate = calendar;
    }
    public void setFrequency(int expenseFrequency) {
        this.expenseFrequency = expenseFrequency;
    }
    public void setFrequencyTag(ChronoUnit expenseFrequencyTag) {
        this.expenseFrequencyTag = expenseFrequencyTag;
    }
    public void setCost(String expenseCost) {
        this.expenseCost = currencyFormat.formatToString(expenseCost);
    }
    public void setShownCost(String shownCost) {
        this.shownCost = currencyFormat.formatToString(shownCost);
    }
    public void setShownCost(float shownCost) {
        this.shownCost = currencyFormat.formatToString(shownCost);
    }
    public void setName(String expenseName) {
        this.expenseName = expenseName;
    }

    // Define getters
    public LocalDate getDate() {
        return this.expenseDate;
    }
    public LocalDate getShownDate() {
        return this.shownDate;
    }
    public int getFrequency() {
        return this.expenseFrequency;
    }
    public ChronoUnit getFrequencyTag() {
        return this.expenseFrequencyTag;
    }
    public String getCost() {
        if (this.expenseCost == null || this.expenseCost.isEmpty()) return "0.00";
        try { return currencyFormat.formatToString(this.expenseCost); }
        catch (NumberFormatException e) { return "0.00"; }
    }
    public String getShownCost() {
        if (this.shownCost == null || this.shownCost.isEmpty()) return "0.00";
        try { return currencyFormat.formatToString(this.shownCost); }
        catch (NumberFormatException e) { return "0.00"; }
    }
    public String getName() {
        return this.expenseName;
    }

    // Recurrence stepping
    public int getAnchorDay() {
        if (anchorDay > 0) return anchorDay;
        return expenseDate != null ? expenseDate.getDayOfMonth() : 1;
    }
    public void setAnchorDay(int anchorDay) { this.anchorDay = anchorDay; }
    /*
    Returns the occurrence `steps` recurrences after `date` (negative = before). For monthly and
    yearly schedules the day of month snaps back to getAnchorDay() whenever the target month is
    long enough, so an expense on the 31st falls on Jan 31 -> Feb 28 -> Mar 31 rather than
    drifting to the 28th forever (and a Feb 29 yearly expense returns to Feb 29 in leap years).
    Every date step for an item's schedule must go through here.
    */
    public LocalDate stepOccurrence(LocalDate date, int steps) {
        return io.github.nishian3695.bujit.StorageManagement.FinancialCalc.stepDate(
                date, (long) steps * expenseFrequency, expenseFrequencyTag, getAnchorDay());
    }

    // Recurrence bounds
    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }
    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }
    // True when the next due date is past the end date, i.e. no occurrences remain.
    public boolean hasEnded() {
        return endDate != null && expenseDate != null && expenseDate.isAfter(endDate);
    }
    // True when an occurrence on this date falls within [startDate, endDate] (either bound may be null).
    public boolean isWithinBounds(LocalDate date) {
        return (startDate == null || !date.isBefore(startDate))
                && (endDate == null || !date.isAfter(endDate));
    }

    // Linked account
    public boolean isLinkedToBank() {
        return linkedAccountId != null && !linkedAccountId.isEmpty();
    }
    public String getLinkedAccountId()      { return linkedAccountId; }
    public String getLinkedAccountToken()   { return linkedAccountToken; }
    public String getLinkedAccountDisplay() { return linkedAccountDisplay; }
    public void setLinkedAccount(String id, String token, String display) {
        this.linkedAccountId      = id;
        this.linkedAccountToken   = token;
        this.linkedAccountDisplay = display;
    }
    public void clearLinkedAccount() {
        this.linkedAccountId      = null;
        this.linkedAccountToken   = null;
        this.linkedAccountDisplay = null;
    }

    // Google Tasks sync
    public String getGoogleTaskId() { return googleTaskId; }
    public void setGoogleTaskId(String id) { this.googleTaskId = id; }
    public boolean isCalendarNotificationsEnabled() { return calendarNotificationsEnabled; }
    public void setCalendarNotificationsEnabled(boolean enabled) { this.calendarNotificationsEnabled = enabled; }

    // Funding source
    public String getSource() { return source != null ? source : "BALANCE"; }
    public void setSource(String source) { this.source = (source != null && !source.isEmpty()) ? source : "BALANCE"; }
    public String getSourceId() { return sourceId; }
    public void setSourceId(String sourceId) { this.sourceId = sourceId; }
    public String getSourceDisplayName() { return sourceDisplayName; }
    public void setSourceDisplayName(String sourceDisplayName) { this.sourceDisplayName = sourceDisplayName; }

    /*
    Returns the number of times this expense occurs in the check ending on payday nextCheck,
    stepping through actual occurrence dates from shownDate.

    A check's expenses include anything due ON its payday, since that debit may clear before
    the paycheck lands — so "After This Check" is the lowest the balance could dip. The window
    is therefore inclusive of nextCheck:
      curCheck=true  (the current check): [today, nextCheck]
      curCheck=false (a projected check): (checkStart, nextCheck] — checkStart is the previous
                     payday, whose occurrence was already counted in the check before this one.
    Occurrences after endDate are never counted.
    */
    public Integer getOccurrences(LocalDate checkStart, LocalDate nextCheck,
                                  Boolean curCheck) {
        LocalDate today = LocalDate.now();
        int occurrences = 0;
        int safety = 0;
        for (LocalDate date = this.shownDate;
             !date.isAfter(nextCheck) && (endDate == null || !date.isAfter(endDate))
                     && safety++ < 3650;
             date = stepOccurrence(date, 1)) {
            boolean afterStart = curCheck ? !date.isBefore(today) : date.isAfter(checkStart);
            if (afterStart) occurrences++;
            if (this.expenseFrequency <= 0) break; // no recurrence to step through
        }
        return occurrences;
    }

    /*
    Advances the item's base date forward until it is in the future (today or later), applies
    any real, up-to-today balance effects, and returns the amount that was just paid off (so the
    caller can route it to this item's funding Source). allExpenses is the full item list, needed
    only by CreditModel's implementation.
    */
    public abstract float makeCurrent(LocalDate beg, LocalDate end, List<ExpenseItem> allExpenses);

    /*
    Advances shownDate forward until it falls within [beg, end) and sets shownCost to this item's
    value for that future check period. allExpenses is the full item list, needed only by
    CreditModel's implementation.
    */
    public abstract void getNextCheckPayments(LocalDate beg, LocalDate end, List<ExpenseItem> allExpenses);

    /*
    Rewinds shownDate backward until it falls within [beg, end) and sets shownCost to this item's
    value for that past check period. allExpenses is the full item list, needed only by
    CreditModel's implementation.
    */
    public abstract void getPrevCheckPayments(LocalDate beg, LocalDate end, List<ExpenseItem> allExpenses);
}
