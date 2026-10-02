# Setup TODO: things only you can do

These need your Google accounts or your signing keys, so they can't be done in
code. The code is ready for them. Until they're done, Settings shows Google Tasks
as **"Not set up in this build"** and everything else works.

---

## Google Tasks sync

Do this in the Google Cloud project behind the Java app's Firebase project,
**`bujit-89ac6`**. Go to <https://console.cloud.google.com>, pick the project at
the top, then open **APIs & Services** / **Google Auth Platform**. Using the same
project lets both apps share one consent screen.

### 1. Turn on the Tasks API
- [ ] **APIs & Services → Library**, search for **Google Tasks API**, then click
      **Enable**. It's probably already on for the Java app.

### 2. Consent screen
- [ ] **Google Auth Platform → Branding**: check that the app name and support
      email are filled in. The Java app probably set this up already.
- [ ] **Data access → Add or remove scopes**: make sure
      `https://www.googleapis.com/auth/tasks` is listed.
- [ ] **Audience**: while the app is in *Testing*, add every Google account
      you'll sign in with as a **test user**. Other accounts get "access blocked".
      In Testing, sign-ins expire after 7 days. When that happens, turn the
      switch off and on again.
- [ ] *(Before a public release)* The Tasks scope is "sensitive", so going to
      *Production* needs Google's verification. That means a privacy policy URL,
      a homepage, and a short demo video of the sign-in. Plan a few weeks for it.

### 3. Android client (one per signing key)
**Clients → Create client → Android**:
- Package name: `io.github.nishian3695.bujit`
- SHA-1 certificate fingerprint. Create one client for each of these:
  - [ ] **Debug key on this PC** (for running from Android Studio):
        `8B:7B:8B:EC:90:7A:59:41:BF:1F:5D:91:04:ED:44:37:4E:9B:46:F5`
        To check it again, run:
        `"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android`
  - [ ] **Your release key**, the same keystore the Java app uses:
        `keytool -list -v -keystore <path to your .jks> -alias <your alias>`
  - [ ] **Google Play's app signing key**, if Play signs your app. Find it in
        Play Console → *Test and release → App integrity → App signing key
        certificate*.

If the Java app already has an Android client for one of these, Google says the
client exists. That one is already done.

### 4. Web client (Android needs it)
- [ ] **Clients → Create client → Web application**. Name it something like
      "Bujit (Android sign-in)". Leave the redirect URIs empty.
- [ ] Copy its **Client ID** (`….apps.googleusercontent.com`) into
      `webClientId` in [lib/config/google_config.dart](lib/config/google_config.dart).

  Use the *Web* client's ID here, not the Android one. Android sign-in fails with
  the Android ID.

### 5. iOS client
- [ ] **Clients → Create client → iOS**, with bundle ID `io.github.nishian3695.bujit`.
- [ ] Copy its **Client ID** into `iosClientId` in
      [lib/config/google_config.dart](lib/config/google_config.dart).
- [ ] Copy its **iOS URL scheme** (`com.googleusercontent.apps.…`, shown on the
      client's page) into [ios/Runner/Info.plist](ios/Runner/Info.plist). Paste this
      just before the last `</dict>`:
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
      <dict>
          <key>CFBundleTypeRole</key>
          <string>Editor</string>
          <key>CFBundleURLSchemes</key>
          <array>
              <string>com.googleusercontent.apps.REPLACE_WITH_YOUR_SCHEME</string>
          </array>
      </dict>
  </array>
  ```
  The deployment target is iOS 15 (Firebase needs it; this plugin needs 13). iOS
  builds need a Mac with Xcode.

### 6. Try it
- [ ] Run the app and go to **Settings → Sync to Google Tasks**. You should see:
  1. the account picker, then
  2. Google's permission screen, then
  3. "Connected as you@gmail.com" and a line like "5 added, 0 updated, 0 removed".
- [ ] Open <https://tasks.google.com>. The **Bujit** list should have:
  - one task per expense and card, due on its next date;
  - one "Paycheck: …" task per income stream.
- [ ] Edit an expense in the app. Its task should update within a few seconds.

### Before turning it on: the Java app
The Flutter app reuses an existing **Bujit** list, but it doesn't know which
tasks the Java app made. With both apps syncing, every item would show up twice.
- [ ] In the **Java** app, go to Settings, disconnect Google sync, then go back
      to the home screen (that's when it deletes its tasks). Then turn sync on
      in the Flutter app.

### If it goes wrong
| Symptom | Usual cause |
|---|---|
| Android: "Developer console is not set up correctly" or "[16]/[10]" errors | SHA-1 or package name doesn't match a client (step 3), or `webClientId` isn't the Web client's ID (step 4) |
| "Access blocked: … has not completed the Google verification process" | That account isn't a test user (step 2) |
| iOS crashes when sign-in starts | The URL scheme is missing from `Info.plist` (step 5) |
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

## Release signing for Android (not done yet)
Release builds of the Flutter app are still signed with the debug key. To ship as
an update to the Java app on Play, and for Google sign-in and App Check to
recognize release builds, they must use your existing release key. I can port the
Java app's `keystore.properties` setup. You'd then copy your `keystore.properties`
into `android/`, where it stays out of git.
