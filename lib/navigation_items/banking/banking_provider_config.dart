// Mirrors NavigationItems/Banking/BankingProviderConfig.java in the original Java
// app: Firebase sign-in for the backend (an anonymous Firebase user, as in the
// Java app) and App Check (Play Integrity / App Attest in release builds, the
// debug providers in debug builds, whose tokens must be registered in Firebase).
// Plaid is the only provider here; the Java app's Teller option isn't ported.
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../config/firebase_config.dart';
import 'banking_auth_exception.dart';
import 'plaid_backend_client.dart';

class FirebaseBankingAuth implements BankingAuth {
    Future<void>? _initialized;

    @override
    bool get isConfigured => firebaseOptions() != null;

    Future<void> _ready() => _initialized ??= () async {
        final FirebaseOptions? options = firebaseOptions();
        if (options == null) throw const BankingException("Bank linking isn't set up in this build");
        await Firebase.initializeApp(options: options);
        await FirebaseAppCheck.instance.activate(
            providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
            providerApple: kDebugMode
                ? const AppleDebugProvider()
                : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
    }();

    @override
    Future<String> idToken() async {
        await _ready();
        final FirebaseAuth auth = FirebaseAuth.instance;
        final User user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
        final String? token = await user.getIdToken();
        if (token == null) throw const BankingException("Couldn't sign in to the Bujit backend");
        return token;
    }

    // Null when App Check can't produce a token (the backend decides whether that's allowed).
    @override
    Future<String?> appCheckToken() async {
        await _ready();
        try {
            return await FirebaseAppCheck.instance.getToken();
        } catch (_) {
            return null;
        }
    }
}
