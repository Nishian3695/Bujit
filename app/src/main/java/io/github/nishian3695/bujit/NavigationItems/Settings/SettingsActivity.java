package io.github.nishian3695.bujit.NavigationItems.Settings;

import android.content.Intent;
import android.net.Uri;
import android.util.Log;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.core.content.FileProvider;
import io.github.nishian3695.bujit.StorageManagement.BackupCrypto;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.PendingPurchasesParams;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.QueryProductDetailsParams;
import io.github.nishian3695.bujit.AppLockPrefs;
import io.github.nishian3695.bujit.BujitApp;
import io.github.nishian3695.bujit.DisplayPrefs;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankingPrefs;
import io.github.nishian3695.bujit.Tutorial.TutorialManager;
import io.github.nishian3695.bujit.Tutorial.TutorialOverlayLayout;
import android.view.ViewGroup;
import io.github.nishian3695.bujit.ColorWheelView;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseActivity;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.ThemeHelper;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.common.api.ApiException;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.button.MaterialButtonToggleGroup;
import com.google.android.material.card.MaterialCardView;
import com.google.android.material.switchmaterial.SwitchMaterial;

import java.io.File;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/*
Activity for app-wide settings.

Appearance: six preset accent colors (blue, purple, green, orange, teal, rose)
and a custom color picker backed by ColorWheelView. Light/dark/system night mode
toggle. All choices are persisted via ThemeHelper to SharedPreferences.

Integrations: Google Calendar sync via Google Sign-In and the Google Tasks API.
Connecting enables automatic task creation in a "Bujit" task list for all expenses
and income streams. Disconnecting deletes those tasks and signs out.
The EXTRA_CALENDAR_SYNC_CHANGED flag in the result Intent tells ExpenseActivity
to perform the initial sync or cleanup on resume.

Data: "Clear Everything" wipes the serialized expense data, SharedPreferences, and
all encrypted banking tokens, then relaunches ExpenseActivity fresh.

Help/Suggestions: opens the GitHub issues page in the device browser.
*/
public class SettingsActivity extends AppCompatActivity {

    private static final String[] COLOR_KEYS  = {"blue", "purple", "green", "orange", "teal", "rose"};
    private static final int[]    SWATCH_IDS  = {
            R.id.swatch_blue, R.id.swatch_purple, R.id.swatch_green,
            R.id.swatch_orange, R.id.swatch_teal, R.id.swatch_rose
    };
    private static final int[]    CHECK_IDS   = {
            R.id.check_blue, R.id.check_purple, R.id.check_green,
            R.id.check_orange, R.id.check_teal, R.id.check_rose
    };

    // Set when the user connects/disconnects so ExpenseActivity can react on return.
    public static final String EXTRA_CALENDAR_SYNC_CHANGED = "calendar_sync_changed";

    private MaterialCardView[]  swatches;
    private View[]              checks;
    private MaterialButtonToggleGroup themeToggle;
    private MaterialCardView swatchCustom;
    private View             checkCustom;

    // Google Calendar Sync UI
    private View     rowGoogleConnect;
    private View     rowGoogleConnected;
    private TextView tvGoogleAccount;

    private SwitchMaterial switchAppLock;
    private boolean updatingLockSwitch = false;

    private TutorialOverlayLayout tutorialOverlay;
    private GoogleSignInClient googleSignInClient;
    private boolean calendarSyncChanged = false;

    private static final String BILLING_TAG = "BujitBilling";
    private BillingClient billingClient;
    private final Map<String, ProductDetails> tipProducts = new HashMap<>();
    private MaterialButton btnTipSmall, btnTipMedium, btnTipLarge;
    private static final String TIP_SMALL  = "tip_small";
    private static final String TIP_MEDIUM = "tip_medium";
    private static final String TIP_LARGE  = "tip_large";

    // Backup export/import (see BackupCrypto) — off-UI-thread crypto/serialization work.
    private ExecutorService backupExecutor;
    private Handler backupMainHandler;
    // Holds the export passphrase between the "Save Your Passphrase" confirmation and the async
    // CreateDocument result, since the SAF picker must be launched before the file URI is known.
    private char[] pendingExportPassphrase;

