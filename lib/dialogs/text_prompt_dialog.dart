// A dialog asking for one or more lines of text, with validation shown under
// the last field. The dialog owns its text controllers and disposes them when
// it's gone -- disposing them as soon as showDialog returns breaks the closing
// animation, which still uses them.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'date_field.dart';

class PromptField {
    final String label;
    final String initialValue;
    final bool obscure;
    final TextInputType keyboardType;
    final List<TextInputFormatter> inputFormatters;
    final String? suffixText;

    const PromptField(
        this.label, {
        this.initialValue = "",
        this.obscure = false,
        this.keyboardType = TextInputType.text,
        this.inputFormatters = const [],
        this.suffixText,
    });
}

// Returns the entered values, or null if cancelled. [validate] returns an error
// to show, or null to accept.
Future<List<String>?> showTextPrompt(
    BuildContext context, {
    required String title,
    String? message,
    required List<PromptField> fields,
    String confirmLabel = "OK",
    String? Function(List<String> values)? validate,
}) {
    return showDialog<List<String>>(
        context: context,
        builder: (context) => _TextPromptDialog(title, message, fields, confirmLabel, validate),
    );
}

class _TextPromptDialog extends StatefulWidget {
    final String title;
    final String? message;
    final List<PromptField> fields;
    final String confirmLabel;
    final String? Function(List<String>)? validate;
    const _TextPromptDialog(this.title, this.message, this.fields, this.confirmLabel, this.validate);

    @override
    State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
    late final List<TextEditingController> _controllers = [
        for (final PromptField field in widget.fields) TextEditingController(text: field.initialValue),
    ];
    String? _error;

    @override
    void dispose() {
        for (final TextEditingController controller in _controllers) {
            controller.dispose();
        }
        super.dispose();
    }

    void _confirm() {
        final List<String> values = [for (final c in _controllers) c.text];
        final String? error = widget.validate?.call(values);
        if (error != null) {
            setState(() => _error = error);
            return;
        }
        Navigator.of(context).pop(values);
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Text(widget.title),
            content: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: formSpacing,
                    children: [
                        if (widget.message != null) Text(widget.message!),
                        for (int i = 0; i < widget.fields.length; i++)
                            TextField(
                                controller: _controllers[i],
                                autofocus: i == 0,
                                obscureText: widget.fields[i].obscure,
                                keyboardType: widget.fields[i].keyboardType,
                                inputFormatters: widget.fields[i].inputFormatters,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                    labelText: widget.fields[i].label,
                                    suffixText: widget.fields[i].suffixText,
                                    errorText: i == widget.fields.length - 1 ? _error : null,
                                ),
                                onSubmitted: i == widget.fields.length - 1 ? (_) => _confirm() : null,
                            ),
                    ],
                ),
            ),
            actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                TextButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
            ],
        );
    }
}
