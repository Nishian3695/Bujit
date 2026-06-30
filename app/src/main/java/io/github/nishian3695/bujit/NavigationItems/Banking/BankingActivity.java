package io.github.nishian3695.bujit.NavigationItems.Banking;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.webkit.WebView;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.textfield.TextInputLayout;
import com.google.firebase.auth.FirebaseAuth;
import io.github.nishian3695.bujit.BuildConfig;
import io.github.nishian3695.bujit.CustomListeners.CurrencyEditTextWatcher;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import io.github.nishian3695.bujit.ThemeHelper;
import io.github.nishian3695.bujit.Tutorial.TutorialManager;
import io.github.nishian3695.bujit.Tutorial.TutorialOverlayLayout;
import android.view.ViewGroup;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import io.teller.connect.sdk.Config;
import io.teller.connect.sdk.ConnectFragment;
import io.teller.connect.sdk.ConnectListener;
import io.teller.connect.sdk.Environment;
import io.teller.connect.sdk.Error;
import io.teller.connect.sdk.Payee;
import io.teller.connect.sdk.Payment;
import io.teller.connect.sdk.Registration;
import androidx.activity.result.ActivityResultLauncher;
import com.plaid.link.OpenPlaidLink;
import com.plaid.link.configuration.LinkTokenConfiguration;
import com.plaid.link.result.LinkExit;
import com.plaid.link.result.LinkResult;
import com.plaid.link.result.LinkSuccess;

/*
Activity for connecting bank accounts via Teller or Plaid (compile-time switch in
BankingProviderConfig). On first open the user taps "Connect Bank" to launch the
provider's SDK. On success the access token is encrypted with AES-256-GCM via the
Android Keystore and stored by BankingPrefs. Multiple banks can be connected; tokens
are kept as a set.

On subsequent opens all stored tokens are fetched in the background and the combined
account list is displayed. Firebase anonymous sign-in is performed silently so the
Cloud Function backend can verify the caller.

Disconnecting a bank revokes the token server-side, then removes it locally and
deletes any credit expenses linked to accounts belonging to that enrollment.
*/
public class BankingActivity extends AppCompatActivity implements ConnectListener {

    private static final String TAG = "BujitBanking";
    private FirebaseAuth mAuth;
    private static final String      TELLER_APP_ID = BuildConfig.TELLER_APP_ID;
    private static final Environment TELLER_ENV    = BankingProviderConfig.TELLER_ENV;
    private View         connectContainer;
    private RecyclerView accountList;
    private ProgressBar  progressBar;
    private View         emptyState;
    private Button       connectBtn;
    private Button       disconnectBtn;
    private BankAccountAdapter adapter;
    private TutorialOverlayLayout tutorialOverlay;
    private final List<BankAccountModel>  accounts       = new ArrayList<>();
    private final List<ManualAccountModel> manualAccounts = new ArrayList<>();
    private RecyclerView      manualAccountList;
    private ManualAccountAdapter manualAdapter;
    private TextView          manualEmptyState;
    private final ExecutorService executor    = Executors.newSingleThreadExecutor();
    private final Handler         mainHandler = new Handler(Looper.getMainLooper());

    public static final String KEY_MANUAL_ACCOUNTS_CHANGED = "manual_accounts_changed";

    private static final String[] ACCOUNT_TYPE_OPTIONS =
            {"Checking", "Savings", "Cash", "Investment", "Other"};

