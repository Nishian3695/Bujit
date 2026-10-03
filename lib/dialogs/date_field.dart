// A date in a dialog's form, drawn like the other outlined fields: a label, the
// date (or a placeholder), a calendar icon, and an optional clear button and
// error. Tapping it opens the date picker.
import 'package:flutter/material.dart';
import '../utils/date_utils.dart';

// Space between the fields of a dialog's form: enough that an outlined field's
// floating label never touches the field above it.
const double formSpacing = 16;

class DateField extends StatelessWidget {
    final String label;
    final DateTime? value;
    final String placeholder; // Shown when there's no date ("Pick a date", "Never")
    final ValueChanged<DateTime> onPicked;
    final VoidCallback? onClear; // Shows a clear button while there's a date
    final DateTime? initialPickerDate; // Where the picker opens when there's no date
    final String? errorText;

    const DateField({
        super.key,
        required this.label,
        required this.value,
        required this.onPicked,
        this.placeholder = "Pick a date",
        this.onClear,
        this.initialPickerDate,
        this.errorText,
    });

    Future<void> _pick(BuildContext context) async {
        final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: value ?? initialPickerDate ?? todayDate(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(dateOnly(picked));
    }

    @override
    Widget build(BuildContext context) {
        final DateTime? date = value;
        final TextStyle? text = Theme.of(context).textTheme.bodyLarge;
        return InkWell(
            onTap: () => _pick(context),
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
                decoration: InputDecoration(
                    labelText: label,
                    errorText: errorText,
                    suffixIcon: date != null && onClear != null
                        ? IconButton(onPressed: onClear, icon: const Icon(Icons.close), tooltip: "Clear $label")
                        : const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                    date == null ? placeholder : shortDate(date),
                    style: date == null ? text?.copyWith(color: Theme.of(context).hintColor) : text,
                ),
            ),
        );
    }
}
