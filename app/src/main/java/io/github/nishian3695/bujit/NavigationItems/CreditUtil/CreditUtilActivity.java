package io.github.nishian3695.bujit.NavigationItems.CreditUtil;

import android.content.Intent;
import android.content.SharedPreferences;
import android.view.MenuItem;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.activity.OnBackPressedCallback;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.CustomListeners.CurrencyFormat;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankingPrefs;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import io.github.nishian3695.bujit.ExpenseActivity.CreditModel;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseItem;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.Interfaces.ClickListener;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankAccountModel;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankingApiClient;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankingProviderConfig;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.appcheck.FirebaseAppCheck;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.ThemeHelper;
import io.github.nishian3695.bujit.Tutorial.TutorialManager;
import io.github.nishian3695.bujit.Tutorial.TutorialOverlayLayout;
import android.view.ViewGroup;
import com.google.android.material.card.MaterialCardView;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.textfield.TextInputLayout;
import java.io.IOException;
import java.io.Serializable;
import java.security.GeneralSecurityException;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/*
Activity for tracking credit card utilization.

The expense list received from ExpenseActivity is split into credit entries
(expenseIsCredit=true) and non-credit entries. Credit entries are shown in a
RecyclerView with color-coded utilization bars. Non-credit entries are kept in
memory so they can be re-merged into the list if a card is removed.

New cards can be added manually (custom name/balance) or linked directly to a
Teller credit/loan account, which pre-fills the balance and limit fields.

Pull-to-refresh re-fetches live balances for any cards that are linked to Teller.

On back-press, changes are communicated back to ExpenseActivity via Intent extras
(changedList / howChangedList / changedCredUseList / changedCredLimList) so the
main expense list stays in sync. Changes are also written directly to disk in
onPause() in case the process is killed before the result is delivered.
*/
public class CreditUtilActivity extends AppCompatActivity implements Serializable {

    private static final long serialVersionUID = 1L;
    private static final String ADD = "ADD";
    private static final String DEL = "DEL";

    private TutorialOverlayLayout tutorialOverlay;
    private ArrayList<ExpenseItem> expenseModelsList;
    private ArrayList<ExpenseModel> notCreditList;
    private ArrayList<Integer>      notCreditPosList;
    private ArrayList<CreditModel> creditList;
    private ArrayList<Integer>      creditPosList;
    // New entries created from Teller (not in expenseModelsList)
    private ArrayList<CreditModel> newCreditModels;

    private ArrayList<Integer> changedList;
    private ArrayList<String>  howChangedList;
    private ArrayList<String>  changedCredUseList;
    private ArrayList<String>  changedCredLimList;
    private ArrayList<String>  changedCredSourceList;
    private ArrayList<String>  changedCredSourceIdList;
    private ArrayList<String>  changedCredSourceDisplayList;

    private CreditAdapter        creditAdapter;
    private SwipeRefreshLayout   swipeRefreshLayout;
    private TextView             syncLabel;
    private TextView             totalDebtView;
    private TextView             totalLimitView;
    private TextView             totalUtilView;
    private ProgressBar          totalUtilBar;

    private boolean dataChanged;
    private Intent  returnIntent;

    private ExecutorService executor;
    private Handler         mainHandler;

