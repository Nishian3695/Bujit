package io.github.nishian3695.bujit.ExpenseActivity;

import io.github.nishian3695.bujit.CustomListeners.CurrencyFormat;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
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

    //Constructor
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
    Advances shownDate forward until it falls within [beg, end) and sets shownCost
    to the total amount due in that check period. Used when navigating to a future check.
    */
    public void getNextCheckPayments(LocalDate beg, LocalDate end) {
        while (this.shownDate.isBefore(beg)) {
            this.shownDate = this.shownDate.plus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        int occurrences;
        if (expenseIsCredit && this.expenseDate.isBefore(this.shownDate)) {
            occurrences = 0; // Since shownDate after expenseDate, credit is already paid
        } else {
            occurrences = getOccurrences(beg, end, false);
        }
        setShownCost(expenseIsCredit
                ? (occurrences > 0 ? Float.parseFloat(this.expenseCost) : 0f)
                : occurrences * Float.parseFloat(this.expenseCost));
    }

    /*
    Rewinds shownDate backward until it falls within [beg, end) and sets shownCost
    to the total amount due in that check period. Used when navigating to a past check.
    */
    public void getPrevCheckPayments(LocalDate beg, LocalDate end) {
        while (beg.isBefore(this.shownDate.minus(this.expenseFrequency, this.expenseFrequencyTag))) {
            this.shownDate = this.shownDate.minus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        int occurrences;
        if (expenseIsCredit && this.expenseDate.isBefore(this.shownDate)) {
            occurrences = 0; // Since shownDate after expenseDate, credit is already paid
        } else {
            occurrences = getOccurrences(beg, end, false);
        }
        setShownCost(expenseIsCredit
                ? (occurrences > 0 ? Float.parseFloat(this.expenseCost) : 0f)
                : occurrences * Float.parseFloat(this.expenseCost));
    }

    /*
    Advances the expense's base date forward until it is in the future (today or later),
    and resets shownDate to match. Returns the total amount of past occurrences that have
    already been paid (so the caller can deduct that from the current balance).
    For credit expenses that have passed, the cost is zeroed and the paid amount returned.
    */
    public float makeCurrent(LocalDate beg, LocalDate end) {
        int passedExpenses = 0;
        while (LocalDate.now().isAfter(this.expenseDate)) {
            this.expenseDate = this.expenseDate.plus(this.expenseFrequency, this.expenseFrequencyTag);
            passedExpenses++;
        }
        setShownDate(this.expenseDate);
        // If credit and expense has passed, assume paid
        // Passed Expenses = 1 (since paid once) and expenseCost = 0 (since paid)
        if (this.expenseIsCredit && passedExpenses > 0) {
            float paid = Float.parseFloat(this.expenseCost);
            this.expenseCost = "0.00";
            this.shownCost = "0.00";
            return paid;
        }
        int occ = getOccurrences(beg, end, true);
        setShownCost(expenseIsCredit
                ? (occ > 0 ? Float.parseFloat(this.expenseCost) : 0f)
                : occ * Float.parseFloat(this.expenseCost));
        return currencyFormat.formatToFloat(passedExpenses * Float.parseFloat(this.expenseCost));
    }
}
