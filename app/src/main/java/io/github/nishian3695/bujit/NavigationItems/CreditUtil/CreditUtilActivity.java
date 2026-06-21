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
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankingPrefs;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.Interfaces.ClickListener;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankAccountModel;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import io.github.nishian3695.bujit.NavigationItems.Banking.TellerBackendClient;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.ThemeHelper;
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
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
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

    private ArrayList<ExpenseModel> expenseModelsList;
    private ArrayList<ExpenseModel> notCreditList;
    private ArrayList<Integer>      notCreditPosList;
    private ArrayList<ExpenseModel> creditList;
    private ArrayList<Integer>      creditPosList;
    // New entries created from Teller (not in expenseModelsList)
    private ArrayList<ExpenseModel> newCreditModels;

    private ArrayList<Integer> changedList;
    private ArrayList<String>  howChangedList;
    private ArrayList<String>  changedCredUseList;
    private ArrayList<String>  changedCredLimList;

    private CreditAdapter        creditAdapter;
    private SwipeRefreshLayout   swipeRefreshLayout;
    private TextView             syncLabel;

    private boolean dataChanged;
    private Intent  returnIntent;

    private ExecutorService executor;
    private Handler         mainHandler;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.credit_util_layout);
        ThemeHelper.tintActionBar(this);

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
        newCreditModels    = new ArrayList<>();

        swipeRefreshLayout = findViewById(R.id.credit_swipe_refresh);
        syncLabel          = findViewById(R.id.credit_sync_label);
        RecyclerView creditRecyclerView = findViewById(R.id.credit_recyclerview);
        FloatingActionButton addBtn     = findViewById(R.id.add_credit_button);
        ThemeHelper.tintFab(addBtn, this);

        // Separate credit from non-credit expenses
        expenseModelsList = (ArrayList<ExpenseModel>) getIntent().getSerializableExtra("creditList");
        notCreditList    = new ArrayList<>();
        notCreditPosList = new ArrayList<>();
        creditList       = new ArrayList<>();
        creditPosList    = new ArrayList<>();

        for (int i = 0; i < expenseModelsList.size(); i++) {
            ExpenseModel e = expenseModelsList.get(i);
            if (e.getIsCredit()) {
                creditList.add(e);
                creditPosList.add(i);
            } else {
                notCreditList.add(e);
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
    }

    // Add credit dialog

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

                    ExpenseModel newEntry = new ExpenseModel(
                            customName, debtStr, LocalDate.now(),
                            1, ChronoUnit.MONTHS, false);
                    newEntry.setIsCredit(true);
                    newEntry.setCreditLimit(limitStr);
                    if (isConnected) {
                        newEntry.setLinkedAccount(linkedId[0], linkedToken[0], linkedDisplay[0]);
                        BankingPrefs.saveAccountToken(this, linkedId[0], linkedToken[0]);
                    }

                    creditList.add(newEntry);
                    creditPosList.add(-1);
                    newCreditModels.add(newEntry);
                    creditAdapter.notifyItemInserted(creditList.size() - 1);
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

    public void editCredit(int position) {
        View dialogLayout = getLayoutInflater().inflate(R.layout.edit_credit_dialog_layout, null);

        EditText         credUseET      = dialogLayout.findViewById(R.id.cred_use_ET);
        EditText         credLimET      = dialogLayout.findViewById(R.id.cred_lim_ET);
        View             fromConnectedBtn = dialogLayout.findViewById(R.id.btn_edit_credit_connected);
        MaterialCardView linkedBanner   = dialogLayout.findViewById(R.id.edit_credit_linked_banner);
        TextView         linkedLabel    = dialogLayout.findViewById(R.id.edit_credit_linked_label);
        View             unlinkBtn      = dialogLayout.findViewById(R.id.btn_edit_credit_unlink);

        ExpenseModel credit = creditList.get(position);
        credUseET.setText(credit.getCost());
        credLimET.setText(credit.getCreditLimit());

        String[] linkedId      = {credit.getLinkedAccountId()};
        String storedToken     = credit.getLinkedAccountToken();
        if (storedToken == null && credit.getLinkedAccountId() != null) {
            storedToken = BankingPrefs.getTokenForAccount(this, credit.getLinkedAccountId());
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
                    credit.setCost(newCost.isEmpty() ? "0" : newCost);
                    credit.setShownCost(credit.getCost());
                    credit.setCreditLimit(newLimit.isEmpty() ? "0" : newLimit);

                    if (linkedId[0] != null) {
                        credit.setLinkedAccount(linkedId[0], linkedToken[0], linkedDisplay[0]);
                        BankingPrefs.saveAccountToken(this, linkedId[0], linkedToken[0]);
                    } else {
                        credit.clearLinkedAccount();
                    }

                    int expPos = creditPosList.get(position);
                    if (expPos >= 0) {
                        changedList.add(expPos);
                        howChangedList.add(ADD);
                        changedCredUseList.add(credit.getCost());
                        changedCredLimList.add(credit.getCreditLimit());
                    }
                    dataChanged = true;
                    creditAdapter.notifyItemChanged(position);
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
                            } else {
                                newCreditModels.remove(credit);
                            }
                            creditList.remove(position);
                            creditPosList.remove(position);
                            creditAdapter.notifyItemRemoved(position);
                            notCreditList.add(credit);
                            notCreditPosList.add(expPos >= 0 ? expPos : expenseModelsList.size());
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
        for (ExpenseModel e : creditList) {
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
            List<BankAccountModel> accounts = new ArrayList<>();
            for (String token : tokens) {
                try {
                    TellerBackendClient client = new TellerBackendClient(this, token, idToken);
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
                            + "  $" + String.format(Locale.US, "%.2f", ledger);
                }
                new AlertDialog.Builder(this)
                        .setTitle("Link connected account")
                        .setItems(labels, (d, idx) -> {
                            BankAccountModel sel = accounts.get(idx);
                            float ledger = parseFloatSafe(sel.getLedgerBalance());
                            float avail  = parseFloatSafe(sel.getAvailableBalance());
                            float limit  = ledger + avail;

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

    // Pull-to-refresh sync for linked credit entries

    private void syncLinkedCredits() {
        boolean hasLinked = false;
        for (ExpenseModel e : creditList) {
            if (e.isLinkedToBank()) { hasLinked = true; break; }
        }
        if (!hasLinked) {
            swipeRefreshLayout.setRefreshing(false);
            return;
        }

        executor.execute(() -> {
            String idToken = getFirebaseIdToken();
            boolean updated = false;
            for (int i = 0; i < creditList.size(); i++) {
                ExpenseModel credit = creditList.get(i);
                if (!credit.isLinkedToBank()) continue;
                try {
                    String tellerToken = credit.getLinkedAccountToken();
                    if (tellerToken == null) tellerToken = BankingPrefs.getTokenForAccount(this, credit.getLinkedAccountId());
                    TellerBackendClient client = new TellerBackendClient(this, tellerToken, idToken);
                    float[] pair  = client.fetchAccountBalancePair(credit.getLinkedAccountId());
                    float ledger  = pair[0];
                    float avail   = pair[1];
                    String debt   = String.format(Locale.US, "%.2f", ledger);
                    String limit  = String.format(Locale.US, "%.2f", ledger + avail);
                    credit.setCost(debt);
                    credit.setShownCost(debt);
                    credit.setCreditLimit(limit);

                    int expPos = creditPosList.get(i);
                    if (expPos >= 0) {
                        changedList.add(expPos);
                        howChangedList.add(ADD);
                        changedCredUseList.add(debt);
                        changedCredLimList.add(limit);
                    }
                    updated = true;
                } catch (Exception e) {
                    Log.e("CreditSync", "failed for " + credit.getName() + ": " + e.getMessage());
                }
            }
            final boolean didUpdate = updated;
            mainHandler.post(() -> {
                swipeRefreshLayout.setRefreshing(false);
                if (didUpdate) {
                    dataChanged = true;
                    creditAdapter.notifyDataSetChanged();
                    syncLabel.setText("Synced just now");
                }
            });
        });
    }

    // Return to caller

    public void goBackHome() {
        returnIntent = new Intent();
        returnIntent.putIntegerArrayListExtra("changedList",        changedList);
        returnIntent.putStringArrayListExtra("howChangedList",      howChangedList);
        returnIntent.putStringArrayListExtra("changedCredUseList",  changedCredUseList);
        returnIntent.putStringArrayListExtra("changedCredLimList",  changedCredLimList);
        if (!newCreditModels.isEmpty()) {
            returnIntent.putExtra("newCreditList", newCreditModels);
        }
        setResult(dataChanged ? RESULT_OK : RESULT_CANCELED, returnIntent);
        finish();
    }

    // Helpers

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

    private Set<String> loadBankTokens() {
        return BankingPrefs.loadTokens(this);
    }

    private float parseFloatSafe(String s) {
        try { return Float.parseFloat(s); } catch (NumberFormatException e) { return 0f; }
    }

    private void updateSyncLabel() {
        boolean anyLinked = false;
        for (ExpenseModel e : creditList) { if (e.isLinkedToBank()) { anyLinked = true; break; } }
        syncLabel.setText(anyLinked ? "Pull down to sync Teller balances" : "—");
    }

    // Persist to storage

    // Writes any credit changes directly to disk so they survive a home-press or
    // process kill while the user is still inside this screen.
    private void persistChanges() {
        if (!dataChanged) return;
        try {
            StorageManager manager = new StorageManager(getApplicationContext());
            StorageHolder holder = manager.getStorageHolder();
            ArrayList<ExpenseModel> list = holder.getExpenseList();

            ArrayList<Integer> delPositions = new ArrayList<>();
            for (int i = 0; i < changedList.size(); i++) {
                int pos = changedList.get(i);
                if (pos < 0 || pos >= list.size()) continue;
                String how = howChangedList.get(i);
                if (DEL.equals(how)) {
                    delPositions.add(pos);
                } else {
                    ExpenseModel e = list.get(pos);
                    e.setIsCredit(true);
                    e.setCost(changedCredUseList.get(i));
                    e.setShownCost(changedCredUseList.get(i));
                    e.setCreditLimit(changedCredLimList.get(i));
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

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            goBackHome();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    protected void onPause() {
        super.onPause();
        persistChanges();
    }

    @Override
    public void onBackPressed() {
        goBackHome();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        executor.shutdown();
    }
}
