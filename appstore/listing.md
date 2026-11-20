# App Store listing (draft)

What to enter in App Store Connect for Bujit (Apple ID 6818891149). Character
limits are Apple's; every field here fits.

---

## App Information (applies to every version)

| Field | Value |
|---|---|
| Name (30) | `Bujit: Budget by Paycheck` (already set) |
| Subtitle (30) | `Plan bills around every payday` |
| Primary category | Finance |
| Secondary category | Productivity |
| Content rights | No, it doesn't contain, show or access third-party content |
| Privacy Policy URL | `https://bujits.com/privacy-policy.html` |

Another subtitle that fits: `Paycheck-to-paycheck budgeting`.

### Age rating

Answer **None / No** to every question (no violence, mature themes, gambling,
contests, user-generated content, messaging, unrestricted web access, and so on).
Result: **4+**. The app only opens links (the website, Plaid's bank sign-in)
for a purpose; it has no general-purpose browser.

### Encryption

Nothing to answer: `ITSAppUsesNonExemptEncryption` is already `false` in
`ios/Runner/Info.plist` (the app uses only standard encryption: HTTPS, the
encrypted database and passphrase-encrypted backups).

---

## Version page (iOS 0.5.x)

### Promotional text (170; can change any time without a new build)

```
Know what's left after the bills due before your next payday. Plan each check, see your cards' utilization, and track it all on your phone.
```

### Description (4000)

```
Bujit budgets the way you get paid: one paycheck at a time.

Instead of a monthly budget that never lines up with your paydays, Bujit puts every bill and card payment on the check that pays for it. Open the app and see your balance, what's due before your next payday, and what's left after it.

PAYCHECK BY PAYCHECK
• See "After This Check": your balance minus everything due before the next payday
• Step ahead to future checks to see how the next few weeks play out
• Paid weekly, every two weeks, monthly or twice a month: your paydays set the plan
• Add side income alongside your main paycheck

BILLS ON ANY SCHEDULE
• Rent, subscriptions, insurance and more, on any repeat: daily, weekly, monthly, yearly or twice a month
• Bills due on a weekend can move to the Friday before
• Categories show which bills take the biggest share of each check

CREDIT CARDS
• Track balances and limits, with utilization for each card and overall
• Card payments are planned on the check that pays them

SEE THE BIG PICTURE
• Cash Flow: income and spending for every pay period of the year
• Categories: spending per check, by category
• Net Balance: savings, cards and accounts over time, with a projection ahead

ONE-OFF EVENTS
• Log a surprise expense or a windfall and it's applied right away, to your balance, a card or a savings account

OPTIONAL EXTRAS
• Link banks and cards through Plaid to keep balances up to date, or track everything by hand
• Reminders for due dates in Apple Reminders or Google Tasks
• Face ID app lock
• Light and dark themes with your choice of accent color
• Import your budget from a CSV file
• Passphrase-encrypted backups you can restore on a new phone, iPhone or Android

PRIVATE BY DESIGN
Your budget is stored in an encrypted database on your iPhone, never on a Bujit server. No ads, no analytics, no account needed.

Bujit is a budgeting tool for informational purposes only and is not financial advice. Projections are estimates.
```

### Keywords (100; commas, no spaces after them)

```
budget,paycheck,payday,biweekly,bills,expense,tracker,planner,money,finance,credit,card,utilization
```

(The name and subtitle are indexed already, so words in them, like "budget" and
"paycheck", could be swapped for others such as `salary,spending,savings` if
you'd rather.)

### URLs

| Field | Value |
|---|---|
| Support URL | `https://bujits.com/support.html` |
| Marketing URL | `https://bujits.com/` |

### Copyright

```
2026 Nishian3695
```

### Screenshots

- iPhone 6.9" Display: `store-screenshots/iphone-6.9/01-home.png` … `07-categories.png`
- iPad 13" Display: `store-screenshots/ipad-13/01-home.png` … `07-categories.png`

Upload in file-name order (Apple shows them in the order uploaded; drag to reorder).

### App Review Information

| Field | Value |
|---|---|
| Sign-in required | **No** (the app has no accounts) |
| Contact | Your name, phone and email (Apple's reviewers only) |

Notes for the reviewer:

```
Bujit needs no account. On first launch it shows a short disclaimer, then a tutorial with sample data (a paycheck, bills and credit cards) so every screen has something to show.

Optional features:
- Linked Accounts (menu > Linked Accounts) connects a real bank through Plaid. It's optional: every feature works with balances entered by hand.
- Settings > Reminders syncs due dates to Apple Reminders (asks for Reminders access) or Google Tasks (Google sign-in).
- Settings > App lock uses Face ID.
- Settings > Tip jar offers optional consumable tips; no features are locked behind them.
```

> The backend uses Plaid's production environment (`PLAID_ENV=production`), so
> there's no test bank login to give the reviewer; the notes say bank linking
> is optional instead.

### Pricing and availability

Free. In-app purchases (consumable tips): `tip_small_ios` ($0.99),
`tip_medium` ($2.99), `tip_large`; attach them to this version under
**In-App Purchases** so they're reviewed with it.

---

## App Privacy ("nutrition label")

**Do you or your third-party partners collect data?** Yes.
**Tracking:** No for every type (nothing is used to track people across other
companies' apps or sites).

Apple builds a privacy report from each SDK's privacy manifest, so these answers
match what the SDKs in the app declare, plus Bujit's own bank-balance requests:

| Data type | Purposes | Linked to the user | Where it comes from |
|---|---|---|---|
| Financial Info → Other Financial Info | App Functionality | Yes | Bank balances fetched through Plaid (only if you link a bank) |
| Identifiers → User ID | App Functionality, Analytics | Yes | Plaid Link SDK; Firebase anonymous sign-in; Google Sign-In SDK |
| Identifiers → Device ID | Analytics | Yes | Google Sign-In SDK |
| Contact Info → Name | App Functionality | Yes | Google Sign-In SDK (only for Google Tasks sync) |
| Contact Info → Email Address | App Functionality | Yes | Google Sign-In SDK (only for Google Tasks sync) |
| Contact Info → Phone Number | App Functionality | Yes | Google Sign-In SDK |
| Location → Coarse Location | App Functionality | Yes | Google Sign-In SDK |
| Usage Data → Other Usage Data | Analytics | Yes | Google Sign-In SDK |
| Diagnostics → Other Diagnostic Data | Analytics | No | Firebase (its user agent: device, OS and app version) |
| Other Data → Other Data Types | App Functionality, Analytics | Yes | Google Sign-In SDK |

Not collected: health, browsing history, search history, contacts, photos,
audio, precise location, purchases (Apple handles tips), user content (the
budget stays on the phone; Reminders and Google Tasks lists live in your own
accounts).

Sources: Plaid's `LinkKit` 6.4.7 privacy manifest (declares User ID, linked,
not tracking), Google Sign-In's iOS privacy manifest, and Firebase's
[App Store data disclosure guide](https://firebase.google.com/docs/ios/app-store-data-collection).

> The Google Sign-In rows are its manifest's worst case. Apple lets you leave out
> data that's optional, user-initiated and not used for tracking or ads, but
> declaring what the SDK declares is the safe choice and avoids a mismatch with
> Apple's privacy report.
