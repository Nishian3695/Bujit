package io.github.nishian3695.bujit.NavigationItems.SingleEvents;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AutoCompleteTextView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.button.MaterialButtonToggleGroup;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.textfield.TextInputLayout;
import io.github.nishian3695.bujit.CustomListeners.CurrencyEditTextWatcher;
import io.github.nishian3695.bujit.ExpenseActivity.CreditModel;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseItem;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankingActivity;
import io.github.nishian3695.bujit.NavigationItems.Banking.ManualAccountModel;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import io.github.nishian3695.bujit.ThemeHelper;
import io.github.nishian3695.bujit.Tutorial.TutorialManager;
import io.github.nishian3695.bujit.Tutorial.TutorialOverlayLayout;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

// Activity for managing one-off single events (unplanned debits/credits applied immediately to
// the main balance, a manual account, or a credit card, as opposed to recurring ExpenseModels).
// Events auto-expire and are purged after a configurable number of days. Every change is
// persisted to disk immediately and flagged via SharedPreferences so ExpenseActivity picks it up
// on its next resume (it owns the authoritative current balance).
public class SingleEventsActivity extends AppCompatActivity {

    public static final String KEY_CHANGED = "single_events_changed";
    public static final String KEY_BALANCE_DELTA = "single_events_balance_delta";

    private StorageManager storageManager;
    private StorageHolder storageHolder;
    private ArrayList<SingleEventModel> eventList;
    private SingleEventAdapter adapter;
    private int expiryDays;
    private View emptyView;
    private TutorialOverlayLayout tutorialOverlay;

