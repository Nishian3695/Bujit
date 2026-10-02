// Shared "Delete X? This cannot be undone." confirmation, like the Java app's.
import 'package:flutter/material.dart';
import 'text_prompt_dialog.dart';

// Returns true if the user confirmed.
Future<bool> confirmDelete(BuildContext context, String what, String name) async {
    final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
            title: Text("Delete $what"),
            content: Text("Delete \"$name\"? This cannot be undone."),
            actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Delete")),
            ],
        ),
    );
    return confirmed ?? false;
}

// Asks for a new category name; returns it trimmed, or null if cancelled.
Future<String?> askNewCategory(BuildContext context) async {
    final List<String>? values = await showTextPrompt(
        context,
        title: "New Category",
        fields: const [PromptField("Category name")],
        confirmLabel: "Add",
        validate: (values) => values.first.trim().isEmpty ? "Name is required" : null,
    );
    return values?.first.trim();
}
