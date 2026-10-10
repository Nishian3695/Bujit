// Shared tag for how often a recurring amount repeats. Used by anything with
// a (frequency count, frequency unit) pair -- expenses, income streams, etc.
//
// Saved by name (see the tables), so values can be added or reordered freely,
// but never renamed. The order here is the order in the dropdowns.
enum FrequencyUnit {
    daily("Daily"),
    weekly("Weekly"),
    biweekly("Biweekly"),
    // Two fixed days each month (MonthDays), e.g. the 15th and the last day.
    // Often called semimonthly; "bimonthly" can also mean every two months,
    // which is "every 2 months" here.
    semimonthly("Twice a month"),
    monthly("Monthly"),
    yearly("Yearly");

    const FrequencyUnit(this.label);
    final String label; // Display text for dropdowns and other UI.

    // Units whose dates are days of the month (or year), which can fall on a
    // weekend and are often moved to the Friday before (see Projector.weekendToFriday).
    // Day counts (daily, weekly, biweekly) keep their weekday, so it doesn't apply.
    bool get isDateBased =>
        this == FrequencyUnit.semimonthly || this == FrequencyUnit.monthly || this == FrequencyUnit.yearly;
}

// The two days of a twice-a-month schedule: [first] is 1-27 and [second] is
// later in the month, with 31 (lastDay) meaning the month's last day. Like a
// monthly date, a day past the end of a short month lands on its last day (the
// 30th is Feb 28/29). Keeping [first] at 27 or earlier means the two dates can
// never land on the same day, even in February.
class MonthDays {
    static const int lastDay = 31;
    static const int latestFirst = 27;
    // The usual semimonthly payroll: the 15th and the last day of the month.
    static const MonthDays standard = MonthDays(15, lastDay);

    final int first;
    final int second;

    const MonthDays(this.first, this.second);

    bool get isValid => first >= 1 && first <= latestFirst && second > first && second <= lastDay;

    // "15th and last day"
    String describe() => "${ordinalDay(first)} and ${dayLabel(second)}";

    // "15th", or "last day" for lastDay.
    static String dayLabel(int day) => day >= lastDay ? "last day" : ordinalDay(day);

    @override
    bool operator ==(Object other) => other is MonthDays && other.first == first && other.second == second;

    @override
    int get hashCode => Object.hash(first, second);

    @override
    String toString() => "MonthDays($first, $second)";
}

// 1 -> "1st", 2 -> "2nd", 11 -> "11th", 22 -> "22nd".
String ordinalDay(int day) {
    if (day % 100 >= 11 && day % 100 <= 13) return "${day}th";
    return switch (day % 10) {
        1 => "${day}st",
        2 => "${day}nd",
        3 => "${day}rd",
        _ => "${day}th",
    };
}

// "Every 2 weeks", "Every 1 month", "Twice a month (15th and last day)", etc.
// [days] is only used for semimonthly (default: MonthDays.standard).
// [weekendToFriday] adds ", Friday if on a weekend" for date-based units.
String describeFrequency(int frequency, FrequencyUnit unit, {MonthDays? days, bool weekendToFriday = false}) {
    final String weekend = weekendToFriday && unit.isDateBased ? ", Friday if on a weekend" : "";
    if (unit == FrequencyUnit.semimonthly) {
        return "Twice a month (${(days ?? MonthDays.standard).describe()})$weekend";
    }
    final String plurality = frequency > 1 ? 's' : '';
    final String base = switch (unit) {
        FrequencyUnit.daily => 'day',
        FrequencyUnit.weekly => 'week',
        FrequencyUnit.biweekly => 'biweek',
        FrequencyUnit.semimonthly => 'half-month', // Handled above
        FrequencyUnit.monthly => 'month',
        FrequencyUnit.yearly => 'year',
    };
    return 'Every $frequency $base$plurality$weekend';
}
