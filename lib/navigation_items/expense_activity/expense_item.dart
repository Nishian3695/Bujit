// Data model for expense entries (e.g., recurring expenses and credit cards)
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:bujit/utils/projector.dart';
import 'package:bujit/utils/category_manager.dart';
import 'check_window.dart';
import 'funding_source.dart';

class ExpenseItem {
    // Persistent fields
    int? id; // Row id once persisted to the database
    String name; // Name of the expense
    int frequency; // Frequency in units of frequencyUnits
    FrequencyUnit frequencyUnits; // Tag to track frequency
    // The two days of a twice-a-month (semimonthly) item; null for other units.
    MonthDays? monthDays;
    // A date on a Saturday or Sunday moves to the Friday before (date-based
    // units only; see Projector.weekendToFriday).
    bool weekendToFriday;
    double amount; // Amount due each occurrence (a credit card's current balance)
    // First scheduled date. Also anchors the schedule: its day of month is what a
    // monthly expense returns to after a short month (Jan 31 -> Feb 28 -> Mar 31).
    // Nothing falls before the first occurrence (firstDate), which is this date
    // or, moved off a weekend, the Friday before.
    DateTime startDate;
    // Next occurrence that hasn't been paid yet. Everything before it is paid.
    DateTime currentDueDate;
    // Last date an occurrence may fall on, inclusive; null = never ends.
    DateTime? endDate;
    String category = otherCategory; // Category of the expense
    String? googleTaskId; // Its task in Google Tasks, once synced (see TasksSync)
    // Whether its Google Task gets the next due date (Google Tasks reminds you
    // on due dates); the Java app's per-expense "calendar notifications".
    bool remindInTasks;
    // What pays each occurrence (see FundingSource): a manual account's id or a
    // card's name in sourceId.
    FundingSource source;
    String? sourceId;
    // A linked bank account (credit or loan) whose balance sets this item's amount
    // at each bank sync -- the Java app's "From Connected Account". Null = not linked.
    String? linkedAccountId;

    // Displayed date and cost for the check currently on screen (see toCheck)
    late DateTime shownDate;
    double periodAmount = 0.00; // Amount due in the check currently on screen

    ExpenseItem({
        this.id,
        required this.name,
        required this.amount,
        required DateTime startDate,
        required this.frequency,
        required this.frequencyUnits,
        this.category = otherCategory,
        DateTime? currentDueDate,
        DateTime? endDate,
        this.googleTaskId,
        this.remindInTasks = true,
        this.source = FundingSource.balance,
        this.sourceId,
        this.linkedAccountId,
        this.monthDays,
        this.weekendToFriday = false,
    }) : startDate = dateOnly(startDate),
         currentDueDate = dateOnly(currentDueDate ?? startDate),
         endDate = endDate == null ? null : dateOnly(endDate) {
        // Twice a month, the start (and next due date) must be one of the two
        // days: move each to the first one on or after it (as scheduled, before
        // any move off a weekend).
        if (frequencyUnits == FrequencyUnit.semimonthly) {
            final Projector scheduled = _makeProjector(weekendRule: false);
            this.startDate = scheduled.firstOnOrAfter(this.startDate);
            this.currentDueDate = scheduled.firstOnOrAfter(maxDate(this.currentDueDate, this.startDate));
        }
        // With the weekend rule, a next due date on a weekend (as scheduled, or from
        // before the rule was turned on) is really the Friday before.
        if (weekendToFriday && frequencyUnits.isDateBased
                && _projector.firstOnOrAfter(this.currentDueDate) != this.currentDueDate) {
            this.currentDueDate = _projector.firstOnOrAfter(addDays(this.currentDueDate, -2));
        }
        shownDate = this.currentDueDate;
        periodAmount = amount;
    }

    // Built on demand so it always reflects the current startDate/frequency.
    // Occurrence 0 is firstDate.
    Projector get _projector => _makeProjector();

    Projector _makeProjector({bool weekendRule = true}) => Projector(
        baseDate: startDate,
        originDate: startDate,
        frequency: frequency,
        frequencyUnits: frequencyUnits,
        monthDays: monthDays,
        weekendToFriday: weekendRule && weekendToFriday,
    );

    // The first occurrence: startDate, or the Friday before it under the weekend rule.
    DateTime get firstDate => _projector.occurrenceDate(0);

