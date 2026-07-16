package io.github.nishian3695.bujit.ExpenseActivity;

import io.github.nishian3695.bujit.CustomListeners.CurrencyFormat;
import io.github.nishian3695.bujit.StorageManagement.FinancialCalc;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Locale;

/*
Data model for a single recurring expense entry.
Each expense has a base cost and recurrence frequency (e.g. every 1 month).
The "shown" fields (shownDate, shownCost, shownStatus) hold display values
for whichever check period is currently on screen, while the base fields
store the canonical next-occurrence data that is persisted to disk.
An expense can also represent a credit card entry (expenseIsCredit=true),
in which case expenseCost is the current balance and creditLimit is the
card's credit limit. The utilization percentage is derived from these two.
Optionally, an expense can be linked to a Teller bank account so that its
balance is refreshed automatically on pull-to-refresh.
Google Tasks sync is tracked via the googleTaskId field, which is null until
the expense has been pushed to the user's Bujit task list.
*/
public class ExpenseModel implements Serializable {

    private static final long serialVersionUID = 1L;
    private static final CurrencyFormat currencyFormat = new CurrencyFormat();

    // Payment status codes
    final private int UNPAID = -1;
    final private int SOMEPAID = 0;
    final private int PAID = 1;
    final private String UNPAID_STR = "Not Paid";
    final private String SOMEPAID_STR = "Partly Paid";
    final private String PAID_STR = "Paid";

    // Base (persisted) expense fields
    private LocalDate expenseDate;
    private int expenseFrequency;
    private String expenseCost;
    private String expenseName;
    private int expenseStatus;
    private int expensePartPaid;
    private boolean expenseIsVariable;
    private ChronoUnit expenseFrequencyTag;
    private float eDaysBtwn;   // days between occurrences, computed by setPerPay()

    // Credit card specific fields
    private boolean expenseIsCredit;
    private String creditLimit;

    // Display fields for the currently viewed check period
    private LocalDate shownDate;
    private String shownCost;
    private int shownStatus;
    // Credit cards only, in-memory/not persisted: the ongoing standing balance as of whichever
    // period is currently displayed (real or projected via paging), for the Rate label and
    // utilization bar. Deliberately separate from shownCost, which represents "amount due this
    // period" — 0 except in the specific period the card's due date falls in. A card can be
    // carrying a nonzero balance (shown here) while nothing is due yet (shownCost == 0).
    private transient String displayBalance;

    // New variables
    private float ePerPay;
    // Linked Teller account (null = not linked)
    private String linkedAccountId      = null;
    private transient String linkedAccountToken = null;
    private String linkedAccountDisplay = null;
    // Google Tasks sync (null = not synced)
    private String googleTaskId = null;
    private boolean calendarNotificationsEnabled = true;
    // User-assigned spending category (e.g. "Food", "Housing"). Defaults to "Other".
    private String category = "Other";
    // Funding source for this expense, distinct from linkedAccountId/isLinkedToBank() above
    // (which drives the loan/credit cost-sync feature). "BALANCE" (default) means occurrences
    // deduct from Current Balance as before; "MANUAL_ACCOUNT"/"CREDIT_CARD" redirect the
    // deduction to a specific manual account or manual credit card; "LINKED_ACCOUNT" means a
    // Plaid/Teller account already reflects the debit on its own, so nothing should be deducted.
    private String source = "BALANCE";
    private String sourceId = null;
    private String sourceDisplayName = null;

