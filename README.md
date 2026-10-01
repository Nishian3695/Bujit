# Bujit

A personal finance budgeting app for Android. Track recurring expenses, project your balance across future pay periods, monitor credit card utilization, and optionally sync to Google Tasks.

---

## Features

- **Expense tracking** -- Add recurring expenses with any frequency (daily, weekly, monthly, yearly, or custom). Each row shows the next due date, recurrence rate, and amount owed this pay period.
- **Balance projection** -- Navigate forward through future pay periods to see your projected balance after each paycheck and set of expenses. A custom projection mode lets you model any stream or period length without changing your saved data.
- **Multiple income streams** -- Add as many income sources as you like. The active stream drives the pay period length and paycheck amount used in projections.
- **Bank integration** -- Connect bank accounts via the Plaid API. Your real balance is fetched automatically on pull-to-refresh. Multiple banks can be connected simultaneously.
- **Credit utilization** -- Track credit card balances and limits. Each card displays a color-coded utilization bar (green < 30%, yellow < 70%, red >= 70%). Cards can be linked to Plaid credit/loan accounts for live balance updates.
- **Google Tasks sync** -- Optionally link a Google account to create tasks for all expenses and income streams in a dedicated "Bujit" task list, which appears in Google Calendar.
- **Theme customization** -- Six preset accent colors or a fully custom color picked from an HSV color wheel. Separate light, dark, and system night mode settings.
- **Multi-select and reorder** -- Long-press any expense to start drag-to-reorder. Tap the select icon in the action bar to enter multi-select mode for batch deletion.
- **Secure storage** -- Bank enrollment tokens are encrypted with AES-256-GCM using the Android Keystore. App data is stored using Java serialization in the app's private files directory.

---

## Screenshots

> Add screenshots here once available.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Java (Android SDK 26+) |
| UI | Material Design 3, ConstraintLayout, RecyclerView |
| Banking | Plaid Connect SDK + Firebase Cloud Functions proxy |
| Calendar sync | Google Tasks REST API via Google Sign-In OAuth 2.0 |
| Auth (backend) | Firebase Authentication (anonymous sign-in for Cloud Function access) |
| HTTP | OkHttp 4 |
| Secure storage | Android Keystore (AES-256-GCM) |
| Data persistence | Java object serialization (StorageHolder) |
| Build | Gradle with buildConfigField for secrets |

---

## Prerequisites

- Android Studio Hedgehog or later
- Android device or emulator running API 26 (Android 8.0) or higher
- A [Plaid](https://plaid.com/) developer account and application ID
- A Google Cloud project with the **Google Tasks API** enabled and an **OAuth 2.0 Android client ID** configured
- A Firebase project with **Anonymous Authentication** enabled and a Cloud Function that proxies Plaid API calls

---

## Setup

### 1. Clone the repository

```
git clone https://github.com/Nishian3695/Bujit.git
cd Bujit
```

### 2. Configure secrets

Create `local.properties` in the project root (it is gitignored) and add your Plaid application ID:

```
sdk.dir=/path/to/your/Android/Sdk
Plaid_APP_ID=app_xxxxxxxxxxxxxxxx
```

### 3. Add Firebase config

Place your `google-services.json` from the Firebase console into `app/`.

### 4. Add the Plaid certificate (Development environment only)

The Plaid Development environment requires mTLS. The certificate and private key should be stored in Firebase Secret Manager and accessed by the Cloud Function backend. The Android app itself does not bundle any certificate.

### 5. Build and run

Open the project in Android Studio and click **Run**, or build from the command line:

```
./gradlew assembleDebug
```

---

## Project Structure

```
app/src/main/java/io/github/nishian3695/bujit/
|
+-- BujitApp.java                  Application class; applies night mode on startup
+-- ThemeHelper.java               Accent color and night mode utilities
+-- ColorWheelView.java            Custom HSV color wheel view for the color picker
|
+-- ExpenseActivity/
|   +-- ExpenseActivity.java       Main screen; expense list, balance, projection navigation
|   +-- ExpenseModel.java          Data model for a recurring expense
|   +-- ExpenseAdapter.java        RecyclerView adapter with selection mode and drag-reorder
|   +-- ExpenseViewHolder.java     ViewHolder for expense list rows
|
+-- CustomListeners/
|   +-- CurrencyEditTextWatcher.java   Limits currency input to two decimal places
|   +-- CurrencyFormat.java            Formats floats/strings to "##0.00"
|
+-- Interfaces/
|   +-- ClickListener.java         Tap / long-press callback interface
|
+-- StorageManagement/
|   +-- StorageHolder.java         Serializable container for all persisted app data
|   +-- StorageManager.java        Reads and writes StorageHolder to a private file
|
+-- NavigationItems/
|   +-- Banking/
|   |   +-- BankingActivity.java         Plaid Connect enrollment and account list
|   |   +-- BankAccountModel.java        Data model for a Plaid account
|   |   +-- BankAccountAdapter.java      RecyclerView adapter for the account list
|   |   +-- BankAccountViewHolder.java   ViewHolder for account cards
|   |   +-- BankingPrefs.java            AES-256-GCM encrypted token storage
|   |   +-- PlaidApi.java               Interface for Plaid API operations
|   |   +-- PlaidBackendClient.java     OkHttp client proxying calls to the Cloud Function
|   |
|   +-- CreditUtil/
|   |   +-- CreditUtilActivity.java      Credit card list with utilization tracking
|   |   +-- CreditAdapter.java           RecyclerView adapter for credit cards
|   |   +-- CreditViewHolder.java        ViewHolder for credit card rows
|   |
|   +-- IncomeStreams/
|   |   +-- IncomeStreamsActivity.java   Add/edit/select income streams
|   |   +-- IncomeStreamModel.java       Data model for an income stream
|   |   +-- IncomeStreamAdapter.java     RecyclerView adapter for income stream cards
|   |   +-- IncomeStreamViewHolder.java  ViewHolder for income stream cards
|   |
|   +-- Settings/
|       +-- SettingsActivity.java        Theme, Google sync, and data management
|       +-- GoogleTasksHelper.java       Google Tasks REST API integration
```

---

## Architecture Notes

**Data flow** -- All app state (expenses, balance, income streams, check dates) lives in a single `StorageHolder` object that is read on startup and written on every `onPause()`. There is no database; Java serialization is used for simplicity.

**Income streams and projections** -- The selected income stream provides the pay period length and paycheck amount. The "projection" mode in `ExpenseActivity` allows the user to temporarily override these values for what-if analysis without touching stored data.

**Bank linking** -- The Plaid mTLS private key never touches the device. A Firebase Cloud Function acts as a proxy; the Android app authenticates to it using a Firebase anonymous ID token.

**Credit entries** -- Credit cards are stored as `ExpenseModel` objects with `expenseIsCredit=true`. Their cost field holds the current balance and `creditLimit` holds the limit. This reuses the existing expense persistence layer without a separate data structure.

---

## Contributing

Contributions are welcome. Please open an issue first to discuss significant changes. When submitting a pull request:

1. Fork the repository and create a feature branch from `main`.
2. Follow the existing code style.
3. Test on a physical device or emulator at API 26+.
4. Describe what the PR changes and why in the PR description.

---

## License

This project is open source. License to be specified by the author.
