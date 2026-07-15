package io.github.nishian3695.bujit.CustomListeners;

import android.content.Context;
import io.github.nishian3695.bujit.DisplayPrefs;
import java.text.DecimalFormat;

/*
Utility for formatting numeric values as currency strings with exactly two decimal places.
Wraps a DecimalFormat configured with the pattern "##0.00" (or "#,##0.00" when the
comma-separator display preference is on) and exposes convenience overloads that
convert between String and float. formatToFloat always parses/re-formats without
grouping so it stays parseable regardless of the display preference.
*/
public class CurrencyFormat {
    // DecimalFormat pattern for currency formatting
    final private String curFormat = "##0.00";
    final private String groupedFormat = "#,##0.00";
    DecimalFormat df;
    private final DecimalFormat plainDf = new DecimalFormat(curFormat);
    // Constructor initializes DecimalFormat with the specified currency pattern
    public CurrencyFormat() {
        this(false);
    }
    // Constructor allowing display formatting with thousands separators
    public CurrencyFormat(boolean useCommaSeparators) {
        df = new DecimalFormat(useCommaSeparators ? groupedFormat : curFormat);
    }
    // Format a numeric string to a currency string with two decimal places
    public String formatToString(String string) {
        return df.format(Float.parseFloat(string));
    }
    // Format a numeric string to a float, ensuring it has two decimal places
    public float formatToFloat(String string) {
        return Float.parseFloat(plainDf.format(Float.parseFloat(string)));
    }
    // Format a float to a currency string with two decimal places
    public String formatToString(float aFloat) {
        return df.format(aFloat);
    }
    // Format a float to a float with two decimal places, ensuring currency format
    public float formatToFloat(float aFloat) {
        return Float.parseFloat(plainDf.format(aFloat));
    }
    // Convenience for display call sites: formats using the app-wide comma-separator preference
    public static String display(Context context, float amount) {
        return new CurrencyFormat(DisplayPrefs.useCommaSeparators(context)).formatToString(amount);
    }
    // Convenience for display call sites: formats using the app-wide comma-separator preference.
    // Falls back to the original string unchanged if it isn't a parseable number (e.g. a
    // placeholder like "—" for an unavailable balance).
    public static String display(Context context, String amount) {
        try {
            return new CurrencyFormat(DisplayPrefs.useCommaSeparators(context)).formatToString(amount);
        } catch (NumberFormatException e) {
            return amount;
        }
    }
}
