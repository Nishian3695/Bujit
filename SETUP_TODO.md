# Setup TODO: things only you can do

These need your Google accounts or your signing keys, so they can't be done in
code. The code is ready for them; each feature stays off until its part is done,
and everything else works.

---

## Google Tasks sync

**Done:** in project `bujit-89ac6`, the Tasks API is on, the consent
screen has your test users, there are Android clients for each signing key, and
the Web and iOS client IDs are in [lib/config/google_config.dart](lib/config/google_config.dart).
The Java app's old OAuth clients were gone, which is why its Tasks sync stopped
working. The new Play-signing client fixes it there too.

### 1. Try it on Android
- [ ] Run the app and go to **Settings → Sync to Google Tasks**. You should see:
  1. the account picker, then
  2. Google's permission screen, then
  3. "Connected as you@gmail.com" and a line like "5 added, 0 updated, 0 removed".
- [ ] Open <https://tasks.google.com>. The **Bujit** list should have:
  - one task per expense and card, due on its next date;
  - one "Paycheck: …" task per income stream.
- [ ] Edit an expense in the app. Its task should update within a few seconds.

Avoid syncing the Java app and this app to the same Google account at the same
time: every item would show up twice in the Bujit list.

### 2. iOS
The iOS client's ID and URL scheme are in place (`iosClientId` in
[lib/config/google_config.dart](lib/config/google_config.dart), and `CFBundleURLTypes`
in [ios/Runner/Info.plist](ios/Runner/Info.plist)).
- [ ] Try it once you can build on a Mac with Xcode (same steps as Android).

### 3. Before a public release
- [ ] The Tasks permission is "sensitive". While the consent screen is in
      *Testing*, only test users can sign in, and their sign-ins expire after 7
      days. Going to *Production* needs Google's verification: a privacy policy
      URL, a homepage, and a short demo video of the sign-in. Plan a few weeks.
