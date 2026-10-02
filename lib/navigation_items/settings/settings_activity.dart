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
