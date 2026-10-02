// How amounts are shown: "$1234.56", or "$1,234.56" with the comma-separator
// setting on (the Java app's CurrencyFormat.display and DisplayPrefs). A
// negative amount reads "$-1234.56", as in the Java app.
class Money {
    // Follows AppData.useCommaSeparators; AppState keeps it in step.
    static bool useCommaSeparators = false;

    static String format(double value) {
        final String fixed = value.abs().toStringAsFixed(2);
        final String sign = value < 0 && fixed != "0.00" ? "-" : "";
        final int dot = fixed.indexOf(".");
        String whole = fixed.substring(0, dot);
        if (useCommaSeparators) {
            final StringBuffer grouped = StringBuffer();
            for (int i = 0; i < whole.length; i++) {
                if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(",");
                grouped.write(whole[i]);
            }
            whole = grouped.toString();
        }
        return "\$$sign$whole${fixed.substring(dot)}";
    }
}
