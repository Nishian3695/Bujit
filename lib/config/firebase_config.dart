// Firebase settings for Linked Accounts (the Bujit backend checks Firebase ID and
// App Check tokens). See SETUP_TODO.md. Until this returns options, Linked
// Accounts shows bank linking as not set up; manual accounts work regardless.
import 'package:firebase_core/firebase_core.dart';

// TODO(you): run `flutterfire configure` (it writes lib/firebase_options.dart), then
// import that file here and return DefaultFirebaseOptions.currentPlatform.
FirebaseOptions? firebaseOptions() => null;

// The Bujit backend on Cloud Run (the Java app's BankingProviderConfig.BACKEND_HOST).
const String bankingBackendHost = "tellerproxy-kswzrkdipq-uc.a.run.app";
