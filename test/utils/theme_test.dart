// Settings > Appearance (theme mode, accent presets, the custom color dialog,
// importing the Java app's theme settings) and the readable dates.
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/settings/settings_activity.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/storage_management/java_migration.dart';
import 'package:bujit/utils/custom_views/color_wheel_view.dart';
import 'package:bujit/utils/date_utils.dart';
import 'package:bujit/utils/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppState _state() => AppState(AppData(balance: BalanceModel(currentBalance: 0.0), tutorialSeen: true));

void main() {
    test("hex colors", () {
        expect(parseHexColor("#2979FF"), 0xFF2979FF);
        expect(parseHexColor("7b1fa2"), 0xFF7B1FA2);
        expect(parseHexColor("#12345"), isNull);
        expect(parseHexColor("#GGGGGG"), isNull);
        expect(parseHexColor(null), isNull);
        expect(hexOf(0xFF00695C), "#00695C");
    });

    test("short dates leave out this year", () {
        final DateTime today = DateTime(2026, 10, 2);
        expect(shortDate(DateTime(2026, 10, 4), today: today), "Oct 4");
        expect(shortDate(DateTime(2026, 1, 31), today: today), "Jan 31");
        expect(shortDate(DateTime(2027, 3, 1), today: today), "Mar 1, 2027");
    });

    test("defaults: the system's mode and the blue accent", () {
        final AppState state = _state();
        expect(state.themeMode, ThemeMode.system);
        expect(state.accent, AccentColor.blue);
        expect(state.accentSeed, const Color(0xFF2979FF));
    });

    test("the theme carries Bujit's colors for light and dark", () {
        expect(AppTheme.build(AccentColor.teal.color, Brightness.dark).extension<BujitColors>(), BujitColors.dark);
        final BujitColors light = AppTheme.build(AccentColor.teal.color, Brightness.light).extension<BujitColors>()!;
        expect(light.forAmount(-1), light.negative);
        expect(light.forAmount(0), light.positive);
        expect(light.forUtilization(0.1), light.good);
        expect(light.forUtilization(0.5), light.moderate);
        expect(light.forUtilization(0.9), light.high);
    });

    testWidgets("Settings changes the mode and the accent", (tester) async {
        final AppState state = _state();
        await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: state)));

        await tester.tap(find.text("Dark"));
        await tester.pump();
        expect(state.themeMode, ThemeMode.dark);

        await tester.tap(find.byTooltip("Teal"));
        await tester.pump();
        expect(state.accent, AccentColor.teal);
        expect(state.accentSeed, AccentColor.teal.color);
    });

    testWidgets("a custom color from the dialog's hex field", (tester) async {
        final AppState state = _state();
        await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: state)));

        await tester.tap(find.byTooltip("Custom"));
        await tester.pumpAndSettle();
        expect(find.text("Custom Accent Color"), findsOneWidget);
        expect(find.byType(ColorWheelView), findsOneWidget);

        await tester.enterText(find.byType(TextField), "#FF8800");
        await tester.tap(find.text("Apply"));
        await tester.pumpAndSettle();
        expect(state.accent, AccentColor.custom);
        expect(state.data.customAccent, 0xFFFF8800);
        expect(state.accentSeed, const Color(0xFFFF8800));
    });

    testWidgets("dragging on the wheel picks a hue; Cancel keeps the old color", (tester) async {
        final AppState state = _state();
        await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: state)));
        await tester.tap(find.byTooltip("Custom"));
        await tester.pumpAndSettle();

        final String before = tester.widget<TextField>(find.byType(TextField)).controller!.text;
        final Rect wheel = tester.getRect(find.byType(ColorWheelView));
        await tester.tapAt(Offset(wheel.left + 20, wheel.top + wheel.width / 2)); // the left edge: cyan
        await tester.pump();
        expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isNot(before));

        await tester.tap(find.text("Cancel"));
        await tester.pumpAndSettle();
        expect(state.accent, AccentColor.blue);
        expect(state.data.customAccent, 0xFF2979FF);
    });

    test("the Java app's theme settings are imported", () {
        final AppData data = JavaMigration.fromJava({
            "data": '{"expenseList": []}',
            "prefs": {"nightMode": "dark", "accentColor": "custom", "customHex": "#123456"},
        })!;
        expect(data.themeMode, "dark");
        expect(data.accentColor, "custom");
        expect(data.customAccent, 0xFF123456);

        final AppData unknown = JavaMigration.fromJava({
            "data": '{"expenseList": []}',
            "prefs": {"nightMode": "sepia", "accentColor": "plaid", "customHex": "nope"},
        })!;
        expect(unknown.themeMode, "system");
        expect(unknown.accentColor, "blue");
        expect(unknown.customAccent, 0xFF2979FF);
    });
}
