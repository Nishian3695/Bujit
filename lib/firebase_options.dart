// Firebase settings for project bujit-89ac6, as `flutterfire configure` would
// write them: Android from the Java app's google-services.json (the same Firebase
// app), iOS from the iOS app's GoogleService-Info.plist. These identify the app
// to Firebase; they aren't secrets (the backend is protected by Firebase Auth and
// App Check).
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
    // The options for this platform, or null where Bujit has no Firebase app.
    static FirebaseOptions? get currentPlatform => switch (defaultTargetPlatform) {
        TargetPlatform.android => android,
        TargetPlatform.iOS => ios,
        _ => null,
    };

    static const FirebaseOptions android = FirebaseOptions(
        apiKey: "AIzaSyCcKaELxh5BUDh2BlBoSwJMfx4TEOEkLVE",
        appId: "1:533939418471:android:e39cb96592f09e1c036bc2",
        messagingSenderId: "533939418471",
        projectId: "bujit-89ac6",
        storageBucket: "bujit-89ac6.firebasestorage.app",
    );

    static const FirebaseOptions ios = FirebaseOptions(
        apiKey: "AIzaSyClKZUDEzMdXTVkR1qi8PdLmt98oQzecl0",
        appId: "1:533939418471:ios:cf013bbafca7b87d036bc2",
        messagingSenderId: "533939418471",
        projectId: "bujit-89ac6",
        storageBucket: "bujit-89ac6.firebasestorage.app",
        iosClientId: "533939418471-hcd1blgas2f6il4qjb6ok84stjq3dcpr.apps.googleusercontent.com",
        iosBundleId: "io.github.nishian3695.bujit",
    );
}
