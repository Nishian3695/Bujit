// Mirrors NavigationItems/Settings/SettingsActivity.java in the original Java app.
// So far: the Next Check setting and resetting to the tutorial's sample data.
import 'package:flutter/material.dart';
import '../../app_state.dart';

class SettingsActivity extends StatefulWidget {
    final AppState state;
    const SettingsActivity({super.key, required this.state});

    @override
    State<SettingsActivity> createState() => _SettingsActivityState();
}

class _SettingsActivityState extends State<SettingsActivity> {
    // Asks how many days a single event stays listed after its last change (at least 1).
    Future<void> _editExpiryDays() async {
        final TextEditingController controller =
            TextEditingController(text: widget.state.data.singleEventExpiryDays.toString());
        final int? days = await showDialog<int>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Clear single events after"),
                content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: "days"),
                ),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(int.tryParse(controller.text.trim())),
                        child: const Text("Save"),
                    ),
                ],
            ),
        );
        controller.dispose();
        if (days == null || days < 1) return;
        setState(() => widget.state.data.singleEventExpiryDays = days);
        await widget.state.changed();
    }

    Future<void> _resetToSampleData() async {
        final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Reset to sample data"),
                content: const Text("Replace your balance, expenses, credit cards and income streams "
                    "with the tutorial's sample data? This cannot be undone."),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Reset")),
                ],
            ),
        );
        if (confirmed != true) return;
        await widget.state.resetToSampleData();
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sample data loaded")));
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text("Settings")),
            body: ListView(
                children: [
                    SwitchListTile(
                        title: const Text("Show Next Check"),
                        subtitle: const Text("Add your next paycheck to the after-check balance"),
                        value: widget.state.data.includeNextCheck,
                        onChanged: (enabled) {
                            setState(() => widget.state.data.includeNextCheck = enabled);
                            widget.state.changed();
                        },
                    ),
                    ListTile(
                        title: const Text("Clear single events after"),
                        subtitle: Text("${widget.state.data.singleEventExpiryDays} days since they were last changed"),
                        onTap: _editExpiryDays,
                    ),
                    const Divider(),
                    ListTile(
                        title: const Text("Reset to sample data"),
                        subtitle: const Text("Replace everything with the tutorial's example data"),
                        onTap: _resetToSampleData,
                    ),
                ],
            ),
        );
    }
}
