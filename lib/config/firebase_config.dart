// Firebase settings for Linked Accounts (the Bujit backend checks Firebase ID and
// App Check tokens). On a platform without options, Linked Accounts shows bank
// linking as not set up; manual accounts work regardless.
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

FirebaseOptions? firebaseOptions() => DefaultFirebaseOptions.currentPlatform;

// The Bujit backend on Cloud Run (the Java app's BankingProviderConfig.BACKEND_HOST).
const String bankingBackendHost = "tellerproxy-kswzrkdipq-uc.a.run.app";
