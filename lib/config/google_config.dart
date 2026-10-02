// OAuth client IDs for Google sign-in (Google Tasks sync). See SETUP_TODO.md.
//
// Paste each ID between the quotes, or pass it at build time with
// --dart-define=BUJIT_GOOGLE_WEB_CLIENT_ID=... (a --dart-define wins over the
// pasted value). Client IDs identify the app to Google; they aren't secrets.
// Until they're set, Settings shows Google Tasks as not set up.
import 'package:flutter/foundation.dart';

class GoogleConfig {
    // "Web application" client. Android sign-in needs it (as serverClientId).
    static const String webClientId = String.fromEnvironment(
        "BUJIT_GOOGLE_WEB_CLIENT_ID",
        defaultValue: "", // TODO(you): paste the Web client ID (…apps.googleusercontent.com)
    );

    // "iOS" client for bundle ID io.github.nishian3695.bujit. Its reversed form
    // also goes in ios/Runner/Info.plist (see SETUP_TODO.md).
    static const String iosClientId = String.fromEnvironment(
        "BUJIT_GOOGLE_IOS_CLIENT_ID",
        defaultValue: "", // TODO(you): paste the iOS client ID
    );

    static bool get isIos => defaultTargetPlatform == TargetPlatform.iOS;

    // Whether this build can sign in to Google on this platform.
    static bool get isConfigured => isIos ? iosClientId.isNotEmpty : webClientId.isNotEmpty;
}