    // Handles the result of the Google Sign-In flow, completing calendar sync setup on success.
    private final ActivityResultLauncher<Intent> googleSignInLauncher =
            registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
                if (result.getResultCode() == RESULT_OK && result.getData() != null) {
                    try {
                        GoogleSignInAccount account =
                                GoogleSignIn.getSignedInAccountFromIntent(result.getData())
                                        .getResult(ApiException.class);
                        onGoogleSignInSuccess(account);
                    } catch (ApiException e) {
                        Toast.makeText(this, "Google sign-in failed", Toast.LENGTH_SHORT).show();
                    }
                }
            });

    // Handles the result of the system file picker used for "Import CSV".
    private final ActivityResultLauncher<String[]> csvPickerLauncher =
            registerForActivityResult(new ActivityResultContracts.OpenDocument(), uri -> {
                if (uri != null) performCsvImport(uri);
            });

    // Handles the result of the system "Save As" dialog used for "Save CSV template to device".
    private final ActivityResultLauncher<String> createTemplateLauncher =
            registerForActivityResult(new ActivityResultContracts.CreateDocument("text/csv"), uri -> {
                if (uri == null) return;
                try (OutputStream os = getContentResolver().openOutputStream(uri)) {
                    if (os != null) {
                        os.write(CsvImportHelper.TEMPLATE.getBytes(StandardCharsets.UTF_8));
                        Toast.makeText(this, "Template saved", Toast.LENGTH_SHORT).show();
                    }
                } catch (Exception e) {
                    Toast.makeText(this, "Could not save template: " + e.getMessage(), Toast.LENGTH_SHORT).show();
                }
            });

    // Handles the result of the "Save As" dialog used for "Export Backup".
    private final ActivityResultLauncher<String> exportBackupLauncher =
            registerForActivityResult(new ActivityResultContracts.CreateDocument("application/octet-stream"), uri -> {
                char[] passphrase = pendingExportPassphrase;
                pendingExportPassphrase = null;
                if (uri != null && passphrase != null) performBackupExport(uri, passphrase);
            });

    // Handles the result of the system file picker used for "Import Backup".
    private final ActivityResultLauncher<String[]> importBackupLauncher =
            registerForActivityResult(new ActivityResultContracts.OpenDocument(), uri -> {
                if (uri != null) promptImportPassphrase(uri);
            });

    // Inflates the settings screen and wires up every section: appearance (accent color/theme),
    // Google Calendar sync, app lock, category manager link, CSV import/export, single-event
    // expiry, help/legal links, and the in-app tip jar.
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);
        ThemeHelper.enableEdgeToEdge(this);
        setContentView(R.layout.activity_settings);
        ThemeHelper.tintActionBar(this);
        ViewCompat.setOnApplyWindowInsetsListener(
                ((android.view.ViewGroup) findViewById(android.R.id.content)).getChildAt(0),
                (v, windowInsets) -> {
                    Insets insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars());
                    v.setPadding(0, insets.top, 0, insets.bottom);
                    return WindowInsetsCompat.CONSUMED;
                });

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Settings");
        }

        ThemeHelper.tintPrimaryText(findViewById(R.id.section_header_appearance), this);
        ThemeHelper.tintPrimaryText(findViewById(R.id.section_header_integrations), this);
        ThemeHelper.tintPrimaryText(findViewById(R.id.section_header_categories), this);
        ThemeHelper.tintPrimaryText(findViewById(R.id.section_header_security), this);
        ThemeHelper.tintPrimaryText(findViewById(R.id.section_header_single_events), this);
        ThemeHelper.tintPrimaryText(findViewById(R.id.section_header_support), this);
        ThemeHelper.tintPrimaryText(findViewById(R.id.section_header_support_dev), this);
        ThemeHelper.tintPrimaryText(findViewById(R.id.section_header_data), this);
        ThemeHelper.tintPrimaryText(findViewById(R.id.section_header_backup), this);
        ThemeHelper.tintPrimaryText(findViewById(R.id.section_header_legal), this);
        themeToggle = findViewById(R.id.theme_toggle);

        backupExecutor    = Executors.newSingleThreadExecutor();
        backupMainHandler = new Handler(Looper.getMainLooper());

        swatches = new MaterialCardView[SWATCH_IDS.length];
        checks   = new View[CHECK_IDS.length];
        for (int i = 0; i < SWATCH_IDS.length; i++) {
            swatches[i] = findViewById(SWATCH_IDS[i]);
            checks[i]   = findViewById(CHECK_IDS[i]);
            final String colorKey = COLOR_KEYS[i];
            final int idx = i;
            swatches[i].setOnClickListener(v -> onColorSelected(colorKey, idx));
        }

        swatchCustom = findViewById(R.id.swatch_custom);
        checkCustom  = findViewById(R.id.check_custom);
        findViewById(R.id.row_custom_color).setOnClickListener(v -> showColorPickerDialog());

        loadCurrentSelections();

        themeToggle.addOnButtonCheckedListener((group, checkedId, isChecked) -> {
            if (!isChecked) return;
            String mode;
            if (checkedId == R.id.btn_light)       mode = "light";
            else if (checkedId == R.id.btn_dark)   mode = "dark";
            else                                    mode = "system";
            ThemeHelper.saveMode(this, mode);
            ThemeHelper.applyNightMode(this);
            recreate();
        });

        // Integrations -- Google Calendar Sync
        googleSignInClient  = GoogleTasksHelper.buildSignInClient(this);
        rowGoogleConnect    = findViewById(R.id.row_google_connect);
        rowGoogleConnected  = findViewById(R.id.row_google_connected);
        tvGoogleAccount     = findViewById(R.id.tv_google_account);
        View btnDisconnect  = findViewById(R.id.btn_google_disconnect);

        refreshGoogleSyncUI();

        rowGoogleConnect.setOnClickListener(v -> startGoogleSignIn());
        btnDisconnect.setOnClickListener(v -> confirmDisconnect());

        switchAppLock = findViewById(R.id.switch_app_lock);
        switchAppLock.setChecked(AppLockPrefs.isLockEnabled(this));
        switchAppLock.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (updatingLockSwitch) return;
            if (isChecked) {
                int canAuth = BiometricManager.from(this).canAuthenticate(
                        BiometricManager.Authenticators.BIOMETRIC_STRONG |
                        BiometricManager.Authenticators.DEVICE_CREDENTIAL);
                if (canAuth != BiometricManager.BIOMETRIC_SUCCESS) {
                    Toast.makeText(this,
                            "No screen lock set up. Enable a PIN, pattern, or biometric in device settings first.",
                            Toast.LENGTH_LONG).show();
                    updatingLockSwitch = true;
                    switchAppLock.setChecked(false);
                    updatingLockSwitch = false;
                    return;
                }
                BiometricPrompt.PromptInfo info = new BiometricPrompt.PromptInfo.Builder()
                        .setTitle("Enable App Lock")
                        .setSubtitle("Confirm your identity to enable lock")
                        .setAllowedAuthenticators(
                                BiometricManager.Authenticators.BIOMETRIC_STRONG |
                                BiometricManager.Authenticators.DEVICE_CREDENTIAL)
                        .build();
                new BiometricPrompt(this, ContextCompat.getMainExecutor(this),
                        new BiometricPrompt.AuthenticationCallback() {
                            @Override
                            public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
                                AppLockPrefs.setLockEnabled(SettingsActivity.this, true);
                                BujitApp.needsAuth = false;
                            }
                            @Override
                            public void onAuthenticationError(int errorCode, CharSequence errString) {
                                updatingLockSwitch = true;
                                switchAppLock.setChecked(false);
                                updatingLockSwitch = false;
                            }
                            @Override
                            public void onAuthenticationFailed() {}
                        }).authenticate(info);
            } else {
                AppLockPrefs.setLockEnabled(this, false);
            }
        });

        SwitchMaterial switchCommaSeparators = findViewById(R.id.switch_comma_separators);
        switchCommaSeparators.setChecked(DisplayPrefs.useCommaSeparators(this));
        switchCommaSeparators.setOnCheckedChangeListener((buttonView, isChecked) ->
                DisplayPrefs.setUseCommaSeparators(this, isChecked));

        findViewById(R.id.row_categories).setOnClickListener(v ->
                startActivity(new android.content.Intent(this, CategoryManagerActivity.class)));
        findViewById(R.id.row_help_suggestions).setOnClickListener(v -> openHelpEmail());
        findViewById(R.id.row_tutorial).setOnClickListener(v -> startTutorial());
        findViewById(R.id.row_rate_app).setOnClickListener(v -> openPlayStoreListing());
        findViewById(R.id.row_import_csv).setOnClickListener(v ->
                csvPickerLauncher.launch(new String[]{"text/csv", "text/plain", "application/octet-stream", "*/*"}));
        findViewById(R.id.row_csv_template).setOnClickListener(v -> promptTemplateAction());
        findViewById(R.id.row_csv_reference).setOnClickListener(v ->
                openUrl("https://nishian3695.github.io/Bujit/csv-import-reference.html"));
        findViewById(R.id.row_clear_data).setOnClickListener(v -> confirmClearData());
        findViewById(R.id.row_export_backup).setOnClickListener(v -> promptExportPassphrase());
        findViewById(R.id.row_import_backup).setOnClickListener(v ->
                importBackupLauncher.launch(new String[]{"application/octet-stream", "*/*"}));
        findViewById(R.id.row_website).setOnClickListener(v ->
                openUrl("https://nishian3695.github.io/Bujit/"));
        findViewById(R.id.row_privacy_policy).setOnClickListener(v -> openPrivacyPolicy());
        findViewById(R.id.row_teller_privacy).setOnClickListener(v -> openTellerPrivacy());
        findViewById(R.id.row_disclaimer).setOnClickListener(v -> showDisclaimer());

        // Tip jar
        btnTipSmall  = findViewById(R.id.btn_tip_small);
        btnTipMedium = findViewById(R.id.btn_tip_medium);
        btnTipLarge  = findViewById(R.id.btn_tip_large);
        btnTipSmall.setOnClickListener(v  -> launchTip(TIP_SMALL));
        btnTipMedium.setOnClickListener(v -> launchTip(TIP_MEDIUM));
        btnTipLarge.setOnClickListener(v  -> launchTip(TIP_LARGE));
        setupBilling();

        // Single Events expiry row
        TextView tvExpiryDays = findViewById(R.id.tv_expiry_days);
        int currentExpiry = getSharedPreferences("bujit_prefs", MODE_PRIVATE)
                .getInt("single_event_expiry_days", 30);
        tvExpiryDays.setText(currentExpiry + " day" + (currentExpiry == 1 ? "" : "s"));
        findViewById(R.id.row_single_event_expiry).setOnClickListener(v -> {
            android.widget.EditText input = new android.widget.EditText(this);
            input.setInputType(android.text.InputType.TYPE_CLASS_NUMBER);
            int existing = getSharedPreferences("bujit_prefs", MODE_PRIVATE)
                    .getInt("single_event_expiry_days", 30);
            input.setText(String.valueOf(existing));
            int padPx = (int) (16 * getResources().getDisplayMetrics().density);
            android.widget.FrameLayout container = new android.widget.FrameLayout(this);
            android.widget.FrameLayout.LayoutParams lp = new android.widget.FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            lp.setMargins(padPx, padPx / 2, padPx, 0);
            input.setLayoutParams(lp);
            container.addView(input);
            new androidx.appcompat.app.AlertDialog.Builder(this)
                    .setTitle("Event Expiry")
                    .setMessage("Remove single events after how many days?")
                    .setView(container)
                    .setPositiveButton("Save", (d, w) -> {
                        String s = input.getText() != null ? input.getText().toString().trim() : "";
                        int days = 30;
                        try { days = Integer.parseInt(s); } catch (NumberFormatException ignored) {}
                        if (days < 1) days = 1;
                        getSharedPreferences("bujit_prefs", MODE_PRIVATE)
                                .edit().putInt("single_event_expiry_days", days).apply();
                        tvExpiryDays.setText(days + " day" + (days == 1 ? "" : "s"));
                    })
                    .setNegativeButton("Cancel", null)
                    .show();
        });
    }

    // Always reports whether calendar sync was toggled this session, so ExpenseActivity knows to
    // trigger the initial sync/cleanup on resume regardless of how this screen was exited.
    @Override
    public void finish() {
        Intent data = new Intent();
        data.putExtra(EXTRA_CALENDAR_SYNC_CHANGED, calendarSyncChanged);
        setResult(RESULT_OK, data);
        super.finish();
    }

    // Makes the toolbar's back arrow close this screen.
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    // Shows the "Connect"/"Connected as ..." row based on current Google sign-in and sync state.
    private void refreshGoogleSyncUI() {
        GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(this);
        boolean synced = GoogleTasksHelper.isCalendarSyncEnabled(this);
        if (account != null && synced) {
            rowGoogleConnect.setVisibility(View.GONE);
            rowGoogleConnected.setVisibility(View.VISIBLE);
            String email = account.getEmail();
            tvGoogleAccount.setText(email != null ? "Connected: " + email : "Connected");
        } else {
            rowGoogleConnect.setVisibility(View.VISIBLE);
            rowGoogleConnected.setVisibility(View.GONE);
        }
    }

    // Launches the Google Sign-In UI.
    private void startGoogleSignIn() {
        googleSignInLauncher.launch(googleSignInClient.getSignInIntent());
    }

    // Marks calendar sync as enabled and refreshes the UI after a successful Google sign-in.
    private void onGoogleSignInSuccess(GoogleSignInAccount account) {
        // Clear pending_disconnect in case the user disconnected then reconnected this session.
        getSharedPreferences("bujit_calendar_prefs", MODE_PRIVATE)
                .edit()
                .putBoolean(GoogleTasksHelper.KEY_SYNC_ENABLED, true)
                .remove("pending_disconnect")
                .apply();
        calendarSyncChanged = true;
        refreshGoogleSyncUI();
        Toast.makeText(this, "Google Calendar sync enabled", Toast.LENGTH_SHORT).show();
    }

    // Confirms before disconnecting Google Calendar sync (since it deletes tasks server-side).
    private void confirmDisconnect() {
        new AlertDialog.Builder(this)
                .setTitle("Disconnect Google Calendar")
                .setMessage("Remove all Bujit tasks from Google Calendar and disconnect?")
                .setPositiveButton("Disconnect", (d, w) -> performDisconnect())
                .setNegativeButton("Cancel", null)
                .show();
    }

    // Flags calendar sync as disabled and pending-disconnect, so ExpenseActivity deletes the
    // remaining Google Tasks (while the token is still valid) and signs the user out on resume.
    private void performDisconnect() {
        // Mark pending so ExpenseActivity deletes tasks (while token is still valid) then signs out.
        getSharedPreferences("bujit_calendar_prefs", MODE_PRIVATE)
                .edit()
                .putBoolean(GoogleTasksHelper.KEY_SYNC_ENABLED, false)
                .putBoolean("pending_disconnect", true)
                .apply();
        calendarSyncChanged = true;
        refreshGoogleSyncUI();
        Toast.makeText(this, "Google Calendar sync disabled", Toast.LENGTH_SHORT).show();
    }

    // Highlights the currently saved accent color swatch and theme-mode toggle button on screen load.
    private void loadCurrentSelections() {
        String savedColor = ThemeHelper.getSavedColor(this);
        for (int i = 0; i < COLOR_KEYS.length; i++) {
            boolean selected = COLOR_KEYS[i].equals(savedColor);
            checks[i].setVisibility(selected ? View.VISIBLE : View.GONE);
            swatches[i].setCardElevation(selected ? dpToPx(6) : dpToPx(3));
        }

        boolean customSelected = "custom".equals(savedColor);
        checkCustom.setVisibility(customSelected ? View.VISIBLE : View.GONE);
        swatchCustom.setCardElevation(customSelected ? dpToPx(6) : dpToPx(3));
        swatchCustom.setCardBackgroundColor(ThemeHelper.customColor(this));

        String savedMode = ThemeHelper.getSavedMode(this);
        int btnId;
        if ("light".equals(savedMode))      btnId = R.id.btn_light;
        else if ("dark".equals(savedMode))  btnId = R.id.btn_dark;
        else                                btnId = R.id.btn_system;
        themeToggle.check(btnId);
    }

    // Saves the tapped preset accent color and recreates the activity so it takes effect.
    private void onColorSelected(String colorKey, int index) {
        ThemeHelper.saveColor(this, colorKey);
        recreate();
    }

    // Shows the custom accent color dialog: a ColorWheelView kept in sync with a hex text field
    // and a live preview swatch, saving the chosen color as the custom accent on "Apply".
    private void showColorPickerDialog() {
        View dialogView = LayoutInflater.from(this).inflate(R.layout.dialog_color_picker, null);
        ColorWheelView colorWheel = dialogView.findViewById(R.id.color_wheel);
        View           previewView = dialogView.findViewById(R.id.color_preview);
        EditText       hexInput    = dialogView.findViewById(R.id.hex_input);

        int initialColor = ThemeHelper.customColor(this);
        colorWheel.setColor(initialColor);

        GradientDrawable previewShape = new GradientDrawable();
        previewShape.setShape(GradientDrawable.OVAL);
        previewShape.setColor(initialColor);
        previewView.setBackground(previewShape);

        hexInput.setText(String.format("#%06X", 0xFFFFFF & initialColor));

        boolean[] syncing = {false};

        colorWheel.setOnColorChangedListener(color -> {
            if (syncing[0]) return;
            syncing[0] = true;
            previewShape.setColor(color);
            hexInput.setText(String.format("#%06X", 0xFFFFFF & color));
            syncing[0] = false;
        });

        hexInput.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) {}
            @Override
            public void afterTextChanged(Editable s) {
                if (syncing[0]) return;
                String text = s.toString();
                if (text.length() == 7 && text.startsWith("#")) {
                    try {
                        int color = Color.parseColor(text);
                        syncing[0] = true;
                        colorWheel.setColor(color);
                        previewShape.setColor(color);
                        syncing[0] = false;
                    } catch (IllegalArgumentException ignored) {}
                }
            }
        });

        new AlertDialog.Builder(this)
                .setTitle("Custom Accent Color")
                .setView(dialogView)
                .setPositiveButton("Apply", (d, w) -> {
                    String hex = hexInput.getText().toString().trim();
                    if (hex.length() == 7 && hex.startsWith("#")) {
                        ThemeHelper.saveCustomColor(this, hex);
                        recreate();
                    }
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    // Confirms before wiping all app data (an irreversible action).
    private void confirmClearData() {
        new AlertDialog.Builder(this)
                .setTitle("Clear All Data")
                .setMessage("This will permanently delete all expenses, your balance, and all linked bank accounts. This cannot be undone.")
                .setPositiveButton("Clear Everything", (d, w) -> performClearData())
                .setNegativeButton("Cancel", null)
                .show();
    }

    // Deletes the serialized expense data file, all app SharedPreferences, and encrypted banking
    // tokens, then relaunches ExpenseActivity as a fresh install.
    private void performClearData() {
        File dataDir = new File(getFilesDir(), "BujitExpenseData");
        // Legacy unencrypted serialized file
        File legacyFile = new File(dataDir, "BujitExpenseDataBujitExpenseData");
        if (legacyFile.exists()) legacyFile.delete();
        // Current AES-256-GCM encrypted JSON file
        File encFile = new File(dataDir, "bujit_data_v2.enc");
        if (encFile.exists()) encFile.delete();

        getSharedPreferences(ThemeHelper.PREFS, MODE_PRIVATE).edit().clear().apply();
        getSharedPreferences("bujit_calendar_prefs", MODE_PRIVATE).edit().clear().apply();
        // Clearing the seed flag ensures sample data (including 2-year snapshot history)
        // is re-generated on next launch rather than starting with an empty app.
        getSharedPreferences("bujit_app_prefs", MODE_PRIVATE).edit().clear().apply();

        BankingPrefs.clear(this);
        AppLockPrefs.setLockEnabled(this, false);

        Intent intent = new Intent(this, ExpenseActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }

    // Runs the CSV import and shows a summary/warning/error dialog with the outcome.
    private void performCsvImport(Uri uri) {
        CsvImportHelper.ImportResult result = CsvImportHelper.importFromUri(this, uri);
        if (!result.hasData() && result.errors.isEmpty()) {
            Toast.makeText(this, "No importable data found in file.", Toast.LENGTH_SHORT).show();
            return;
        }
        StringBuilder msg = new StringBuilder();
        if (result.hasData()) msg.append(result.summary());
        if (!result.errors.isEmpty()) {
            if (msg.length() > 0) msg.append("\n\n");
            msg.append(result.hasData() ? "Warnings:\n" : "Errors:\n");
            for (String err : result.errors) msg.append("• ").append(err).append("\n");
        }
        new AlertDialog.Builder(this)
                .setTitle(result.hasData() ? "Import complete" : "Import failed")
                .setMessage(msg.toString().trim())
                .setPositiveButton("OK", null)
                .show();
    }

    // Lets the user choose whether to save the CSV import template to device or share it directly.
    private void promptTemplateAction() {
        new AlertDialog.Builder(this)
                .setTitle("CSV Template")
                .setItems(new String[]{"Save to device", "Share"}, (d, which) -> {
                    if (which == 0) {
                        createTemplateLauncher.launch("bujit_import_template.csv");
                    } else {
                        shareTemplateViaIntent();
                    }
                })
                .show();
    }

    // Writes the CSV template to a cache file and hands it off to the system share sheet via a
    // FileProvider content URI.
    private void shareTemplateViaIntent() {
        try {
            File file = new File(getCacheDir(), "bujit_import_template.csv");
            try (FileWriter writer = new FileWriter(file)) {
                writer.write(CsvImportHelper.TEMPLATE);
            }
            Uri fileUri = FileProvider.getUriForFile(
                    this, getPackageName() + ".fileprovider", file);
            Intent share = new Intent(Intent.ACTION_SEND);
            share.setType("text/csv");
            share.putExtra(Intent.EXTRA_STREAM, fileUri);
            share.putExtra(Intent.EXTRA_SUBJECT, "Bujit Import Template");
            share.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            startActivity(Intent.createChooser(share, "Share template…"));
        } catch (Exception e) {
            Toast.makeText(this, "Could not share template: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    // ── Backup export/import (passphrase-encrypted, fully local — see BackupCrypto) ──────────

    // Shows the passphrase entry dialog for exporting a backup. Both fields may be left blank,
    // in which case a secure random passphrase is generated on the user's behalf — either way,
    // confirmSavePassphrase() below is always shown next before the file is actually written.
    private void promptExportPassphrase() {
        int padPx = (int) (20 * getResources().getDisplayMetrics().density);
        LinearLayout container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(padPx, padPx / 2, padPx, 0);

        EditText passInput = new EditText(this);
        passInput.setHint("Leave blank to auto-generate a secure passphrase");
        passInput.setInputType(android.text.InputType.TYPE_CLASS_TEXT
                | android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD);
        container.addView(passInput);

        EditText confirmInput = new EditText(this);
        confirmInput.setHint("Confirm passphrase");
        confirmInput.setInputType(android.text.InputType.TYPE_CLASS_TEXT
                | android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.topMargin = padPx / 2;
        confirmInput.setLayoutParams(lp);
        container.addView(confirmInput);

        new AlertDialog.Builder(this)
                .setTitle("Export Backup")
                .setMessage("Set a passphrase to protect this backup, or leave both fields blank "
                        + "and Bujit will generate one for you.")
                .setView(container)
                .setPositiveButton("Next", (d, w) -> {
                    String pass = passInput.getText() != null ? passInput.getText().toString() : "";
                    String confirm = confirmInput.getText() != null ? confirmInput.getText().toString() : "";
                    if (pass.isEmpty() && confirm.isEmpty()) {
                        confirmSavePassphrase(BackupCrypto.generatePassphrase());
                    } else if (!pass.equals(confirm)) {
                        Toast.makeText(this, "Passphrases don't match", Toast.LENGTH_SHORT).show();
                        promptExportPassphrase();
                    } else if (pass.length() < 8) {
                        Toast.makeText(this, "Passphrase must be at least 8 characters", Toast.LENGTH_SHORT).show();
                        promptExportPassphrase();
                    } else {
                        confirmSavePassphrase(pass);
                    }
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    // Mandatory checkpoint shown for every export, regardless of whether the passphrase was
    // self-chosen or generated — Bujit never stores it, so this is the user's only chance to
    // record it before continuing.
    private void confirmSavePassphrase(String passphrase) {
        int padPx = (int) (20 * getResources().getDisplayMetrics().density);
        TextView passphraseView = new TextView(this);
        passphraseView.setText(passphrase);
        passphraseView.setTextIsSelectable(true);
        passphraseView.setTextSize(18f);
        passphraseView.setTypeface(android.graphics.Typeface.MONOSPACE);
        passphraseView.setGravity(android.view.Gravity.CENTER);
        passphraseView.setPadding(padPx, padPx, padPx, padPx / 2);

        new AlertDialog.Builder(this)
                .setTitle("Save Your Passphrase")
                .setView(passphraseView)
                .setMessage("Bujit does not store this passphrase anywhere and cannot recover "
                        + "your backup without it. Write it down or save it somewhere safe before continuing.")
                .setCancelable(false)
                .setPositiveButton("I've Saved It — Export", (d, w) -> {
                    pendingExportPassphrase = passphrase.toCharArray();
                    exportBackupLauncher.launch(defaultBackupFilename());
                })
                .setNegativeButton("Go Back", (d, w) -> promptExportPassphrase())
                .show();
    }

    // Builds a dated default filename for the exported backup, e.g. "bujit_backup_2026-07-15.bujitbackup".
    private String defaultBackupFilename() {
        return "bujit_backup_" + LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE) + ".bujitbackup";
    }

    // Serializes and passphrase-encrypts the current data, then writes it to the chosen file.
    // Runs off the UI thread since PBKDF2 key derivation is deliberately slow.
    private void performBackupExport(Uri uri, char[] passphrase) {
        AlertDialog loading = new AlertDialog.Builder(this)
                .setTitle("Exporting…")
                .setView(new ProgressBar(this))
                .setCancelable(false)
                .create();
        loading.show();
        backupExecutor.execute(() -> {
            try {
                StorageManager sm = new StorageManager(getApplicationContext());
                String json = sm.exportJson(sm.getStorageHolder());
                String envelope = BackupCrypto.encrypt(json, passphrase);
                try (OutputStream os = getContentResolver().openOutputStream(uri)) {
                    if (os != null) os.write(envelope.getBytes(StandardCharsets.UTF_8));
                }
                backupMainHandler.post(() -> {
                    loading.dismiss();
                    Toast.makeText(this, "Backup exported", Toast.LENGTH_SHORT).show();
                });
            } catch (Exception e) {
                backupMainHandler.post(() -> {
                    loading.dismiss();
                    Toast.makeText(this, "Could not export backup: " + e.getMessage(), Toast.LENGTH_LONG).show();
                });
            } finally {
                Arrays.fill(passphrase, '\0');
            }
        });
    }

    // Prompts for the passphrase used to create the selected backup file.
    private void promptImportPassphrase(Uri uri) {
        int padPx = (int) (20 * getResources().getDisplayMetrics().density);
        LinearLayout container = new LinearLayout(this);
        container.setOrientation(LinearLayout.VERTICAL);
        container.setPadding(padPx, padPx / 2, padPx, 0);

        EditText passInput = new EditText(this);
        passInput.setHint("Passphrase");
        passInput.setInputType(android.text.InputType.TYPE_CLASS_TEXT
                | android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD);
        container.addView(passInput);

        new AlertDialog.Builder(this)
                .setTitle("Import Backup")
                .setMessage("Enter the passphrase used to create this backup.")
                .setView(container)
                .setPositiveButton("Import", (d, w) -> {
                    String pass = passInput.getText() != null ? passInput.getText().toString() : "";
                    performBackupDecrypt(uri, pass.toCharArray());
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    // Reads and decrypts the selected file off the UI thread. Current data is left completely
    // untouched on any failure — the destructive-overwrite confirmation only appears after a
    // successful decrypt, so a wrong passphrase never puts existing data at risk.
    private void performBackupDecrypt(Uri uri, char[] passphrase) {
        AlertDialog loading = new AlertDialog.Builder(this)
                .setTitle("Reading backup…")
                .setView(new ProgressBar(this))
                .setCancelable(false)
                .create();
        loading.show();
        backupExecutor.execute(() -> {
            try {
                String envelopeText = readUriAsString(uri);
                String json;
                try {
                    json = BackupCrypto.decrypt(envelopeText, passphrase);
                } catch (BackupCrypto.BackupCryptoException e) {
                    backupMainHandler.post(() -> {
                        loading.dismiss();
                        showBackupErrorDialog(e);
                    });
                    return;
                }
                StorageManager sm = new StorageManager(getApplicationContext());
                StorageHolder restored = sm.importJson(json);
                String exportedAt = BackupCrypto.readExportedAt(envelopeText);
                backupMainHandler.post(() -> {
                    loading.dismiss();
                    confirmOverwriteWithBackup(sm, restored, exportedAt);
                });
            } catch (Exception e) {
                backupMainHandler.post(() -> {
                    loading.dismiss();
                    Toast.makeText(this, "Could not read backup file: " + e.getMessage(), Toast.LENGTH_LONG).show();
                });
            } finally {
                Arrays.fill(passphrase, '\0');
            }
        });
    }

    // Reads the full text contents of a picked SAF Uri.
    private String readUriAsString(Uri uri) throws Exception {
        try (InputStream is = getContentResolver().openInputStream(uri)) {
            if (is == null) throw new java.io.IOException("Could not open file");
            BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) sb.append(line);
            return sb.toString();
        }
    }

    // Maps a decrypt failure reason to a user-facing explanation. Wrong-passphrase and
    // corrupted-file collapse into the same message since AES-GCM can't distinguish them.
    private void showBackupErrorDialog(BackupCrypto.BackupCryptoException e) {
        String title;
        String message;
        switch (e.reason) {
            case UNSUPPORTED_VERSION:
                title = "Update Required";
                message = "This backup was created with a newer version of Bujit and can't be "
                        + "read by this version. Please update the app and try again.";
                break;
            case MALFORMED_ENVELOPE:
                title = "Not a Backup File";
                message = "This doesn't look like a Bujit backup file. Please select a "
                        + ".bujitbackup file exported from Bujit.";
                break;
            case WRONG_PASSPHRASE_OR_CORRUPT:
            default:
                title = "Import Failed";
                message = "Incorrect passphrase, or this file is corrupted. Please check the "
                        + "passphrase and try again.";
                break;
        }
        new AlertDialog.Builder(this)
                .setTitle(title)
                .setMessage(message)
                .setPositiveButton("OK", null)
                .show();
    }

    // Confirms the destructive overwrite now that the backup has been verified as valid —
    // shown only after a successful decrypt, so it can reference the actual export date.
    private void confirmOverwriteWithBackup(StorageManager sm, StorageHolder restored, String exportedAt) {
        String dateText = exportedAt != null ? " from " + exportedAt : "";
        new AlertDialog.Builder(this)
                .setTitle("Import Backup")
                .setMessage("Import backup" + dateText + "? This will replace all current data "
                        + "on this device. This cannot be undone.")
                .setPositiveButton("Import", (d, w) -> performBackupWrite(sm, restored))
                .setNegativeButton("Cancel", null)
                .show();
    }

    // Persists the restored data and relaunches ExpenseActivity fresh, mirroring
    // performClearData() — but unlike a full clear, SharedPreferences (theme, App Lock, linked
    // bank tokens) are device-local settings that are NOT part of the portable backup and must
    // survive a restore untouched.
    private void performBackupWrite(StorageManager sm, StorageHolder restored) {
        AlertDialog loading = new AlertDialog.Builder(this)
                .setTitle("Restoring…")
                .setView(new ProgressBar(this))
                .setCancelable(false)
                .create();
        loading.show();
        backupExecutor.execute(() -> {
            try {
                sm.writeData(restored);
                backupMainHandler.post(() -> {
                    loading.dismiss();
                    Intent intent = new Intent(this, ExpenseActivity.class);
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    startActivity(intent);
                    finish();
                });
            } catch (Exception e) {
                backupMainHandler.post(() -> {
                    loading.dismiss();
                    Toast.makeText(this, "Could not restore backup: " + e.getMessage(), Toast.LENGTH_LONG).show();
                });
            }
        });
    }

    // Resets the guided tutorial's progress and closes Settings so it replays from the start.
    private void startTutorial() {
        TutorialManager.reset(this);
        finish();
    }

    // Opens the GitHub "new issue" page in the device browser for bug reports/suggestions.
    private void openHelpEmail() {
        Intent intent = new Intent(Intent.ACTION_VIEW,
                Uri.parse("https://github.com/Nishian3695/Bujit/issues/new"));
        try {
            startActivity(intent);
        } catch (android.content.ActivityNotFoundException e) {
            Toast.makeText(this, "No browser found", Toast.LENGTH_SHORT).show();
        }
    }

    // Opens Bujit's own privacy policy in the device browser.
    private void openPrivacyPolicy() {
        openUrl("https://nishian3695.github.io/Bujit/privacy-policy.html");
    }

    // Opens the banking provider's (Plaid's) privacy statement in the device browser.
    private void openTellerPrivacy() {
        openUrl("https://plaid.com/legal/#privacy-statement");
    }

    // Opens Bujit's Play Store listing for rating, preferring the Play Store app itself and
    // falling back to the web listing if it isn't installed.
    private void openPlayStoreListing() {
        try {
            startActivity(new Intent(Intent.ACTION_VIEW,
                    Uri.parse("market://details?id=" + getPackageName())));
        } catch (android.content.ActivityNotFoundException e) {
            openUrl("https://play.google.com/store/apps/details?id=" + getPackageName());
        }
    }

    // Opens a URL in the device's default browser, showing a toast if none is available.
    private void openUrl(String url) {
        Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        try {
            startActivity(intent);
        } catch (android.content.ActivityNotFoundException e) {
            Toast.makeText(this, "No browser found", Toast.LENGTH_SHORT).show();
        }
    }

    // Shows the "not a financial advisor" legal disclaimer text in a dialog.
    private void showDisclaimer() {
        new AlertDialog.Builder(this)
                .setTitle("Disclaimer")
                .setMessage(getString(R.string.disclaimer_text))
                .setPositiveButton("OK", null)
                .show();
    }

    // Resumes the guided tutorial if this screen still has unfinished tutorial steps.
    @Override
    protected void onResume() {
        super.onResume();
        maybeShowTutorial();
    }

    // Removes any active tutorial overlay so it doesn't leak past this screen's lifecycle.
    @Override
    protected void onPause() {
        removeTutorialOverlay();
        super.onPause();
    }

    // Kicks off the tutorial's current step, but only if this activity still has steps left to show.
    private void maybeShowTutorial() {
        if (!TutorialManager.hasStepsForActivity(this, SettingsActivity.class)) return;
        showTutorialStep(TutorialManager.getCurrentStep(this));
    }

    // Renders a single tutorial overlay step (spotlight + text bubble), wiring "Next"/"Skip" to
    // advance to the next step or return home once the tutorial finishes.
    private void showTutorialStep(int step) {
        TutorialManager.StepDef def = TutorialManager.STEPS[step];
        removeTutorialOverlay();
        tutorialOverlay = new TutorialOverlayLayout(this);

        View target = def.viewId != 0 ? findViewById(def.viewId) : null;
        boolean isLast = (step == TutorialManager.STEPS.length - 1);
        String nextText = def.nextActivity != null ? "Next ›" : (isLast ? "Done" : "Next");

        tutorialOverlay.showStep(target, def.title, def.message, nextText,
            () -> {
                TutorialManager.advance(this);
                removeTutorialOverlay();
                if (TutorialManager.hasStepsForActivity(this, SettingsActivity.class)) {
                    showTutorialStep(TutorialManager.getCurrentStep(this));
                } else {
                    Intent home = new Intent(this, ExpenseActivity.class);
                    home.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                    startActivity(home);
                }
            },
            () -> {
                TutorialManager.markDone(this);
                removeTutorialOverlay();
                Intent home = new Intent(this, ExpenseActivity.class);
                home.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                startActivity(home);
            });

        ((ViewGroup) getWindow().getDecorView())
                .addView(tutorialOverlay, new ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT));
    }

    // Detaches the tutorial overlay view from the window decor, if one is currently showing.
    private void removeTutorialOverlay() {
        if (tutorialOverlay != null) {
            ViewGroup p = (ViewGroup) tutorialOverlay.getParent();
            if (p != null) p.removeView(tutorialOverlay);
            tutorialOverlay = null;
        }
    }

    // Converts a dp value to actual pixels for this device's screen density.
    private float dpToPx(int dp) {
        return dp * getResources().getDisplayMetrics().density;
    }

    // ── Tip jar / billing ────────────────────────────────────────────────────

    // Connects to the Play Billing service and queries the tip jar products once ready.
    private void setupBilling() {
        billingClient = BillingClient.newBuilder(this)
                .setListener(this::onPurchasesUpdated)
                .enablePendingPurchases(
                        PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
                .build();
        billingClient.startConnection(new BillingClientStateListener() {
            @Override
            public void onBillingSetupFinished(@NonNull BillingResult result) {
                Log.d(BILLING_TAG, "onBillingSetupFinished: code=" + result.getResponseCode()
                        + " msg=" + result.getDebugMessage());
                if (result.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                    queryTipProducts();
                }
            }
            @Override
            public void onBillingServiceDisconnected() {
                Log.d(BILLING_TAG, "onBillingServiceDisconnected");
            }
        });
    }

    // Fetches Play Store pricing for the three one-time tip products and updates each button's
    // label with its localized price once the data comes back.
    private void queryTipProducts() {
        List<QueryProductDetailsParams.Product> products = Arrays.asList(
                QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(TIP_SMALL).setProductType(BillingClient.ProductType.INAPP).build(),
                QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(TIP_MEDIUM).setProductType(BillingClient.ProductType.INAPP).build(),
                QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(TIP_LARGE).setProductType(BillingClient.ProductType.INAPP).build()
        );
        billingClient.queryProductDetailsAsync(
                QueryProductDetailsParams.newBuilder().setProductList(products).build(),
                (billingResult, detailsList) -> {
                    Log.d(BILLING_TAG, "queryProductDetails: code=" + billingResult.getResponseCode()
                            + " count=" + detailsList.size()
                            + " msg=" + billingResult.getDebugMessage());
                    for (ProductDetails pd : detailsList) {
                        Log.d(BILLING_TAG, "  found product: " + pd.getProductId());
                        tipProducts.put(pd.getProductId(), pd);
                        updateTipButton(pd);
                    }
                });
    }

    // Sets one tip button's label to an emoji + its formatted Play Store price.
    private void updateTipButton(ProductDetails pd) {
        if (pd.getOneTimePurchaseOfferDetails() == null) return;
        String price = pd.getOneTimePurchaseOfferDetails().getFormattedPrice();
        String id = pd.getProductId();
        runOnUiThread(() -> {
            if (TIP_SMALL.equals(id))       btnTipSmall.setText("☕  " + price);
            else if (TIP_MEDIUM.equals(id)) btnTipMedium.setText("🍕  " + price);
            else if (TIP_LARGE.equals(id))  btnTipLarge.setText("❤️  " + price);
        });
    }

    // Launches the Play Billing purchase flow for the given tip product.
    private void launchTip(String productId) {
        ProductDetails pd = tipProducts.get(productId);
        if (pd == null) {
            Toast.makeText(this, "Store unavailable — try again later", Toast.LENGTH_SHORT).show();
            return;
        }
        BillingFlowParams params = BillingFlowParams.newBuilder()
                .setProductDetailsParamsList(Collections.singletonList(
                        BillingFlowParams.ProductDetailsParams.newBuilder()
                                .setProductDetails(pd)
                                .build()))
                .build();
        billingClient.launchBillingFlow(this, params);
    }

    // BillingClient listener: consumes each completed tip purchase immediately (tips are one-time,
    // non-refundable "consumable" products) and thanks the user once the consume succeeds.
    private void onPurchasesUpdated(BillingResult result, List<Purchase> purchases) {
        if (result.getResponseCode() != BillingClient.BillingResponseCode.OK || purchases == null) return;
        for (Purchase purchase : purchases) {
            ConsumeParams consumeParams = ConsumeParams.newBuilder()
                    .setPurchaseToken(purchase.getPurchaseToken())
                    .build();
            billingClient.consumeAsync(consumeParams, (consumeResult, token) -> {
                if (consumeResult.getResponseCode() == BillingClient.BillingResponseCode.OK) {
                    runOnUiThread(() -> Toast.makeText(this,
                            "Thank you for your support!", Toast.LENGTH_LONG).show());
                }
            });
        }
    }

    // Closes the Play Billing connection so it doesn't leak past this activity's lifecycle.
    @Override
    protected void onDestroy() {
        if (billingClient != null) billingClient.endConnection();
        if (backupExecutor != null) backupExecutor.shutdown();
        super.onDestroy();
    }
}