    // Inflates the single events screen, loads and cleans up expired events, and wires the
    // list adapter plus the "add" FAB.
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);
        ThemeHelper.enableEdgeToEdge(this);
        setContentView(R.layout.activity_single_events);
        ThemeHelper.tintActionBar(this);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.single_events_root), (v, insets) -> {
            Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(0, bars.top, 0, bars.bottom);
            return WindowInsetsCompat.CONSUMED;
        });

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Single Events");
        }

        expiryDays = getExpiryDays();

        try {
            storageManager = new StorageManager(this);
            storageHolder = storageManager.getStorageHolder();
            eventList = storageHolder.getSingleEventList();
        } catch (Exception e) {
            Log.e("SingleEvents", "load failed: " + e.getMessage());
            eventList = new ArrayList<>();
        }

        cleanupExpired();

        // Newest-first order
        eventList.sort((a, b) -> b.getLastModifiedDate().compareTo(a.getLastModifiedDate()));

        if (TutorialManager.hasStepsForActivity(this, SingleEventsActivity.class) && eventList.isEmpty()) {
            injectTutorialDummyData();
        }

        RecyclerView recyclerView = findViewById(R.id.single_events_recycler);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));

        adapter = new SingleEventAdapter(this, eventList, expiryDays, new SingleEventAdapter.ItemClickListener() {
            @Override
            public void onItemClick(int position) {
                showEventDialog(eventList.get(position), position);
            }

            @Override
            public void onItemLongClick(int position) {
                showDeleteConfirmation(position);
            }
        });
        recyclerView.setAdapter(adapter);

        emptyView = findViewById(R.id.single_events_empty);
        updateEmptyState();

        FloatingActionButton fab = findViewById(R.id.single_events_add_fab);
        ThemeHelper.tintFab(fab, this);
        fab.setOnClickListener(v -> showEventDialog(null, -1));
    }

    // ── Funding source helpers ────────────────────────────────────────────────

    // One entry in the funding-source dropdown (balance, a manual account, or a credit card).
    private static class TargetOption {
        final String displayName;
        final String targetType;
        final String targetId; // null for BALANCE, account id for MANUAL_ACCOUNT, card name for CREDIT_CARD

        TargetOption(String displayName, String targetType, String targetId) {
            this.displayName = displayName;
            this.targetType = targetType;
            this.targetId = targetId;
        }
    }

    // Builds the list of possible funding sources: the main balance, every manual account, and
    // every unlinked credit card.
    private List<TargetOption> buildTargetOptions() {
        List<TargetOption> options = new ArrayList<>();
        options.add(new TargetOption("Current Balance", "BALANCE", null));
        ArrayList<ManualAccountModel> accounts = storageHolder.getManualAccountList();
        if (accounts != null) {
            for (ManualAccountModel acct : accounts) {
                options.add(new TargetOption(acct.getName(), "MANUAL_ACCOUNT", acct.getId()));
            }
        }
        ArrayList<ExpenseItem> expenses = storageHolder.getExpenseList();
        if (expenses != null) {
            for (ExpenseItem e : expenses) {
                if (e.isCredit() && !e.isLinkedToBank()) {
                    options.add(new TargetOption(e.getName() + " (card)", "CREDIT_CARD", e.getName()));
                }
            }
        }
        return options;
    }

    // Finds the dropdown index matching an event's stored target, so the edit dialog can
    // pre-select the correct funding source.
    private int findTargetIndex(List<TargetOption> options, String targetType, String targetId) {
        for (int i = 0; i < options.size(); i++) {
            TargetOption opt = options.get(i);
            if (opt.targetType.equals(targetType)) {
                if (targetId == null ? opt.targetId == null : targetId.equals(opt.targetId)) return i;
            }
        }
        return 0;
    }

    /** Applies a signed delta to the selected funding source (not BALANCE — that's handled via KEY_BALANCE_DELTA). */
    private void applyToTarget(String targetType, String targetId, float delta) {
        if ("BALANCE".equals(targetType)) {
            // Balance delta is communicated to ExpenseActivity via KEY_BALANCE_DELTA, not here.
        } else if ("MANUAL_ACCOUNT".equals(targetType)) {
            ManualAccountModel acct = findManualAccount(targetId);
            if (acct != null) acct.setBalance(acct.getBalance() + delta);
        } else if ("CREDIT_CARD".equals(targetType)) {
            CreditModel card = findCreditCard(targetId);
            if (card != null) {
                // Debit event → delta is negative → subtracting negative increases debt.
                // Credit event → delta is positive → subtracting positive decreases debt.
                card.applyCharge(-delta);
            }
        }
    }

    // Finds a manual account by its stored ID.
    private ManualAccountModel findManualAccount(String id) {
        ArrayList<ManualAccountModel> accounts = storageHolder.getManualAccountList();
        if (accounts == null || id == null) return null;
        for (ManualAccountModel a : accounts) {
            if (id.equals(a.getId())) return a;
        }
        return null;
    }

    // Finds an unlinked credit-card expense by name.
    private CreditModel findCreditCard(String name) {
        ArrayList<ExpenseItem> expenses = storageHolder.getExpenseList();
        if (expenses == null || name == null) return null;
        for (ExpenseItem e : expenses) {
            if (e instanceof CreditModel && name.equals(e.getName())) return (CreditModel) e;
        }
        return null;
    }

    // ── CRUD ─────────────────────────────────────────────────────────────────

    // Removes every event past its expiry window, saving if anything was removed.
    private void cleanupExpired() {
        boolean any = false;
        java.util.Iterator<SingleEventModel> it = eventList.iterator();
        while (it.hasNext()) {
            if (it.next().isExpired(expiryDays)) {
                it.remove();
                any = true;
            }
        }
        if (any) saveData(false, false, false);
    }

    // Builds the add/edit single event dialog: name, signed amount (debit/credit toggle), and a
    // funding-source dropdown. On save, applies the (possibly changed) effect to the target and
    // persists the change; edits reverse the old effect before applying the new one.
    private void showEventDialog(SingleEventModel existing, int position) {
        boolean isAdd = (existing == null);

        View dialogView = LayoutInflater.from(this).inflate(R.layout.add_single_event_layout, null);
        TextInputLayout nameLayout   = dialogView.findViewById(R.id.add_single_event_name);
        TextInputLayout amountLayout = dialogView.findViewById(R.id.add_single_event_amount);
        EditText nameField   = dialogView.findViewById(R.id.single_event_name_input);
        EditText amountField = dialogView.findViewById(R.id.single_event_amount_input);
        MaterialButtonToggleGroup typeToggle = dialogView.findViewById(R.id.single_event_type_toggle);
        AutoCompleteTextView targetInput = dialogView.findViewById(R.id.single_event_target_input);

        List<TargetOption> targetOptions = buildTargetOptions();
        ArrayList<String> targetNames = new ArrayList<>();
        for (TargetOption opt : targetOptions) targetNames.add(opt.displayName);

        ArrayAdapter<String> targetAdapter = new ArrayAdapter<>(this, R.layout.expense_dropdown_item, targetNames);
        targetInput.setAdapter(targetAdapter);

        int initialIdx = isAdd ? 0
                : findTargetIndex(targetOptions, existing.getTargetType(), existing.getTargetId());
        final int[] selectedIdx = {initialIdx};
        targetInput.setText(targetNames.get(initialIdx), false);

        targetInput.setOnItemClickListener((parent, v, pos, id) -> selectedIdx[0] = pos);

        if (!isAdd) {
            nameField.setText(existing.getName());
            amountField.setText(String.format(Locale.US, "%.2f", existing.getAmount()));
            typeToggle.check(existing.isDebit() ? R.id.btn_single_debit : R.id.btn_single_credit);
        } else {
            typeToggle.check(R.id.btn_single_debit);
        }

        amountField.addTextChangedListener(new CurrencyEditTextWatcher(amountField));

        AlertDialog.Builder builder = new AlertDialog.Builder(this)
                .setTitle(isAdd ? "Add Single Event" : "Edit Single Event")
                .setView(dialogView)
                .setNegativeButton("Cancel", null)
                .setPositiveButton(isAdd ? "Add" : "Save", null);
        if (!isAdd) {
            builder.setNeutralButton("Remove", null);
        }
        AlertDialog dialog = builder.create();

        dialog.setOnShowListener(d -> {
            if (!isAdd) {
                dialog.getButton(AlertDialog.BUTTON_NEUTRAL).setOnClickListener(v -> {
                    dialog.dismiss();
                    showDeleteConfirmation(position);
                });
            }

            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> {
                String name = nameField.getText() != null ? nameField.getText().toString().trim() : "";
                String amtStr = amountField.getText() != null ? amountField.getText().toString().trim() : "";

                boolean valid = true;
                if (name.isEmpty()) {
                    nameLayout.setError("Name is required");
                    valid = false;
                } else {
                    nameLayout.setErrorEnabled(false);
                }

                float amount = 0;
                try { amount = Float.parseFloat(amtStr); } catch (NumberFormatException ignored) {}
                if (amount <= 0) {
                    amountLayout.setError("Enter a valid amount");
                    valid = false;
                } else {
                    amountLayout.setErrorEnabled(false);
                }
                if (!valid) return;

                boolean isDebit = (typeToggle.getCheckedButtonId() == R.id.btn_single_debit);

                TargetOption selectedTarget = targetOptions.get(
                        selectedIdx[0] >= 0 && selectedIdx[0] < targetOptions.size() ? selectedIdx[0] : 0);
                String newTargetType = selectedTarget.targetType;
                String newTargetId   = selectedTarget.targetId;

                if (isAdd) {
                    SingleEventModel model = new SingleEventModel(name, amount, isDebit);
                    model.setTargetType(newTargetType);
                    model.setTargetId(newTargetId);
                    model.setTargetDisplayName(selectedTarget.displayName);
                    applyToTarget(newTargetType, newTargetId, model.getAppliedAmount());
                    float balanceDelta = "BALANCE".equals(newTargetType) ? model.getAppliedAmount() : 0f;
                    eventList.add(0, model);
                    adapter.notifyItemInserted(0);
                    saveData(true,
                            "MANUAL_ACCOUNT".equals(newTargetType),
                            "CREDIT_CARD".equals(newTargetType),
                            balanceDelta);
                } else {
                    // Capture old target before update.
                    String oldTargetType = existing.getTargetType();
                    String oldTargetId   = existing.getTargetId();
                    float  oldApplied    = existing.getAppliedAmount();

                    existing.applyUpdate(amount, isDebit);
                    existing.setName(name);
                    existing.setTargetType(newTargetType);
                    existing.setTargetId(newTargetId);
                    existing.setTargetDisplayName(selectedTarget.displayName);

                    // Reverse old effect, then apply new effect.
                    applyToTarget(oldTargetType, oldTargetId, -oldApplied);
                    applyToTarget(newTargetType, newTargetId, existing.getAppliedAmount());

                    // Compute the net change in BALANCE contribution for ExpenseActivity.
                    // Rule: track additions to BALANCE, not removals (removals are implicit in the
                    // manual/card delta that ExpenseActivity computes separately).
                    float balanceDelta = 0f;
                    if ("BALANCE".equals(newTargetType)) {
                        balanceDelta = existing.getAppliedAmount();
                        if ("BALANCE".equals(oldTargetType)) balanceDelta -= oldApplied; // same target, amount changed
                    }
                    // BALANCE → other: balanceDelta stays 0; manual/card reload handles the net effect.

                    eventList.sort((a, b) -> b.getLastModifiedDate().compareTo(a.getLastModifiedDate()));
                    adapter.notifyDataSetChanged();
                    boolean touchedManual = "MANUAL_ACCOUNT".equals(oldTargetType)
                            || "MANUAL_ACCOUNT".equals(newTargetType);
                    boolean touchedCard   = "CREDIT_CARD".equals(oldTargetType)
                            || "CREDIT_CARD".equals(newTargetType);
                    saveData(true, touchedManual, touchedCard, balanceDelta);
                }

                updateEmptyState();
                dialog.dismiss();
            });
        });

        dialog.show();
    }

    // Confirms and then deletes a single event, reversing its effect on the funding source it was
    // applied to.
    private void showDeleteConfirmation(int position) {
        if (position < 0 || position >= eventList.size()) return;
        SingleEventModel item = eventList.get(position);
        new AlertDialog.Builder(this)
                .setTitle("Remove Event")
                .setMessage("Remove \"" + item.getName() + "\"? Its effect on your balance will be undone.")
                .setPositiveButton("Remove", (d, w) -> {
                    String tType = item.getTargetType();
                    applyToTarget(tType, item.getTargetId(), -item.getAppliedAmount());
                    boolean touchedManual = "MANUAL_ACCOUNT".equals(tType);
                    boolean touchedCard   = "CREDIT_CARD".equals(tType);
                    float balanceDelta = "BALANCE".equals(tType) ? -item.getAppliedAmount() : 0f;
                    eventList.remove(position);
                    adapter.notifyItemRemoved(position);
                    saveData(true, touchedManual, touchedCard, balanceDelta);
                    updateEmptyState();
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    // Convenience overload for callers with no BALANCE-target delta to report.
    private void saveData(boolean flagChanged, boolean manualAccountModified, boolean creditCardModified) {
        saveData(flagChanged, manualAccountModified, creditCardModified, 0f);
    }

    // Persists the event list to disk and, if flagChanged, sets SharedPreferences flags so
    // ExpenseActivity/BankingActivity reload the affected data (and accumulates any BALANCE
    // delta) on their next resume.
    private void saveData(boolean flagChanged, boolean manualAccountModified, boolean creditCardModified, float balanceDelta) {
        try {
            storageHolder.setSingleEventList(eventList);
            // currentBalance is NOT saved here; ExpenseActivity owns it and applies
            // the BALANCE delta via KEY_BALANCE_DELTA when it resumes.
            storageManager.writeData(storageHolder);
            if (flagChanged) {
                android.content.SharedPreferences prefs = getSharedPreferences("bujit_prefs", MODE_PRIVATE);
                android.content.SharedPreferences.Editor ed = prefs.edit();
                ed.putBoolean(KEY_CHANGED, true);
                if (balanceDelta != 0f) {
                    float accumulated = prefs.getFloat(KEY_BALANCE_DELTA, 0f) + balanceDelta;
                    ed.putFloat(KEY_BALANCE_DELTA, accumulated);
                }
                if (manualAccountModified)
                    ed.putBoolean(BankingActivity.KEY_MANUAL_ACCOUNTS_CHANGED, true);
                if (creditCardModified)
                    ed.putBoolean(BankingActivity.KEY_BANKING_EXPENSE_CHANGED, true);
                ed.apply();
            }
        } catch (Exception e) {
            Log.e("SingleEvents", "save failed: " + e.getMessage());
        }
    }

    // ── Misc ─────────────────────────────────────────────────────────────────

    // Adds a few sample single events so the tutorial has something to show a first-time user
    // whose list is otherwise empty. Not persisted unless the user later edits/saves them.
    private void injectTutorialDummyData() {
        eventList.add(new SingleEventModel("Spontaneous concert tickets", 85.00f, true));
        eventList.add(new SingleEventModel("Won trivia night 🎉", 50.00f, false));
        eventList.add(new SingleEventModel("Forgot to pack lunch", 12.75f, true));
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
        if (!TutorialManager.hasStepsForActivity(this, SingleEventsActivity.class)) return;
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
                    startActivity(new Intent(this, def.nextActivity));
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

    // Reads the user-configured single-event expiry window (in days) from Settings, default 30.
    private int getExpiryDays() {
        return getSharedPreferences("bujit_prefs", MODE_PRIVATE)
                .getInt("single_event_expiry_days", 30);
    }

    // Toggles the "no events" placeholder based on whether the list is empty.
    private void updateEmptyState() {
        if (emptyView != null) {
            emptyView.setVisibility(eventList.isEmpty() ? View.VISIBLE : View.GONE);
        }
    }

    // Makes the toolbar's back arrow close this screen.
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) { finish(); return true; }
        return super.onOptionsItemSelected(item);
    }
}