    // Plaid Link SDK launcher, registered in onCreate, only used when ACTIVE_PROVIDER == PLAID
    private ActivityResultLauncher<LinkTokenConfiguration> plaidLauncher;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);

        // One-time migration: re-encrypts stored tokens under the current v4 key.
        BankingPrefs.migrateIfNeeded(this);

        // Plaid launcher must be registered before the Activity reaches STARTED state.
        if (BankingProviderConfig.ACTIVE_PROVIDER == BankingProviderConfig.Provider.PLAID) {
            plaidLauncher = registerForActivityResult(
                    new OpenPlaidLink(),
                    this::handlePlaidResult
            );
        }
        WebView.setWebContentsDebuggingEnabled(false);
        setContentView(R.layout.activity_banking);
        ThemeHelper.tintActionBar(this);
        ViewCompat.setOnApplyWindowInsetsListener(
                ((android.view.ViewGroup) findViewById(android.R.id.content)).getChildAt(0),
                (v, windowInsets) -> {
                    Insets insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars());
                    v.setPadding(0, insets.top, 0, insets.bottom);
                    return WindowInsetsCompat.CONSUMED;
                });

        // Back arrow in ActionBar
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Accounts");
        }

        connectContainer = findViewById(R.id.connect_container);
        accountList      = findViewById(R.id.banking_account_list);
        progressBar      = findViewById(R.id.banking_progress);
        emptyState       = findViewById(R.id.banking_empty_state);
        connectBtn       = findViewById(R.id.btn_connect_bank);
        disconnectBtn    = findViewById(R.id.btn_disconnect_bank);
        manualAccountList  = findViewById(R.id.manual_account_list);
        manualEmptyState   = findViewById(R.id.manual_empty_state);

        adapter = new BankAccountAdapter(this, accounts);
        accountList.setLayoutManager(new LinearLayoutManager(this));
        accountList.setAdapter(adapter);

        manualAdapter = new ManualAccountAdapter(this, manualAccounts,
                (account, position) -> showManualAccountDialog(account, position));
        manualAccountList.setLayoutManager(new LinearLayoutManager(this));
        manualAccountList.setAdapter(manualAdapter);

        loadManualAccounts();

        findViewById(R.id.btn_add_manual_account).setOnClickListener(
                v -> showManualAccountDialog(null, -1));

        connectBtn.setOnClickListener(v -> {
            if (BankingProviderConfig.ACTIVE_PROVIDER == BankingProviderConfig.Provider.PLAID) {
                launchPlaidLink();
            } else {
                launchTellerConnect();
            }
        });
        disconnectBtn.setOnClickListener(v -> confirmDisconnect());

        mAuth = FirebaseAuth.getInstance();
        if (mAuth.getCurrentUser() == null) {
            // Sign in anonymously. Silent, no prompt. Gives the Cloud Function
            // a verifiable token without requiring the user to have a Google account.
            mAuth.signInAnonymously().addOnCompleteListener(this, task -> {
                if (task.isSuccessful()) {
                    Log.d(TAG, "Anonymous Firebase sign-in successful");
                    loadAccountsIfAny();
                } else {
                    Exception ex = task.getException();
                    Log.e(TAG, "Anonymous sign-in failed: " + (ex != null ? ex.getMessage() : "unknown"));
                    Toast.makeText(this, "Could not connect to banking service", Toast.LENGTH_LONG).show();
                }
            });
        } else {
            loadAccountsIfAny();
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    private void loadAccountsIfAny() {
        Set<String> tokens = loadAllTokens();
        if (!tokens.isEmpty()) {
            Log.d(TAG, "loadAccountsIfAny: " + tokens.size() + " stored token(s) — fetching accounts");
            fetchAndShowAllAccounts(tokens);
        } else {
            Log.d(TAG, "loadAccountsIfAny: no stored tokens — showing empty state");
            showEmptyState();
        }
    }

    // Plaid Link SDK
    private void launchPlaidLink() {
        showLoading();
        executor.execute(() -> {
            try {
                String idToken = BankingProviderConfig.fetchFirebaseIdToken();
                String appCheckToken = BankingProviderConfig.fetchAppCheckToken();
                String linkToken = PlaidBackendClient.fetchLinkToken(this, idToken, appCheckToken);
                String finalLinkToken = linkToken;
                mainHandler.post(() -> {
                    LinkTokenConfiguration config = new LinkTokenConfiguration.Builder()
                            .token(finalLinkToken)
                            .build();
                    plaidLauncher.launch(config);
                    // Restore UI while the Plaid Activity is in the foreground
                    if (accounts.isEmpty()) showEmptyState();
                    else showAccountList();
                });
            } catch (Exception e) {
                Log.e(TAG, "launchPlaidLink: failed to fetch link token: " + e.getMessage(), e);
                mainHandler.post(() -> {
                    Toast.makeText(this, "Failed to start bank connection", Toast.LENGTH_LONG).show();
                    if (accounts.isEmpty()) showEmptyState();
                    else showAccountList();
                });
            }
        });
    }

    private void handlePlaidResult(LinkResult result) {
        if (result instanceof LinkSuccess) {
            String publicToken = ((LinkSuccess) result).getPublicToken();
            Log.d(TAG, "handlePlaidResult: success, exchanging public token");
            exchangePlaidPublicToken(publicToken);
        } else if (result instanceof LinkExit) {
            LinkExit exit = (LinkExit) result;
            if (exit.getError() != null) {
                Log.e(TAG, "handlePlaidResult: exit error=" + exit.getError().getErrorCode()
                        + " message=" + exit.getError().getErrorMessage());
            } else {
                Log.d(TAG, "handlePlaidResult: user exited without linking");
            }
            if (accounts.isEmpty()) showEmptyState();
        }
    }

    private void exchangePlaidPublicToken(String publicToken) {
        showLoading();
        executor.execute(() -> {
            try {
                String idToken = BankingProviderConfig.fetchFirebaseIdToken();
                String appCheckToken = BankingProviderConfig.fetchAppCheckToken();
                String accessToken = PlaidBackendClient.exchangePublicToken(this, publicToken, idToken, appCheckToken);
                Log.d(TAG, "exchangePlaidPublicToken: access token received");
                addPlaidToken(accessToken);
                Set<String> tokens = loadAllTokens();
                mainHandler.post(() -> fetchAndShowAllAccounts(tokens));
            } catch (Exception e) {
                Log.e(TAG, "exchangePlaidPublicToken: failed: " + e.getMessage(), e);
                mainHandler.post(() -> {
                    Toast.makeText(this, "Failed to complete bank connection", Toast.LENGTH_LONG).show();
                    if (accounts.isEmpty()) showEmptyState();
                    else showAccountList();
                });
            }
        });
    }

    // Teller Connect SDK
    private void launchTellerConnect() {
        Log.d(TAG, "launchTellerConnect: appId=" + TELLER_APP_ID + " env=" + TELLER_ENV);
        Config config = new Config(
                TELLER_APP_ID, TELLER_ENV,
                null, null, Collections.emptyList(),
                false, null, null, null, null,
                Collections.emptyMap(), true
        );
        Bundle args = ConnectFragment.Companion.buildArgs(config);
        ConnectFragment fragment = new ConnectFragment();
        fragment.setArguments(args);

        connectContainer.setVisibility(View.VISIBLE);
        getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.connect_container, fragment)
                .commit();
        Log.d(TAG, "ConnectFragment launched");
    }

    private void dismissConnectFragment() {
        connectContainer.setVisibility(View.GONE);
        ConnectFragment fragment = (ConnectFragment) getSupportFragmentManager()
                .findFragmentById(R.id.connect_container);
        if (fragment != null) {
            getSupportFragmentManager().beginTransaction().remove(fragment).commit();
        }
    }

    @Override
    public void onInit() {
        Log.d(TAG, "onInit: Connect WebView ready");
    }

    @Override
    public void onSuccess(Registration registration) {
        String token = registration.getAccessToken();
        Log.d(TAG, "onSuccess: new enrollment token received, enrollmentId="
                + registration.getEnrollment().getId());
        // Add to the existing set
        addToken(token);
        dismissConnectFragment();
        Set<String> tokens = loadAllTokens();
        fetchAndShowAllAccounts(tokens);
    }

    @Override public void onSuccess(Payment payment) { Log.d(TAG, "onSuccess(Payment)"); }
    @Override public void onSuccess(Payee payee)     { Log.d(TAG, "onSuccess(Payee)"); }

    @Override
    public void onExit() {
        Log.d(TAG, "onExit: user dismissed Connect without enrolling");
        dismissConnectFragment();
        if (accounts.isEmpty()) showEmptyState();
    }

    @Override
    public void onFailure(Error error) {
        Log.e(TAG, "onFailure: type=" + error.getType()
                + " code=" + error.getCode()
                + " message=" + error.getMessage());
        dismissConnectFragment();
        Toast.makeText(this,
                "Connection failed [" + error.getCode() + "]: " + error.getMessage(),
                Toast.LENGTH_LONG).show();
        if (accounts.isEmpty()) showEmptyState();
    }

    @Override
    public void onEvent(String name, Map<String, ? extends Object> data) {
        Log.d(TAG, "onEvent: " + name);
    }

    // Fetches accounts from every stored token and merges them into one list.
    // If a token returns BankingAuthException (HTTP 401), it is removed locally and the
    // user is offered a chance to re-link. All other tokens are still fetched.
    private void fetchAndShowAllAccounts(Set<String> tokens) {
        showLoading();
        Log.d(TAG, "fetchAndShowAllAccounts: " + tokens.size() + " token(s)");
        executor.execute(() -> {
            String idToken = BankingProviderConfig.fetchFirebaseIdToken();
            String appCheckToken = BankingProviderConfig.fetchAppCheckToken();
            List<BankAccountModel> allAccounts = new ArrayList<>();
            boolean hadAuthError = false;
            for (String token : tokens) {
                try {
                    List<BankAccountModel> fetched =
                            BankingProviderConfig.createClient(this, token, idToken, appCheckToken).fetchAccounts();
                    Log.d(TAG, "  token → " + fetched.size() + " account(s)");
                    allAccounts.addAll(fetched);
                } catch (BankingAuthException e) {
                    Log.w(TAG, "  token revoked/expired — removing locally: " + e.getMessage());
                    hadAuthError = true;
                    // Remove the invalid token so it doesn't keep failing on next load.
                    Set<String> remaining = new HashSet<>(loadAllTokens());
                    remaining.remove(token);
                    saveAllTokens(remaining);
                } catch (Exception e) {
                    Log.e(TAG, "  token fetch failed: " + e.getMessage(), e);
                }
            }
            final boolean showRelink = hadAuthError;
            mainHandler.post(() -> {
                accounts.clear();
                accounts.addAll(allAccounts);
                adapter.notifyDataSetChanged();
                Log.d(TAG, "fetchAndShowAllAccounts: displaying " + allAccounts.size() + " total accounts");
                if (accounts.isEmpty()) showEmptyState();
                else showAccountList();
                if (showRelink) {
                    new AlertDialog.Builder(this)
                            .setTitle("Bank Connection Expired")
                            .setMessage("One or more bank connections have been revoked or expired. " +
                                    "Tap \"Reconnect\" to re-link your account.")
                            .setPositiveButton("Reconnect", (d, w) -> connectBtn.performClick())
                            .setNegativeButton("Dismiss", null)
                            .show();
                }
            });
        });
    }

    // Saves a full set of tokens back to encrypted storage for the active provider.
    private void saveAllTokens(Set<String> tokens) {
        if (BankingProviderConfig.ACTIVE_PROVIDER == BankingProviderConfig.Provider.PLAID) {
            BankingPrefs.savePlaidTokens(this, tokens);
        } else {
            BankingPrefs.saveTokens(this, tokens);
        }
    }

    private void confirmDisconnect() {
        // Build ordered map of token → institution name, deduplicating by token.
        Map<String, String> tokenToInstitution = new LinkedHashMap<>();
        for (BankAccountModel account : accounts) {
            String tok = account.getToken();
            if (tok != null && !tokenToInstitution.containsKey(tok)) {
                tokenToInstitution.put(tok, account.getInstitutionName());
            }
        }

        String[] institutionNames = tokenToInstitution.values().toArray(new String[0]);
        String[] tokenArray       = tokenToInstitution.keySet().toArray(new String[0]);
        boolean[] checkedState    = new boolean[tokenArray.length];

        new AlertDialog.Builder(this)
                .setTitle("Disconnect Banks")
                .setMultiChoiceItems(institutionNames, checkedState,
                        (dialog, which, isChecked) -> checkedState[which] = isChecked)
                .setPositiveButton("Disconnect Selected", (d, w) -> {
                    Set<String> toRemove = new HashSet<>();
                    List<String> namesToRemove = new ArrayList<>();
                    for (int i = 0; i < tokenArray.length; i++) {
                        if (checkedState[i]) {
                            toRemove.add(tokenArray[i]);
                            namesToRemove.add(institutionNames[i]);
                        }
                    }
                    if (toRemove.isEmpty()) return;
                    String msg = namesToRemove.size() == 1
                            ? "Disconnect from " + namesToRemove.get(0) + "? This cannot be undone."
                            : "Disconnect from " + namesToRemove.size() + " banks? This cannot be undone.";
                    new AlertDialog.Builder(this)
                            .setTitle("Are you sure?")
                            .setMessage(msg)
                            .setPositiveButton("Disconnect", (d2, w2) -> {
                                Log.d(TAG, "User disconnecting " + toRemove.size() + " bank(s)");
                                showLoading();
                                // Revoke tokens server-side first, then clean up locally.
                                executor.execute(() -> {
                                    String idToken = BankingProviderConfig.fetchFirebaseIdToken();
                                    String appCheckToken = BankingProviderConfig.fetchAppCheckToken();
                                    for (String tok : toRemove) {
                                        BankingProviderConfig.revokeToken(this, tok, idToken, appCheckToken);
                                    }
                                    mainHandler.post(() -> {
                                        removeLinkedExpensesForTokens(toRemove);
                                        removeTokens(toRemove);
                                        Set<String> remaining = loadAllTokens();
                                        if (remaining.isEmpty()) {
                                            accounts.clear();
                                            adapter.notifyDataSetChanged();
                                            showEmptyState();
                                        } else {
                                            fetchAndShowAllAccounts(remaining);
                                        }
                                    });
                                });
                            })
                            .setNegativeButton("Cancel", null)
                            .show();
                })
                .setNeutralButton("Disconnect All", (d, w) -> {
                    new AlertDialog.Builder(this)
                            .setTitle("Are you sure?")
                            .setMessage("Disconnect all banks? This cannot be undone.")
                            .setPositiveButton("Disconnect All", (d2, w2) -> {
                                Log.d(TAG, "User disconnected all banks");
                                showLoading();
                                Set<String> allTokens = new HashSet<>(loadAllTokens());
                                executor.execute(() -> {
                                    String idToken = BankingProviderConfig.fetchFirebaseIdToken();
                                    String appCheckToken = BankingProviderConfig.fetchAppCheckToken();
                                    for (String tok : allTokens) {
                                        BankingProviderConfig.revokeToken(this, tok, idToken, appCheckToken);
                                    }
                                    mainHandler.post(() -> {
                                        removeAllLinkedExpenses();
                                        clearAllTokens();
                                        accounts.clear();
                                        adapter.notifyDataSetChanged();
                                        showEmptyState();
                                    });
                                });
                            })
                            .setNegativeButton("Cancel", null)
                            .show();
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    // UI state helpers
    private void showLoading() {
        progressBar.setVisibility(View.VISIBLE);
        emptyState.setVisibility(View.GONE);
        accountList.setVisibility(View.GONE);
        connectBtn.setEnabled(false);
        disconnectBtn.setVisibility(View.GONE);
    }

    private void showEmptyState() {
        progressBar.setVisibility(View.GONE);
        emptyState.setVisibility(View.VISIBLE);
        accountList.setVisibility(View.GONE);
        connectBtn.setEnabled(true);
        connectBtn.setText("Connect Bank");
        connectBtn.setVisibility(View.VISIBLE);
        disconnectBtn.setVisibility(View.GONE);
    }

    private void showAccountList() {
        progressBar.setVisibility(View.GONE);
        emptyState.setVisibility(View.GONE);
        accountList.setVisibility(View.VISIBLE);
        connectBtn.setEnabled(true);
        connectBtn.setText("Add Account");
        disconnectBtn.setVisibility(View.VISIBLE);
    }

    // Token storage -- one per enrolled bank, routed to the active provider's namespace

    private Set<String> loadAllTokens() {
        if (BankingProviderConfig.ACTIVE_PROVIDER == BankingProviderConfig.Provider.PLAID) {
            return BankingPrefs.loadPlaidTokens(this);
        }
        return BankingPrefs.loadTokens(this);
    }

    // Teller enrollment callback path
    private void addToken(String token) {
        Set<String> tokens = new HashSet<>(BankingPrefs.loadTokens(this));
        tokens.add(token);
        BankingPrefs.saveTokens(this, tokens);
    }

    // Plaid exchange callback path
    private void addPlaidToken(String token) {
        Set<String> tokens = new HashSet<>(BankingPrefs.loadPlaidTokens(this));
        tokens.add(token);
        BankingPrefs.savePlaidTokens(this, tokens);
    }

    private void clearAllTokens() {
        if (BankingProviderConfig.ACTIVE_PROVIDER == BankingProviderConfig.Provider.PLAID) {
            BankingPrefs.clearPlaid(this);
        } else {
            BankingPrefs.clear(this);
        }
    }

    private void removeTokens(Set<String> tokensToRemove) {
        if (BankingProviderConfig.ACTIVE_PROVIDER == BankingProviderConfig.Provider.PLAID) {
            Set<String> current = new HashSet<>(BankingPrefs.loadPlaidTokens(this));
            current.removeAll(tokensToRemove);
            if (current.isEmpty()) {
                BankingPrefs.clearPlaid(this);
            } else {
                BankingPrefs.savePlaidTokens(this, current);
            }
        } else {
            Set<String> current = new HashSet<>(BankingPrefs.loadTokens(this));
            current.removeAll(tokensToRemove);
            if (current.isEmpty()) {
                BankingPrefs.clear(this);
            } else {
                BankingPrefs.saveTokens(this, current);
            }
        }
    }

    // Removes any credit expense entries linked to accounts belonging to the given tokens.
    private void removeLinkedExpensesForTokens(Set<String> tokensToRemove) {
        try {
            StorageManager manager = new StorageManager(getApplicationContext());
            StorageHolder holder = manager.getStorageHolder();
            ArrayList<ExpenseModel> list = holder.getExpenseList();
            int before = list.size();
            list.removeIf(e -> {
                if (!e.isLinkedToBank()) return false;
                String accountId = e.getLinkedAccountId();
                for (BankAccountModel account : accounts) {
                    if (accountId.equals(account.getId()) && tokensToRemove.contains(account.getToken())) {
                        return true;
                    }
                }
                // Fallback: check the persisted account→token map when in-memory list is stale
                String storedToken = BankingProviderConfig.ACTIVE_PROVIDER == BankingProviderConfig.Provider.PLAID
                        ? BankingPrefs.getPlaidTokenForAccount(this, accountId)
                        : BankingPrefs.getTokenForAccount(this, accountId);
                return storedToken != null && tokensToRemove.contains(storedToken);
            });
            if (list.size() != before) {
                holder.setExpenseList(list);
                manager.writeData(holder);
                flagExpenseDataChanged();
            }
        } catch (Exception e) {
            Log.e(TAG, "removeLinkedExpensesForTokens failed: " + e.getMessage());
        }
    }

    // Removes all credit expense entries that are linked to any bank account.
    private void removeAllLinkedExpenses() {
        try {
            StorageManager manager = new StorageManager(getApplicationContext());
            StorageHolder holder = manager.getStorageHolder();
            ArrayList<ExpenseModel> list = holder.getExpenseList();
            int before = list.size();
            list.removeIf(ExpenseModel::isLinkedToBank);
            if (list.size() != before) {
                holder.setExpenseList(list);
                manager.writeData(holder);
                flagExpenseDataChanged();
            }
        } catch (Exception e) {
            Log.e(TAG, "removeAllLinkedExpenses failed: " + e.getMessage());
        }
    }

    // Signals ExpenseActivity to reload its in-memory expense list on next resume.
    public static final String PREFS_NAME = "bujit_prefs";
    public static final String KEY_BANKING_EXPENSE_CHANGED = "banking_expense_changed";

    private void flagExpenseDataChanged() {
        getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                .edit().putBoolean(KEY_BANKING_EXPENSE_CHANGED, true).apply();
    }

    // ── Manual accounts ───────────────────────────────────────────────────────

    private void loadManualAccounts() {
        try {
            StorageManager manager = new StorageManager(getApplicationContext());
            List<ManualAccountModel> loaded = manager.getStorageHolder().getManualAccountList();
            manualAccounts.clear();
            manualAccounts.addAll(loaded);
            manualAdapter.notifyDataSetChanged();
            updateManualEmptyState();
        } catch (Exception e) {
            Log.e(TAG, "loadManualAccounts failed: " + e.getMessage());
        }
    }

    private void saveManualAccounts() {
        try {
            StorageManager manager = new StorageManager(getApplicationContext());
            StorageHolder holder = manager.getStorageHolder();
            holder.setManualAccountList(new ArrayList<>(manualAccounts));
            manager.writeData(holder);
            getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                    .edit().putBoolean(KEY_MANUAL_ACCOUNTS_CHANGED, true).apply();
        } catch (Exception e) {
            Log.e(TAG, "saveManualAccounts failed: " + e.getMessage());
            Toast.makeText(this, "Failed to save account", Toast.LENGTH_SHORT).show();
        }
    }

    private void updateManualEmptyState() {
        if (manualAccounts.isEmpty()) {
            manualEmptyState.setVisibility(View.VISIBLE);
            manualAccountList.setVisibility(View.GONE);
        } else {
            manualEmptyState.setVisibility(View.GONE);
            manualAccountList.setVisibility(View.VISIBLE);
        }
    }

    /*
    Shows the add/edit dialog for a manual account.
    Pass null/−1 to add a new one; pass the existing account and its position to edit.
    */
    private void showManualAccountDialog(ManualAccountModel existing, int position) {
        boolean isEdit = (existing != null);

        View dialogView = LayoutInflater.from(this).inflate(R.layout.add_manual_account_layout, null);
        TextInputLayout nameLayout    = dialogView.findViewById(R.id.manual_account_name_layout);
        EditText        nameInput     = dialogView.findViewById(R.id.manual_account_name_input);
        AutoCompleteTextView typeInput = dialogView.findViewById(R.id.manual_account_type_input);
        TextInputLayout balLayout     = dialogView.findViewById(R.id.manual_account_balance_layout);
        EditText        balInput      = dialogView.findViewById(R.id.manual_account_balance_input);

        ArrayAdapter<String> typeAdapter = new ArrayAdapter<>(
                this, R.layout.expense_dropdown_item, ACCOUNT_TYPE_OPTIONS);
        typeInput.setAdapter(typeAdapter);

        if (isEdit) {
            nameInput.setText(existing.getName());
            typeInput.setText(existing.getAccountType(), false);
            balInput.setText(String.format(Locale.US, "%.2f", existing.getBalance()));
        } else {
            typeInput.setText(ACCOUNT_TYPE_OPTIONS[1], false); // default Savings
        }
        balInput.addTextChangedListener(new CurrencyEditTextWatcher(balInput));

        AlertDialog.Builder builder = new AlertDialog.Builder(this)
                .setTitle(isEdit ? "Edit Account" : "Add Account")
                .setView(dialogView)
                .setNegativeButton("Cancel", null)
                .setPositiveButton(isEdit ? "Save" : "Add", null);

        if (isEdit) {
            builder.setNeutralButton("Delete", null);
        }

        AlertDialog dialog = builder.create();
        dialog.setOnShowListener(d -> {
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> {
                String name   = nameInput.getText() != null ? nameInput.getText().toString().trim() : "";
                String type   = typeInput.getText().toString().trim();
                String balStr = balInput.getText() != null ? balInput.getText().toString().trim() : "";

                boolean valid = true;
                if (name.isEmpty()) {
                    nameLayout.setError("Name is required");
                    valid = false;
                } else {
                    nameLayout.setErrorEnabled(false);
                }
                float bal = 0f;
                try { bal = Float.parseFloat(balStr); } catch (NumberFormatException ignored) {}
                if (balStr.isEmpty() || bal < 0) {
                    balLayout.setError("Enter a valid balance");
                    valid = false;
                } else {
                    balLayout.setErrorEnabled(false);
                }
                if (!valid) return;

                if (type.isEmpty()) type = "Other";

                if (isEdit) {
                    existing.setName(name);
                    existing.setAccountType(type);
                    existing.setBalance(bal);
                    manualAccounts.set(position, existing);
                    manualAdapter.notifyItemChanged(position);
                } else {
                    ManualAccountModel newAccount = new ManualAccountModel(name, type, bal);
                    manualAccounts.add(newAccount);
                    manualAdapter.notifyItemInserted(manualAccounts.size() - 1);
                }
                updateManualEmptyState();
                saveManualAccounts();
                dialog.dismiss();
            });

            if (isEdit) {
                dialog.getButton(AlertDialog.BUTTON_NEUTRAL).setOnClickListener(v -> {
                    new AlertDialog.Builder(this)
                            .setTitle("Delete Account")
                            .setMessage("Delete \"" + existing.getName() + "\"? This cannot be undone.")
                            .setPositiveButton("Delete", (d2, w2) -> {
                                manualAccounts.remove(position);
                                manualAdapter.notifyItemRemoved(position);
                                updateManualEmptyState();
                                saveManualAccounts();
                                dialog.dismiss();
                            })
                            .setNegativeButton("Cancel", null)
                            .show();
                });
            }
        });
        dialog.show();
    }

    // ── End manual accounts ───────────────────────────────────────────────────

    @Override
    protected void onResume() {
        super.onResume();
        maybeShowTutorial();
    }

    @Override
    protected void onPause() {
        removeTutorialOverlay();
        super.onPause();
    }

    private void maybeShowTutorial() {
        if (!TutorialManager.hasStepsForActivity(this, BankingActivity.class)) return;
        showTutorialStep(TutorialManager.getCurrentStep(this));
    }

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
                if (def.nextActivity != null) {
                    startActivity(new android.content.Intent(this, def.nextActivity));
                }
            },
            () -> {
                TutorialManager.markDone(this);
                removeTutorialOverlay();
                Intent home = new Intent(this, io.github.nishian3695.bujit.ExpenseActivity.ExpenseActivity.class);
                home.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                startActivity(home);
            });

        ((ViewGroup) getWindow().getDecorView())
                .addView(tutorialOverlay, new ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT));
    }

    private void removeTutorialOverlay() {
        if (tutorialOverlay != null) {
            ViewGroup p = (ViewGroup) tutorialOverlay.getParent();
            if (p != null) p.removeView(tutorialOverlay);
            tutorialOverlay = null;
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        executor.shutdown();
    }
}
