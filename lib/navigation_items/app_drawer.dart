// The home screen's navigation drawer (burger menu), with the Java app's items
// (res/menu/navigation_menu.xml) in the same order.
import 'package:flutter/material.dart';
import '../app_state.dart';
import 'credit_util/credit_util_activity.dart';
import 'income_streams/income_streams_activity.dart';
import 'not_built_yet.dart';
import 'settings/settings_activity.dart';
import 'single_events/single_events_activity.dart';
import 'visuals/visuals_activity.dart';

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
                    item(Icons.payments, "Income Streams", IncomeStreamsActivity(state: state)),
                    item(Icons.credit_card, "Credit Utilization", CreditUtilActivity(state: state)),
                    item(Icons.account_balance, "Linked Accounts", const NotBuiltYet(title: "Linked Accounts")),
                    item(Icons.event, "Single Events", SingleEventsActivity(state: state)),
                    item(Icons.bar_chart, "Visuals", VisualsActivity(state: state)),
                    const Divider(),
                    item(Icons.settings, "Settings", SettingsActivity(state: state)),
                ],
            ),
        );
    }
}
