package io.github.nishian3695.bujit.CustomListeners;

import java.text.DecimalFormat;

/*
Utility for formatting numeric values as currency strings with exactly two decimal places.
Wraps a DecimalFormat configured with the pattern "##0.00" and exposes
convenience overloads that convert between String and float.
*/
public class CurrencyFormat {
    // DecimalFormat pattern for currency formatting
    final private String curFormat = "##0.00";
    DecimalFormat df;
    // Constructor initializes DecimalFormat with the specified currency pattern
    public CurrencyFormat() {
        df = new DecimalFormat(curFormat);
    }
    // Format a numeric string to a currency string with two decimal places
    public String formatToString(String string) {
        return df.format(Float.parseFloat(string));
    }
    // Format a numeric string to a float, ensuring it has two decimal places
    public float formatToFloat(String string) {
        return Float.parseFloat(formatToString(string));
    }
    // Format a float to a currency string with two decimal places
    public String formatToString(float aFloat) {
        return df.format(aFloat);
    }
    // Format a float to a float with two decimal places, ensuring currency format
    public float formatToFloat(float aFloat) {
        return Float.parseFloat(formatToString(aFloat));
    }
}
