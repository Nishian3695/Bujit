// The two days of a twice-a-month schedule, for the income stream and expense
// dialogs: the first day (1st-27th) and a later one or the month's last day.
import 'package:flutter/material.dart';
import '../utils/frequency_unit.dart';

class MonthDaysField extends StatelessWidget {
    final MonthDays value;
    final ValueChanged<MonthDays> onChanged;

    const MonthDaysField({super.key, required this.value, required this.onChanged});

    @override
    Widget build(BuildContext context) {
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
                Expanded(
                    child: DropdownButtonFormField<int>(
                        key: const ValueKey("monthDays.first"),
                        initialValue: value.first,
                        decoration: const InputDecoration(labelText: "First day"),
                        items: [
                            for (int day = 1; day <= MonthDays.latestFirst; day++)
                                DropdownMenuItem(value: day, child: Text(ordinalDay(day))),
                        ],
                        // A second day that's no longer later moves to the last day.
                        onChanged: (day) => onChanged(MonthDays(
                            day!, value.second > day ? value.second : MonthDays.lastDay)),
                    ),
                ),
                Expanded(
                    // Rebuilt when the first day changes, so its choices start after it.
                    child: DropdownButtonFormField<int>(
                        key: ValueKey("monthDays.second.${value.first}"),
                        initialValue: value.second,
                        decoration: const InputDecoration(labelText: "Second day"),
                        items: [
                            for (int day = value.first + 1; day < MonthDays.lastDay; day++)
                                DropdownMenuItem(value: day, child: Text(ordinalDay(day))),
                            const DropdownMenuItem(value: MonthDays.lastDay, child: Text("Last day")),
                        ],
                        onChanged: (day) => onChanged(MonthDays(value.first, day!)),
                    ),
                ),
            ],
        );
    }
}
