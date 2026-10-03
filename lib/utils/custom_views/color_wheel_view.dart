// Mirrors ColorWheelView.java in the original Java app: an HSV color wheel (hue
// around it, saturation outward from the white center) with a brightness strip
// below it, and the "Custom Accent Color" dialog that uses it (Settings).
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme_helper.dart';

class ColorWheelView extends StatelessWidget {
    final HSVColor color;
    final ValueChanged<HSVColor> onChanged;
    // The wheel's diameter. Fixed rather than measured: dialogs size their content
    // by its intrinsic width, which a LayoutBuilder can't report.
    final double size;
    const ColorWheelView({super.key, required this.color, required this.onChanged, this.size = 220});

    static const double _stripHeight = 28;
    static const double _gap = 20;

    @override
    Widget build(BuildContext context) {
        final Size area = Size(size, size + _gap + _stripHeight);
        void pick(Offset p) {
            if (p.dy <= size + _gap / 2) {
                final Offset fromCenter = p - Offset(size / 2, size / 2);
                final double hue = (math.atan2(fromCenter.dy, fromCenter.dx) * 180 / math.pi + 360) % 360;
                final double saturation = (fromCenter.distance / (size / 2)).clamp(0.0, 1.0);
                onChanged(color.withHue(hue).withSaturation(saturation));
            } else {
                onChanged(color.withValue((p.dx / size).clamp(0.0, 1.0)));
            }
        }

        return SizedBox.fromSize(
            size: area,
            child: GestureDetector(
                onPanDown: (d) => pick(d.localPosition),
                onPanUpdate: (d) => pick(d.localPosition),
                child: CustomPaint(painter: _WheelPainter(color, size, outline: Theme.of(context).colorScheme.outline)),
            ),
        );
    }
}

class _WheelPainter extends CustomPainter {
    final HSVColor color;
    final double size;
    final Color outline;
    _WheelPainter(this.color, this.size, {required this.outline});

    @override
    void paint(Canvas canvas, Size _) {
        final Offset center = Offset(size / 2, size / 2);
        final double radius = size / 2;
        final Rect wheel = Rect.fromCircle(center: center, radius: radius);
        // Hues around, fading to white at the center, darkened to the chosen brightness.
        canvas.drawCircle(center, radius, Paint()
            ..shader = SweepGradient(colors: [
                for (int h = 0; h <= 360; h += 60) HSVColor.fromAHSV(1, h % 360, 1, 1).toColor(),
            ]).createShader(wheel));
        canvas.drawCircle(center, radius, Paint()
            ..shader = const RadialGradient(colors: [Colors.white, Color(0x00FFFFFF)]).createShader(wheel));
        if (color.value < 1) {
            canvas.drawCircle(center, radius, Paint()..color = Colors.black.withValues(alpha: 1 - color.value));
        }
        final double angle = color.hue * math.pi / 180;
        final Offset marker = center + Offset(math.cos(angle), math.sin(angle)) * color.saturation * radius;
        _marker(canvas, marker);

        // The brightness strip: black to the full-brightness color.
        final Rect strip = Rect.fromLTWH(0, size + ColorWheelView._gap, size, ColorWheelView._stripHeight);
        final RRect rounded = RRect.fromRectAndRadius(strip, const Radius.circular(8));
        canvas.drawRRect(rounded, Paint()
            ..shader = LinearGradient(colors: [Colors.black, color.withValue(1).toColor()]).createShader(strip));
        canvas.drawRRect(rounded, Paint()
            ..style = PaintingStyle.stroke
            ..color = outline);
        _marker(canvas, Offset(color.value * size, strip.center.dy));
    }

    void _marker(Canvas canvas, Offset at) {
        canvas.drawCircle(at, 9, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..color = Colors.black54);
        canvas.drawCircle(at, 9, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.white);
    }

    @override
    bool shouldRepaint(_WheelPainter old) => old.color != color || old.size != size || old.outline != outline;
}

// Java's showColorPickerDialog: the wheel, a preview and a hex field. Returns the
// chosen color (ARGB), or null if cancelled.
Future<int?> showCustomColorDialog(BuildContext context, int initial) =>
    showDialog<int>(context: context, builder: (_) => _CustomColorDialog(initial));

class _CustomColorDialog extends StatefulWidget {
    final int initial;
    const _CustomColorDialog(this.initial);

    @override
    State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
    late HSVColor _color = HSVColor.fromColor(Color(widget.initial));
    late final TextEditingController _hex = TextEditingController(text: hexOf(widget.initial));

    int get _argb => _color.toColor().toARGB32();

    @override
    void dispose() {
        _hex.dispose();
        super.dispose();
    }

    void _picked(HSVColor color) {
        setState(() => _color = color);
        _hex.text = hexOf(_argb);
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text("Custom Accent Color"),
            content: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ColorWheelView(color: _color, onChanged: _picked),
                        const SizedBox(height: 16),
                        Row(children: [
                            CircleAvatar(radius: 20, backgroundColor: _color.toColor()),
                            const SizedBox(width: 16),
                            Expanded(
                                child: TextField(
                                    controller: _hex,
                                    decoration: const InputDecoration(labelText: "Hex", isDense: true),
                                    inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r"[#0-9a-fA-F]")),
                                        LengthLimitingTextInputFormatter(7),
                                    ],
                                    onChanged: (text) {
                                        final int? argb = parseHexColor(text);
                                        if (argb != null) setState(() => _color = HSVColor.fromColor(Color(argb)));
                                    },
                                ),
                            ),
                        ]),
                    ],
                ),
            ),
            actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.of(context).pop(_argb), child: const Text("Apply")),
            ],
        );
    }
}
