// Mirrors NavigationItems/Settings/SettingsActivity.java in the original Java app.
// So far: the Next Check setting, single-event expiry, Google Tasks sync, CSV
// import and its template, and resetting to the tutorial's sample data.
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import 'csv_import_helper.dart';
import 'google_tasks_helper.dart';

class SettingsActivity extends StatefulWidget {
    final AppState state;
    const SettingsActivity({super.key, required this.state});

    @override
    State<SettingsActivity> createState() => _SettingsActivityState();
}

class _SettingsActivityState extends State<SettingsActivity> {
    // Picks a CSV file, imports it, saves, and shows what was added and any skipped rows.
    Future<void> _importCsv() async {
        // Any type: CSVs arrive with several MIME types; the importer judges the contents.
        final PlatformFile? picked = await FilePicker.pickFile(dialogTitle: "Import CSV");
        if (picked == null) return;
        final Uint8List bytes = await picked.readAsBytes();
        final CsvImportResult result = CsvImportHelper.importInto(
            widget.state.data, utf8.decode(bytes, allowMalformed: true));
        if (result.hasData) await widget.state.changed();
        if (!mounted) return;
        final String errors = result.errors.map((e) => "• $e").join("\n");
        await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
                title: Text(result.hasData ? "Import complete" : "Import failed"),
                content: SingleChildScrollView(child: Text([
                    if (result.hasData) result.summary(),
                    if (errors.isNotEmpty) "${result.hasData ? "Warnings" : "Errors"}:\n$errors",
                    if (!result.hasData && errors.isEmpty) "No importable data found in the file.",
                ].join("\n\n"))),
                actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))],
            ),
        );
    }

    Future<void> _saveCsvTemplate() async {
        final Uri? saved = await FilePicker.saveFile(
            dialogTitle: "Save CSV template",
            fileName: "bujit_import_template.csv",
            mimeType: "text/csv",
            bytes: Uint8List.fromList(utf8.encode(CsvImportHelper.template)),
        );
        if (saved != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Template saved")));
        }
    }

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

    bool _connectingTasks = false;

    // Turning sync on signs in to Google (the account picker and permission
    // screen); turning it off asks whether to remove the tasks Bujit added.
    Future<void> _toggleTasks(bool enable) async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        if (enable) {
            setState(() => _connectingTasks = true);
            try {
                if (await widget.state.connectTasks()) {
                    messenger.showSnackBar(const SnackBar(content: Text("Connected to Google Tasks")));
                }
            } on TasksAuthException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
            } finally {
                if (mounted) setState(() => _connectingTasks = false);
            }
            return;
        }
        final bool? removeTasks = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Stop syncing to Google Tasks?"),
                content: const Text("Remove the tasks Bujit added to your \"Bujit\" list, or keep them?"),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Keep tasks")),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Remove tasks")),
                ],
            ),
        );
        if (removeTasks == null) return;
        await widget.state.disconnectTasks(removeTasks: removeTasks);
    }

    // The Google Tasks switch, its status, and Sync now. Rebuilt as syncs run.
    Widget _googleTasksSection() {
        return ListenableBuilder(
            listenable: widget.state,
            builder: (context, _) {
                final AppState state = widget.state;
                final bool configured = state.tasks?.account.isConfigured ?? false;
                final bool on = state.data.tasksSyncEnabled;
                final TasksSyncResult? last = state.lastTasksSync;
                final String status = !configured
                    ? "Not set up in this build"
                    : !on
                        ? "Add expenses, cards and paychecks to a \"Bujit\" list, with reminders on due dates"
                        : [
                            "Connected as ${state.data.tasksAccount ?? "your Google account"}",
                            if (state.tasksSyncing) "Syncing…" else if (last != null) last.summary(),
                        ].join("\n");
                return Column(
                    children: [
                        SwitchListTile(
                            title: const Text("Sync to Google Tasks"),
                            subtitle: Text(status),
                            value: on,
                            onChanged: configured && !_connectingTasks ? _toggleTasks : null,
                        ),
                        if (on && configured)
                            ListTile(
                                title: const Text("Sync now"),
                                enabled: !state.tasksSyncing,
                                onTap: () => state.syncTasks(),
                            ),
                    ],
                );
            },
        );
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
        return TutorialOverlay(
            state: widget.state,
            screen: TutorialScreen.settings,
            child: Scaffold(
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
                    _googleTasksSection(),
                    const Divider(),
                    TutorialTarget(
                        id: "import_csv",
                        child: ListTile(
                            title: const Text("Import CSV"),
                            subtitle: const Text("Add expenses, credit cards and income streams from a file"),
                            onTap: _importCsv,
                        ),
                    ),
                    ListTile(
                        title: const Text("Save CSV template"),
                        subtitle: const Text("An example file showing the format"),
                        onTap: _saveCsvTemplate,
                    ),
                    const Divider(),
                    TutorialTarget(
                        id: "replay_tutorial",
                        child: ListTile(
                            title: const Text("Replay tutorial"),
                            subtitle: const Text("Walk through Bujit's features again"),
                            onTap: () async {
                                final NavigatorState navigator = Navigator.of(context);
                                await widget.state.replayTutorial();
                                navigator.popUntil((route) => route.isFirst); // it starts on the home screen
                            },
                        ),
                    ),
                    ListTile(
                        title: const Text("Reset to sample data"),
                        subtitle: const Text("Replace everything with the tutorial's example data"),
                        onTap: _resetToSampleData,
                    ),
                ],
            ),
            ),
        );
    }
}
