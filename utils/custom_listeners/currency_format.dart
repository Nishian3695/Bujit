/*
Utility for formatting currency values
*/
class CurrencyFormat {
    // Number of decimal places; can use this instead of ##0.00 and NumberFormat to format currency values.
    final int _currencyDecimalDigits = 2;
    // String -> currency string
    String formatToString(String value) {
        double doubleValue = double.parse(value);
        return doubleValue.toStringAsFixed(_currencyDecimalDigits);
    }
    // String -> currency double
    double formatToDouble(String value) {
        return double.parse(value);
    }
    // double -> currency string
    String formatToStringFromDouble(double value) {
        return value.toStringAsFixed(_currencyDecimalDigits);
    }
    // double -> currency double
    double formatToDoubleFromDouble(double value) {
        String stringValue = value.toStringAsFixed(_currencyDecimalDigits);
        return double.parse(stringValue);
    }
}