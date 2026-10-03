// Mirrors ThemeHelper.java in the original Java app: the accent color (a preset
// or a custom one) and light/dark mode (or following the system). The look is
// Material 3, generated from the accent, with Bujit's own colors for money going
// up or down and utilization levels (BujitColors), in light and dark variants.
import 'package:flutter/material.dart';

// The Java app's accent presets ("blue" is the default).
enum AccentColor {
    blue("Blue", Color(0xFF2979FF)),
    purple("Purple", Color(0xFF7B1FA2)),
    green("Green", Color(0xFF2E7D32)),
    orange("Orange", Color(0xFFE65100)),
    teal("Teal", Color(0xFF00695C)),
    rose("Rose", Color(0xFFC62828)),
    custom("Custom", Color(0xFF2979FF));

    const AccentColor(this.label, this.color);
    final String label;
    final Color color;

    static AccentColor byName(String? name) =>
        AccentColor.values.firstWhere((a) => a.name == name, orElse: () => AccentColor.blue);
}

// "system", "light" or "dark", as the Java app stored it.
ThemeMode themeModeFromName(String? name) => switch (name) {
    "light" => ThemeMode.light,
    "dark" => ThemeMode.dark,
    _ => ThemeMode.system,
};

// "#RRGGBB" (the "#" is optional) as an opaque ARGB color, or null if it isn't one.
int? parseHexColor(String? hex) {
    final String digits = (hex ?? "").trim().replaceFirst("#", "");
    if (!RegExp(r"^[0-9a-fA-F]{6}$").hasMatch(digits)) return null;
    return 0xFF000000 | int.parse(digits, radix: 16);
}

// An ARGB color as "#RRGGBB".
String hexOf(int argb) => "#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, "0").toUpperCase()}";

// Colors with a meaning, beyond the accent: a positive or negative balance, and
// the utilization levels (under 30%, under 70%, 70% and up).
@immutable
class BujitColors extends ThemeExtension<BujitColors> {
    final Color positive;
    final Color negative;
    final Color good;
    final Color moderate;
    final Color high;

    const BujitColors({
        required this.positive,
        required this.negative,
        required this.good,
        required this.moderate,
        required this.high,
    });

    // The Java app's balance_positive/balance_negative/util_warning, and lighter
    // versions that stay readable on dark backgrounds.
    static const BujitColors light = BujitColors(
        positive: Color(0xFF2E7D32),
        negative: Color(0xFFC62828),
        good: Color(0xFF2E7D32),
        moderate: Color(0xFFF57C00),
        high: Color(0xFFC62828),
    );
    static const BujitColors dark = BujitColors(
        positive: Color(0xFF81C784),
        negative: Color(0xFFEF9A9A),
        good: Color(0xFF81C784),
        moderate: Color(0xFFFFB74D),
        high: Color(0xFFEF9A9A),
    );

    static BujitColors of(BuildContext context) =>
        Theme.of(context).extension<BujitColors>() ?? BujitColors.light;

    Color forAmount(double amount) => amount < 0 ? negative : positive;

    Color forUtilization(double utilization) {
        if (utilization < 0.30) return good;
        if (utilization < 0.70) return moderate;
        return high;
    }

    @override
    BujitColors copyWith({Color? positive, Color? negative, Color? good, Color? moderate, Color? high}) =>
        BujitColors(
            positive: positive ?? this.positive,
            negative: negative ?? this.negative,
            good: good ?? this.good,
            moderate: moderate ?? this.moderate,
            high: high ?? this.high,
        );

    @override
    BujitColors lerp(BujitColors? other, double t) {
        if (other == null) return this;
        return BujitColors(
            positive: Color.lerp(positive, other.positive, t)!,
            negative: Color.lerp(negative, other.negative, t)!,
            good: Color.lerp(good, other.good, t)!,
            moderate: Color.lerp(moderate, other.moderate, t)!,
            high: Color.lerp(high, other.high, t)!,
        );
    }
}

class AppTheme {
    // The app's theme for an accent [seed] in light or dark.
    static ThemeData build(Color seed, Brightness brightness) {
        final ColorScheme scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
        final bool dark = brightness == Brightness.dark;
        return ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            extensions: [dark ? BujitColors.dark : BujitColors.light],
            appBarTheme: AppBarTheme(
                backgroundColor: scheme.surface,
                foregroundColor: scheme.onSurface,
                centerTitle: false,
                scrolledUnderElevation: 2,
            ),
            cardTheme: CardThemeData(
                elevation: 0,
                color: scheme.surfaceContainerLow,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
            dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
            ),
            inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
            snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        );
    }

    // The accent in use: a preset, or the custom color.
    static Color seedFor(AccentColor accent, int customColor) =>
        accent == AccentColor.custom ? Color(customColor) : accent.color;
}
