# Setup TODO: things only you can do

These need your accounts (Google, Apple, Plaid, Play) or your keys, so they can't
be done in code. The code is ready for each; a feature stays off until its part is
done, and everything else works. Last reviewed October 3, 2026 (release 0.5.4).

## At a glance

| Area | Android | iPhone |
|---|---|---|
| The app itself | **Live** for internal and closed testers (0.5.4) | Builds and runs in the simulator ([previews](#previewing-on-ios-without-a-mac)); not released |
| Google Tasks sync | Works for test users; [verification](#google-tasks) pending | Same |
| Apple Reminders sync | n/a | **Ready**; try it in Appetize |
| Bank linking (Plaid) | **Works** in release builds | Needs the [Apple setup](#iphone-bank-logins) |
| Tips | **Works** (Play products exist) | Needs App Store products |
| Rating | "Rate Bujit" in Settings opens the store page | "Rate Bujit" is greyed out until there's an App Store ID |

---

## Android and Google Play

**Done:**
- **Repository.** Code goes only to `Nishian3695/Bujit` (BujitDEV is on hold).
  Its `main` is the Flutter app; the Java app's last `main` is kept on the
  `java-main` branch.
- **Releases.** Pushing a tag to the release repo builds, signs and uploads to Play
  ([release.yml](.github/workflows/release.yml)). The suffix picks the tracks:
  none = internal, `-closed` = internal + both closed tracks, `-open` = open
  testing, `-all` = every testing track. Production is a promotion in Play Console.
- **Versions.** The version code is major·10000 + minor·1000 + patch, continuing
  from the Java app's 0.4.5 (4005). Latest: `v0.5.6-closed` (5006). Never reuse one.
- **Signing.** Builds are signed with the Java app's upload key; Play re-signs them
  with its app signing key (SHA-1 `41:97:BF:65:17:8D:63:1A:83:A5:7D:B0:3C:3E:CC:4C:F0:E5:FA:83`).
- **CI** analyzes and tests every push to `main`, and fails on any analyzer issue.
- **Database.** Every released layout is kept (version 3 now; steps in
  [app_database.dart](lib/storage_management/database/app_database.dart)), so
  updates migrate data.
- **Java app data** is imported on the first open after updating over it (checked
  with a release build over the Java app's 0.4.5): data, settings, counted
  accounts and bank logins. Google Tasks needs signing in again.
- **Play listing links:** privacy policy and data deletion pages are live (below).

**For you:**
- [ ] **Google sign-in in Play builds.** Add the app signing key's **SHA-1** above
      to the Android OAuth client in Google Cloud Console (Credentials), and its
      **SHA-1 and SHA-256** (Play Console → Test and release → App integrity) to the
      Android app in Firebase → Project settings.
- [ ] **New logo on the Play listing.** Play Console → Grow users → Store presence →
      Main store listing. App icon: upload
      [site-assets/bujit-logo-512.png](site-assets/bujit-logo-512.png) (512×512).
      Feature graphic: upload [play/listing/feature-graphic.png](play/listing/feature-graphic.png)
      (1024×500).
      The app's own icon and launch screen already use it from the next release.
- [ ] **Check the update path on your phone** with your real data: data, settings,
      banks (pull down to sync), Google Tasks after signing in again, and a tip.
- [ ] **When testing is done:** delete the App Check debug tokens in Firebase →
      App Check → Apps → Manage debug tokens.
- [ ] **Going public:** tag `v1.0.0-all` (or promote in Play Console), then
      promote to production in Play Console. Edit
      [play/whatsnew/whatsnew-en-US](play/whatsnew/whatsnew-en-US) first.

---

## Website

`https://nishian3695.github.io/Bujit/`: GitHub Pages, built from the root of the
release repo's `main`. It has the home page, privacy policy, data deletion page,
CSV import reference and the CSV template (a test keeps it identical to the app's).

- Keep these at the repo root: `index.html`, `privacy-policy.html`,
  `data-deletion.html`, `csv-import-reference.html`, `bujit_import_template.csv`,
  `site.css`, `site-assets/`, `.nojekyll` and `google47d20b5a7bb30863.html` (Google
  Search Console's ownership check). Removing them took the site down once and got
  a release rejected.
- [ ] Read over the privacy policy and data deletion page; they're your text. The
      deletion page sends requests to GitHub issues (public); add an email if you
      prefer.

---

## Google Tasks

**Done:** in project `bujit-89ac6` the Tasks API is on, there are Android, Web and
iOS OAuth clients (IDs in [lib/config/google_config.dart](lib/config/google_config.dart)),
the website is verified in Search Console, and the privacy policy has Google's
Limited Use statement.

**While the consent screen isn't verified,** users see "Google hasn't verified this
app" and continue with **Advanced → Go to Bujit (unsafe)**; only listed test users
can sign in, and sign-ins expire after 7 days.

**For you (verification):** in Google Cloud Console → Google Auth Platform:
- [ ] **Branding:** home page `https://nishian3695.github.io/Bujit/`, privacy policy
      `https://nishian3695.github.io/Bujit/privacy-policy.html`, authorized domain
      `nishian3695.github.io` (allow ~24 hours after the Search Console check).
- [ ] **Data Access:** only `https://www.googleapis.com/auth/tasks`. Remove the
      read-only Tasks scope if it's listed; Bujit doesn't use it.
- [ ] **Audience:** publish to **In production**.
- [ ] **Verification Center:** submit with a reason like: *"Bujit creates a 'Bujit'
      task list in the user's Google Tasks and keeps one task per expense and
      paycheck, with its due date, so the user gets Google's reminders. It only
      reads list names (to find its own list) and only changes tasks in that list;
      the user can remove them when turning sync off."* Add an unlisted YouTube
      video: Settings → Sync to Google Tasks, the consent screen, and the Bujit list
      in Google Tasks. Review takes days to weeks.
- [ ] **Keep clients in use:** Google deletes OAuth clients unused for ~6 months
      (likely why the Java app's clients vanished).

| Symptom | Usual cause |
|---|---|
| "Developer console is not set up correctly", errors [10]/[16] | The build's signing key isn't on an Android client (see the Play SHA-1 above) |
| "Access blocked: … has not completed the Google verification process" | That account isn't a test user |
| "Google Tasks needs permission again" | The 7-day test sign-in expired, or access was removed. Turn the switch off and on. |

---

## Apple Reminders (iPhone)

**Done:** on iPhone, Settings offers **Sync to Apple Reminders** next to Google
Tasks (one at a time). It keeps the same "Bujit" list in Reminders, synced to the
user's Apple devices by iCloud, with no sign-in. Native code:
[AppDelegate.swift](ios/Runner/AppDelegate.swift); permission text in
[Info.plist](ios/Runner/Info.plist).
- [ ] Try it in Appetize (allow Reminders when asked), and again on a real iPhone
      in TestFlight.

---

## Linked Accounts (Plaid)

**Done:** the backend (a Firebase Cloud Function, source in [backend/](backend/))
is deployed from this repo with Firebase Hosting, holds the Plaid keys in Secret
Manager, and checks each request's Firebase sign-in and App Check token. Android
release builds pass App Check with Play Integrity.

### iPhone bank logins
For banks that log in on their own site (Chase, Capital One, …), Plaid returns to
`https://bujit-89ac6.web.app/plaid-oauth`, which opens Bujit. The code is ready:
1. [ ] **Apple Team ID** (Apple developer account → Membership): send it to me, and
       I'll put it in [apple-app-site-association](backend/hosting/.well-known/apple-app-site-association).
2. [ ] Then deploy hosting: in `backend/`, `firebase deploy --only hosting`.
3. [ ] **Plaid dashboard → Developers → API → Allowed redirect URIs:** add
       `https://bujit-89ac6.web.app/plaid-oauth`.
4. [ ] **Apple developer account → Identifiers → io.github.nishian3695.bujit:**
       turn on **Associated Domains** and **App Attest**.
5. [ ] **Firebase → App Check:** register the iOS app with **App Attest** (and
       DeviceCheck as the fallback, which needs a DeviceCheck key from Apple).
6. [ ] Test on a real iPhone (TestFlight); App Attest doesn't work in the simulator.

| Symptom | Usual cause |
|---|---|
| "Bujit's server refused the request (Missing App Check token)" | A debug build whose App Check debug token isn't registered, or iOS App Check not set up |
| A bank says "connection expired" | Its login changed or access was revoked; use **Reconnect** |

---

## Tips and ratings

- **Tips** sell `tip_small`, `tip_medium` and `tip_large` (one-time, consumable).
  On Play they already exist. Purchases only work in builds installed from a store.
- **Rating:** only "Rate Bujit" in Settings, which opens the store's review page.
  The app never pops up a rating prompt on its own.

**For you (App Store):**
- [ ] App Store Connect → **Business:** accept the **Paid Apps agreement**, and add
      tax and bank details.
- [ ] Create three **Consumable** in-app purchases: `tip_small`, `tip_medium`,
      `tip_large`. In review notes, say they're tips that unlock nothing.
- [ ] Once the app record exists, send me its **Apple ID** (App Information) for
      `appStoreId` in [legal.dart](lib/utils/legal.dart), so "Rate Bujit" works on iPhone.

---

## iPhone release

### Previewing on iOS without a Mac
[ios-simulator.yml](.github/workflows/ios-simulator.yml) builds a simulator app on
GitHub's Macs (no Apple account needed) whenever `ios-preview` is pushed, or from
Actions → iOS Simulator Build → Run workflow. With the `APPETIZE_TOKEN` secret it's
uploaded to Appetize; the run's summary links to it.
- [ ] `APPETIZE_TOKEN` repository secret (Appetize → Organization → API Tokens),
      if not added yet; without it, download the build from the run instead.
- [ ] Optional: add the repository **variable** `APPETIZE_APP_KEY` (shown in the
      run's summary) so every build replaces the same Appetize app and link.

### Publishing (needs the Apple developer account, $99/year)
1. [ ] Enroll in the **Apple Developer Program**.
2. [ ] Do the [iPhone bank logins](#iphone-bank-logins) steps (Team ID, capabilities,
       App Check).
3. [ ] **App Store Connect → Apps → +:** new iOS app with bundle ID
       `io.github.nishian3695.bujit` (register it under Identifiers first if it
       isn't listed). App names must be unique on the App Store.
4. [ ] **App Store Connect API key** for releases: Users and Access → Integrations
       → App Store Connect API → **Generate**, role **Admin**. Add repository
       secrets `APPSTORE_API_KEY_ID`, `APPSTORE_API_ISSUER_ID`,
       `APPSTORE_API_KEY_P8` (the .p8 file's contents) and `APPLE_TEAM_ID`.
5. [ ] Push a tag like `ios-v0.5.4` to the release repo:
       [ios-release.yml](.github/workflows/ios-release.yml) builds, signs (Xcode's
       cloud signing) and uploads to **TestFlight**. Its first run may need fixes.
6. [ ] **TestFlight** on a real iPhone: bank linking, Face ID app lock, Apple
       Reminders, a sandbox tip purchase.
7. [ ] App Store listing:
   - **App icon:** taken from the build (the logo); nothing to upload.
   - **App Privacy** ("nutrition label"): no tracking; data is on the device; bank
     data goes through Plaid; diagnostics through Firebase.
   - **Encryption:** the app uses standard encryption (HTTPS and its encrypted
     database); answer App Store Connect's export questions (typically exempt).
   - **Screenshots** (the simulator can produce them), description, support URL
     (the website), privacy policy URL.
8. [ ] Submit for review.

---

## Name (optional)

"Bujit" is used elsewhere, and a "Budgit" budgeting app exists. If protecting the
name matters, ask a trademark attorney before the iOS launch; a rename is easy now
(store titles and the in-app name), while the package name never changes.