    //Constructor
    // Creates a new expense/credit entry with its base recurrence data; shownDate/shownCost start
    // out equal to the base values until a check-period navigation updates them.
    public ExpenseModel(String expenseName, String expenseCost, LocalDate expenseDate,
                        int expenseFrequency, ChronoUnit expenseFrequencyTag,
                        boolean expenseIsVariable) {
        this.expenseName = expenseName;
        this.expenseCost = expenseCost;
        this.expenseDate = expenseDate;
        this.expenseFrequency = expenseFrequency;
        this.expenseFrequencyTag = expenseFrequencyTag;
        this.expenseIsVariable = expenseIsVariable;
        this.expenseStatus = UNPAID;
        this.shownDate = this.expenseDate;
        setShownCost(expenseCost);
        this.expenseIsCredit = false;
        this.creditLimit = "1.00";
    }

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
    public void setShownCost(Float shownCost) {
        this.shownCost = currencyFormat.formatToString(String.valueOf(shownCost));
    }
    public void setName(String expenseName) {
        this.expenseName = expenseName;
    }
    public void setStatus(int expenseStatus) {
        this.expenseStatus = expenseStatus;
        setShownStatus(expenseStatus);
    }
    public void setShownStatus(int shownStatus) {
        this.shownStatus = shownStatus;
    }
    public void setPartPaid(int expensePartPaid) {
        this.expensePartPaid = expensePartPaid;
    }
    public void setIsVariable(boolean expenseIsVariable) {
        this.expenseIsVariable = expenseIsVariable;
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
    // Credit cards' ongoing balance for the currently displayed period (see field comment above).
    // Falls back to getCost() when unset (e.g. a freshly loaded expense that hasn't been through
    // makeCurrent()/getNextCheckPayments()/getPrevCheckPayments() yet this session).
    public String getDisplayBalance() {
        if (this.displayBalance == null || this.displayBalance.isEmpty()) return getCost();
        try { return currencyFormat.formatToString(this.displayBalance); }
        catch (NumberFormatException e) { return getCost(); }
    }
    private void setDisplayBalance(float balance) {
        this.displayBalance = currencyFormat.formatToString(balance);
    }
    public String getName() {
        return this.expenseName;
    }
    public int getStatus() {
        return this.expenseStatus;
    }
    public String getShownStatusAsString() {
        String retStr = "";
        switch (this.shownStatus) {
            case (UNPAID): {
                retStr = UNPAID_STR;
                break;
            }
            case (SOMEPAID): {
                retStr = SOMEPAID_STR;
                break;
            }
            case (PAID): {
                retStr = PAID_STR;
                break;
            }
        }
        return retStr;
    }
    public int getShownStatus() {
        return this.shownStatus;
    }
    public int getPartPaid() {
        return this.expensePartPaid;
    }
    public boolean getIsVariable() {
        return this.expenseIsVariable;
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

    // Category
    public String getCategory() { return category != null ? category : "Other"; }
    public void setCategory(String category) { this.category = (category != null && !category.isEmpty()) ? category : "Other"; }

    // Funding source
    public String getSource() { return source != null ? source : "BALANCE"; }
    public void setSource(String source) { this.source = (source != null && !source.isEmpty()) ? source : "BALANCE"; }
    public String getSourceId() { return sourceId; }
    public void setSourceId(String sourceId) { this.sourceId = sourceId; }
    public String getSourceDisplayName() { return sourceDisplayName; }
    public void setSourceDisplayName(String sourceDisplayName) { this.sourceDisplayName = sourceDisplayName; }

    // Credit
    public void setIsCredit(boolean expenseIsCredit) {
        this.expenseIsCredit = expenseIsCredit;
    }
    public void setCreditLimit(String creditLimit) {
        this.creditLimit = creditLimit;
    }
    public boolean getIsCredit() {
        return this.expenseIsCredit;
    }
    public String getCreditLimit() {
        return this.creditLimit;
    }
    // Computes this credit card's utilization percentage (balance / limit) as a formatted string.
    public String getCreditUtil() {
        float utilization = Float.parseFloat(this.expenseCost) / Float.parseFloat(this.creditLimit);
        float percentUtil = utilization  * 100;
        return String.format(Locale.US, "%.2f", percentUtil) + "%";
    }
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
    Advances shownDate forward until it falls within [beg, end) and sets shownCost to the total
    amount due in that check period. Used when navigating to a future check. allExpenses is the
    full expense list, used only for credit cards (see creditAmountFor/getDisplayBalance).
    */
    public void getNextCheckPayments(LocalDate beg, LocalDate end, List<ExpenseModel> allExpenses) {
        while (this.shownDate.isBefore(beg)) {
            this.shownDate = this.shownDate.plus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        if (expenseIsCredit) {
            setShownCost(creditAmountDueWithin(beg, end, allExpenses));
            setDisplayBalance(projectedBalanceAsOf(allExpenses, beg, end));
            return;
        }
        int occurrences = getOccurrences(beg, end, false);
        setShownCost(occurrences * Float.parseFloat(this.expenseCost));
    }

    /*
    Rewinds shownDate backward until it falls within [beg, end) and sets shownCost to the total
    amount due in that check period. Used when navigating to a past check. allExpenses is the
    full expense list, used only for credit cards (see creditAmountFor/getDisplayBalance).
    */
    public void getPrevCheckPayments(LocalDate beg, LocalDate end, List<ExpenseModel> allExpenses) {
        while (beg.isBefore(this.shownDate.minus(this.expenseFrequency, this.expenseFrequencyTag))) {
            this.shownDate = this.shownDate.minus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        if (expenseIsCredit) {
            setShownCost(creditAmountDueWithin(beg, end, allExpenses));
            setDisplayBalance(projectedBalanceAsOf(allExpenses, beg, end));
            return;
        }
        int occurrences = getOccurrences(beg, end, false);
        setShownCost(occurrences * Float.parseFloat(this.expenseCost));
    }

    /*
    Credit cards only. Two distinct questions, deliberately kept separate:

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
    private float creditAmountDueWithin(LocalDate beg, LocalDate end, List<ExpenseModel> allExpenses) {
        LocalDate due = dueDateWithin(beg, end);
        if (due == null) return 0f;
        LocalDate precedingDue = due.minus(this.expenseFrequency, this.expenseFrequencyTag);
        return projectedBalanceUpTo(allExpenses, precedingDue, due);
    }

    private float projectedBalanceAsOf(List<ExpenseModel> allExpenses, LocalDate beg, LocalDate end) {
        LocalDate reset = mostRecentDueDateAtOrBefore(beg.minusDays(1));
        return projectedBalanceUpTo(allExpenses, reset, end);
    }

    // Shared by both projections above: the balance at `asOf`, starting from whichever is later
    // — today's real, persisted expenseCost (nothing has reset since), or zero as of a due-date
    // reset that falls after today but at/before asOf — plus any Source-attributed charges
    // between that starting point and asOf. bringDataUpToDate()/makeCurrent() only ever applies
    // occurrences up through today, so charges from today onward haven't been added to
    // expenseCost yet and must be simulated here instead.
    private float projectedBalanceUpTo(List<ExpenseModel> allExpenses, LocalDate resetPoint, LocalDate asOf) {
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
    private float sourcedChargesBetween(List<ExpenseModel> allExpenses, LocalDate from, LocalDate to) {
        if (allExpenses == null || !from.isBefore(to)) return 0f;
        float total = 0f;
        for (ExpenseModel e : allExpenses) {
            if (e == this || e.getIsCredit()) continue;
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

    /*
    Advances the expense's base date forward until it is in the future (today or later),
    and resets shownDate to match. Returns the total amount of past occurrences that have
    already been paid (so the caller can deduct that from the current balance).
    For credit expenses, expenseCost (the real, applied balance) is zeroed the moment the due
    date passes — that part is unaffected by display lag, since it drives the real curBalance
    deduction. shownCost/displayBalance, however, use the same "lags one check period behind
    the Amount reset" rule as getNextCheckPayments/getPrevCheckPayments (see creditAmountDueWithin/
    projectedBalanceAsOf) so the home screen and paged views agree: if the just-passed due date
    fell within [beg, end) (this check period), the display still shows what was paid off through
    this period rather than jumping straight to $0 — that only happens starting next period.
    allExpenses is the full expense list, needed only for credit cards' display computation.
    */
    public float makeCurrent(LocalDate beg, LocalDate end, List<ExpenseModel> allExpenses) {
        LocalDate dueBeforeAdvance = this.expenseDate;
        int passedExpenses = 0;
        while (LocalDate.now().isAfter(this.expenseDate)) {
            this.expenseDate = this.expenseDate.plus(this.expenseFrequency, this.expenseFrequencyTag);
            passedExpenses++;
        }
        setShownDate(this.expenseDate);
        if (this.expenseIsCredit && passedExpenses > 0) {
            float paid = Float.parseFloat(this.expenseCost);
            this.expenseCost = "0.00";
            boolean dueThisCheck = !dueBeforeAdvance.isBefore(beg) && dueBeforeAdvance.isBefore(end);
            setShownCost(dueThisCheck ? paid : 0f);
            setDisplayBalance(dueThisCheck ? paid : 0f);
            return paid;
        }
        if (this.expenseIsCredit) {
            setShownCost(creditAmountDueWithin(beg, end, allExpenses));
            setDisplayBalance(projectedBalanceAsOf(allExpenses, beg, end));
            return 0f;
        }
        int occ = getOccurrences(beg, end, true);
        setShownCost(occ * Float.parseFloat(this.expenseCost));
        return currencyFormat.formatToFloat(passedExpenses * Float.parseFloat(this.expenseCost));
    }
}
