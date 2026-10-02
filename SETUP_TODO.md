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

The app reaches Plaid through the Bujit backend, a Firebase Cloud Function (Cloud
Run URL `tellerproxy-kswzrkdipq-uc.a.run.app`). Its source now lives in this repo,
under [backend/](backend/), copied from the Java repo. The backend holds the Plaid
keys (in Secret Manager) and checks each request for a Firebase ID token and an
App Check token.

**Done (Android):**
- Firebase settings are in [lib/firebase_options.dart](lib/firebase_options.dart).
- Anonymous sign-in works.
- This phone's App Check debug token is registered. Delete it when you're done
  testing debug builds, and add a new one for any other test device.
- Android release builds prove they're genuine the way the Java app did: a Play
  Integrity token exchanged at the backend. Play Console is already linked for
  this, since the Java app's Play version links banks.

### iOS bank logins (OAuth: Chase, Capital One, Wells Fargo, …)
After logging in on the bank's own site, Plaid sends iOS users to
`https://bujit-89ac6.web.app/plaid-oauth`, which opens Bujit (a universal link).
The code for this is ready; these steps aren't:
1. [ ] **Apple Team ID.** Find it in your Apple developer account under
       *Membership*. Replace `TEAMID` in
       [backend/hosting/.well-known/apple-app-site-association](backend/hosting/.well-known/apple-app-site-association)
       with it, or send it to me.
2. [ ] **Plaid dashboard → Developers → API → Allowed redirect URIs:** add
       `https://bujit-89ac6.web.app/plaid-oauth`.
3. [ ] **Deploy the backend and the hosting** (see "Deploying the backend" below).
       This also publishes the app-link file and the redirect page.
4. [ ] **Apple developer account → Identifiers → io.github.nishian3695.bujit:**
       turn on **Associated Domains** and **App Attest**. The app already asks for
       both in [ios/Runner/Runner.entitlements](ios/Runner/Runner.entitlements).
5. [ ] **Firebase console → App Check:** register the iOS app with **App Attest**
       (with DeviceCheck as the fallback, which needs a key from your Apple
       developer account).

Android needs none of this. Its link token names the app's package, as before.

### Deploying the backend
The backend's source is in [backend/](backend/), and the Java repo's copy can be
retired with it. Deploying from here sends the same `tellerProxy` function, plus
the iOS redirect change and Firebase Hosting.
1. [ ] Install the Firebase CLI once: `npm install -g firebase-tools`, then
       `firebase login`. Node 24 is already on this PC.
2. [ ] `cd backend/functions` then `npm ci`.
3. [ ] `cd ..` (into `backend/`) then `firebase deploy --only functions,hosting`.
4. [ ] Check that `https://bujit-89ac6.web.app/.well-known/apple-app-site-association`
       shows the JSON with your Team ID.

### Try it (in Sandbox)
- [ ] Linked Accounts → **Link a bank or credit card**. In Plaid's sandbox, pick
      any bank and log in with `user_good` / `pass_good`.
- [ ] Home → tap **Current Balance → From Accounts**, pick the checking account,
      then Save. The balance becomes that account's balance (plus any additional
      funds).
- [ ] Pull down on the home screen to sync right away. Otherwise it syncs on
      opening, at most every 15 minutes.

| Symptom | Usual cause |
|---|---|
| "Bujit's server refused the request (Missing App Check token)" | A debug build on a device whose App Check debug token isn't registered |
| "Failed to start bank connection" (another cause) | The backend is down, or Plaid refused the request (the log says which) |
| A bank says "connection expired" | Its login changed or access was revoked. Use **Reconnect** under the bank's name. |

### Differences from the Java app
- **Disconnecting a bank keeps** the expenses and cards that used it, with their
  last amounts, paid from the current balance. The Java app deleted them.
- **Reconnecting an expired bank keeps settings.** Which accounts count toward
  the balance, and what's paid from or synced with them, carries over to the
  reconnected accounts.
- **Linking a bank offers to add its credit cards,** asking for what the bank
  can't share: due dates, and limits the bank doesn't report.
- **Only Plaid is ported.** The Java app's Teller option isn't, since Plaid was
  the one in use.

---

## Tip jar and ratings

The tip buttons sell the Java app's one-time products: `tip_small`, `tip_medium`
and `tip_large`. Until the store returns them, the buttons show $0.99, $2.99 and
$4.99, and tapping one says "Store unavailable".
- [ ] **Google Play:** these products already exist for the Java app. Purchases
      only work in builds installed from Play (internal testing track or later).
- [ ] **App Store:** in App Store Connect, create three **Consumable** in-app
      purchases with the same product IDs, and accept the Paid Apps agreement.
- [ ] **Rate Bujit** opens the Play Store and only shows on Android. Once the app
      has an App Store listing, send me its numeric App Store ID and I'll add the
      iOS link.

---

## Releasing on Android

**Done:**
- **Signing.** Release builds are signed with the Java app's keystore, so Play
  accepts them as an update. Locally, the values come from
  `android/keystore.properties` (copied from the Java repo; never committed; see
  `android/keystore.properties.example`).
- **Version.** It's `1.0.0`, with version code 10000. The Java app's last release
  was 3016.
- **Workflows.** [.github/workflows/release.yml](.github/workflows/release.yml)
  builds, signs and uploads to Play when you push a tag like `v1.0.0`. CI analyzes
  and tests every push.
- **Database.** The layout is frozen as version 1 (see the steps in
  [app_database.dart](lib/storage_management/database/app_database.dart)), so from
  now on updates migrate data instead of needing a reinstall.
- **Data from the Java app** is imported on the first launch after updating over
  it. That covers its data, settings, counted accounts and bank logins. Google
  Tasks needs signing in again.

**For you:**
- [ ] **Repository secrets.** Add the Java repo's release secrets to the repository
      that will run the release workflow: `KEYSTORE_BASE64`, `STORE_PASSWORD`,
      `KEY_ALIAS`, `KEY_PASSWORD` and `SERVICE_ACCOUNT_JSON` (GitHub → Settings →
      Secrets and variables → Actions). The Firebase settings are committed, so
      `GOOGLE_SERVICES_JSON` and `TELLER_APP_ID` aren't needed.
- [ ] **Test the update path once** before releasing:
  1. install the Java app's Play version on a test device and use it;
  2. install the Flutter app's release build over it (the internal testing track
     does this);
  3. check that the data, settings and linked banks came across.
- [ ] Edit [play/whatsnew/whatsnew-en-US](play/whatsnew/whatsnew-en-US) (the Play
      release notes) as you like.
