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

    @override
    Widget build(BuildContext context) {
        ListTile item(IconData icon, String title, Widget screen) => ListTile(
            leading: Icon(icon),
            title: Text(title),
            onTap: () => _open(context, screen),
        );

        return Drawer(
            child: ListView(
                children: [
                    const DrawerHeader(child: Text("Bujit")),
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
