// The home screen's navigation drawer (burger menu), with the Java app's items
// (res/menu/navigation_menu.xml) in the same order.
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../tutorial/tutorial_manager.dart';
import 'screens.dart';

class AppDrawer extends StatelessWidget {
    final AppState state;
    // Called after a screen opened from the drawer closes, so the home screen
    // can recompute with whatever changed there.
    final VoidCallback onReturn;

    const AppDrawer({super.key, required this.state, required this.onReturn});

    Future<void> _open(BuildContext context, Widget screen) async {
        final NavigatorState navigator = Navigator.of(context);
        navigator.pop(); // close the drawer
        await navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
        onReturn();
    }

    // The app's name and tagline on the accent color, like the home screen's check bar.
    Widget _header(BuildContext context) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        return DrawerHeader(
            decoration: BoxDecoration(color: scheme.primary),
            child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text("Bujit", style: TextStyle(color: scheme.onPrimary, fontSize: 28, fontWeight: FontWeight.w600)),
                        Text("Budget by paycheck",
                            style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8), fontSize: 14)),
                    ],
                ),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        ListTile item(IconData icon, String title, Widget screen) => ListTile(
            leading: Icon(icon),
            title: Text(title),
            onTap: () => _open(context, screen),
        );

        return Drawer(
            child: ListView(
                padding: EdgeInsets.zero, // the header runs up under the status bar
                children: [
                    _header(context),
                    item(Icons.payments, "Income Streams", screenFor(TutorialScreen.incomeStreams, state)),
                    item(Icons.credit_card, "Credit Utilization", screenFor(TutorialScreen.creditUtil, state)),
                    item(Icons.account_balance, "Linked Accounts", screenFor(TutorialScreen.linkedAccounts, state)),
                    item(Icons.event, "Single Events", screenFor(TutorialScreen.singleEvents, state)),
                    item(Icons.bar_chart, "Visuals", screenFor(TutorialScreen.visuals, state)),
                    const Divider(),
                    item(Icons.settings, "Settings", screenFor(TutorialScreen.settings, state)),
                ],
            ),
        );
    }
}