    // Inflates the credit utilization screen, splits the incoming expense list into credit vs.
    // non-credit entries, wires up the add/edit/pull-to-refresh flows, and shows totals.
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);
        ThemeHelper.enableEdgeToEdge(this);
        setContentView(R.layout.credit_util_layout);
        ThemeHelper.tintActionBar(this);
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                goBackHome();
            }
        });
        ViewCompat.setOnApplyWindowInsetsListener(
                ((android.view.ViewGroup) findViewById(android.R.id.content)).getChildAt(0),
                (v, windowInsets) -> {
                    Insets insets = windowInsets.getInsets(WindowInsetsCompat.Type.systemBars());
                    v.setPadding(0, insets.top, 0, insets.bottom);
                    return WindowInsetsCompat.CONSUMED;
                });

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Credit Utilization");
        }

        executor    = Executors.newSingleThreadExecutor();
        mainHandler = new Handler(Looper.getMainLooper());

        changedList        = new ArrayList<>();
        howChangedList     = new ArrayList<>();
        changedCredUseList = new ArrayList<>();
        changedCredLimList = new ArrayList<>();
        changedCredSourceList        = new ArrayList<>();
        changedCredSourceIdList      = new ArrayList<>();
        changedCredSourceDisplayList = new ArrayList<>();
        newCreditModels    = new ArrayList<>();

        swipeRefreshLayout = findViewById(R.id.credit_swipe_refresh);
        syncLabel          = findViewById(R.id.credit_sync_label);
        totalDebtView      = findViewById(R.id.credit_total_debt);
        totalLimitView     = findViewById(R.id.credit_total_limit);
        totalUtilView      = findViewById(R.id.credit_total_util);
        totalUtilBar       = findViewById(R.id.credit_total_util_bar);
        RecyclerView creditRecyclerView = findViewById(R.id.credit_recyclerview);
        FloatingActionButton addBtn     = findViewById(R.id.add_credit_button);
        ThemeHelper.tintFab(addBtn, this);

        // Separate credit from non-credit expenses
        expenseModelsList = (ArrayList<ExpenseItem>) getIntent().getSerializableExtra("creditList");
        notCreditList    = new ArrayList<>();
        notCreditPosList = new ArrayList<>();
        creditList       = new ArrayList<>();
        creditPosList    = new ArrayList<>();

        for (int i = 0; i < expenseModelsList.size(); i++) {
            ExpenseItem e = expenseModelsList.get(i);
            if (e instanceof CreditModel) {
                creditList.add((CreditModel) e);
                creditPosList.add(i);
            } else {
                notCreditList.add((ExpenseModel) e);
                notCreditPosList.add(i);
            }
        }

        dataChanged = false;

        creditAdapter = new CreditAdapter(this, creditList, new ClickListener() {
            @Override public void onPositionClicked(int position) { /* no-op */ }
            @Override public void onLongClicked(int position) { editCredit(position); }
        });
        creditRecyclerView.setLayoutManager(new LinearLayoutManager(this));
        creditRecyclerView.setAdapter(creditAdapter);

        addBtn.setOnClickListener(v -> showAddCreditDialog());

        swipeRefreshLayout.setOnRefreshListener(this::syncLinkedCredits);

        updateSyncLabel();
        updateTotalUtilization();
    }

    // Add credit dialog

    // Builds the "Add Credit Card" dialog: the user either links a connected credit/loan account
    // or enters a custom name/balance/limit, creating a brand-new ExpenseModel either way.
    private void showAddCreditDialog() {
        View dialogLayout = getLayoutInflater().inflate(R.layout.add_credit_dialog_layout, null);

        TextInputLayout      expenseLayout      = dialogLayout.findViewById(R.id.add_credit_expense_layout);
        AutoCompleteTextView expenseDropdown    = dialogLayout.findViewById(R.id.add_credit_expense_input);
        TextInputLayout      limitLayout        = dialogLayout.findViewById(R.id.add_credit_limit_layout);
        EditText             limitInput         = dialogLayout.findViewById(R.id.add_credit_limit_input);
        View                 fromConnectedBtn   = dialogLayout.findViewById(R.id.btn_add_credit_connected);
        MaterialCardView     linkedBanner       = dialogLayout.findViewById(R.id.add_credit_linked_banner);
        TextView             linkedLabel        = dialogLayout.findViewById(R.id.add_credit_linked_label);
        View                 unlinkBtn          = dialogLayout.findViewById(R.id.btn_add_credit_unlink);
        TextInputLayout      customNameLayout   = dialogLayout.findViewById(R.id.add_credit_custom_name_layout);
        EditText             customNameInput    = dialogLayout.findViewById(R.id.add_credit_custom_name_input);
        TextInputLayout      customBalanceLayout = dialogLayout.findViewById(R.id.add_credit_custom_balance_layout);
        EditText             customBalanceInput = dialogLayout.findViewById(R.id.add_credit_custom_balance_input);
        AutoCompleteTextView sourceInput        = dialogLayout.findViewById(R.id.add_credit_source_input);

        // TODO: Re-enable "link to existing expense" once the expense-to-credit sync is fixed.
        dialogLayout.findViewById(R.id.add_credit_existing_header).setVisibility(View.GONE);
        expenseLayout.setVisibility(View.GONE);
        dialogLayout.findViewById(R.id.add_credit_existing_or).setVisibility(View.GONE);

        // Dropdown population kept for when the existing-expense path is re-enabled.
        ArrayList<String> expenseNames = new ArrayList<>();
        ArrayAdapter<String> dropAdapter = new ArrayAdapter<>(this,
                R.layout.expense_dropdown_item, expenseNames);
        expenseDropdown.setAdapter(dropAdapter);

        String[] linkedId      = {null};
        String[] linkedToken   = {null};
        String[] linkedDisplay = {null};

        // "From Connected" pre-fills the custom name/balance fields and shows the banner
        fromConnectedBtn.setOnClickListener(v ->
                showConnectedCreditPicker(customNameInput, customBalanceInput, limitInput,
                        linkedBanner, linkedLabel, linkedId, linkedToken, linkedDisplay, null));

        unlinkBtn.setOnClickListener(v -> {
            linkedId[0] = linkedToken[0] = linkedDisplay[0] = null;
            linkedBanner.setVisibility(View.GONE);
        });

        // Source dropdown — same options as the regular Add/Edit Expense dialog's Source
        // section, minus any credit-card entries (a card can't be paid off by another card).
        ArrayList<String> sourceNames = new ArrayList<>();
        ArrayList<String> sourceTypes = new ArrayList<>();
        ArrayList<String> sourceIds   = new ArrayList<>();
        ArrayList<String> sourceDisplayNames = new ArrayList<>();
        sourceNames.add("Current Balance"); sourceTypes.add("BALANCE"); sourceIds.add(null); sourceDisplayNames.add("Current Balance");
        ArrayList<io.github.nishian3695.bujit.NavigationItems.Banking.ManualAccountModel> sourceManualAccounts = loadManualAccounts();
        for (io.github.nishian3695.bujit.NavigationItems.Banking.ManualAccountModel a : sourceManualAccounts) {
            sourceNames.add(a.getName()); sourceTypes.add("MANUAL_ACCOUNT");
            sourceIds.add(a.getId()); sourceDisplayNames.add(a.getName());
        }
        final String CREDIT_LINKED_TRIGGER = "Linked Bank/Credit Account…";
        sourceNames.add(CREDIT_LINKED_TRIGGER);
        ArrayAdapter<String> sourceAdapter = new ArrayAdapter<>(this, R.layout.expense_dropdown_item, sourceNames);
        sourceInput.setAdapter(sourceAdapter);
        final String[] selSource        = {"BALANCE"};
        final String[] selSourceId      = {null};
        final String[] selSourceDisplay = {null};
        final String[] lastSourceText   = {sourceNames.get(0)};
        sourceInput.setText(sourceNames.get(0), false);
        sourceInput.setOnItemClickListener((parent, v2, pos, id) -> {
            String pickedName = sourceNames.get(pos);
            if (CREDIT_LINKED_TRIGGER.equals(pickedName)) {
                sourceInput.setText(lastSourceText[0], false);
                showSourceAccountPicker(display -> {
                    if (display == null) return;
                    selSource[0] = "LINKED_ACCOUNT";
                    lastSourceText[0] = display;
                    sourceInput.setText(display, false);
                }, selSourceId, selSourceDisplay);
            } else {
                selSource[0]        = sourceTypes.get(pos);
                selSourceId[0]      = sourceIds.get(pos);
                selSourceDisplay[0] = sourceDisplayNames.get(pos);
                lastSourceText[0]   = pickedName;
            }
        });

        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("Add Credit Card")
                .setView(dialogLayout)
                .setNegativeButton("Cancel", null)
                .setPositiveButton("Add", null)
                .create();

        dialog.setOnShowListener(d -> {
            Button positiveBtn = dialog.getButton(AlertDialog.BUTTON_POSITIVE);
            positiveBtn.setOnClickListener(v -> {
                // Determine mode: Connected > Custom
                // TODO: Re-enable Existing path once the expense-to-credit sync is fixed.
                boolean isConnected = linkedId[0] != null;
                String customName   = customNameInput.getText() != null
                        ? customNameInput.getText().toString().trim() : "";
                boolean isCustom    = !isConnected && !customName.isEmpty();

                String limitStr = limitInput.getText() != null
                        ? limitInput.getText().toString().trim() : "";

                // Validate: a source must be chosen (existing-expense path is disabled)
                if (!isConnected && !isCustom) {
                    customNameLayout.setError("Use From Connected or enter a custom card name");
                    return;
                }
                customNameLayout.setErrorEnabled(false);

                if (limitStr.isEmpty()) {
                    limitLayout.setError("Enter a credit limit");
                    return;
                }
                limitLayout.setErrorEnabled(false);

                if (isConnected || isCustom) {
                    // Both paths create a brand-new ExpenseModel
                    if (customName.isEmpty()) {
                        customNameLayout.setError("Enter a card name");
                        return;
                    }
                    customNameLayout.setErrorEnabled(false);

                    String debtStr = customBalanceInput.getText() != null
                            ? customBalanceInput.getText().toString().trim() : "";
                    if (debtStr.isEmpty()) debtStr = "0";

                    CreditModel newEntry = new CreditModel(
                            customName, debtStr, LocalDate.now(), limitStr);
                    newEntry.setSource(selSource[0]);
                    newEntry.setSourceId(selSourceId[0]);
                    newEntry.setSourceDisplayName(selSourceDisplay[0]);
                    if (isConnected) {
                        newEntry.setLinkedAccount(linkedId[0], linkedToken[0], linkedDisplay[0]);
                        BankingProviderConfig.saveAccountToken(this, linkedId[0], linkedToken[0]);
                    }

                    creditList.add(newEntry);
                    creditPosList.add(-1);
                    newCreditModels.add(newEntry);
                    creditAdapter.notifyItemInserted(creditList.size() - 1);
                    updateTotalUtilization();
                }
                // TODO: Re-enable "link to existing expense" once the expense-to-credit sync
                // is fixed. The block below correctly tracks the change in changedList/
                // howChangedList, but the callback in ExpenseActivity does not yet reliably
                // propagate the isCredit flag back to the expense entry.
                // else {
                //     int selIndex = expenseNames.indexOf(expenseDropdown.getText().toString());
                //     if (selIndex < 0) { expenseLayout.setError("Select an expense"); return; }
                //     expenseLayout.setErrorEnabled(false);
                //     ExpenseModel selected = notCreditList.get(selIndex);
                //     selected.setCreditLimit(limitStr);
                //     changedList.add(notCreditPosList.get(selIndex));
                //     howChangedList.add(ADD);
                //     changedCredUseList.add(selected.getCost());
                //     changedCredLimList.add(limitStr);
                //     creditList.add(selected);
                //     creditPosList.add(notCreditPosList.get(selIndex));
                //     creditAdapter.notifyItemInserted(creditList.size() - 1);
                //     notCreditList.remove(selIndex);
                //     notCreditPosList.remove(selIndex);
                //     dropAdapter.remove(expenseNames.get(selIndex));
                //     expenseNames.remove(selIndex);
                // }
                dataChanged = true;
                dialog.dismiss();
            });
        });

        dialog.show();
    }

    // Edit credit dialog

    // Builds the dialog for editing an existing credit card's balance/limit/link, and a "Remove"
    // path that moves the card back into the non-credit expense list.
    public void editCredit(int position) {
        View dialogLayout = getLayoutInflater().inflate(R.layout.edit_credit_dialog_layout, null);

        EditText         credUseET      = dialogLayout.findViewById(R.id.cred_use_ET);
        EditText         credLimET      = dialogLayout.findViewById(R.id.cred_lim_ET);
        View             fromConnectedBtn = dialogLayout.findViewById(R.id.btn_edit_credit_connected);
        MaterialCardView linkedBanner   = dialogLayout.findViewById(R.id.edit_credit_linked_banner);
        TextView         linkedLabel    = dialogLayout.findViewById(R.id.edit_credit_linked_label);
        View             unlinkBtn      = dialogLayout.findViewById(R.id.btn_edit_credit_unlink);

        CreditModel credit = creditList.get(position);
        credUseET.setText(credit.getCost());
        credLimET.setText(credit.getCreditLimit());

        // Source dropdown — same options as showAddCreditDialog()'s Source section,
        // minus any credit-card entries (a card can't be paid off by another card).
        AutoCompleteTextView sourceInput = dialogLayout.findViewById(R.id.edit_credit_source_input);
        ArrayList<String> sourceNames = new ArrayList<>();
        ArrayList<String> sourceTypes = new ArrayList<>();
        ArrayList<String> sourceIds   = new ArrayList<>();
        ArrayList<String> sourceDisplayNames = new ArrayList<>();
        sourceNames.add("Current Balance"); sourceTypes.add("BALANCE"); sourceIds.add(null); sourceDisplayNames.add("Current Balance");
        ArrayList<io.github.nishian3695.bujit.NavigationItems.Banking.ManualAccountModel> sourceManualAccounts = loadManualAccounts();
        for (io.github.nishian3695.bujit.NavigationItems.Banking.ManualAccountModel a : sourceManualAccounts) {
            sourceNames.add(a.getName()); sourceTypes.add("MANUAL_ACCOUNT");
            sourceIds.add(a.getId()); sourceDisplayNames.add(a.getName());
        }
        final String CREDIT_LINKED_TRIGGER = "Linked Bank/Credit Account…";
        sourceNames.add(CREDIT_LINKED_TRIGGER);
        ArrayAdapter<String> sourceAdapter = new ArrayAdapter<>(this, R.layout.expense_dropdown_item, sourceNames);
        sourceInput.setAdapter(sourceAdapter);
        final String[] selSource        = {credit.getSource()};
        final String[] selSourceId      = {credit.getSourceId()};
        final String[] selSourceDisplay = {credit.getSourceDisplayName()};
        final String[] lastSourceText   = {sourceNames.get(0)};
        int existingIdx = -1;
        if (!"LINKED_ACCOUNT".equals(selSource[0])) {
            for (int i = 0; i < sourceTypes.size(); i++) {
                if (sourceTypes.get(i).equals(selSource[0])
                        && java.util.Objects.equals(sourceIds.get(i), selSourceId[0])) {
                    existingIdx = i;
                    break;
                }
            }
        }
        if ("LINKED_ACCOUNT".equals(selSource[0])) {
            String text = selSourceDisplay[0] != null ? selSourceDisplay[0] : "Linked Account";
            lastSourceText[0] = text;
            sourceInput.setText(text, false);
        } else if (existingIdx >= 0) {
            lastSourceText[0] = sourceNames.get(existingIdx);
            sourceInput.setText(sourceNames.get(existingIdx), false);
        } else {
            // The previously-selected manual account no longer exists (deleted since this card's
            // Source was set) -- warn rather than silently falling back, since saving now would
            // permanently overwrite the stored reference with "BALANCE".
            if (selSource[0] != null && !"BALANCE".equals(selSource[0])) {
                Toast.makeText(this, "This card's funding source is no longer available; reset to Current Balance.", Toast.LENGTH_LONG).show();
            }
            selSource[0] = "BALANCE"; selSourceId[0] = null; selSourceDisplay[0] = null;
            sourceInput.setText(sourceNames.get(0), false);
        }
        sourceInput.setOnItemClickListener((parent, v2, pos, id) -> {
            String pickedName = sourceNames.get(pos);
            if (CREDIT_LINKED_TRIGGER.equals(pickedName)) {
                sourceInput.setText(lastSourceText[0], false);
                showSourceAccountPicker(display -> {
                    if (display == null) return;
                    selSource[0] = "LINKED_ACCOUNT";
                    lastSourceText[0] = display;
                    sourceInput.setText(display, false);
                }, selSourceId, selSourceDisplay);
            } else {
                selSource[0]        = sourceTypes.get(pos);
                selSourceId[0]      = sourceIds.get(pos);
                selSourceDisplay[0] = sourceDisplayNames.get(pos);
                lastSourceText[0]   = pickedName;
            }
        });

        String[] linkedId      = {credit.getLinkedAccountId()};
        String storedToken     = credit.getLinkedAccountToken();
        if (storedToken == null && credit.getLinkedAccountId() != null) {
            storedToken = BankingProviderConfig.getTokenForAccount(this, credit.getLinkedAccountId());
        }
        String[] linkedToken = {storedToken};
        String[] linkedDisplay = {credit.getLinkedAccountDisplay()};

        if (credit.isLinkedToBank()) {
            linkedLabel.setText(linkedDisplay[0]);
            linkedBanner.setVisibility(View.VISIBLE);
        }

        fromConnectedBtn.setOnClickListener(v ->
                showConnectedCreditPicker(null, credUseET, credLimET, linkedBanner,
                        linkedLabel, linkedId, linkedToken, linkedDisplay,
                        credit.getLinkedAccountId()));

        unlinkBtn.setOnClickListener(v -> {
            linkedId[0] = linkedToken[0] = linkedDisplay[0] = null;
            linkedBanner.setVisibility(View.GONE);
        });

        AlertDialog editDialog = new AlertDialog.Builder(this)
                .setTitle("Edit Credit Card")
                .setView(dialogLayout)
                .setNegativeButton("Cancel", null)
                .setNeutralButton("Remove", null)
                .setPositiveButton("Save", (d, w) -> {
                    String newCost  = credUseET.getText().toString().trim();
                    String newLimit = credLimET.getText().toString().trim();
                    credit.setBalance(newCost.isEmpty() ? "0" : newCost);
                    credit.setCreditLimit(newLimit.isEmpty() ? "0" : newLimit);

                    if (linkedId[0] != null) {
                        credit.setLinkedAccount(linkedId[0], linkedToken[0], linkedDisplay[0]);
                        BankingProviderConfig.saveAccountToken(this, linkedId[0], linkedToken[0]);
                    } else {
                        credit.clearLinkedAccount();
                    }

                    credit.setSource(selSource[0]);
                    credit.setSourceId(selSourceId[0]);
                    credit.setSourceDisplayName(selSourceDisplay[0]);

                    int expPos = creditPosList.get(position);
                    if (expPos >= 0) {
                        changedList.add(expPos);
                        howChangedList.add(ADD);
                        changedCredUseList.add(credit.getCost());
                        changedCredLimList.add(credit.getCreditLimit());
                        changedCredSourceList.add(credit.getSource());
                        changedCredSourceIdList.add(credit.getSourceId());
                        changedCredSourceDisplayList.add(credit.getSourceDisplayName());
                    }
                    dataChanged = true;
                    creditAdapter.notifyItemChanged(position);
                    updateTotalUtilization();
                })
                .create();

        // Override the neutral button so the edit dialog stays open while the
        // confirmation is shown -- only dismiss once the user confirms removal.
        editDialog.setOnShowListener(d -> {
            editDialog.getButton(AlertDialog.BUTTON_NEUTRAL).setOnClickListener(v -> {
                new AlertDialog.Builder(this)
                        .setTitle("Remove Card")
                        .setMessage("Remove \"" + credit.getName() + "\"? This cannot be undone.")
                        .setPositiveButton("Remove", (d2, w2) -> {
                            int expPos = creditPosList.get(position);
                            if (expPos >= 0) {
                                changedList.add(expPos);
                                howChangedList.add(DEL);
                                changedCredUseList.add(credit.getCost());
                                changedCredLimList.add(credit.getCreditLimit());
                                changedCredSourceList.add(credit.getSource());
                                changedCredSourceIdList.add(credit.getSourceId());
                                changedCredSourceDisplayList.add(credit.getSourceDisplayName());
                            } else {
                                newCreditModels.remove(credit);
                            }
                            creditList.remove(position);
                            creditPosList.remove(position);
                            creditAdapter.notifyItemRemoved(position);
                            updateTotalUtilization();
                            dataChanged = true;
                            editDialog.dismiss();
                        })
                        .setNegativeButton("Cancel", null)
                        .show();
            });
        });

        editDialog.show();
    }

    // Teller account picker (credit/loan only)

    // Fetches all connected credit/loan accounts (excluding ones already linked to other cards)
    // and shows a picker so the user can link this card to one, pre-filling name/balance/limit.
    // nameField may be null (e.g. from the edit dialog where the name is already fixed).
    // currentLinkedId is the account ID already linked to the card being edited (null when adding),
    // so the picker keeps that account available while excluding all other already-linked accounts.
    private void showConnectedCreditPicker(
            EditText nameField,
            EditText debtField,
            EditText limitField,
            View bannerView,
            TextView bannerLabel,
            String[] linkedId,
            String[] linkedToken,
            String[] linkedDisplay,
            String currentLinkedId) {

        Set<String> tokens = loadBankTokens();
        if (tokens.isEmpty()) {
            Toast.makeText(this, "No banks connected — add one in Banking.", Toast.LENGTH_SHORT).show();
            return;
        }

        // Collect account IDs already linked to other credit cards so they can be excluded.
        Set<String> alreadyLinked = new HashSet<>();
        for (CreditModel e : creditList) {
            if (e.isLinkedToBank()) {
                String id = e.getLinkedAccountId();
                if (id != null && !id.equals(currentLinkedId)) {
                    alreadyLinked.add(id);
                }
            }
        }

        AlertDialog loading = new AlertDialog.Builder(this)
                .setTitle("Loading accounts…")
                .setView(new ProgressBar(this))
                .setCancelable(false)
                .create();
        loading.show();

        executor.execute(() -> {
            String idToken = getFirebaseIdToken();
            String appCheckToken = getAppCheckToken();
            List<BankAccountModel> accounts = new ArrayList<>();
            for (String token : tokens) {
                try {
                    BankingApiClient client = BankingProviderConfig.createClient(this, token, idToken, appCheckToken);
                    List<BankAccountModel> all = client.fetchAccounts();
                    for (BankAccountModel m : all) {
                        String type = m.getType() != null ? m.getType().toLowerCase(Locale.US) : "";
                        if (type.equals("credit") || type.equals("loan")) {
                            m.setToken(token);
                            accounts.add(m);
                        }
                    }
                } catch (Exception e) {
                    Log.e("CreditPicker", "fetch failed: " + e.getMessage());
                }
            }
            mainHandler.post(() -> {
                loading.dismiss();
                accounts.removeIf(m -> alreadyLinked.contains(m.getId()));
                if (accounts.isEmpty()) {
                    Toast.makeText(this, "No credit or loan accounts found.", Toast.LENGTH_SHORT).show();
                    return;
                }
                String[] labels = new String[accounts.size()];
                for (int i = 0; i < accounts.size(); i++) {
                    BankAccountModel m = accounts.get(i);
                    float ledger = parseFloatSafe(m.getLedgerBalance());
                    float avail  = parseFloatSafe(m.getAvailableBalance());
                    labels[i] = m.getInstitutionName()
                            + " – " + m.getDisplayType()
                            + " (…" + m.getLastFour() + ")"
                            + "  $" + CurrencyFormat.display(this, ledger);
                }
                new AlertDialog.Builder(this)
                        .setTitle("Link connected account")
                        .setItems(labels, (d, idx) -> {
                            BankAccountModel sel = accounts.get(idx);
                            float ledger = parseFloatSafe(sel.getLedgerBalance());
                            float avail  = parseFloatSafe(sel.getAvailableBalance());
                            // Use the provider's reported credit limit when available (Plaid
                            // exposes balances.limit directly). For Teller, fall back to
                            // ledger + available, which understates the limit by any pending
                            // amount but is the best approximation without a limit field.
                            String rawLimit = sel.getCreditLimit();
                            float limit = (rawLimit != null && !rawLimit.isEmpty())
                                    ? parseFloatSafe(rawLimit) : ledger + avail;
                            if (limit <= 0f) limit = ledger + avail;

                            String display = sel.getInstitutionName()
                                    + " " + sel.getDisplayType()
                                    + " …" + sel.getLastFour();

                            linkedId[0]      = sel.getId();
                            linkedToken[0]   = sel.getToken();
                            linkedDisplay[0] = display;

                            String debtStr  = String.format(Locale.US, "%.2f", ledger);
                            String limitStr = String.format(Locale.US, "%.2f", limit);

                            if (nameField != null) nameField.setText(display);
                            debtField.setText(debtStr);
                            limitField.setText(limitStr);

                            bannerLabel.setText(display);
                            bannerView.setVisibility(View.VISIBLE);
                        })
                        .setNegativeButton("Cancel", null)
                        .show();
            });
        });
    }

    // Lets the user pick any linked Plaid/Teller account (all types, not just credit/loan) as a
    // credit card's funding Source. Unlike showConnectedCreditPicker(), this never touches the
    // name/balance/limit fields — picking a Source only marks the card as "already handled by
    // this account's own sync," it doesn't attach the account's balance to the card itself.
    // onPicked is called with the chosen display name, or null if the user cancelled.
    private void showSourceAccountPicker(java.util.function.Consumer<String> onPicked,
                                          String[] sourceId, String[] sourceDisplay) {
        Set<String> tokens = loadBankTokens();
        if (tokens.isEmpty()) {
            Toast.makeText(this, "No banks connected — add one in Banking.", Toast.LENGTH_SHORT).show();
            onPicked.accept(null);
            return;
        }

        AlertDialog loadingDialog = new AlertDialog.Builder(this)
                .setTitle("Loading accounts…")
                .setView(new ProgressBar(this))
                .setCancelable(false)
                .create();
        loadingDialog.show();

        executor.execute(() -> {
            String idToken = getFirebaseIdToken();
            String appCheckToken = getAppCheckToken();
            List<BankAccountModel> all = new ArrayList<>();
            for (String token : tokens) {
                try {
                    BankingApiClient client = BankingProviderConfig.createClient(this, token, idToken, appCheckToken);
                    for (BankAccountModel m : client.fetchAccounts()) {
                        m.setToken(token);
                        all.add(m);
                    }
                } catch (Exception e) {
                    Log.e("SourcePicker", "fetch failed: " + e.getMessage());
                }
            }
            mainHandler.post(() -> {
                loadingDialog.dismiss();
                if (all.isEmpty()) {
                    Toast.makeText(this, "No linked accounts found.", Toast.LENGTH_SHORT).show();
                    onPicked.accept(null);
                    return;
                }
                String[] labels = new String[all.size()];
                for (int i = 0; i < all.size(); i++) {
                    BankAccountModel m = all.get(i);
                    labels[i] = m.getInstitutionName()
                            + " – " + m.getDisplayType()
                            + " (…" + m.getLastFour() + ")"
                            + "  $" + CurrencyFormat.display(this, parseFloatSafe(m.getLedgerBalance()));
                }
                new AlertDialog.Builder(this)
                        .setTitle("Select Linked Account")
                        .setItems(labels, (d, idx) -> {
                            BankAccountModel selected = all.get(idx);
                            String display = selected.getInstitutionName()
                                    + " " + selected.getDisplayType()
                                    + " …" + selected.getLastFour();
                            sourceId[0]      = selected.getId();
                            sourceDisplay[0] = display;
                            onPicked.accept(display);
                        })
                        .setOnCancelListener(d -> onPicked.accept(null))
                        .setNegativeButton("Cancel", (d, w) -> onPicked.accept(null))
                        .show();
            });
        });
    }

    // Pull-to-refresh sync for linked credit entries.
    // Uses fetchAccounts() (Plaid's /accounts/get, cached data) rather than
    // fetchAccountBalancePair() (/accounts/balance/get, real-time and billed per call).
    // One fetchAccounts() call per unique token covers all accounts for that institution.
    private void syncLinkedCredits() {
        boolean hasLinked = false;
        for (CreditModel e : creditList) {
            if (e.isLinkedToBank()) { hasLinked = true; break; }
        }
        if (!hasLinked) {
            swipeRefreshLayout.setRefreshing(false);
            return;
        }

        executor.execute(() -> {
            String idToken = getFirebaseIdToken();
            String appCheckToken = getAppCheckToken();

            Set<String> tokens = new HashSet<>();
            for (CreditModel credit : creditList) {
                if (!credit.isLinkedToBank()) continue;
                String tok = credit.getLinkedAccountToken();
                if (tok == null) tok = BankingProviderConfig.getTokenForAccount(this, credit.getLinkedAccountId());
                if (tok != null) tokens.add(tok);
            }

            Map<String, BankAccountModel> accountMap = new HashMap<>();
            for (String tok : tokens) {
                BankingApiClient client = BankingProviderConfig.createClient(this, tok, idToken, appCheckToken);
                try {
                    for (BankAccountModel acct : client.fetchAccounts()) {
                        accountMap.put(acct.getId(), acct);
                    }
                } catch (Exception e) {
                    Log.e("CreditSync", "fetchAccounts failed: " + e.getMessage());
                }
            }

            boolean updated = false;
            for (int i = 0; i < creditList.size(); i++) {
                CreditModel credit = creditList.get(i);
                if (!credit.isLinkedToBank()) continue;
                BankAccountModel acct = accountMap.get(credit.getLinkedAccountId());
                if (acct == null) continue;

                float ledger = parseFloatSafe(acct.getLedgerBalance());
                float avail  = parseFloatSafe(acct.getAvailableBalance());
                String rawLimit = acct.getCreditLimit();
                String debt = String.format(Locale.US, "%.2f", ledger);
                credit.setBalance(debt);
                // Only overwrite the stored credit limit when the provider gives reliable data.
                // If both limit and available are absent/null (e.g. charge cards), leave the
                // stored limit intact rather than corrupting it to ledger + 0.
                if (rawLimit != null && !rawLimit.isEmpty()) {
                    float lf = parseFloatSafe(rawLimit);
                    if (lf > 0f) credit.setCreditLimit(String.format(Locale.US, "%.2f", lf));
                } else if (avail > 0f) {
                    credit.setCreditLimit(String.format(Locale.US, "%.2f", ledger + avail));
                }

                int expPos = creditPosList.get(i);
                if (expPos >= 0) {
                    changedList.add(expPos);
                    howChangedList.add(ADD);
                    changedCredUseList.add(debt);
                    changedCredLimList.add(credit.getCreditLimit());
                    // A balance sync never touches Source — carry the existing value through
                    // unchanged, just to keep these parallel lists index-aligned with the two above.
                    changedCredSourceList.add(credit.getSource());
                    changedCredSourceIdList.add(credit.getSourceId());
                    changedCredSourceDisplayList.add(credit.getSourceDisplayName());
                }
                updated = true;
            }
            final boolean didUpdate = updated;
            mainHandler.post(() -> {
                swipeRefreshLayout.setRefreshing(false);
                if (didUpdate) {
                    dataChanged = true;
                    creditAdapter.notifyDataSetChanged();
                    updateTotalUtilization();
                    syncLabel.setText("Synced just now");
                }
            });
        });
    }

    // Return to caller

    // Packages up every tracked change (edits, deletes, new cards) into the result Intent and
    // finishes this activity, returning control to ExpenseActivity.
    public void goBackHome() {
        returnIntent = new Intent();
        returnIntent.putIntegerArrayListExtra("changedList",        changedList);
        returnIntent.putStringArrayListExtra("howChangedList",      howChangedList);
        returnIntent.putStringArrayListExtra("changedCredUseList",  changedCredUseList);
        returnIntent.putStringArrayListExtra("changedCredLimList",  changedCredLimList);
        returnIntent.putStringArrayListExtra("changedCredSourceList",        changedCredSourceList);
        returnIntent.putStringArrayListExtra("changedCredSourceIdList",      changedCredSourceIdList);
        returnIntent.putStringArrayListExtra("changedCredSourceDisplayList", changedCredSourceDisplayList);
        if (!newCreditModels.isEmpty()) {
            returnIntent.putExtra("newCreditList", newCreditModels);
        }
        setResult(dataChanged ? RESULT_OK : RESULT_CANCELED, returnIntent);
        finish();
    }

    // Helpers

    // Returns a Firebase Auth ID token for authenticating banking-backend requests, signing the
    // user in anonymously first if they aren't already signed in. Returns null on failure.
    private String getFirebaseIdToken() {
        try {
            FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
            if (user == null) {
                Tasks.await(FirebaseAuth.getInstance().signInAnonymously());
                user = FirebaseAuth.getInstance().getCurrentUser();
            }
            if (user != null) return Tasks.await(user.getIdToken(false)).getToken();
        } catch (Exception e) {
            Log.e("CreditUtil", "Firebase token fetch failed: " + e.getMessage());
        }
        return null;
    }

    // Returns a Firebase App Check token, proving to the banking backend that requests come from
    // a genuine copy of this app. Returns null on failure.
    private String getAppCheckToken() {
        try {
            return Tasks.await(FirebaseAppCheck.getInstance().getToken(false)).getToken();
        } catch (Exception e) {
            Log.e("CreditUtil", "App Check token fetch failed: " + e.getMessage());
            return null;
        }
    }

    // Loads the set of stored bank-connection access tokens (Plaid/Teller) for this device.
    private Set<String> loadBankTokens() {
        return BankingProviderConfig.loadTokens(this);
    }

    // Parses a balance string, returning 0 instead of throwing on invalid input.
    private float parseFloatSafe(String s) {
        try { return Float.parseFloat(s); } catch (NumberFormatException e) { return 0f; }
    }

    // Recomputes and displays the total debt, total limit, and overall utilization percentage
    // across every credit card, with a color-coded bar.
    private void updateTotalUtilization() {
        float totalDebt  = 0f;
        float totalLimit = 0f;
        for (CreditModel e : creditList) {
            try { totalDebt  += Float.parseFloat(e.getCost()); }        catch (NumberFormatException ignored) {}
            try { totalLimit += Float.parseFloat(e.getCreditLimit()); } catch (NumberFormatException ignored) {}
        }
        int utilPct = (totalLimit > 0) ? Math.min(100, Math.round(totalDebt / totalLimit * 100)) : 0;

        totalDebtView.setText("$" + CurrencyFormat.display(this, totalDebt));
        totalLimitView.setText("$" + CurrencyFormat.display(this, totalLimit));
        totalUtilView.setText(utilPct + "%");
        totalUtilBar.setProgress(utilPct);

        int color;
        if (utilPct < 30)      color = R.color.balance_positive;
        else if (utilPct < 70) color = R.color.util_warning;
        else                   color = R.color.balance_negative;

        int resolved = androidx.core.content.ContextCompat.getColor(this, color);
        totalUtilView.setTextColor(resolved);
        totalUtilBar.setProgressTintList(android.content.res.ColorStateList.valueOf(resolved));
    }

    // Shows a "pull down to sync" hint if any card is linked to a bank, else a placeholder dash.
    private void updateSyncLabel() {
        boolean anyLinked = false;
        for (CreditModel e : creditList) { if (e.isLinkedToBank()) { anyLinked = true; break; } }
        syncLabel.setText(anyLinked ? "Pull down to sync balances" : "—");
    }

    // This screen doesn't keep a live StorageHolder like ExpenseActivity does, so the Source
    // dropdown's manual-account options are loaded fresh on demand — same on-demand pattern
    // persistChanges() below already uses to reach StorageHolder.
    private ArrayList<io.github.nishian3695.bujit.NavigationItems.Banking.ManualAccountModel> loadManualAccounts() {
        try {
            StorageManager manager = new StorageManager(getApplicationContext());
            return manager.getStorageHolder().getManualAccountList();
        } catch (Exception e) {
            Log.e("CreditUtil", "loadManualAccounts failed: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    // Persist to storage

    // Writes any credit changes directly to disk so they survive a home-press or
    // process kill while the user is still inside this screen.
    private void persistChanges() {
        if (!dataChanged) return;
        try {
            StorageManager manager = new StorageManager(getApplicationContext());
            StorageHolder holder = manager.getStorageHolder();
            ArrayList<ExpenseItem> list = holder.getExpenseList();

            ArrayList<Integer> delPositions = new ArrayList<>();
            for (int i = 0; i < changedList.size(); i++) {
                int pos = changedList.get(i);
                if (pos < 0 || pos >= list.size()) continue;
                String how = howChangedList.get(i);
                if (DEL.equals(how)) {
                    delPositions.add(pos);
                } else if (list.get(pos) instanceof CreditModel) {
                    CreditModel e = (CreditModel) list.get(pos);
                    e.setBalance(changedCredUseList.get(i));
                    e.setCreditLimit(changedCredLimList.get(i));
                    e.setSource(changedCredSourceList.get(i));
                    e.setSourceId(changedCredSourceIdList.get(i));
                    e.setSourceDisplayName(changedCredSourceDisplayList.get(i));
                }
            }
            Collections.sort(delPositions, Collections.reverseOrder());
            for (int pos : delPositions) list.remove(pos);
            list.addAll(newCreditModels);

            holder.setExpenseList(list);
            manager.writeData(holder);
        } catch (Exception e) {
            Log.e("CreditUtil", "Failed to persist changes: " + e.getMessage());
        }
    }

    // Lifecycle

    // Makes the toolbar's back arrow return to ExpenseActivity with any pending changes.
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            goBackHome();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    // Resumes the guided tutorial if this screen still has unfinished tutorial steps.
    @Override
    protected void onResume() {
        super.onResume();
        maybeShowTutorial();
    }

    // Removes any active tutorial overlay, then persists changes and signals ExpenseActivity to
    // reload — covering every exit path (back arrow, swipe gesture, home button, process kill).
    @Override
    protected void onPause() {
        removeTutorialOverlay();
        super.onPause();
        persistChanges();
        // Always set the result when there are changes so ExpenseActivity's callback
        // fires regardless of whether the user used the back arrow, a swipe gesture,
        // or the system killed the process. setResult only delivers when the Activity
        // actually finishes, so this is harmless on a plain home-button press.
        if (dataChanged) {
            // Signal ExpenseActivity to reload the expense list from disk on its next
            // resume. This is the primary save mechanism — persists regardless of how
            // the user exits (backswipe, home gesture, process kill).
            getSharedPreferences("bujit_prefs", MODE_PRIVATE)
                    .edit().putBoolean("credit_util_changed", true).apply();
            // Belt-and-suspenders: also set the result for the ActivityResultLauncher
            // callback (works for all normal navigation paths).
            Intent intent = new Intent();
            intent.putIntegerArrayListExtra("changedList",        changedList);
            intent.putStringArrayListExtra("howChangedList",      howChangedList);
            intent.putStringArrayListExtra("changedCredUseList",  changedCredUseList);
            intent.putStringArrayListExtra("changedCredLimList",  changedCredLimList);
            intent.putStringArrayListExtra("changedCredSourceList",        changedCredSourceList);
            intent.putStringArrayListExtra("changedCredSourceIdList",      changedCredSourceIdList);
            intent.putStringArrayListExtra("changedCredSourceDisplayList", changedCredSourceDisplayList);
            if (!newCreditModels.isEmpty()) {
                intent.putExtra("newCreditList", newCreditModels);
            }
            setResult(RESULT_OK, intent);
        }
    }

    // Kicks off the tutorial's current step, but only if this activity still has steps left to show.
    private void maybeShowTutorial() {
        if (!TutorialManager.hasStepsForActivity(this, CreditUtilActivity.class)) return;
        showTutorialStep(TutorialManager.getCurrentStep(this));
    }

    // Renders a single tutorial overlay step (spotlight + text bubble), wiring "Next"/"Skip" to
    // advance to the next step, hand off to another activity's tutorial, or return home.
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

    // Detaches the tutorial overlay view from the window decor, if one is currently showing.
    private void removeTutorialOverlay() {
        if (tutorialOverlay != null) {
            ViewGroup p = (ViewGroup) tutorialOverlay.getParent();
            if (p != null) p.removeView(tutorialOverlay);
            tutorialOverlay = null;
        }
    }

    // Shuts down the background executor so no pending sync work leaks past this activity's life.
    @Override
    protected void onDestroy() {
        super.onDestroy();
        executor.shutdown();
    }
}
