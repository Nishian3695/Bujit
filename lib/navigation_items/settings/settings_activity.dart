// Mirrors NavigationItems/Settings/SettingsActivity.java in the original Java app,
// in its sections: appearance (theme, accent color) and display options, Google
// Tasks, categories, the app lock, single-event expiry, support (help, tutorial,
// rating), the tip jar, data (CSV import and template, resetting or clearing),
// encrypted backups, and the website and legal links. (Java's "Transfer to New
// Device" was only a "coming soon" row.)
import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../app_state.dart';
import '../../dialogs/text_prompt_dialog.dart';
import '../../prefs/app_lock_prefs.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import '../../utils/custom_views/color_wheel_view.dart';
import '../../utils/legal.dart';
import '../../utils/theme_helper.dart';
import '../../utils/ui.dart';
import '../../storage_management/app_data_store.dart';
import 'backup_flow.dart';
import 'category_manager_activity.dart';
import 'csv_import_helper.dart';
import 'google_tasks_helper.dart';
import 'tip_jar.dart';

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
        final List<String>? values = await showTextPrompt(
            context,
            title: "Clear single events after",
            fields: [
                PromptField("Days",
                    initialValue: widget.state.data.singleEventExpiryDays.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    suffixText: "days"),
            ],
            confirmLabel: "Save",
            validate: (values) => (int.tryParse(values.first.trim()) ?? 0) < 1 ? "At least 1 day" : null,
        );
        final int? days = values == null ? null : int.tryParse(values.first.trim());
        if (days == null || days < 1) return;
        setState(() => widget.state.data.singleEventExpiryDays = days);
        await widget.state.changed();
    }

    bool _connectingTasks = false;

    static String _serviceName(String provider) =>
        provider == AppState.appleReminders ? "Apple Reminders" : "Google Tasks";

    // Turning sync on signs in to Google (the account picker and permission
    // screen) or asks for Reminders access; with the other service on, that one
    // is turned off (its tasks stay). Turning it off asks whether to remove the
    // tasks Bujit added.
    Future<void> _toggleTasks(String provider, bool enable) async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        final String service = _serviceName(provider);
        if (enable) {
            setState(() => _connectingTasks = true);
            try {
                if (await widget.state.connectTasks(provider: provider)) {
                    messenger.showSnackBar(SnackBar(content: Text("Connected to $service")));
                }
            } on TasksAuthException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
            } finally {
                if (mounted) setState(() => _connectingTasks = false);
            }
            return;
        }
        final String items = provider == AppState.appleReminders ? "reminders" : "tasks";
        final bool? removeTasks = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: Text("Stop syncing to $service?"),
                content: Text("Remove the $items Bujit added to your \"Bujit\" list, or keep them?"),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Keep $items")),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("Remove $items")),
                ],
            ),
        );
        if (removeTasks == null) return;
        await widget.state.disconnectTasks(removeTasks: removeTasks);
    }

    // A switch for each task sync service this device has (Google Tasks; Apple
    // Reminders on iPhone), their status, and Sync now. Rebuilt as syncs run.
    Widget _tasksSection() {
        return ListenableBuilder(
            listenable: widget.state,
            builder: (context, _) {
                final AppState state = widget.state;
                final bool remindersAvailable = state.reminders?.account.isConfigured ?? false;
                Widget serviceTile(String provider) {
                    final bool configured = state.taskSyncFor(provider)?.account.isConfigured ?? false;
                    final bool on = state.data.tasksSyncEnabled && state.data.tasksProvider == provider;
                    final TasksSyncResult? last = state.lastTasksSync;
                    final String status = !configured
                        ? "Not set up in this build"
                        : !on
                            ? provider == AppState.appleReminders
                                ? "Add expenses, cards and paychecks to a \"Bujit\" list in Reminders, on all your Apple devices"
                                : "Add expenses, cards and paychecks to a \"Bujit\" list, with reminders on due dates"
                            : [
                                provider == AppState.appleReminders
                                    ? "Syncing to the \"Bujit\" list in Reminders"
                                    : "Connected as ${state.data.tasksAccount ?? "your Google account"}",
                                if (state.tasksSyncing) "Syncing…" else if (last != null) last.summary(),
                            ].join("\n");
                    return SwitchListTile(
                        title: Text("Sync to ${_serviceName(provider)}"),
                        subtitle: Text(status),
                        value: on,
                        onChanged: configured && !_connectingTasks ? (enable) => _toggleTasks(provider, enable) : null,
                    );
                }

                return Column(
                    children: [
                        serviceTile(AppState.googleTasks),
                        if (remindersAvailable) serviceTile(AppState.appleReminders),
                        if (state.canSyncTasks)
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

    // Turning the lock on needs a screen lock on the device and a successful
    // unlock first, as in the Java app; turning it off doesn't.
    Future<void> _toggleAppLock(bool enable) async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        if (enable) {
            final DeviceAuth? auth = widget.state.deviceAuth;
            if (auth == null || !await auth.isAvailable()) {
                messenger.showSnackBar(const SnackBar(content: Text(
                    "No screen lock set up. Enable a PIN, pattern, or biometric in device settings first.")));
                return;
            }
            if (!await auth.authenticate("Confirm your identity to enable lock")) return;
        }
        setState(() => widget.state.data.appLockEnabled = enable);
        await widget.state.changed();
    }

    Future<void> _clearAllData() async {
        final NavigatorState navigator = Navigator.of(context);
        final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text("Clear All Data"),
                content: const Text("This will permanently delete all expenses, your balance, accounts and "
                    "settings, and turn off task sync. Bujit starts over with the tutorial's sample "
                    "data. This cannot be undone."),
                actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Clear Everything")),
                ],
            ),
        );
        if (confirmed != true) return;
        await widget.state.clearAllData();
        navigator.popUntil((route) => route.isFirst); // The tutorial starts on the home screen
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

    // ── Support, data and legal (the Java app's remaining Settings rows) ────

    // Get CSV Template: save it to the device, or share it, as in the Java app.
    Future<void> _csvTemplate() async {
        final String? choice = await showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
                title: const Text("CSV Template"),
                children: [
                    SimpleDialogOption(onPressed: () => Navigator.of(context).pop("save"), child: const Text("Save to device")),
                    SimpleDialogOption(onPressed: () => Navigator.of(context).pop("share"), child: const Text("Share")),
                ],
            ),
        );
        if (choice == "save") await _saveCsvTemplate();
        if (choice == "share") await _shareCsvTemplate();
    }

    Future<void> _shareCsvTemplate() async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        try {
            await SharePlus.instance.share(ShareParams(
                subject: "Bujit Import Template",
                files: [
                    XFile.fromData(Uint8List.fromList(utf8.encode(CsvImportHelper.template)),
                        mimeType: "text/csv", name: "bujit_import_template.csv"),
                ],
                fileNameOverrides: const ["bujit_import_template.csv"],
            ));
        } catch (e) {
            messenger.showSnackBar(SnackBar(content: Text("Could not share template: $e")));
        }
    }

    Future<void> _showDisclaimer() => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text("Disclaimer"),
            content: const SingleChildScrollView(child: Text(disclaimerText)),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))],
        ),
    );

    Future<void> _tip(TipJar jar, Tip tip) async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        if (!await jar.give(tip)) {
            // Replaces any message showing, as the Java app's toasts did.
            messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text("Store unavailable — try again later")));
        }
    }

    // Three tip buttons with the store's prices (defaults until they arrive).
    Widget _tipJarSection() {
        final TipJar? jar = widget.state.tipJar;
        return ListenableBuilder(
            listenable: jar ?? widget.state,
            builder: (context, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text("Bujit is free and has no ads. Leave a tip if you're feeling generous."),
                        const SizedBox(height: 8),
                        Wrap(
                            spacing: 8,
                            children: [
                                for (final Tip tip in Tip.values)
                                    OutlinedButton(
                                        onPressed: jar == null ? null : () => _tip(jar, tip),
                                        child: Text("${tip.emoji}  ${jar?.price(tip) ?? tip.defaultPrice}"),
                                    ),
                            ],
                        ),
                    ],
                ),
            ),
        );
    }

    static Widget _header(String title) => SectionLabel(title);

    // App theme (System/Light/Dark) and the accent color: Java's presets as
    // swatches, then one for a custom color picked on the color wheel.
    Widget _appearanceSection() {
        final AppData data = widget.state.data;
        final AccentColor accent = widget.state.accent;
        Future<void> setAccent(AccentColor value, [int? custom]) async {
            setState(() {
                data.accentColor = value.name;
                if (custom != null) data.customAccent = custom;
            });
            await widget.state.changed();
        }

        Widget swatch(AccentColor value, Color color, {required VoidCallback onTap, IconData? icon}) {
            final bool selected = value == accent;
            final Color onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                ? Colors.white : Colors.black;
            return Tooltip(
                message: value.label,
                child: InkResponse(
                    onTap: onTap,
                    radius: 24,
                    child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selected
                                ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                                : null,
                        ),
                        child: selected
                            ? Icon(Icons.check, color: onColor)
                            : icon == null ? null : Icon(icon, color: onColor, size: 20),
                    ),
                ),
            );
        }

        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                            segments: const [
                                ButtonSegment(value: ThemeMode.system, label: Text("System"), icon: Icon(Icons.brightness_auto)),
                                ButtonSegment(value: ThemeMode.light, label: Text("Light"), icon: Icon(Icons.light_mode)),
                                ButtonSegment(value: ThemeMode.dark, label: Text("Dark"), icon: Icon(Icons.dark_mode)),
                            ],
                            selected: {widget.state.themeMode},
                            showSelectedIcon: false,
                            onSelectionChanged: (modes) {
                                setState(() => data.themeMode = modes.first.name);
                                widget.state.changed();
                            },
                        ),
                    ),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Accent color"),
                ),
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                            for (final AccentColor value in AccentColor.values)
                                if (value != AccentColor.custom)
                                    swatch(value, value.color, onTap: () => setAccent(value)),
                            swatch(AccentColor.custom, Color(data.customAccent), icon: Icons.colorize, onTap: () async {
                                final int? picked = await showCustomColorDialog(context, data.customAccent);
                                if (picked != null) await setAccent(AccentColor.custom, picked);
                            }),
                        ],
                    ),
                ),
            ],
        );
    }

    ListTile _link(String title, String subtitle, String url) => ListTile(
        title: Text(title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => Links.open(context, url),
    );

    @override
    void initState() {
        super.initState();
        _thanks = widget.state.tipJar?.thanks.listen((_) {
            if (mounted) {
                ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text("Thank you for your support!")));
            }
        });
    }

    StreamSubscription<void>? _thanks;

    @override
    void dispose() {
        _thanks?.cancel();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final AppData data = widget.state.data;
        return TutorialOverlay(
            state: widget.state,
            screen: TutorialScreen.settings,
            child: Scaffold(
                appBar: AppBar(title: const Text("Settings")),
                // Not a lazy ListView: every row is built, so the tutorial can scroll
                // its targets near the bottom (Import from CSV, Replay tutorial) into view.
                body: SingleChildScrollView(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        _header("APPEARANCE"),
                        _appearanceSection(),
                        SwitchListTile(
                            title: const Text("Comma separators"),
                            subtitle: const Text("Show amounts like \$3,000.00 instead of \$3000.00"),
                            value: data.useCommaSeparators,
                            onChanged: (enabled) {
                                setState(() => data.useCommaSeparators = enabled);
                                widget.state.changed();
                            },
                        ),
                        SwitchListTile(
                            title: const Text("Show Next Check"),
                            subtitle: const Text("Add your next check's income to the after-check balance"),
                            value: data.includeNextCheck,
                            onChanged: (enabled) {
                                setState(() => data.includeNextCheck = enabled);
                                widget.state.changed();
                            },
                        ),
                        const Divider(),
                        _header("INTEGRATIONS"),
                        _tasksSection(),
                        const Divider(),
                        _header("CATEGORIES"),
                        ListTile(
                            title: const Text("Manage categories"),
                            subtitle: const Text("Add, remove, or reorder spending categories"),
                            onTap: () async {
                                await Navigator.of(context).push(MaterialPageRoute<void>(
                                    builder: (_) => CategoryManagerActivity(state: widget.state)));
                                if (mounted) setState(() {});
                            },
                        ),
                        const Divider(),
                        _header("SECURITY"),
                        SwitchListTile(
                            title: const Text("App lock"),
                            subtitle: const Text("Unlock with your fingerprint, face or screen lock when opening Bujit"),
                            value: data.appLockEnabled,
                            onChanged: _toggleAppLock,
                        ),
                        const Divider(),
                        _header("SINGLE EVENTS"),
                        ListTile(
                            title: const Text("Clear single events after"),
                            subtitle: Text("${data.singleEventExpiryDays} days since they were last changed"),
                            onTap: _editExpiryDays,
                        ),
                        const Divider(),
                        _header("SUPPORT"),
                        _link("Help / Suggestions", "Send feedback or report an issue", Links.helpSuggestions),
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
                        if (Links.canRate)
                            ListTile(
                                title: const Text("Rate Bujit"),
                                subtitle: Text(defaultTargetPlatform == TargetPlatform.iOS
                                    ? "Leave a rating on the App Store" : "Leave a rating on the Play Store"),
                                onTap: () => Links.rate(context),
                            ),
                        const Divider(),
                        _header("SUPPORT DEVELOPMENT"),
                        _tipJarSection(),
                        const Divider(),
                        _header("DATA"),
                        TutorialTarget(
                            id: "import_csv",
                            child: ListTile(
                                title: const Text("Import from CSV"),
                                subtitle: const Text("Bulk-import expenses, cards, income streams and accounts from a file"),
                                onTap: _importCsv,
                            ),
                        ),
                        ListTile(
                            title: const Text("Get CSV template"),
                            subtitle: const Text("Share or save the import template"),
                            onTap: _csvTemplate,
                        ),
                        _link("CSV import reference", "Row types, fields, and examples for the import format",
                            Links.csvReference),
                        ListTile(
                            title: const Text("Reset to sample data"),
                            subtitle: const Text("Replace your data with the tutorial's example data, keeping settings"),
                            onTap: _resetToSampleData,
                        ),
                        ListTile(
                            title: const Text("Clear all data"),
                            subtitle: const Text("Permanently removes all expenses, balance, and linked accounts"),
                            onTap: _clearAllData,
                        ),
                        const Divider(),
                        _header("BACKUP & TRANSFER"),
                        ListTile(
                            title: const Text("Export backup"),
                            subtitle: const Text("Save a passphrase-encrypted copy of all your data to a file"),
                            onTap: () => exportBackup(context, widget.state),
                        ),
                        ListTile(
                            title: const Text("Import backup"),
                            subtitle: const Text("Restore your data from a backup (including one from the old Android app)"),
                            onTap: () => importBackup(context, widget.state),
                        ),
                        const Divider(),
                        _header("INFO"),
                        _link("Website", "Privacy policy, CSV reference, and support", Links.website),
                        const Divider(),
                        _header("LEGAL"),
                        _link("Privacy Policy", "", Links.privacyPolicy),
                        _link("Plaid Legal and Privacy Policy", "Third-party banking data provider", Links.plaidPrivacy),
                        ListTile(title: const Text("Disclaimer"), onTap: _showDisclaimer),
                    ],
                    ),
                ),
            ),
        );
    }
}
