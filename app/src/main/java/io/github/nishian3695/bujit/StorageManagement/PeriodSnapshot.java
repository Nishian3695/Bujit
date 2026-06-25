package io.github.nishian3695.bujit.StorageManagement;

import java.io.Serializable;
import java.time.LocalDate;

/*
Immutable snapshot of a single completed pay period.
Captured by ExpenseActivity when checkForNextCheck() rolls a period into the past,
using the expense and income lists as they existed at that moment.
Stored in StorageHolder.periodSnapshots and passed to VisualsActivity via Intent.
*/
public class PeriodSnapshot implements Serializable {
    private static final long serialVersionUID = 1L;

    private final LocalDate periodStart;
    private final float incomeTotal;
    private final float expenseTotal;

    public PeriodSnapshot(LocalDate periodStart, float incomeTotal, float expenseTotal) {
        this.periodStart  = periodStart;
        this.incomeTotal  = incomeTotal;
        this.expenseTotal = expenseTotal;
    }

    public LocalDate getPeriodStart() { return periodStart; }
    public float     getIncomeTotal() { return incomeTotal; }
    public float     getExpenseTotal(){ return expenseTotal; }
}
