package io.github.nishian3695.bujit.StorageManagement;

import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamModel;
import io.github.nishian3695.bujit.NavigationItems.SingleEvents.SingleEventModel;
import java.io.Serializable;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;

/*
Serializable container that holds all persistent app state written to disk by StorageManager.
Fields include the expense list, current balance, legacy check-period settings
(superseded by incomeStreamList), check period start/end dates, and the last-opened date.
Default constructor initialises sane starting values so a first-run app works without data.
*/
public class StorageHolder implements Serializable {
    private static final long serialVersionUID = 1L;

    // region Stored Data
    private ArrayList<ExpenseModel> expenseList;
    private String currentBalance;
    private String averageCheck;
    private String checkFrequency;
    private ChronoUnit checkFrequencyTag;
    private LocalDate curCheckDate;
    private LocalDate nextCheckDate;
    private LocalDate lastOpenedDate;
    private ArrayList<IncomeStreamModel> incomeStreamList;
    private ArrayList<PeriodSnapshot> periodSnapshots;
    private ArrayList<String> categoryList;
    private ArrayList<SingleEventModel> singleEventList;
    private float manualBalanceAddition;
    // endregion

    public StorageHolder() {
        expenseList = new ArrayList<>();
        currentBalance = "0.00";
        averageCheck = "0.00";
        checkFrequency = "1";
        checkFrequencyTag = ChronoUnit.WEEKS;
        LocalDate calendar = LocalDate.now();
        curCheckDate = calendar;
        lastOpenedDate = calendar;
        nextCheckDate = calendar.plus(1, ChronoUnit.WEEKS);
        periodSnapshots = new ArrayList<>();
        categoryList = CategoryManager.getDefaults();
        singleEventList = new ArrayList<>();
    }

    // region Getters
    public ArrayList<ExpenseModel> getExpenseList() {
        return expenseList;
    }
    public float getCurrentBalance() {
        return Float.parseFloat(currentBalance);
    }
    public float getAverageCheck() {
        return Float.parseFloat(averageCheck);
    }
    public int getCheckFrequency() {
        return Integer.parseInt(checkFrequency);
    }
    public ChronoUnit getCheckFrequencyTag() {
        return checkFrequencyTag;
    }
    public LocalDate getCurCheckDate() {
        return curCheckDate;
    }
    public LocalDate getNextCheckDate() {
        return nextCheckDate;
    }
    public LocalDate getLastOpenedDate() {
        return lastOpenedDate;
    }
    public ArrayList<IncomeStreamModel> getIncomeStreamList() {
        return incomeStreamList;
    }
    public ArrayList<PeriodSnapshot> getPeriodSnapshots() {
        return periodSnapshots;
    }
    public ArrayList<String> getCategoryList() {
        if (categoryList == null) categoryList = CategoryManager.getDefaults();
        return categoryList;
    }
    public ArrayList<SingleEventModel> getSingleEventList() {
        if (singleEventList == null) singleEventList = new ArrayList<>();
        return singleEventList;
    }
    public float getManualBalanceAddition() { return manualBalanceAddition; }
    // endregion

    // region Setters
    public void setExpenseList(ArrayList<ExpenseModel> expenseList) {
        this.expenseList = expenseList;
    }
    public void setCurrentBalance(float currentBalance) {
        this.currentBalance = String.valueOf(currentBalance);
    }
    public void setAverageCheck(float averageCheck) {
        this.averageCheck = String.valueOf(averageCheck);
    }
    public void setCheckFrequency(int checkFrequency) {
        this.checkFrequency = String.valueOf(checkFrequency);
    }
    public void setCheckFrequencyTag(ChronoUnit checkFrequencyTag) {
        this.checkFrequencyTag = checkFrequencyTag;
    }
    public void setCurCheckDate(LocalDate curCheckDate) {
        this.curCheckDate = curCheckDate;
    }
    public void setNextCheckDate(LocalDate nextCheckDate) {
        this.nextCheckDate = nextCheckDate;
    }
    public void setLastOpenedDate(LocalDate lastOpenedDate) {
        this.lastOpenedDate = lastOpenedDate;
    }
    public void setIncomeStreamList(ArrayList<IncomeStreamModel> incomeStreamList) {
        this.incomeStreamList = incomeStreamList;
    }
    public void setPeriodSnapshots(ArrayList<PeriodSnapshot> periodSnapshots) {
        this.periodSnapshots = periodSnapshots;
    }
    public void setCategoryList(ArrayList<String> categoryList) {
        this.categoryList = categoryList;
    }
    public void setSingleEventList(ArrayList<SingleEventModel> list) {
        this.singleEventList = list;
    }
    public void setManualBalanceAddition(float v) { this.manualBalanceAddition = v; }
    // endregion
}
