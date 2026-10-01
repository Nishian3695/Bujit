// One pay period ("check") as the home screen shows it: from the payday it
// starts on to the next payday. index 0 is the current check; 1, 2, ... are
// projected future checks.
//
// This is the single place the payday rule lives, matching the Java app:
// a check's expenses include anything due ON its closing payday, because
// that debit may clear before the paycheck lands -- so "After This Check" is
// the lowest the balance could dip. A projected check therefore starts the
// day AFTER its opening payday, whose expenses the previous check already
// counted:
//   current check   (index 0): expenses due in [today, end]
//   projected check (index k): expenses due in (start, end]
import '../../utils/date_utils.dart';

class CheckWindow {
    final int index; // 0 = current check
    final DateTime start; // payday the check opens on
    final DateTime end; // next payday, which closes it
    final DateTime today;

    CheckWindow({
        required this.index,
        required DateTime start,
        required DateTime end,
        required DateTime today,
    }) : start = dateOnly(start),
         end = dateOnly(end),
         today = dateOnly(today);

    bool get isCurrent => index == 0;

    // First and last day (both inclusive) whose expenses belong to this check.
    DateTime get expensesFrom => isCurrent ? today : addDays(start, 1);
    DateTime get expensesTo => end;

    @override
    String toString() => 'CheckWindow($index: $start -> $end)';
}
