package io.github.nishian3695.bujit.ExpenseActivity;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

/*
Data model for a single regular recurring expense (as opposed to a credit card — see
CreditModel). Each expense has a base cost and recurrence frequency (e.g. every 1 month). The
"shown" fields (shownDate, shownCost, shownStatus) hold display values for whichever check
period is currently on screen, while the base fields store the canonical next-occurrence data
that is persisted to disk.
*/
public class ExpenseModel extends ExpenseItem {

    private static final long serialVersionUID = 1L;

    // Payment status codes
    final private int UNPAID = -1;
    final private int SOMEPAID = 0;
    final private int PAID = 1;
    final private String UNPAID_STR = "Not Paid";
    final private String SOMEPAID_STR = "Partly Paid";
    final private String PAID_STR = "Paid";

    private int expenseStatus;
    private int expensePartPaid;
    private boolean expenseIsVariable;
    private int shownStatus;
    // User-assigned spending category (e.g. "Food", "Housing"). Defaults to "Other".
    private String category = "Other";

    //Constructor
    // Creates a new expense with its base recurrence data; shownDate/shownCost start out equal
    // to the base values until a check-period navigation updates them.
    public ExpenseModel(String expenseName, String expenseCost, LocalDate expenseDate,
                        int expenseFrequency, ChronoUnit expenseFrequencyTag,
                        boolean expenseIsVariable) {
        super(expenseName, expenseCost, expenseDate, expenseFrequency, expenseFrequencyTag);
        this.expenseIsVariable = expenseIsVariable;
        this.expenseStatus = UNPAID;
    }

    // Define setters
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

    // Category
    public String getCategory() { return category != null ? category : "Other"; }
    public void setCategory(String category) { this.category = (category != null && !category.isEmpty()) ? category : "Other"; }

    /*
    Advances shownDate forward until it falls within [beg, end) and sets shownCost
    to the total amount due in that check period. Used when navigating to a future check.
    */
    @Override
    public void getNextCheckPayments(LocalDate beg, LocalDate end, List<ExpenseItem> allExpenses) {
        while (this.shownDate.isBefore(beg)) {
            this.shownDate = this.shownDate.plus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        int occurrences = getOccurrences(beg, end, false);
        setShownCost(occurrences * Float.parseFloat(this.expenseCost));
    }

    /*
    Rewinds shownDate backward until it falls within [beg, end) and sets shownCost
    to the total amount due in that check period. Used when navigating to a past check.
    */
    @Override
    public void getPrevCheckPayments(LocalDate beg, LocalDate end, List<ExpenseItem> allExpenses) {
        while (beg.isBefore(this.shownDate.minus(this.expenseFrequency, this.expenseFrequencyTag))) {
            this.shownDate = this.shownDate.minus(this.expenseFrequency, this.expenseFrequencyTag);
        }
        int occurrences = getOccurrences(beg, end, false);
        setShownCost(occurrences * Float.parseFloat(this.expenseCost));
    }

    /*
    Advances the expense's base date forward until it is in the future (today or later),
    and resets shownDate to match. Returns the total amount of past occurrences that have
    already been paid (so the caller can deduct that from its funding Source).
    */
    @Override
    public float makeCurrent(LocalDate beg, LocalDate end, List<ExpenseItem> allExpenses) {
        int passedExpenses = 0;
        while (LocalDate.now().isAfter(this.expenseDate)) {
            this.expenseDate = this.expenseDate.plus(this.expenseFrequency, this.expenseFrequencyTag);
            passedExpenses++;
        }
        setShownDate(this.expenseDate);
        int occ = getOccurrences(beg, end, true);
        setShownCost(occ * Float.parseFloat(this.expenseCost));
        return currencyFormat.formatToFloat(passedExpenses * Float.parseFloat(this.expenseCost));
    }
}
