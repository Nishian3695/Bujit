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
  The deployment target is already iOS 13, which the plugin requires. iOS builds
  need a Mac with Xcode.

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

## Coming later (needs you as well)

- **Release signing for Android.** Release builds of the Flutter app are still
  signed with the debug key. To ship as an update to the Java app on Play, they
  must use the same key. I can port the Java app's `keystore.properties` setup;
  you'd copy your `keystore.properties` into `android/` (it stays out of git).
- **Linked Accounts / Plaid.** This needs the Flutter app registered in Firebase
  (`flutterfire configure`), App Check, and your Cloud Run backend. A checklist
  will go here when that work starts.