    // True once no occurrences remain: the next due date is past the end date.
    bool get hasEnded => endDate != null && currentDueDate.isAfter(endDate!);

    // Methods

    // Number of unpaid occurrences from [from] through [to], both inclusive.
    // Never counts anything before firstDate, before currentDueDate (already
    // paid) or after endDate.
    int occurrencesBetween(DateTime from, DateTime to) {
        final DateTime lo = maxDate(maxDate(dateOnly(from), firstDate), currentDueDate);
        final DateTime hi = endDate == null ? dateOnly(to) : minDate(dateOnly(to), endDate!);
        if (lo.isAfter(hi)) return 0;
        return _projector.countBetween(lo, hi);
    }

    // Dates of the unpaid occurrences from [from] through [to], both inclusive
    // (the same ones occurrencesBetween counts).
    List<DateTime> occurrenceDatesBetween(DateTime from, DateTime to) {
        final DateTime lo = maxDate(maxDate(dateOnly(from), firstDate), currentDueDate);
        final DateTime hi = endDate == null ? dateOnly(to) : minDate(dateOnly(to), endDate!);
        final List<DateTime> dates = [];
        DateTime date = _projector.firstOnOrAfter(lo);
        while (!date.isAfter(hi) && date.isBefore(Projector.never)) {
            dates.add(date);
            date = _projector.firstOnOrAfter(addDays(date, 1));
        }
        return dates;
    }

    // Get number of occurrences in the half-open period [start, end)
    int numOccurrencesInPeriod(DateTime start, DateTime end) {
        return occurrencesBetween(start, addDays(end, -1));
    }

    // Total due from [from] through [to], both inclusive. CreditModel overrides
    // this, since a card's balance is due once rather than per occurrence.
    double amountDueBetween(DateTime from, DateTime to) => amount * occurrencesBetween(from, to);

    // Total due in a check (see CheckWindow for which days that covers).
    double amountDueInCheck(CheckWindow check) => amountDueBetween(check.expensesFrom, check.expensesTo);

    // Total of every occurrence from [from] through [to] (inclusive), paid or not --
    // for history and the Visuals charts, which show what falls in a period rather
    // than what's still owed. Bounded by firstDate and endDate.
    double historicalAmountBetween(DateTime from, DateTime to) {
        final DateTime lo = maxDate(dateOnly(from), firstDate);
        final DateTime hi = endDate == null ? dateOnly(to) : minDate(dateOnly(to), endDate!);
        if (lo.isAfter(hi)) return 0.00;
        return amount * _projector.countBetween(lo, hi);
    }

    // Brings the item up to [today] (default: now), paying every occurrence that
    // fell before it, and returns the total paid so the caller can deduct it
    // from the balance. An occurrence due today is still unpaid. Stops at the
    // end date, so an ended expense never pays again. Calling it twice on the
    // same day pays nothing the second time.
    double makeRecent({DateTime? today}) {
        final DateTime day = dateOnly(today ?? todayDate());
        final double paid = amountDueBetween(currentDueDate, addDays(day, -1));
        _advanceTo(day);
        return paid;
    }

    // Moves the next due date to [today] or later WITHOUT paying anything, for an
    // item entered with a past date whose earlier occurrences already happened
    // outside the app (the add-expense dialog, CSV import). Mirrors the Java
    // app's skipToNextDueDate.
    void skipToNextDueDate({DateTime? today}) {
        _advanceTo(dateOnly(today ?? todayDate()));
    }

    // Sets currentDueDate to the first occurrence on or after [day] (never moving
    // it backward). Past the end date it stops at the first occurrence after the
    // end, which marks the item as ended.
    void _advanceTo(DateTime day) {
        DateTime next = _projector.firstOnOrAfter(maxDate(day, currentDueDate));
        if (endDate != null && next.isAfter(endDate!)) {
            next = maxDate(currentDueDate, _projector.firstOnOrAfter(addDays(endDate!, 1)));
        }
        currentDueDate = next;
        shownDate = next;
    }

    // Updates the displayed date and amount for a check: the amount due in it,
    // and the first unpaid occurrence from the check's first day on.
    void toCheck(CheckWindow check) {
        periodAmount = amountDueInCheck(check);
        final DateTime from = maxDate(check.expensesFrom, currentDueDate);
        shownDate = _projector.firstOnOrAfter(maxDate(from, firstDate));
    }
}
