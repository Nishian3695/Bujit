// Shared "Delete X? This cannot be undone." confirmation, like the Java app's.
import 'package:flutter/material.dart';

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

// Asks for a new category name; returns it trimmed, or null if cancelled/blank.
Future<String?> askNewCategory(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text("New Category"),
            content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: "Category name"),
            ),
            actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text("Add")),
            ],
        ),
    );
    controller.dispose();
    return (name == null || name.isEmpty) ? null : name;
}
