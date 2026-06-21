package io.github.nishian3695.bujit.NavigationItems.IncomeStreams;

import java.io.Serializable;

/*
Data model for a single income stream (i.e. a paycheck source).
Stores the stream name, pay amount, next check date (yyyy.MM.dd), and
recurrence frequency. The frequencyTag field uses integer codes
(0=Days, 1=Weeks, 2=Months, 3=Years). Only one stream should be marked
selected at a time; it drives the balance projection in ExpenseActivity.
*/
public class IncomeStreamModel implements Serializable {
    private static final long serialVersionUID = 1L;

    private String name;
    private String amount;
    private String checkDate;
    private int frequency;
    private int frequencyTag; // 0=Days, 1=Weeks, 2=Months, 3=Years
    private boolean selected;
    private String googleTaskId = null;

    public IncomeStreamModel(String name, String amount, String checkDate,
                             int frequency, int frequencyTag) {
        this.name = name;
        this.amount = amount;
        this.checkDate = checkDate;
        this.frequency = frequency;
        this.frequencyTag = frequencyTag;
        this.selected = false;
    }

    // Getters
    public String getName()      { return name; }
    public String getAmount()    { return amount; }
    public String getCheckDate() { return checkDate; }
    public int    getFrequency() { return frequency; }
    public int    getFrequencyTag() { return frequencyTag; }
    public boolean isSelected()  { return selected; }

    public float getAmountFloat() {
        try { return Float.parseFloat(amount); } catch (NumberFormatException e) { return 0f; }
    }

    // Setters
    public void setName(String name)           { this.name = name; }
    public void setAmount(String amount)       { this.amount = amount; }
    public void setCheckDate(String checkDate) { this.checkDate = checkDate; }
    public void setFrequency(int frequency)    { this.frequency = frequency; }
    public void setFrequencyTag(int tag)       { this.frequencyTag = tag; }
    public void setSelected(boolean selected)  { this.selected = selected; }
    public String getGoogleTaskId()            { return googleTaskId; }
    public void setGoogleTaskId(String id)     { this.googleTaskId = id; }

    public String getFrequencyDisplayString() {
        String unit;
        switch (frequencyTag) {
            case 0: unit = frequency == 1 ? "day"   : "days";   break;
            case 2: unit = frequency == 1 ? "month" : "months"; break;
            case 3: unit = frequency == 1 ? "year"  : "years";  break;
            default: unit = frequency == 1 ? "week"  : "weeks"; break;
        }
        if (frequency == 2 && frequencyTag == 1) return "Biweekly";
        if (frequency == 1) return "Every " + unit;
        return "Every " + frequency + " " + unit;
    }
}
