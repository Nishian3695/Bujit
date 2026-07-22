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
    protected float eDaysBtwn;   // days between occurrences, computed by setPerPay()
    protected float ePerPay;

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
    public void setDate(LocalDate expenseDate) {
        this.expenseDate = expenseDate;
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
    Converts a frequency (magnitude + ChronoUnit) into a total number of days.
    For month/year units the calculation accounts for variable month/year lengths
    by summing the actual lengths of each period starting from timeCal.
    Returns -1 as a base (incremented in the loop) for those branches, so the
    caller receives the correct fractional representation.
    */
    public float freqToDays(int freq, ChronoUnit freqTag, LocalDate timeCal) {
        float factor = -1f;
        if (freqTag.equals(ChronoUnit.YEARS)) {
            for (int i=0;i<freq;i++) {
                timeCal = timeCal.plusYears(i);
                factor += timeCal.lengthOfYear();

            }
            return factor;
        } else if (freqTag.equals(ChronoUnit.MONTHS)) {
            for (int i=0;i<freq;i++) {
                timeCal = timeCal.plusMonths(i);
                factor += timeCal.lengthOfMonth();
            }
            return factor;
        } else if (freqTag.equals(ChronoUnit.WEEKS)) {
            factor = 7f; // Days per week
        } else if (freqTag.equals(ChronoUnit.DAYS)) {
            factor = 1f; // Days per day
        }
        return freq * factor;
    }
    /*
    Pre-computes how many times this expense occurs within one pay period (ePerPay).
    ePerPay > 1 means the expense recurs multiple times per check (e.g. a daily
    expense in a weekly pay period). ePerPay <= 1 means it occurs at most once.
    Must be called after the income stream frequency is known, before getOccurrences().
    */
    public void setPerPay(int payFreq, ChronoUnit payFreqTag, LocalDate timeCal) {
        float payFreqDays = freqToDays(payFreq, payFreqTag, timeCal);
        this.eDaysBtwn = freqToDays(expenseFrequency, expenseFrequencyTag, timeCal);
        this.ePerPay = payFreqDays / this.eDaysBtwn;
    }
    /*
    Returns the number of times this expense occurs within [checkStart, nextCheck).
    curCheck=true means we compare against today (to skip already-passed occurrences);
    curCheck=false compares against checkStart (used when projecting future checks).
    For high-frequency expenses (ePerPay > 1), the count is derived from the number
    of full recurrence intervals that fit in the remaining days of the check period.
    */
    public Integer getOccurrences(LocalDate checkStart, LocalDate nextCheck,
                                  Boolean curCheck) {
        LocalDate compCal = LocalDate.now();
        if (!curCheck) {
            compCal = checkStart;
        }
        int occurrences;
        if (this.ePerPay <= 1) {
            // If today <= shownDate < next check, one occurrence, else zero
            occurrences = (compCal.isBefore(shownDate) || compCal.equals(shownDate)) &&
                    shownDate.isBefore(nextCheck) ? 1 : 0;
        } else { // If occurs more than once per check
            // Get days from first occurrence to end of check
            int daysLeft = (int) ChronoUnit.DAYS.between(this.shownDate, nextCheck);
            // +1 counts the first occurrence on shownDate itself
            occurrences = (int) (Math.floor(daysLeft / this.eDaysBtwn) + 1);
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
