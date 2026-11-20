// Which screens the store screenshots show, in order, with their captions, and
// the app as it's drawn for a screenshot (status bar included).
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/expense_activity/expense_activity.dart';
import 'package:bujit/navigation_items/screens.dart';
import 'package:bujit/tutorial/tutorial_manager.dart';
import 'package:bujit/utils/theme_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_screenshots_test.dart';

class Shot {
    final String name; // File name
    final String caption; // The frame's headline
    final String subtitle; // The line under it
    final TutorialScreen? screen; // Opened over the home screen; null = the home screen
    final bool dark;
    // Taps or scrolls after the screen opens (switching tabs, opening a dialog).
    final Future<void> Function(WidgetTester tester)? interact;

    const Shot(this.name, this.caption, this.subtitle, {this.screen, this.dark = false, this.interact});
}

Future<void> _tap(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
}

final List<Shot> shots = [
    const Shot("home", "Budget by paycheck", "See what's left after the bills due before your next payday"),
    const Shot("income", "Every payday, planned", "Biweekly, monthly or twice a month: your checks set the plan",
        screen: TutorialScreen.incomeStreams),
    Shot("cash-flow", "See where each check goes", "Income and spending for every pay period",
        screen: TutorialScreen.visuals),
    const Shot("credit", "Keep cards in check", "Credit utilization at a glance, card by card",
        screen: TutorialScreen.creditUtil),
    Shot("net-balance", "Watch your net worth grow", "Savings up, card debt down, all in one chart",
        screen: TutorialScreen.visuals, dark: true, interact: (tester) => _tap(tester, "Net Balance")),
    const Shot("single-events", "Log the unexpected", "One-off costs and windfalls, applied right away",
        screen: TutorialScreen.singleEvents),
    Shot("categories", "Spending by category", "Know which bills take the biggest bite",
        screen: TutorialScreen.visuals, interact: (tester) => _tap(tester, "Categories")),
];

// The app as the screenshot shows it: [shot]'s screen over the home screen,
// sized like [device], under a status bar.
class ScreenshotApp extends StatelessWidget {
    final StoreDevice device;
    final Shot shot;
    final AppState state;
    const ScreenshotApp({super.key, required this.device, required this.shot, required this.state});

    @override
    Widget build(BuildContext context) {
        final Brightness brightness = shot.dark ? Brightness.dark : Brightness.light;
        final ThemeData theme = AppTheme.build(state.accentSeed, brightness);
        return MediaQuery(
            data: MediaQueryData(
                size: device.logical,
                devicePixelRatio: device.ratio,
                padding: device.padding,
                viewPadding: device.padding,
                platformBrightness: brightness,
            ),
            child: SizedBox.fromSize(
                size: device.logical,
                child: Stack(textDirection: TextDirection.ltr, children: [
                    MaterialApp(
                        debugShowCheckedModeBanner: false,
                        theme: theme,
                        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => ExpenseActivity(state: state)),
                        onGenerateInitialRoutes: (_) => [
                            MaterialPageRoute(builder: (_) => ExpenseActivity(state: state)),
                            if (shot.screen case final TutorialScreen screen)
                                MaterialPageRoute(builder: (_) => screenFor(screen, state)),
                        ],
                    ),
                    Positioned(top: 0, left: 0, right: 0, height: device.padding.top,
                        child: _StatusBar(device: device, color: theme.colorScheme.onSurface)),
                    if (device.platform == TargetPlatform.iOS)
                        Positioned(bottom: 8, left: 0, right: 0,
                            child: Center(child: Container(width: device.isTablet ? 320 : 140, height: 5,
                                decoration: BoxDecoration(color: theme.colorScheme.onSurface,
                                    borderRadius: BorderRadius.circular(3))))),
                ]),
            ),
        );
    }
}

// The phone's status bar: the time on the left, signal, Wi-Fi and battery on the right.
class _StatusBar extends StatelessWidget {
    final StoreDevice device;
    final Color color;
    const _StatusBar({required this.device, required this.color});

    @override
    Widget build(BuildContext context) {
        final bool ios = device.platform == TargetPlatform.iOS;
        final bool island = ios && !device.isTablet;
        final double size = ios ? 17 : 14;
        return Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: island ? 34 : 28),
                child: Row(
                    children: [
                        Text("9:41", style: TextStyle(fontFamily: "Roboto", color: color,
                            fontSize: size, fontWeight: ios ? FontWeight.w600 : FontWeight.w500)),
                        const Spacer(),
                        Icon(Icons.signal_cellular_alt, size: size + 1, color: color),
                        const SizedBox(width: 4),
                        Icon(Icons.wifi, size: size + 1, color: color),
                        const SizedBox(width: 4),
                        Icon(Icons.battery_full, size: size + 2, color: color),
                    ],
                ),
            ),
        );
    }
}
