// Builds each navigable screen, so the drawer and the tutorial open them the same way.
import 'package:flutter/widgets.dart';
import '../app_state.dart';
import '../tutorial/tutorial_manager.dart';
import 'banking/banking_activity.dart';
import 'credit_util/credit_util_activity.dart';
import 'income_streams/income_streams_activity.dart';
import 'settings/settings_activity.dart';
import 'single_events/single_events_activity.dart';
import 'visuals/visuals_activity.dart';

// The screen for a tutorial stop. The home screen is the app's root, so it's never built here.
Widget screenFor(TutorialScreen screen, AppState state) => switch (screen) {
    TutorialScreen.incomeStreams => IncomeStreamsActivity(state: state),
    TutorialScreen.creditUtil => CreditUtilActivity(state: state),
    TutorialScreen.linkedAccounts => BankingActivity(state: state),
    TutorialScreen.singleEvents => SingleEventsActivity(state: state),
    TutorialScreen.visuals => VisualsActivity(state: state),
    TutorialScreen.settings => SettingsActivity(state: state),
    TutorialScreen.home => throw ArgumentError("The home screen is the app's root"),
};