- [ ] **Keep clients in use.** Google deletes OAuth clients that go unused for
      about six months (the likely reason the Java app's clients disappeared).

### If it goes wrong
| Symptom | Usual cause |
|---|---|
| Android: "Developer console is not set up correctly" or "[16]/[10]" errors | The build's signing key has no Android client, or `webClientId` isn't the Web client's ID |
| "Access blocked: … has not completed the Google verification process" | That account isn't a test user (Google Auth Platform → Audience) |
| iOS crashes when sign-in starts | The URL scheme is missing from `Info.plist` |
| "Google Tasks needs permission again" in Settings | The sign-in expired (7 days in Testing) or access was removed from the Google account. Turn the switch off and on. |
| The switch flips back with no message | The sign-in was cancelled |

---

## Linked Accounts (Plaid)

The app talks to Plaid the same way the Java app did: through your Cloud Run
backend (`tellerproxy-kswzrkdipq-uc.a.run.app`, set in
[lib/config/firebase_config.dart](lib/config/firebase_config.dart)). The backend
holds the Plaid keys and checks each request for two things:
- a **Firebase ID token** (the app signs in anonymously);
- a **Firebase App Check** token.

So the Flutter app needs to be set up in the same Firebase project, **`bujit-89ac6`**.
Until then, Linked Accounts shows "Not set up in this build", and manual accounts
work as usual.

### 1. Connect the app to Firebase
- [ ] Install the FlutterFire command-line tool, if you haven't:
      `dart pub global activate flutterfire_cli` (needs the
      [Firebase CLI](https://firebase.google.com/docs/cli) and `firebase login`).
- [ ] In the project folder, run `flutterfire configure --project=bujit-89ac6`.
  - Choose **android** and **ios**.
  - For Android, pick the existing app `io.github.nishian3695.bujit`. The Java app
    already registered it, and the Flutter app uses the same package name.
  - For iOS, let it create the app (bundle ID `io.github.nishian3695.bujit`).

  This writes `lib/firebase_options.dart`. It may also add `google-services.json`
  and a Gradle plugin; both are fine.
- [ ] In [lib/config/firebase_config.dart](lib/config/firebase_config.dart):
  1. add `import '../firebase_options.dart';`;
  2. change the function to
     `FirebaseOptions? firebaseOptions() => DefaultFirebaseOptions.currentPlatform;`.
- [ ] Choose whether to commit `lib/firebase_options.dart`. Its keys identify the
      app and aren't secret, but the Java repo kept `google-services.json` out of
      git. If you add it to `.gitignore`, each machine has to run
      `flutterfire configure`.
- [ ] Firebase console → **Authentication → Sign-in method**: make sure
      **Anonymous** is enabled (the Java app uses it too).

### 2. App Check
- [ ] **Debug builds** use the App Check *debug provider*. On the first bank
      request, the debug console prints a line like "Enter this debug secret into
      the allow list…".
  - Android: look in Logcat. iOS: look in the Xcode console.
  - Add that token in Firebase console → **App Check → Apps → ⋮ → Manage debug
    tokens**. Each device or emulator has its own token.
- [ ] **Android release builds** use Play Integrity, like the Java app.
  - In App Check, the Android app must list the **SHA-256** of the signing key
    (Play's app signing key, if Play signs the app).
  - This only works once release builds use your real key (see "Release signing"
    below).
- [ ] **iOS release builds** use App Attest, falling back to DeviceCheck.
  - In Xcode: **Runner → Signing & Capabilities → + Capability → App Attest**.
  - Register the iOS app under App Check with App Attest and DeviceCheck. DeviceCheck
    needs a key from your Apple developer account.

### 3. Backend and Plaid
- [ ] Check that the Cloud Run backend is still deployed and that its Plaid keys
      point at the environment you want (Sandbox for testing, Production for real
      banks).
- [ ] Android needs nothing new. The backend's link token names the package
      `io.github.nishian3695.bujit`, the same as the Java app, and the Plaid
      dashboard already allows it.
- [ ] **iOS banks that log in on their own site (OAuth: Chase, Capital One, Wells
      Fargo, …) need a redirect URI:**
  - the backend must send `redirect_uri` when creating link tokens for iOS;
  - the URI must be registered in the Plaid dashboard (*Developers → API → Allowed
    redirect URIs*);
  - it must be a universal link to a domain you control, with Associated Domains
    set up in Xcode.

  Without it, those banks can't be linked on iOS; other banks still work. This
  needs a backend change, so tell me when you're ready.

### 4. Try it (in Sandbox)
- [ ] Linked Accounts → **Link a bank or credit card**. In Plaid's sandbox, pick
      any bank and log in with `user_good` / `pass_good`. Its accounts show up
      under the bank's name.
- [ ] Home → tap **Current Balance → From Accounts**, pick the checking account,
      then Save. The balance becomes that account's balance (plus any additional
      funds).
- [ ] Pull down on the home screen. It syncs right away. Otherwise it syncs on
      opening, at most every 15 minutes.
- [ ] Add a credit card or expense with **From connected account**. Its amount
      (and a card's limit) follows the bank's.

| Symptom | Usual cause |
|---|---|
| "Failed to start bank connection" | Firebase isn't set up (step 1), App Check rejected the request (step 2, often a missing debug token), or the backend is down |
| A bank says "connection expired" | Its login changed or access was revoked. Use **Reconnect** under the bank's name. |

### Differences from the Java app
- **Disconnecting a bank keeps** the expenses and cards that used it, with their
  last amounts, paid from the current balance. The Java app deleted them.
- **Reconnecting an expired bank keeps settings.** Which accounts count toward
  the balance, and what's paid from or synced with them, carries over to the
  reconnected accounts.
- **Only Plaid is ported.** The Java app's Teller option isn't, since Plaid was
  the one in use.

---

## Tip jar and ratings

The tip buttons sell the Java app's one-time products: `tip_small`, `tip_medium`
and `tip_large`. Until the store returns them, the buttons show $0.99, $2.99 and
$4.99, and tapping one says "Store unavailable".
- [ ] **Google Play:** these products already exist for the Java app. Purchases
      only work in builds installed from Play (internal testing track or later)
      and signed with your release key (see below).
- [ ] **App Store:** in App Store Connect, create three **Consumable** in-app
      purchases with the same product IDs, and accept the Paid Apps agreement.
- [ ] **Rate Bujit** opens the Play Store and only shows on Android. Once the app
      has an App Store listing, send me its numeric App Store ID and I'll add the
      iOS link.

---

## Release signing for Android (not done yet)
Release builds of the Flutter app are still signed with the debug key. To ship as
an update to the Java app on Play, and for Google sign-in and App Check to
recognize release builds, they must use your existing release key. I can port the
Java app's `keystore.properties` setup. You'd then copy your `keystore.properties`
into `android/`, where it stays out of git.
