// The Java app's Projection Settings dialog: which income stream to project
// with, and whether checks follow its pay period or a custom one.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation_items/expense_activity/projection_settings.dart';
import '../navigation_items/income_streams/income_stream_model.dart';
import '../utils/frequency_unit.dart';
import '../utils/money.dart';
import 'date_field.dart';

// null = cancelled; a null [settings] = Reset (back to the real paydays).
typedef ProjectionChoice = ({ProjectionSettings? settings});

Future<ProjectionChoice?> showProjectionSettingsDialog(
    BuildContext context, {
    required List<IncomeStreamModel> streams,
    required IncomeStreamModel? activeStream,
    ProjectionSettings? current,
}) {
    return showAdaptiveDialog<ProjectionChoice>(
        context: context,
        builder: (context) => _ProjectionSettingsDialog(streams, activeStream, current),
    );
}

class _ProjectionSettingsDialog extends StatefulWidget {
    final List<IncomeStreamModel> streams;
    final IncomeStreamModel? activeStream;
    final ProjectionSettings? current;
    const _ProjectionSettingsDialog(this.streams, this.activeStream, this.current);

    @override
    State<_ProjectionSettingsDialog> createState() => _ProjectionSettingsDialogState();
}

class _ProjectionSettingsDialogState extends State<_ProjectionSettingsDialog> {
    // The custom period's units, as in the Java app.
    static const Map<FrequencyUnit, String> _units = {
        FrequencyUnit.daily: "Days",
        FrequencyUnit.weekly: "Weeks",
        FrequencyUnit.monthly: "Months",
        FrequencyUnit.yearly: "Years",
    };

    late int _stream = _initialStream();
    late bool _custom = _currentCustom != null;
    // Prefilled from a custom period already set; otherwise 1 week, as in the Java app.
    late final TextEditingController _length =
        TextEditingController(text: _currentCustom?.frequency.toString() ?? "1");
    late FrequencyUnit _unit = _units.containsKey(_currentCustom?.unit) ? _currentCustom!.unit : FrequencyUnit.weekly;

    ProjectionSettings? get _currentCustom {
        final ProjectionSettings? current = widget.current;
        return current != null && current.isCustomPeriod ? current : null;
    }
    final _formKey = GlobalKey<FormState>();

    int _initialStream() {
        final IncomeStreamModel? chosen = widget.current?.stream ?? widget.activeStream;
        final int index = widget.streams.indexWhere((s) => identical(s, chosen));
        return index < 0 ? 0 : index;
    }

    @override
    void dispose() {
        _length.dispose();
        super.dispose();
    }

    static String _label(IncomeStreamModel s) =>
        "${s.name} · ${Money.format(s.amount)} · ${s.displayString()}";

    void _apply() {
        if (!_formKey.currentState!.validate()) return;
        final IncomeStreamModel stream = widget.streams[_stream];
        final ProjectionSettings settings = _custom
            ? ProjectionSettings(stream: stream, frequency: int.parse(_length.text.trim()), unit: _unit)
            : ProjectionSettings.streamPeriod(stream);
        // The active stream on its own period is just the real paydays.
        final bool isDefault = identical(stream, widget.activeStream) && !settings.isCustomPeriod;
        Navigator.of(context).pop((settings: isDefault ? null : settings));
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog.adaptive(
            title: const Text("Projection Settings"),
            content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: formSpacing,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            DropdownButtonFormField<int>(
                                initialValue: _stream,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: "Project with"),
                                items: [
                                    for (int i = 0; i < widget.streams.length; i++)
                                        DropdownMenuItem(value: i, child: Text(_label(widget.streams[i]), overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (i) => setState(() => _stream = i ?? 0),
                            ),
                            // The label and its choices, kept together and lined up with the fields.
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text("Pay period", style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                    RadioGroup<bool>(
                                        groupValue: _custom,
                                        onChanged: (custom) => setState(() => _custom = custom ?? false),
                                        child: const Column(
                                            children: [
                                                RadioListTile<bool>(value: false, contentPadding: EdgeInsets.zero,
                                                    title: Text("The stream's pay period")),
                                                RadioListTile<bool>(value: true, contentPadding: EdgeInsets.zero,
                                                    title: Text("Custom")),
                                            ],
                                        ),
                                    ),
                                ],
                            ),
                            if (_custom)
                                Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    spacing: 12,
                                    children: [
                                        Expanded(
                                            child: TextFormField(
                                                controller: _length,
                                                keyboardType: TextInputType.number,
                                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                decoration: const InputDecoration(labelText: "Every"),
                                                validator: (value) => (int.tryParse(value?.trim() ?? "") ?? 0) < 1
                                                    ? "Must be at least 1"
                                                    : null,
                                            ),
                                        ),
                                        Expanded(
                                            child: DropdownButtonFormField<FrequencyUnit>(
                                                initialValue: _unit,
                                                decoration: const InputDecoration(labelText: "Unit"),
                                                items: [
                                                    for (final MapEntry<FrequencyUnit, String> unit in _units.entries)
                                                        DropdownMenuItem(value: unit.key, child: Text(unit.value)),
                                                ],
                                                onChanged: (unit) => setState(() => _unit = unit ?? _unit),
                                            ),
                                        ),
                                    ],
                                ),
                        ],
                    ),
                ),
            ),
            actions: [
                TextButton(onPressed: () => Navigator.of(context).pop((settings: null)), child: const Text("Reset")),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                TextButton(onPressed: _apply, child: const Text("Apply")),
            ],
        );
    }
}
