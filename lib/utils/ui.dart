// Small pieces of the app's look, shared by its screens so they match the home
// screen: section labels, empty-list messages, a label over a large figure, and
// row text styles.
import 'package:flutter/material.dart';

// A small, spaced, uppercase label over a section ("MY ACCOUNTS"), like the
// home screen's column header.
class SectionLabel extends StatelessWidget {
    final String text;
    final EdgeInsetsGeometry padding;
    const SectionLabel(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 6)});

    @override
    Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
            padding: padding,
            child: Text(text.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                letterSpacing: 0.9, color: Theme.of(context).colorScheme.primary)),
        ),
    );
}

// What an empty list shows: an icon and a hint at how to add the first item.
class EmptyState extends StatelessWidget {
    final IconData icon;
    final String message;
    const EmptyState({super.key, required this.icon, required this.message});

    @override
    Widget build(BuildContext context) {
        final Color color = Theme.of(context).colorScheme.onSurfaceVariant;
        return Center(
            child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(icon, size: 48, color: color.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: color)),
                    ],
                ),
            ),
        );
    }
}

// A small grey label over a large figure, as in the home screen's balance card.
// The figure shrinks to fit rather than overflowing.
class Figure extends StatelessWidget {
    final String label;
    final String value;
    final Color? color;
    const Figure({super.key, required this.label, required this.value, this.color});

    @override
    Widget build(BuildContext context) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.7,
                    color: scheme.onSurface.withValues(alpha: 0.6))),
                const SizedBox(height: 4),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500,
                        color: color ?? scheme.onSurface)),
                ),
            ],
        );
    }
}

// Row text, as on the home screen: a medium-weight title, a quieter details line,
// and a larger trailing amount.
class RowStyles {
    static const TextStyle title = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
    static TextStyle details(BuildContext context) =>
        TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant);
    static TextStyle amount(BuildContext context, {Color? color}) => TextStyle(fontSize: 16,
        fontWeight: FontWeight.w500, color: color ?? Theme.of(context).colorScheme.onSurface);
}

// A utilization bar as on the home screen's card rows.
class UtilizationBar extends StatelessWidget {
    final double value;
    final Color color;
    const UtilizationBar({super.key, required this.value, required this.color});

    @override
    Widget build(BuildContext context) => LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        color: color,
        minHeight: 4,
        borderRadius: BorderRadius.circular(2),
    );
}
