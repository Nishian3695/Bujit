// Calendar-day helpers. All schedule math in the app works on whole local
// days (midnight), so these never use Duration arithmetic: adding
// Duration(days: n) to a local midnight lands on 23:00 or 01:00 when the span
// crosses a daylight-saving change, which breaks day comparisons.

// The date part of [date], at local midnight.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

// [date] moved by [days] calendar days (negative = backward), at local midnight.
DateTime addDays(DateTime date, int days) => DateTime(date.year, date.month, date.day + days);

// Today at local midnight.
DateTime todayDate() => dateOnly(DateTime.now());

// Whole calendar days from [from] to [to] (negative if [to] is earlier). Done
// in UTC so a daylight-saving change in between can't make it off by one.
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;

// The later / earlier of two dates.
DateTime maxDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
DateTime minDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
