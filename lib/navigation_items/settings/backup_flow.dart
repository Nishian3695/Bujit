// Settings' Export Backup and Import Backup, as in the Java app's SettingsActivity:
// a passphrase (typed, or generated when left blank), a reminder to save it, then
// the encrypted .bujitbackup file; importing asks for the passphrase and confirms
// before replacing everything. Backups from the Java app import too (see BackupJson).
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app_state.dart';
import '../../dialogs/text_prompt_dialog.dart';
import '../../storage_management/app_data_store.dart';
import '../../storage_management/backup/backup_crypto.dart';
import '../../storage_management/backup/backup_json.dart';
import '../../utils/date_utils.dart';

// The Java app's default file name: bujit_backup_YYYY-MM-DD.bujitbackup.
String defaultBackupFilename({DateTime? today}) {
    final DateTime day = dateOnly(today ?? todayDate());
    String two(int n) => n.toString().padLeft(2, "0");
    return "bujit_backup_${day.year}-${two(day.month)}-${two(day.day)}.bujitbackup";
}

Future<void> exportBackup(BuildContext context, AppState state) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    String? passphrase;
    while (passphrase == null) {
        if (!context.mounted) return;
        final String? chosen = await _askExportPassphrase(context);
        if (chosen == null || !context.mounted) return;
        final bool? saved = await _confirmSavedPassphrase(context, chosen);
        if (saved == null) return; // dismissed
        if (saved) passphrase = chosen; // otherwise "Go Back" to choose again
    }
    if (!context.mounted) return;
    final String? envelope = await _withProgress(context, "Exporting…",
        () => BackupCrypto.encrypt(BackupJson.encode(state.data), passphrase!));
    if (envelope == null) {
        messenger.showSnackBar(const SnackBar(content: Text("Could not export backup")));
        return;
    }
    final Uri? saved = await FilePicker.saveFile(
        dialogTitle: "Export Backup",
        fileName: defaultBackupFilename(),
        mimeType: "application/octet-stream",
        bytes: Uint8List.fromList(utf8.encode(envelope)),
    );
    if (saved != null) messenger.showSnackBar(const SnackBar(content: Text("Backup exported")));
}

Future<void> importBackup(BuildContext context, AppState state) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final PlatformFile? picked = await FilePicker.pickFile(dialogTitle: "Import Backup");
    if (picked == null || !context.mounted) return;
    final String envelope = utf8.decode(await picked.readAsBytes(), allowMalformed: true);
    if (!context.mounted) return;
    final String? passphrase = await _askImportPassphrase(context);
    if (passphrase == null || !context.mounted) return;

    BackupCryptoException? failure;
    final AppData? restored = await _withProgress(context, "Reading backup…", () async {
        try {
            return BackupJson.decode(await BackupCrypto.decrypt(envelope, passphrase));
        } on BackupCryptoException catch (e) {
            failure = e;
        } on FormatException {
            failure = const BackupCryptoException(BackupFailure.malformedEnvelope, "Not Bujit data");
        }
        return null;
    });
    if (!context.mounted) return;
    if (restored == null) {
        final BackupCryptoException error = failure ??
            const BackupCryptoException(BackupFailure.malformedEnvelope, "Could not read backup file");
        await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
                title: Text(error.title),
                content: Text(error.explanation),
                actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("OK"))],
            ),
        );
        return;
    }
    final String? exportedAt = BackupCrypto.readExportedAt(envelope);
    final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text("Import Backup"),
            content: Text("Import backup${exportedAt == null ? "" : " from $exportedAt"}? This will replace all "
                "current data on this device. This cannot be undone."),
            actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Import")),
            ],
        ),
    );
    if (confirmed != true) return;
    await state.restoreBackup(restored);
    navigator.popUntil((route) => route.isFirst); // Back to the home screen, as the Java app restarts it
    messenger.showSnackBar(const SnackBar(content: Text("Backup restored")));
}

// Both fields blank -> a generated passphrase; else they must match and be 8+ characters.
Future<String?> _askExportPassphrase(BuildContext context) async {
    final List<String>? values = await showTextPrompt(
        context,
        title: "Export Backup",
        message: "Set a passphrase to protect this backup, or leave both fields blank "
            "and Bujit will generate one for you.",
        fields: const [PromptField("Passphrase", obscure: true), PromptField("Confirm passphrase", obscure: true)],
        confirmLabel: "Next",
        validate: (values) {
            final String pass = values[0];
            final String confirm = values[1];
            if (pass.isEmpty && confirm.isEmpty) return null;
            if (pass != confirm) return "Passphrases don't match";
            if (pass.length < 8) return "Passphrase must be at least 8 characters";
            return null;
        },
    );
    if (values == null) return null;
    return values[0].isEmpty ? BackupCrypto.generatePassphrase() : values[0];
}

// true = saved, continue; false = go back; null = dismissed.
Future<bool?> _confirmSavedPassphrase(BuildContext context, String passphrase) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            title: const Text("Save Your Passphrase"),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    SelectableText(passphrase, style: const TextStyle(fontFamily: "monospace", fontSize: 18)),
                    TextButton.icon(
                        onPressed: () => Clipboard.setData(ClipboardData(text: passphrase)),
                        icon: const Icon(Icons.copy),
                        label: const Text("Copy"),
                    ),
                    const Text("Bujit does not store this passphrase anywhere and cannot recover your backup "
                        "without it. Write it down or save it somewhere safe before continuing."),
                ],
            ),
            actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Go Back")),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("I've Saved It — Export")),
            ],
        ),
    );
}

Future<String?> _askImportPassphrase(BuildContext context) async {
    final List<String>? values = await showTextPrompt(
        context,
        title: "Import Backup",
        message: "Enter the passphrase used to create this backup.",
        fields: const [PromptField("Passphrase", obscure: true)],
        confirmLabel: "Import",
    );
    return values?.first;
}

// Runs [work] behind a non-dismissible progress dialog; null if it threw.
Future<T?> _withProgress<T>(BuildContext context, String title, Future<T?> Function() work) async {
    final NavigatorState navigator = Navigator.of(context);
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            title: Text(title),
            content: const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
        ),
    );
    try {
        return await work();
    } catch (_) {
        return null;
    } finally {
        navigator.pop();
    }
}
