package io.github.nishian3695.bujit.ExpenseActivity;

import androidx.activity.result.ActivityResult;
import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import android.annotation.SuppressLint;
import android.app.DatePickerDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.DatePicker;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.AutoCompleteTextView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.core.content.ContextCompat;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankingPrefs;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import io.github.nishian3695.bujit.CustomListeners.CurrencyFormat;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamModel;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamsActivity;
import io.github.nishian3695.bujit.Interfaces.ClickListener;
import io.github.nishian3695.bujit.CustomListeners.CurrencyEditTextWatcher;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankingActivity;
import io.github.nishian3695.bujit.NavigationItems.CreditUtil.CreditUtilActivity;
import io.github.nishian3695.bujit.NavigationItems.Settings.GoogleTasksHelper;
import io.github.nishian3695.bujit.NavigationItems.Settings.SettingsActivity;
import androidx.appcompat.widget.SwitchCompat;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.ThemeHelper;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.textfield.TextInputLayout;
import com.google.android.material.navigation.NavigationView;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankAccountModel;
import io.github.nishian3695.bujit.NavigationItems.Banking.TellerBackendClient;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/*
Main activity and central hub of the Bujit app.

Displays the expense list for the current pay period alongside the user's
running balance and projected end-of-period balance (balance minus all
expenses due this check). The user can swipe forward/backward through future
and past pay periods to project their finances.

- Loads and saves all app state (expenses, balance, income streams, dates)
via StorageManager/StorageHolder using Java serialization.
- Manages the active income stream that determines pay period length/amount.
- Supports custom "projection" settings (different stream or period length)
for what-if scenarios without altering saved data.
- Refreshes linked Teller bank balances on pull-to-refresh and startup.
- Syncs expenses and income streams to Google Tasks when enabled.
- Hosts the navigation drawer for Banking, Income Streams, Credit Util, Settings.
- Supports multi-select (batch delete) and drag-to-reorder on the expense list.

The "home screen" is always the current check period. Navigating forward or backward
uses animated slide transitions. The FAB switches between "add expense" and "go home"
depending on whether the user is on the home screen.
*/
public class ExpenseActivity extends AppCompatActivity implements NavigationView.OnNavigationItemSelectedListener {
    // region Variables
    private final CurrencyFormat currencyFormat = new CurrencyFormat();
    private final String READ = "READ", WRITE = "WRITE", ADD = "ADD", DEL = "DEL", EDIT = "EDIT";
    private final String VIEW_FORMAT = "EEEE, MMMM d, yyyy", STORE_FORMAT = "yyyy.MM.dd", HEADER_FORMAT = "MMMM dd, yyyy";
    private final ChronoUnit DAY = ChronoUnit.DAYS, WEEK = ChronoUnit.WEEKS, MONTH = ChronoUnit.MONTHS, YEAR = ChronoUnit.YEARS;
    private final int DAY_INT = 0, WEEK_INT = 1, MONTH_INT = 2, YEAR_INT = 3;

    // Keeping track
    private boolean onHomeScreen;
    // Data Storage
    private StorageManager storageManager;
    private StorageHolder storageHolder;
    // View variables
    private ConstraintLayout mainLayout;
    private RecyclerView expenseTable;
    private ExpenseAdapter expenseAdapter;
    private DrawerLayout drawerLayout;
    private NavigationView navigationView;
    private ActionBarDrawerToggle actionBarDrawerToggle;
    private FloatingActionButton addExpenseButton;
    private Button nextCheckButton, prevCheckButton;
    private TextView currentBankBalance, finalBalance, checkName, syncLabel, checkBarSubtitle;
    private SwipeRefreshLayout swipeRefreshLayout;
    // ActivityResultLaunchers
    ActivityResultLauncher<Intent> getBalanceOptionsContent, creditUtilizationContent, settingsContent;
    // Data variables
    private ArrayList<ExpenseModel> expenseListStor;
    private ArrayList<IncomeStreamModel> incomeStreamList;
    private float curBalance, shownBalance, averageCheck, projAmount;
    private LocalDate curCheckDate, begCheckDate, nextCheckDate, endCheckDate, mToday, lastOpened;
    private int checkFrequency, projFrequency, projStepsForward;
    private ChronoUnit checkFrequencyTag, projFreqTag;
    private String projStreamName;
    // Background work
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    // Google Tasks helper (lazy-init, non-null after first access)
    private GoogleTasksHelper googleTasksHelper;
    // endregion

    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);
        onHomeScreen = true;
        setContentView(R.layout.activity_main);
        ThemeHelper.tintActionBar(this);
        // Set up layout items
        mainLayout = findViewById(R.id.main_constraint_layout);
        ThemeHelper.tintPrimaryCard(findViewById(R.id.check_bar_card), this);
        addExpenseButton = findViewById(R.id.add_button);
        ThemeHelper.tintFab(addExpenseButton, this);
        nextCheckButton = findViewById(R.id.next_check_button);
        prevCheckButton = findViewById(R.id.prev_check_button);
        currentBankBalance = findViewById(R.id.current_balance_TV);
        ThemeHelper.tintPrimaryText(currentBankBalance, this);
        finalBalance = findViewById(R.id.final_balance);
        checkName = findViewById(R.id.current_check);
        checkBarSubtitle = findViewById(R.id.check_bar_subtitle);
        syncLabel = findViewById(R.id.sync_label);
        checkName.setOnLongClickListener(v -> { showProjectionSettingsDialog(); return true; });
        swipeRefreshLayout = findViewById(R.id.swipe_refresh);
        ThemeHelper.tintSwipeRefresh(swipeRefreshLayout, this);
        swipeRefreshLayout.setOnRefreshListener(this::refreshLinkedBankBalance);
        // Set up navigation drawer
        drawerLayout = findViewById(R.id.main_drawer_layout);
        actionBarDrawerToggle = new ActionBarDrawerToggle(this, drawerLayout,
                R.string.nav_open, R.string.nav_close);
        drawerLayout.addDrawerListener(actionBarDrawerToggle);
        actionBarDrawerToggle.syncState();
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        addExpenseButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (onHomeScreen) {
                    addEditExpenseDialog(ADD, -1).show();
                } else {
                    performCheckTransition(false, () -> goHomePage());
                }
            }
        });
        nextCheckButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                getNextCheck();
            }
        });
        prevCheckButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                getPrevCheck();
            }
        });

        currentBankBalance.setOnLongClickListener(new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View view) {
                goHomePage();
                changeBankBalance().show();
                return true;
            }
        });
        // Set up expense list
        try {
            getExpenses();
            setFinalBalance();
        } catch (IOException | ClassNotFoundException e) {
            e.printStackTrace();
        }
        // Set up Navigation View
        setNavigationViewListener();
        // Register intents
        registerOtherActivities();

        updateExpensePerPaid();
        showDisclaimerIfNeeded();
    }

    private void showDisclaimerIfNeeded() {
        SharedPreferences prefs = getSharedPreferences("bujit_legal_prefs", MODE_PRIVATE);
        if (prefs.getBoolean("disclaimer_accepted", false)) return;
        new AlertDialog.Builder(this)
                .setTitle("Before You Begin")
                .setMessage(getString(R.string.disclaimer_text) + "\n\n" +
                        "By tapping \"I Understand\", you acknowledge that Bujit is not a financial advisor, " +
                        "balances may not reflect real-time data, projections are estimates, and should not be relied upon for financial decisions.")
                .setPositiveButton("I Understand", (d, w) ->
                        prefs.edit().putBoolean("disclaimer_accepted", true).apply())
                .setCancelable(false)
                .show();
    }
    // Recalculates ePerPay for every expense using the current check frequency.
    public void updateExpensePerPaid() {
        for (ExpenseModel anExpense : expenseListStor) {
            anExpense.setPerPay(checkFrequency, checkFrequencyTag, mToday);
        }
    }

    /*
    Registers ActivityResultLaunchers for SettingsActivity, IncomeStreamsActivity,
    and CreditUtilActivity. Each launcher has a result callback that applies changes
    returned by the sub-activity back into the in-memory expense/income data and
    triggers a UI refresh and save.
    */
    private void registerOtherActivities() {
        settingsContent = registerForActivityResult(
                new ActivityResultContracts.StartActivityForResult(),
                result -> {
                    if (result.getData() != null &&
                            result.getData().getBooleanExtra(
                                    SettingsActivity.EXTRA_CALENDAR_SYNC_CHANGED, false)) {
                        getSharedPreferences("bujit_calendar_prefs", MODE_PRIVATE)
                                .edit().putBoolean("needs_sync_check", true).apply();
                    }
                    recreate();
                });

        getBalanceOptionsContent = registerForActivityResult(
                new ActivityResultContracts.StartActivityForResult(),
                result -> {
                    if (result.getResultCode() == RESULT_OK && result.getData() != null) {
                        //noinspection unchecked
                        ArrayList<IncomeStreamModel> updatedStreams =
                                (ArrayList<IncomeStreamModel>)
                                        result.getData().getSerializableExtra("incomeStreamList");
                        if (updatedStreams != null) {
                            incomeStreamList = updatedStreams;
                            for (IncomeStreamModel s : incomeStreamList) {
                                if (s.isSelected()) {
                                    averageCheck = s.getAmountFloat();
                                    setCheckFreq(s.getFrequency(),
                                            intFreqTagToChronoUnit(s.getFrequencyTag()));
                                    curCheckDate = stringToCalendar(s.getCheckDate());
                                    begCheckDate = curCheckDate;
                                    nextCheckDate = curCheckDate.plus(checkFrequency, checkFrequencyTag);
                                    endCheckDate = nextCheckDate;
                                    break;
                                }
                            }
                            // Reset in-session projection to follow the new active stream
                            resetProjToActiveStream();
                            // Sync any new income streams that don't have tasks yet
                            if (GoogleTasksHelper.isCalendarSyncEnabled(this)) {
                                ArrayList<IncomeStreamModel> streamsToSync = incomeStreamList;
                                executor.execute(() -> {
                                    for (IncomeStreamModel s : streamsToSync) {
                                        if (s.getGoogleTaskId() == null) {
                                            try {
                                                s.setGoogleTaskId(tasksHelper().createIncomeTask(s));
                                            } catch (Exception ignored) {}
                                        }
                                    }
                                    mainHandler.post(this::saveNow);
                                });
                            }
                        }
                    }
                    drawerLayout.close();
                });
        creditUtilizationContent = registerForActivityResult(
                new ActivityResultContracts.StartActivityForResult(),
                new ActivityResultCallback<ActivityResult>() {
                    @Override
                    @SuppressWarnings("unchecked")
                    public void onActivityResult(ActivityResult result) {
                        Log.d("Result", String.valueOf(result.getResultCode()));
                        Intent data = result.getData();
                        if (data == null) { drawerLayout.close(); return; }

                        ArrayList<Integer> changedList = data.getIntegerArrayListExtra("changedList");
                        if (changedList != null && !changedList.isEmpty()) {
                            ArrayList<String> howChangedList     = data.getStringArrayListExtra("howChangedList");
                            ArrayList<String> changedCredUseList = data.getStringArrayListExtra("changedCredUseList");
                            ArrayList<String> changedCredLimList = data.getStringArrayListExtra("changedCredLimList");
                            ArrayList<Integer> delPositions = new ArrayList<>();
                            try {
                                for (int i = 0; i < changedList.size(); i++) {
                                    int changedPos = changedList.get(i);
                                    if (changedPos < 0 || changedPos >= expenseListStor.size()) continue;
                                    String howChanged = howChangedList.get(i);
                                    if (DEL.equals(howChanged)) {
                                        delPositions.add(changedPos);
                                    } else {
                                        ExpenseModel changedExpense = expenseListStor.get(changedPos);
                                        if (ADD.equals(howChanged)) changedExpense.setIsCredit(true);
                                        changedExpense.setCost(changedCredUseList.get(i));
                                        changedExpense.setShownCost(changedCredUseList.get(i));
                                        changedExpense.setCreditLimit(changedCredLimList.get(i));
                                        expenseAdapter.notifyItemChanged(changedPos);
                                    }
                                }
                                Collections.sort(delPositions, Collections.reverseOrder());
                                for (int pos : delPositions) {
                                    if (pos >= 0 && pos < expenseListStor.size()) {
                                        expenseListStor.remove(pos);
                                        expenseAdapter.notifyItemRemoved(pos);
                                    }
                                }
                            } catch (Exception ex) {
                                Log.e("CreditCallback", "Error applying credit changes: " + ex.getMessage());
                            }
                            setFinalBalance();
                        }

                        // New credit entries created from Teller - append to expense list
                        ArrayList<ExpenseModel> newCredits = (ArrayList<ExpenseModel>)
                                data.getSerializableExtra("newCreditList");
                        if (newCredits != null && !newCredits.isEmpty()) {
                            for (ExpenseModel e : newCredits) {
                                expenseListStor.add(e);
                            }
                            expenseAdapter.notifyDataSetChanged();
                            setFinalBalance();
                        }

                        saveNow();
                        drawerLayout.close();
                    }
                });
    }

    /*
    Centralised storage dispatcher. Pass READ to deserialize all data from disk into
    the activity's fields (including income stream migration from legacy single-stream
    format). Pass WRITE to serialize the current state back to disk.
    */
    private void handleStorage(String interaction) throws IOException, ClassNotFoundException {
        switch (interaction) {
            case (READ): {
                storageManager = new StorageManager(getBaseContext());
                storageHolder = storageManager.getStorageHolder();

                expenseListStor = storageHolder.getExpenseList();
                curBalance = storageHolder.getCurrentBalance();
                averageCheck = storageHolder.getAverageCheck();
                checkFrequency = storageHolder.getCheckFrequency();
                checkFrequencyTag = storageHolder.getCheckFrequencyTag();
                if (checkFrequencyTag == null) checkFrequencyTag = ChronoUnit.WEEKS;
                if (checkFrequency <= 0) checkFrequency = 1;
                curCheckDate = storageHolder.getCurCheckDate();
                nextCheckDate = storageHolder.getNextCheckDate();
                if (curCheckDate == null) curCheckDate = LocalDate.now();
                if (nextCheckDate == null) nextCheckDate = curCheckDate.plus(checkFrequency, checkFrequencyTag);
                lastOpened = storageHolder.getLastOpenedDate();
                if (lastOpened == null) lastOpened = LocalDate.now();
                // Load income streams; migrate from legacy single-stream fields on first open
                incomeStreamList = storageHolder.getIncomeStreamList();
                if (incomeStreamList == null || incomeStreamList.isEmpty()) {
                    incomeStreamList = new ArrayList<>();
                    if (averageCheck > 0) {
                        int legacyTag = WEEK_INT;
                        if (checkFrequencyTag == DAY)   legacyTag = DAY_INT;
                        else if (checkFrequencyTag == MONTH) legacyTag = MONTH_INT;
                        else if (checkFrequencyTag == YEAR)  legacyTag = YEAR_INT;
                        IncomeStreamModel legacy = new IncomeStreamModel(
                                "Primary Income",
                                String.format(Locale.US, "%.2f", averageCheck),
                                calendarToString(curCheckDate, STORE_FORMAT),
                                checkFrequency,
                                legacyTag);
                        legacy.setSelected(true);
                        incomeStreamList.add(legacy);
                    }
                }
                // Guarantee exactly one stream is marked selected
                boolean anySelected = false;
                for (IncomeStreamModel s : incomeStreamList) {
                    if (s.isSelected()) { anySelected = true; break; }
                }
                if (!anySelected && !incomeStreamList.isEmpty()) {
                    incomeStreamList.get(0).setSelected(true);
                }
                // Apply selected stream's values to drive check calculations
                for (IncomeStreamModel s : incomeStreamList) {
                    if (s.isSelected()) {
                        averageCheck = s.getAmountFloat();
                        checkFrequency = s.getFrequency();
                        ChronoUnit resolvedTag = intFreqTagToChronoUnit(s.getFrequencyTag());
                        checkFrequencyTag = resolvedTag != null ? resolvedTag : ChronoUnit.WEEKS;
                        curCheckDate = stringToCalendar(s.getCheckDate());
                        nextCheckDate = curCheckDate.plus(checkFrequency, checkFrequencyTag);
                        break;
                    }
                }
                // Set variables dependent on main data
                begCheckDate = curCheckDate;
                endCheckDate = nextCheckDate;
                break;
            }
            case (WRITE): {
                if (storageHolder == null) storageHolder = new StorageHolder();
                if (storageManager == null) storageManager = new StorageManager(getBaseContext());
                storageHolder.setExpenseList(expenseListStor);
                storageHolder.setCurrentBalance(curBalance);
                storageHolder.setAverageCheck(averageCheck);
                storageHolder.setCheckFrequency(checkFrequency);
                storageHolder.setCheckFrequencyTag(checkFrequencyTag);
                storageHolder.setCurCheckDate(curCheckDate);
                storageHolder.setNextCheckDate(nextCheckDate);
                storageHolder.setLastOpenedDate(lastOpened);
                storageHolder.setIncomeStreamList(incomeStreamList);
                storageManager.writeData(storageHolder);
                break;
            }
        }
    }

    /*
    Advances curCheckDate and nextCheckDate to the current pay period if time has
    elapsed since the last save. Also adds missed paychecks to curBalance.
    Called on every app open so the home screen always reflects today's pay period.
    */
    public void checkForNextCheck() {
        mToday = LocalDate.now();
        while (mToday.equals(this.nextCheckDate) || mToday.isAfter(this.nextCheckDate)) {
            curCheckDate = curCheckDate.plus(checkFrequency, checkFrequencyTag);
            nextCheckDate = nextCheckDate.plus(checkFrequency, checkFrequencyTag);
            curBalance += averageCheck;
        }
        begCheckDate = curCheckDate;
        endCheckDate = nextCheckDate;
    }

    public void setCheckFreq(int freq, ChronoUnit tag) {
        checkFrequency = freq;
        checkFrequencyTag = tag;
        updateExpensePerPaid();
    }

    // Projection helpers

    /*
    Resets the in-session projection back to the currently active income stream.
    Called on launch, after returning from IncomeStreamsActivity, and when the
    user hits "Reset" in the projection settings dialog.
    */
    private void resetProjToActiveStream() {
        projFrequency = checkFrequency;
        projFreqTag = checkFrequencyTag;
        projAmount = averageCheck;
        projStepsForward = 0;
        projStreamName = activeStreamName();
        if (checkBarSubtitle != null) updateCheckBarSubtitle();
    }

    private String activeStreamName() {
        if (incomeStreamList == null) return "";
        for (IncomeStreamModel s : incomeStreamList) {
            if (s.isSelected()) return s.getName();
        }
        return "";
    }

    private void updateCheckBarSubtitle() {
        if (checkBarSubtitle == null) return;
        // Show subtitle only when the projection differs from the active stream
        boolean nonDefaultStream = !projStreamName.equals(activeStreamName());
        boolean customPeriod = projFrequency != checkFrequency || projFreqTag != checkFrequencyTag;
        if (!nonDefaultStream && !customPeriod) {
            checkBarSubtitle.setVisibility(android.view.View.GONE);
            return;
        }
        StringBuilder sb = new StringBuilder();
        if (nonDefaultStream) sb.append(projStreamName);
        if (customPeriod) {
            if (sb.length() > 0) sb.append("  ·  ");
            sb.append(projFrequency).append(" ").append(chronoUnitLabel(projFreqTag, projFrequency));
        }
        checkBarSubtitle.setText(sb.toString());
        checkBarSubtitle.setVisibility(android.view.View.VISIBLE);
    }

    private String chronoUnitLabel(ChronoUnit unit, int magnitude) {
        if (unit == ChronoUnit.DAYS)   return magnitude == 1 ? "day"   : "days";
        if (unit == ChronoUnit.WEEKS)  return magnitude == 1 ? "week"  : "weeks";
        if (unit == ChronoUnit.MONTHS) return magnitude == 1 ? "month" : "months";
        if (unit == ChronoUnit.YEARS)  return magnitude == 1 ? "year"  : "years";
        return "";
    }

    /*
    Shows the Projection Settings dialog, which lets the user choose which income
    stream and what pay period length to use when projecting future checks. Changes
    are in-session only and do not modify stored income stream data.
    */
    private void showProjectionSettingsDialog() {
        if (incomeStreamList == null || incomeStreamList.isEmpty()) {
            android.widget.Toast.makeText(this,
                    "Add an income stream first.", android.widget.Toast.LENGTH_SHORT).show();
            return;
        }

        View dialogView = LayoutInflater.from(this)
                .inflate(R.layout.projection_settings_dialog, null);

        AutoCompleteTextView streamInput   = dialogView.findViewById(R.id.proj_stream_input);
        android.widget.RadioGroup radioGroup = dialogView.findViewById(R.id.proj_period_radio_group);
        android.widget.RadioButton radioStream  = dialogView.findViewById(R.id.proj_period_stream);
        android.widget.RadioButton radioCustom  = dialogView.findViewById(R.id.proj_period_custom);
        View           customSection  = dialogView.findViewById(R.id.proj_custom_section);
        TextInputLayout magLayout     = dialogView.findViewById(R.id.proj_custom_mag_layout);
        EditText        magInput      = dialogView.findViewById(R.id.proj_custom_mag_input);
        AutoCompleteTextView unitInput = dialogView.findViewById(R.id.proj_custom_unit_input);

        // Build stream labels: "Name  x  $amount  x  freq"
        String[] streamLabels = new String[incomeStreamList.size()];
        for (int i = 0; i < incomeStreamList.size(); i++) {
            IncomeStreamModel s = incomeStreamList.get(i);
            streamLabels[i] = s.getName() + "  ·  $" + s.getAmount()
                    + "  ·  " + s.getFrequencyDisplayString();
        }
        ArrayAdapter<String> streamAdapter = new ArrayAdapter<>(
                this, R.layout.expense_dropdown_item, streamLabels);
        streamInput.setAdapter(streamAdapter);

        // Pre-select the stream matching projStreamName (or active stream)
        int initialStreamIdx = 0;
        for (int i = 0; i < incomeStreamList.size(); i++) {
            if (incomeStreamList.get(i).getName().equals(projStreamName)) {
                initialStreamIdx = i;
                break;
            }
        }
        final int[] selectedStreamIdx = {initialStreamIdx};
        streamInput.setText(streamLabels[initialStreamIdx], false);
        streamInput.setOnItemClickListener((parent, v, pos, id) -> selectedStreamIdx[0] = pos);

        // Custom unit dropdown
        final String[] UNIT_LABELS = {"Days", "Weeks", "Months", "Years"};
        ArrayAdapter<String> unitAdapter = new ArrayAdapter<>(
                this, R.layout.expense_dropdown_item, UNIT_LABELS);
        unitInput.setAdapter(unitAdapter);

        // Pre-fill period section
        boolean isCustomPeriod = projFrequency != checkFrequency || projFreqTag != checkFrequencyTag;
        if (isCustomPeriod) {
            radioCustom.setChecked(true);
            customSection.setVisibility(android.view.View.VISIBLE);
            magInput.setText(String.valueOf(projFrequency));
            unitInput.setText(UNIT_LABELS[chronoUnitToInt(projFreqTag)], false);
        } else {
            radioStream.setChecked(true);
            customSection.setVisibility(android.view.View.GONE);
            unitInput.setText(UNIT_LABELS[1], false); // default Weeks
        }

        radioGroup.setOnCheckedChangeListener((group, checkedId) ->
                customSection.setVisibility(
                        checkedId == R.id.proj_period_custom
                                ? android.view.View.VISIBLE : android.view.View.GONE));

        AlertDialog.Builder builder = new AlertDialog.Builder(this)
                .setTitle("Projection Settings")
                .setView(dialogView)
                .setNegativeButton("Cancel", null)
                .setPositiveButton("Apply", null)
                .setNeutralButton("Reset", (d, w) -> {
                    resetProjToActiveStream();
                    goHomePage();
                });

        AlertDialog dialog = builder.create();
        dialog.setOnShowListener(d -> {
            Button applyBtn = ((AlertDialog) d).getButton(AlertDialog.BUTTON_POSITIVE);
            applyBtn.setOnClickListener(v -> {
                IncomeStreamModel chosenStream = incomeStreamList.get(selectedStreamIdx[0]);

                int newFreq;
                ChronoUnit newTag;
                if (radioCustom.isChecked()) {
                    String magStr = magInput.getText() != null
                            ? magInput.getText().toString().trim() : "";
                    if (magStr.isEmpty()) {
                        magLayout.setError("Required");
                        return;
                    }
                    int mag = 0;
                    try { mag = Integer.parseInt(magStr); } catch (NumberFormatException ignored) {}
                    if (mag <= 0) { magLayout.setError("Must be at least 1"); return; }
                    magLayout.setError(null);

                    String unitStr = unitInput.getText().toString();
                    int unitIdx = Arrays.asList(UNIT_LABELS).indexOf(unitStr);
                    if (unitIdx < 0) unitIdx = 1;
                    newFreq = mag;
                    newTag  = intFreqTagToChronoUnit(unitIdx);
                } else {
                    newFreq = chosenStream.getFrequency();
                    newTag  = intFreqTagToChronoUnit(chosenStream.getFrequencyTag());
                }
                if (newTag == null) newTag = ChronoUnit.WEEKS;

                projStreamName = chosenStream.getName();
                projFrequency  = newFreq;
                projFreqTag    = newTag;
                projAmount     = computeProjAmount(chosenStream, newFreq, newTag);

                goHomePage();
                updateCheckBarSubtitle();
                dialog.dismiss();
            });
        });
        dialog.show();
    }

    /*
    Scales a stream's pay amount to a custom period length.
    If freq/tag match the stream's own frequency, the stream amount is returned directly.
    Otherwise the amount is prorated using the ratio of custom-period days to stream-period days.
    */
    private float computeProjAmount(IncomeStreamModel stream, int freq, ChronoUnit tag) {
        ChronoUnit streamTag = intFreqTagToChronoUnit(stream.getFrequencyTag());
        if (streamTag == null) streamTag = ChronoUnit.WEEKS;
        if (freq == stream.getFrequency() && tag == streamTag) return stream.getAmountFloat();
        LocalDate now = LocalDate.now();
        long customDays = ChronoUnit.DAYS.between(now, now.plus(freq, tag));
        long streamDays = ChronoUnit.DAYS.between(now, now.plus(stream.getFrequency(), streamTag));
        if (streamDays <= 0) return stream.getAmountFloat();
        return stream.getAmountFloat() * ((float) customDays / streamDays);
    }

    private int chronoUnitToInt(ChronoUnit unit) {
        if (unit == ChronoUnit.DAYS)   return 0;
        if (unit == ChronoUnit.WEEKS)  return 1;
        if (unit == ChronoUnit.MONTHS) return 2;
        if (unit == ChronoUnit.YEARS)  return 3;
        return 1;
    }
    // End projection helpers

    public ChronoUnit intFreqTagToChronoUnit(int freqTag) {
        if (freqTag == DAY_INT) {
            return ChronoUnit.DAYS;
        } else if (freqTag == WEEK_INT) {
            return ChronoUnit.WEEKS;
        } else if (freqTag == MONTH_INT) {
            return ChronoUnit.MONTHS;
        } else if (freqTag == YEAR_INT) {
            return ChronoUnit.YEARS;
        }
        return null;
    }

    @SuppressLint("ClickableViewAccessibility")
    private void getExpenses() throws IOException, ClassNotFoundException {
        // Reference RecyclerView
        expenseTable = findViewById(R.id.expense_table);
        // Set layout as linear so items stack vertically
        expenseTable.setLayoutManager(new LinearLayoutManager(this));

        // Safe defaults — applied before storage load so any failure leaves the app functional.
        expenseListStor = new ArrayList<>();
        incomeStreamList = new ArrayList<>();
        mToday = LocalDate.now();
        curCheckDate = mToday;
        nextCheckDate = mToday.plus(1, ChronoUnit.WEEKS);
        begCheckDate = curCheckDate;
        endCheckDate = nextCheckDate;
        lastOpened = mToday;
        curBalance = 0f;
        averageCheck = 0f;
        checkFrequency = 1;
        checkFrequencyTag = ChronoUnit.WEEKS;
        projFrequency = 1;
        projFreqTag = ChronoUnit.WEEKS;
        projAmount = 0f;
        projStepsForward = 0;
        projStreamName = "";

        try {
            handleStorage(READ);
        } catch (Exception e) {
            // Corrupt or incompatible saved data (e.g. backup from an older build).
            // Defaults above remain in effect; the user starts fresh.
            Log.e("Bujit", "Storage load failed, resetting to defaults: " + e.getMessage());
            expenseListStor = new ArrayList<>();
            incomeStreamList = new ArrayList<>();
            curBalance = 0f;
            averageCheck = 0f;
            checkFrequency = 1;
            checkFrequencyTag = ChronoUnit.WEEKS;
            projFrequency = 1;
            projFreqTag = ChronoUnit.WEEKS;
            projAmount = 0f;
            projStepsForward = 0;
            projStreamName = "";
            curCheckDate = mToday;
            nextCheckDate = mToday.plus(1, ChronoUnit.WEEKS);
            begCheckDate = curCheckDate;
            endCheckDate = nextCheckDate;
            lastOpened = mToday;
        }

        checkForNextCheck();
        resetProjToActiveStream();
        bringDataUpToDate(false);
        expenseAdapter = new ExpenseAdapter(this, expenseListStor, new ClickListener() {
            @Override
            public void onPositionClicked(int position) {
                addEditExpenseDialog(EDIT, position).show();
            }

            @Override
            public void onLongClicked(int position) {
                // Selection mode is handled by the adapter on long press
            }
        }, new ExpenseAdapter.SelectionCallback() {
            @Override
            public void onEnterSelectionMode() {
                invalidateOptionsMenu();
            }

            @Override
            public void onExitSelectionMode() {
                invalidateOptionsMenu();
            }

            @Override
            public void onSelectionCountChanged(int count) {
                invalidateOptionsMenu();
            }
        });

        // Set adapter to RecyclerView
        expenseTable.setAdapter(expenseAdapter);

        // Drag-to-reorder: long-press on a row (when not in selection mode) starts a drag.
        ItemTouchHelper.SimpleCallback dragCallback = new ItemTouchHelper.SimpleCallback(
                ItemTouchHelper.UP | ItemTouchHelper.DOWN, 0) {

            @Override
            public boolean isLongPressDragEnabled() {
                return false; // drag is started manually from the adapter's long-click handler
            }

            @Override
            public boolean onMove(@NonNull RecyclerView rv,
                                  @NonNull RecyclerView.ViewHolder vh,
                                  @NonNull RecyclerView.ViewHolder target) {
                int from = vh.getAdapterPosition();
                int to   = target.getAdapterPosition();
                if (from == RecyclerView.NO_POSITION || to == RecyclerView.NO_POSITION) return false;
                Collections.swap(expenseListStor, from, to);
                expenseAdapter.notifyItemMoved(from, to);
                return true;
            }

            @Override
            public void onSwiped(@NonNull RecyclerView.ViewHolder vh, int direction) {}

            @Override
            public void onSelectedChanged(RecyclerView.ViewHolder vh, int actionState) {
                super.onSelectedChanged(vh, actionState);
                if (actionState == ItemTouchHelper.ACTION_STATE_DRAG && vh != null) {
                    vh.itemView.setAlpha(0.85f);
                    vh.itemView.setElevation(16f);
                }
            }

            @Override
            public void clearView(@NonNull RecyclerView rv, @NonNull RecyclerView.ViewHolder vh) {
                super.clearView(rv, vh);
                vh.itemView.setAlpha(1f);
                vh.itemView.setElevation(0f);
            }
        };
        ItemTouchHelper itemTouchHelper = new ItemTouchHelper(dragCallback);
        itemTouchHelper.attachToRecyclerView(expenseTable);
        expenseAdapter.setItemTouchHelper(itemTouchHelper);

        // Show last sync time immediately, then a background refresh if accounts are linked.
        updateSyncLabel();
        refreshLinkedBankBalance();
    }

    public AlertDialog addEditExpenseDialog(String method, int position) {
        // Go to home page to avoid bugs
        goHomePage();
        // Set up dialog layout
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(method.equals(ADD) ? "Add Expense" : "Edit Expense");
        LayoutInflater inflater = getLayoutInflater();
        View dialogLayout = inflater.inflate(R.layout.add_expense_layout, null);
        builder.setView(dialogLayout);

        // Set up items
        EditText expenseName = dialogLayout.findViewById(R.id.expense_name_input);
        EditText expenseCost = dialogLayout.findViewById(R.id.expense_cost_input);
        EditText expenseFrequency = dialogLayout.findViewById(R.id.expense_frequency_input);
        AutoCompleteTextView expenseFreqMagnitude = dialogLayout.findViewById(R.id.expense_frequency_magnitude_input);
        Button addExpenseStartDate = dialogLayout.findViewById(R.id.expense_start_date_input_button);
        Button fromConnectedBtn    = dialogLayout.findViewById(R.id.btn_from_connected);
        View linkedBanner          = dialogLayout.findViewById(R.id.linked_account_banner);
        TextView linkedLabel       = dialogLayout.findViewById(R.id.linked_account_label);
        Button unlinkBtn           = dialogLayout.findViewById(R.id.btn_unlink_account);
        final String[] linkedId      = {null};
        final String[] linkedToken   = {null};
        final String[] linkedDisplay = {null};
        // Calendar notification controls
        View rowCalNotif        = dialogLayout.findViewById(R.id.row_calendar_notifications);
        SwitchCompat switchCal  = dialogLayout.findViewById(R.id.switch_calendar_notifications);
        View tvNoCalSync        = dialogLayout.findViewById(R.id.tv_no_calendar_sync);
        boolean calSyncEnabled  = GoogleTasksHelper.isCalendarSyncEnabled(this);
        if (calSyncEnabled) {
            rowCalNotif.setVisibility(View.VISIBLE);
            tvNoCalSync.setVisibility(View.GONE);
        } else {
            rowCalNotif.setVisibility(View.GONE);
            tvNoCalSync.setVisibility(View.VISIBLE);
        }
        // Set up frequency unit dropdown
        String[] freqUnits = getResources().getStringArray(R.array.expense_frequency_magnitude_spinner_items);
        ArrayAdapter<String> spinnerAdapter = new ArrayAdapter<>(this, R.layout.expense_dropdown_item, freqUnits);
        expenseFreqMagnitude.setAdapter(spinnerAdapter);
        expenseFreqMagnitude.setText(freqUnits[0], false);

        expenseCost.addTextChangedListener(new CurrencyEditTextWatcher(expenseCost));
        int year;
        int month;
        int day;
        if (method.equals(EDIT)) {
            ExpenseModel expenseModel = expenseAdapter.getItem(position);
            expenseName.setText(expenseModel.getName());
            expenseCost.setText(expenseModel.getCost());
            int freqNum = expenseModel.getFrequency();
            ChronoUnit freqTag = expenseModel.getFrequencyTag();
            List<String> spinnerItems = Arrays.asList(getResources().getStringArray(
                    R.array.expense_frequency_magnitude_spinner_items));
            // Get spinner item
            int index = -1;
            if (freqTag.equals(ChronoUnit.DAYS)) {
                index = spinnerItems.indexOf("Day(s)");
            } else if (freqTag.equals(ChronoUnit.WEEKS)) {
                index = spinnerItems.indexOf("Week(s)");
            } else if (freqTag.equals(ChronoUnit.MONTHS)) {
                index = spinnerItems.indexOf("Month(s)");
            } else if (freqTag.equals(ChronoUnit.YEARS)) {
                index = spinnerItems.indexOf("Year(s)");
            }
            expenseFrequency.setText(String.valueOf(freqNum));
            if (index >= 0) expenseFreqMagnitude.setText(freqUnits[index], false);
            LocalDate expenseDate = expenseModel.getDate();
            year = expenseDate.getYear();
            month = expenseDate.getMonth().getValue();
            day = expenseDate.getDayOfMonth();
            addExpenseStartDate.setText(calendarToString(expenseDate, VIEW_FORMAT));
            if (expenseModel.isLinkedToBank()) {
                linkedId[0]      = expenseModel.getLinkedAccountId();
                linkedToken[0]   = expenseModel.getLinkedAccountToken();
                if (linkedToken[0] == null) linkedToken[0] = BankingPrefs.getTokenForAccount(this, linkedId[0]);
                linkedDisplay[0] = expenseModel.getLinkedAccountDisplay();
                linkedLabel.setText(linkedDisplay[0] != null ? linkedDisplay[0] : "Bank account");
                linkedBanner.setVisibility(View.VISIBLE);
            }
            if (calSyncEnabled) {
                switchCal.setChecked(expenseModel.isCalendarNotificationsEnabled());
            }
        } else {
            LocalDate today = LocalDate.now();
            year = today.getYear();
            month = today.getMonth().getValue();
            day = today.getDayOfMonth();
            if (calSyncEnabled) {
                switchCal.setChecked(true);
            }
        }
        final LocalDate[] testDate = {LocalDate.of(year, month, day)};
        addExpenseStartDate.setText(calendarToString(testDate[0], VIEW_FORMAT));
        DatePickerDialog.OnDateSetListener dateSetListener = new DatePickerDialog.OnDateSetListener() {
            @Override
            public void onDateSet(DatePicker datePicker, int i, int i1, int i2) {
                // DatePickerDialog uses 0 as Jan., so add 1 for LocalDate
                testDate[0] = LocalDate.of(i, i1 + 1, i2);
                addExpenseStartDate.setText(calendarToString(testDate[0], VIEW_FORMAT));
            }
        };
        addExpenseStartDate.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                // DatePickerDialog uses 0 as Jan., so subtract 1 when creating from LocalDate
                DatePickerDialog dialog = new DatePickerDialog(ExpenseActivity.this,
                        dateSetListener, year, month - 1, day);
                dialog.show();
            }
        });

        fromConnectedBtn.setOnClickListener(v -> showConnectedAccountPicker(
                expenseName, expenseCost, linkedId, linkedToken, linkedDisplay, linkedBanner, linkedLabel));
        unlinkBtn.setOnClickListener(v -> {
            linkedId[0] = null;
            linkedToken[0] = null;
            linkedDisplay[0] = null;
            linkedBanner.setVisibility(View.GONE);
        });

        builder.setNegativeButton("Cancel", (d, w) -> d.cancel());
        builder.setPositiveButton(method.equals(ADD) ? "Add Expense" : "Save Changes", null);

        if (method.equals(EDIT)) {
            builder.setNeutralButton("Delete", null);
        }

        AlertDialog dialog = builder.create();
        dialog.setOnShowListener(d -> {
            if (method.equals(EDIT)) {
                dialog.getButton(AlertDialog.BUTTON_NEUTRAL).setOnClickListener(v -> {
                    ExpenseModel toDelete = expenseListStor.get(position);
                    new AlertDialog.Builder(ExpenseActivity.this)
                            .setTitle("Delete Expense")
                            .setMessage("Delete \"" + toDelete.getName() + "\"? This cannot be undone.")
                            .setPositiveButton("Delete", (d2, w2) -> {
                                String taskId = toDelete.getGoogleTaskId();
                                if (GoogleTasksHelper.isCalendarSyncEnabled(this) && taskId != null) {
                                    executor.execute(() -> tasksHelper().deleteTask(taskId));
                                }
                                expenseListStor.remove(position);
                                expenseAdapter.notifyItemRemoved(position);
                                setFinalBalance();
                                saveNow();
                                dialog.dismiss();
                            })
                            .setNegativeButton("Cancel", null)
                            .show();
                });
            }

            Button positiveBtn = ((AlertDialog) d).getButton(AlertDialog.BUTTON_POSITIVE);
            positiveBtn.setOnClickListener(v -> {
                TextInputLayout nameLayout = dialogLayout.findViewById(R.id.add_expense_name);
                TextInputLayout costLayout = dialogLayout.findViewById(R.id.add_expense_cost);
                TextInputLayout freqLayout  = dialogLayout.findViewById(R.id.expense_frequency_layout);

                String eName    = expenseName.getText().toString().trim();
                String eCost    = expenseCost.getText().toString().trim();
                String eFreqStr = expenseFrequency.getText().toString().trim();

                boolean valid = true;
                if (eName.isEmpty()) {
                    nameLayout.setError("Name is required");
                    valid = false;
                } else {
                    nameLayout.setErrorEnabled(false);
                }
                if (eCost.isEmpty()) {
                    costLayout.setError("Amount is required");
                    valid = false;
                } else {
                    costLayout.setErrorEnabled(false);
                }
                if (eFreqStr.isEmpty()) {
                    freqLayout.setError("Required");
                    valid = false;
                } else {
                    freqLayout.setErrorEnabled(false);
                }
                if (!valid) return;

                LocalDate finalDate = testDate[0];
                int eFreqNum = Integer.parseInt(eFreqStr);
                int freqTagIndex = Arrays.asList(freqUnits).indexOf(expenseFreqMagnitude.getText().toString());
                ChronoUnit eFreqTag = null;
                if (freqTagIndex == 0)      eFreqTag = DAY;
                else if (freqTagIndex == 1) eFreqTag = WEEK;
                else if (freqTagIndex == 2) eFreqTag = MONTH;
                else if (freqTagIndex == 3) eFreqTag = YEAR;
                switch (method) {
                    case ADD: {
                        ExpenseModel newExpense = new ExpenseModel(eName, eCost, finalDate, eFreqNum, eFreqTag, false);
                        if (linkedId[0] != null) {
                            newExpense.setLinkedAccount(linkedId[0], linkedToken[0], linkedDisplay[0]);
                            BankingPrefs.saveAccountToken(this, linkedId[0], linkedToken[0]);
                        }
                        if (calSyncEnabled) {
                            newExpense.setCalendarNotificationsEnabled(switchCal.isChecked());
                            ExpenseModel expenseRef = newExpense;
                            executor.execute(() -> {
                                try {
                                    expenseRef.setGoogleTaskId(tasksHelper().createExpenseTask(expenseRef));
                                } catch (Exception ex) {
                                    mainHandler.post(() -> Toast.makeText(this,
                                            "Google Tasks sync failed: " + ex.getMessage(),
                                            Toast.LENGTH_LONG).show());
                                }
                                mainHandler.post(this::saveNow);
                            });
                        }
                        expenseListStor.add(newExpense);
                        newExpense.makeCurrent(begCheckDate, nextCheckDate);
                        expenseAdapter.notifyItemInserted(expenseListStor.size() - 1);
                        break;
                    }
                    case EDIT: {
                        ExpenseModel expenseModel = expenseAdapter.getItem(position);
                        expenseModel.setName(eName);
                        expenseModel.setCost(eCost);
                        expenseModel.setFrequency(eFreqNum);
                        expenseModel.setFrequencyTag(eFreqTag);
                        expenseModel.setDate(finalDate);
                        expenseModel.makeCurrent(begCheckDate, nextCheckDate);
                        expenseModel.setIsVariable(false);
                        if (linkedId[0] != null) {
                            expenseModel.setLinkedAccount(linkedId[0], linkedToken[0], linkedDisplay[0]);
                            BankingPrefs.saveAccountToken(this, linkedId[0], linkedToken[0]);
                        } else {
                            expenseModel.clearLinkedAccount();
                        }
                        if (calSyncEnabled) {
                            expenseModel.setCalendarNotificationsEnabled(switchCal.isChecked());
                            ExpenseModel modelRef = expenseModel;
                            executor.execute(() -> {
                                try {
                                    if (modelRef.getGoogleTaskId() != null) {
                                        tasksHelper().updateExpenseTask(modelRef);
                                    } else {
                                        modelRef.setGoogleTaskId(tasksHelper().createExpenseTask(modelRef));
                                    }
                                } catch (Exception ex) {
                                    mainHandler.post(() -> Toast.makeText(this,
                                            "Google Tasks sync failed: " + ex.getMessage(),
                                            Toast.LENGTH_LONG).show());
                                }
                                mainHandler.post(this::saveNow);
                            });
                        }
                        expenseAdapter.notifyItemChanged(position);
                        break;
                    }
                }
                shownBalance = curBalance;
                setFinalBalance();
                saveNow();
                dialog.dismiss();
            });
        });
        return dialog;
    }

    public AlertDialog changeBankBalance() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Change Bank Balance");
        LayoutInflater inflater = getLayoutInflater();
        View dialogLayout = inflater.inflate(R.layout.change_balance_layout, null);
        builder.setView(dialogLayout);

        EditText bankBalanceET = dialogLayout.findViewById(R.id.bank_balance_ET);
        bankBalanceET.setText(String.valueOf(curBalance));
        bankBalanceET.addTextChangedListener(new CurrencyEditTextWatcher(bankBalanceET));

        Button fromBankBtn = dialogLayout.findViewById(R.id.btn_from_bank);
        fromBankBtn.setOnClickListener(v -> showBankAccountPicker(bankBalanceET));

        builder.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                dialogInterface.dismiss();
            }
        });

        builder.setPositiveButton("Save", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                String balanceInput = bankBalanceET.getText().toString();
                curBalance = Float.parseFloat(balanceInput);
                shownBalance = curBalance;
                setFinalBalance();
                setCurrentBalanceText(curBalance);
            }
        });

        return builder.create();
    }

    public String calendarToString(LocalDate calendar, String format) {
        DateTimeFormatter dateFormat = DateTimeFormatter.ofPattern(format, Locale.US);
        return calendar.format(dateFormat);
    }

    public LocalDate stringToCalendar(String aSimpleDateFormat) {
        // SimpleDateFormat in yyyy.MM.dd format (STORE_FORMAT) to Calendar object
        String[] splitCal = aSimpleDateFormat.split("\\.");
        int year = Integer.parseInt(splitCal[0]);
        int month = Integer.parseInt(splitCal[1]);
        int day = Integer.parseInt(splitCal[2]);
        LocalDate retCal = LocalDate.of(year, month, day);
        return retCal;
    }

    // Sums the shownCost of every expense in the list for the currently displayed check period
    public float getCheckExpenses() {
        float expenseSum = 0;
        for (ExpenseModel anExpense : expenseListStor) {
            try { expenseSum += Float.parseFloat(anExpense.getShownCost()); }
            catch (NumberFormatException ignored) {}
        }
        return expenseSum;
    }

    /*
    Recalculates and displays the projected end-of-period balance (shownBalance - expenses).
    Text is colored green when positive and red when negative.
    */
    public void setFinalBalance() {
        if (onHomeScreen) {
            shownBalance = currencyFormat.formatToFloat(curBalance);
        }
        float finVal = shownBalance - getCheckExpenses();
        finalBalance.setText("$" + currencyFormat.formatToString(String.valueOf(finVal)));
        finalBalance.setTextColor(ContextCompat.getColor(this,
                finVal >= 0 ? R.color.balance_positive : R.color.balance_negative));
    }

    private void setCurrentBalanceText(float value) {
        currentBankBalance.setText("$" + currencyFormat.formatToString(value));
    }

    // Swipe functions
    public void getNextCheck() {
        if (incomeStreamList == null || incomeStreamList.isEmpty()) {
            Toast.makeText(this, "Add an income stream to project future checks.",
                    Toast.LENGTH_SHORT).show();
            return;
        }
        onHomeScreen = false;
        projStepsForward++;
        currentBankBalance.setClickable(false);
        expenseTable.setClickable(false);
        addExpenseButton.setImageResource(R.drawable.sharp_home);

        performCheckTransition(true, () -> {
            begCheckDate = begCheckDate.plus(projFrequency, projFreqTag);
            endCheckDate = begCheckDate.plus(projFrequency, projFreqTag);
            shownBalance -= getCheckExpenses();
            for (ExpenseModel expenseModel : expenseListStor) {
                expenseModel.getNextCheckPayments(begCheckDate, endCheckDate);
            }
            shownBalance += projAmount;
            setCurrentBalanceText(shownBalance);
            setFinalBalance();
            checkName.setText("Check of " + calendarToString(begCheckDate, HEADER_FORMAT));
            expenseAdapter.notifyDataSetChanged();
        });
    }

    public void getPrevCheck() {
        if (projStepsForward == 0) return; // already home
        if (projStepsForward == 1) {
            performCheckTransition(false, () -> goHomePage());
        } else {
            performCheckTransition(false, () -> {
                projStepsForward--;
                begCheckDate = begCheckDate.minus(projFrequency, projFreqTag);
                endCheckDate = endCheckDate.minus(projFrequency, projFreqTag);
                for (ExpenseModel expenseModel : expenseListStor) {
                    expenseModel.getPrevCheckPayments(begCheckDate, endCheckDate);
                }
                expenseAdapter.notifyDataSetChanged();
                checkName.setText("Check of " + calendarToString(begCheckDate, HEADER_FORMAT));
                shownBalance -= projAmount;
                shownBalance += getCheckExpenses();
                setFinalBalance();
                setCurrentBalanceText(shownBalance);
            });
        }
    }

    public void goHomePage() {
        // Bank balance can be edited only on home page
        currentBankBalance.setClickable(true);
        expenseTable.setClickable(true);
        begCheckDate = curCheckDate;
        endCheckDate = nextCheckDate;
        bringDataUpToDate(true);
        shownBalance = curBalance;
        setCurrentBalanceText(shownBalance);
        setFinalBalance();
        projStepsForward = 0;
        checkName.setText("This Check");
        updateCheckBarSubtitle();

        // Change floating action button icon back to "add"
        addExpenseButton.setImageResource(R.drawable.sharp_add);
        onHomeScreen = true;
    }

    /*
    Calls makeCurrent() on every expense to advance base dates to today, then
    deducts the sum of past occurrences from curBalance. Pass notifyAdapter=true
    after navigating back home so the RecyclerView rows refresh their displayed costs.
    */
    public void bringDataUpToDate(boolean notifyAdapter) {
        float paid = 0;
        for (ExpenseModel expenseModel : expenseListStor) {
            paid += expenseModel.makeCurrent(begCheckDate, nextCheckDate);
        }
        if (notifyAdapter) {
            expenseAdapter.notifyDataSetChanged();
        }
        curBalance -= paid;
        setCurrentBalanceText(curBalance);
    }

    /*
    Plays a slide-out animation on the expense list, calls updateData to swap in new
    data, then plays a slide-in animation. The nav buttons are disabled while
    animating to prevent double-taps from corrupting the check period state.
    */
    private void performCheckTransition(boolean goingForward, Runnable updateData) {
        int exitRes  = goingForward ? R.anim.slide_out_left  : R.anim.slide_out_right;
        int enterRes = goingForward ? R.anim.swipe_right_anim : R.anim.swipe_left_anim;

        nextCheckButton.setEnabled(false);
        prevCheckButton.setEnabled(false);

        Animation enter = AnimationUtils.loadAnimation(this, enterRes);
        enter.setAnimationListener(new Animation.AnimationListener() {
            @Override public void onAnimationStart(Animation a) {}
            @Override public void onAnimationRepeat(Animation a) {}
            @Override public void onAnimationEnd(Animation a) {
                nextCheckButton.setEnabled(true);
                prevCheckButton.setEnabled(true);
            }
        });

        Animation exit = AnimationUtils.loadAnimation(this, exitRes);
        exit.setAnimationListener(new Animation.AnimationListener() {
            @Override public void onAnimationStart(Animation a) {}
            @Override public void onAnimationRepeat(Animation a) {}
            @Override public void onAnimationEnd(Animation a) {
                updateData.run();
                expenseTable.startAnimation(enter);
            }
        });

        expenseTable.startAnimation(exit);
    }

    // Navigation menu
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        getMenuInflater().inflate(R.menu.expense_action_menu, menu);
        return true;
    }

    @Override
    public boolean onPrepareOptionsMenu(Menu menu) {
        boolean inSelection = expenseAdapter != null && expenseAdapter.isInSelectionMode();
        int selectedCount = inSelection ? expenseAdapter.getSelectedPositions().size() : 0;

        MenuItem selectItem = menu.findItem(R.id.action_select);
        if (selectItem != null) {
            selectItem.setVisible(!inSelection);
        }

        MenuItem deleteItem = menu.findItem(R.id.action_delete_selected);
        if (deleteItem != null) {
            deleteItem.setVisible(inSelection);
        }

        MenuItem editItem = menu.findItem(R.id.action_edit_selected);
        if (editItem != null) {
            editItem.setVisible(inSelection);
            boolean singleSelected = selectedCount == 1;
            editItem.setEnabled(singleSelected);
            if (editItem.getIcon() != null) {
                editItem.getIcon().mutate().setAlpha(singleSelected ? 255 : 100);
            }
        }

        return super.onPrepareOptionsMenu(menu);
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == R.id.action_select) {
            expenseAdapter.enterSelectionMode();
            return true;
        }
        if (item.getItemId() == R.id.action_edit_selected) {
            Set<Integer> selected = expenseAdapter.getSelectedPositions();
            if (selected.size() == 1) {
                int position = selected.iterator().next();
                expenseAdapter.exitSelectionMode();
                addEditExpenseDialog(EDIT, position).show();
            }
            return true;
        }
        if (item.getItemId() == R.id.action_delete_selected) {
            showDeleteConfirmation();
            return true;
        }
        if (actionBarDrawerToggle.onOptionsItemSelected(item)) {
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onBackPressed() {
        if (expenseAdapter != null && expenseAdapter.isInSelectionMode()) {
            expenseAdapter.exitSelectionMode();
        } else {
            super.onBackPressed();
        }
    }

    private void showDeleteConfirmation() {
        Set<Integer> selected = expenseAdapter.getSelectedPositions();
        if (selected.isEmpty()) return;
        int count = selected.size();
        new AlertDialog.Builder(this)
                .setTitle("Delete Expenses")
                .setMessage("Delete " + count + " expense" + (count == 1 ? "" : "s") + "? This cannot be undone.")
                .setPositiveButton("Delete", (d, w) -> {
                    List<Integer> positions = new ArrayList<>(selected);
                    Collections.sort(positions, Collections.reverseOrder());
                    boolean calSync = GoogleTasksHelper.isCalendarSyncEnabled(this);
                    for (int pos : positions) {
                        ExpenseModel toDelete = expenseListStor.get(pos);
                        if (calSync && toDelete.getGoogleTaskId() != null) {
                            String taskId = toDelete.getGoogleTaskId();
                            executor.execute(() -> tasksHelper().deleteTask(taskId));
                        }
                        expenseListStor.remove(pos);
                        expenseAdapter.notifyItemRemoved(pos);
                    }
                    expenseAdapter.exitSelectionMode();
                    setFinalBalance();
                    saveNow();
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    public void setNavigationViewListener() {
        navigationView = findViewById(R.id.main_navigation_view);
        navigationView.setNavigationItemSelectedListener(this);
    }

    // Navigation menu items
    @Override
    public boolean onNavigationItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.income_streams: {
                Intent incomeStreamsIntent = new Intent(this, IncomeStreamsActivity.class);
                incomeStreamsIntent.putExtra("incomeStreamList", incomeStreamList);
                getBalanceOptionsContent.launch(incomeStreamsIntent);
                break;
            }
            case R.id.banking: {
                Intent bankingIntent = new Intent(this, BankingActivity.class);
                startActivity(bankingIntent);
                drawerLayout.close();
                break;
            }
            case R.id.settings: {
                settingsContent.launch(new Intent(this, SettingsActivity.class));
                drawerLayout.close();
                break;
            }
            case R.id.credit_util: {
                Intent creditUtilizationIntent = new Intent(this, CreditUtilActivity.class);
                creditUtilizationIntent.putExtra("creditList", expenseListStor);
                creditUtilizationContent.launch(creditUtilizationIntent);
                break;
            }
        }
        return true;
    }

    private String getFirebaseIdToken() {
        try {
            FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
            if (user == null) {
                Tasks.await(FirebaseAuth.getInstance().signInAnonymously());
                user = FirebaseAuth.getInstance().getCurrentUser();
            }
            if (user != null) return Tasks.await(user.getIdToken(false)).getToken();
        } catch (Exception e) {
            Log.e("BankSync", "Firebase token fetch failed: " + e.getMessage());
        }
        return null;
    }

    private Set<String> loadBankTokens() {
        return BankingPrefs.loadTokens(this);
    }

    // Loads the (token, accountId) pairs the user chose to link to the balance.
    private Map<String, List<String>> loadLinkedAccounts() {
        try {
            Set<String> stored = BankingPrefs.loadLinkedAccounts(this);
            Map<String, List<String>> result = new HashMap<>();
            for (String entry : stored) {
                int sep = entry.indexOf('|');
                if (sep > 0) {
                    String tok = entry.substring(0, sep);
                    String id  = entry.substring(sep + 1);
                    result.computeIfAbsent(tok, k -> new ArrayList<>()).add(id);
                }
            }
            return result;
        } catch (Exception e) {
            Log.e("BankPicker", "Could not read linked accounts: " + e.getMessage());
            return Collections.emptyMap();
        }
    }

    private void saveLinkedAccounts(Set<String> composites) {
        BankingPrefs.saveLinkedAccounts(this, composites);
    }

    private void saveLastSyncTime(long millis) {
        BankingPrefs.saveLastSync(this, millis);
    }

    private long loadLastSyncTime() {
        return BankingPrefs.loadLastSync(this);
    }

    private void updateSyncLabel() {
        long millis = loadLastSyncTime();
        if (millis == 0 || loadLinkedAccounts().isEmpty()) {
            syncLabel.setVisibility(View.GONE);
            return;
        }
        syncLabel.setVisibility(View.VISIBLE);
        String timeStr = new SimpleDateFormat("h:mm a", Locale.US).format(new Date(millis));
        Calendar syncCal = Calendar.getInstance();
        syncCal.setTimeInMillis(millis);
        Calendar now = Calendar.getInstance();
        String label;
        if (now.get(Calendar.YEAR) == syncCal.get(Calendar.YEAR)
                && now.get(Calendar.DAY_OF_YEAR) == syncCal.get(Calendar.DAY_OF_YEAR)) {
            label = "Synced today at " + timeStr;
        } else {
            String dateStr = new SimpleDateFormat("MMM d", Locale.US).format(new Date(millis));
            label = "Synced " + dateStr + " at " + timeStr;
        }
        syncLabel.setText(label);
    }

    // Fetches the latest balance for every linked main-balance account and every linked expense.
    // Shows the SwipeRefreshLayout spinner; safe to call on startup or pull-to-refresh.
    private void refreshLinkedBankBalance() {
        Map<String, List<String>> tokenToIds = loadLinkedAccounts();
        boolean hasLinkedExpenses = hasAnyLinkedExpenses();

        if (tokenToIds.isEmpty() && !hasLinkedExpenses) {
            swipeRefreshLayout.setRefreshing(false);
            return;
        }
        swipeRefreshLayout.setRefreshing(true);
        executor.execute(() -> {
            String idToken = getFirebaseIdToken();
            // Sync main balance
            float total = 0;
            boolean anyFetched = false;
            for (Map.Entry<String, List<String>> entry : tokenToIds.entrySet()) {
                TellerBackendClient client = new TellerBackendClient(this, entry.getKey(), idToken);
                for (String accountId : entry.getValue()) {
                    try {
                        total += client.fetchAccountBalance(accountId);
                        anyFetched = true;
                    } catch (Exception e) {
                        Log.e("BalanceSync", "fetch failed [" + accountId + "]: " + e.getMessage());
                    }
                }
            }
            // Sync linked expense amounts and credit limits for credit cards
            boolean expensesUpdated = false;
            if (expenseListStor != null) {
                for (ExpenseModel expense : expenseListStor) {
                    if (!expense.isLinkedToBank()) continue;
                    try {
                        String tellerToken = expense.getLinkedAccountToken();
                        if (tellerToken == null) tellerToken = BankingPrefs.getTokenForAccount(this, expense.getLinkedAccountId());
                        TellerBackendClient client = new TellerBackendClient(this, tellerToken, idToken);
                        if (expense.getIsCredit()) {
                            float[] pair  = client.fetchAccountBalancePair(expense.getLinkedAccountId());
                            String debt   = String.format(Locale.US, "%.2f", pair[0]);
                            String limit  = String.format(Locale.US, "%.2f", pair[0] + pair[1]);
                            expense.setCost(debt);
                            expense.setShownCost(debt);
                            expense.setCreditLimit(limit);
                        } else {
                            float balance = client.fetchAccountBalance(expense.getLinkedAccountId());
                            String formatted = String.format(Locale.US, "%.2f", balance);
                            expense.setCost(formatted);
                            expense.setShownCost(formatted);
                        }
                        expensesUpdated = true;
                    } catch (Exception e) {
                        Log.e("LinkedExpenseSync", "fetch failed [" + expense.getName() + "]: " + e.getMessage());
                    }
                }
            }
            final float finalTotal      = total;
            final boolean fetched       = anyFetched;
            final boolean expUpdated    = expensesUpdated;
            mainHandler.post(() -> {
                swipeRefreshLayout.setRefreshing(false);
                if (fetched) {
                    curBalance   = finalTotal;
                    shownBalance = curBalance;
                    setCurrentBalanceText(curBalance);
                    saveLastSyncTime(System.currentTimeMillis());
                    updateSyncLabel();
                }
                if (expUpdated) {
                    expenseAdapter.notifyDataSetChanged();
                }
                if (fetched || expUpdated) {
                    setFinalBalance();
                }
            });
        });
    }

    // Fetches all accounts from every stored token, then shows a multi-select dialog so
    // the user can pick which accounts to sum into the balance field.
    private void showBankAccountPicker(EditText target) {
        Set<String> tokens = loadBankTokens();
        if (tokens.isEmpty()) {
            Toast.makeText(this, "No banks connected — add one in Banking.", Toast.LENGTH_SHORT).show();
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
            List<BankAccountModel> all = new ArrayList<>();
            for (String token : tokens) {
                try {
                    TellerBackendClient client = new TellerBackendClient(this, token, idToken);
                    List<BankAccountModel> fetched = client.fetchAccounts();
                    for (BankAccountModel m : fetched) {
                        String type = m.getType() != null ? m.getType().toLowerCase(Locale.US) : "";
                        if (!type.equals("credit") && !type.equals("loan")) {
                            m.setToken(token);
                            all.add(m);
                        }
                    }
                } catch (Exception e) {
                    Log.e("BankPicker", "fetch failed: " + e.getMessage());
                }
            }
            mainHandler.post(() -> {
                loadingDialog.dismiss();
                if (all.isEmpty()) {
                    Toast.makeText(this, "No depository accounts found.", Toast.LENGTH_SHORT).show();
                    return;
                }
                Set<String> alreadyLinked = new HashSet<>(BankingPrefs.loadLinkedAccounts(this));
                String[] labels  = new String[all.size()];
                boolean[] checked = new boolean[all.size()];
                for (int i = 0; i < all.size(); i++) {
                    BankAccountModel m = all.get(i);
                    labels[i] = m.getInstitutionName()
                            + " - " + m.getDisplayType()
                            + " (…" + m.getLastFour() + ")"
                            + "  $" + m.getLedgerBalance();
                    checked[i] = alreadyLinked.contains(m.getToken() + "|" + m.getId());
                }
                new AlertDialog.Builder(this)
                        .setTitle("Link accounts to balance")
                        .setMultiChoiceItems(labels, checked,
                                (d, idx, isChecked) -> checked[idx] = isChecked)
                        .setPositiveButton("Use Total", (d, w) -> {
                            double total = 0;
                            Set<String> linked = new HashSet<>();
                            for (int i = 0; i < all.size(); i++) {
                                if (checked[i]) {
                                    BankAccountModel m = all.get(i);
                                    try { total += Double.parseDouble(m.getLedgerBalance()); }
                                    catch (NumberFormatException ignored) {}
                                    linked.add(m.getToken() + "|" + m.getId());
                                }
                            }
                            target.setText(String.format(Locale.US, "%.2f", total));
                            saveLinkedAccounts(linked);
                            saveLastSyncTime(System.currentTimeMillis());
                            updateSyncLabel();
                        })
                        .setNegativeButton("Cancel", null)
                        .show();
            });
        });
    }

    // Shows a single-select picker of credit/loan accounts for linking to an expense.
    private void showConnectedAccountPicker(
            EditText nameField,
            EditText costField,
            String[] linkedId,
            String[] linkedToken,
            String[] linkedDisplay,
            View bannerView,
            TextView bannerLabel) {

        Set<String> tokens = loadBankTokens();
        if (tokens.isEmpty()) {
            Toast.makeText(this, "No banks connected — add one in Banking.", Toast.LENGTH_SHORT).show();
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
            List<BankAccountModel> all = new ArrayList<>();
            for (String token : tokens) {
                try {
                    TellerBackendClient client = new TellerBackendClient(this, token, idToken);
                    List<BankAccountModel> accounts = client.fetchAccounts();
                    for (BankAccountModel m : accounts) {
                        String type = m.getType() != null ? m.getType().toLowerCase(Locale.US) : "";
                        if (type.equals("credit") || type.equals("loan")) {
                            m.setToken(token);
                            all.add(m);
                        }
                    }
                } catch (Exception e) {
                    Log.e("ConnectedPicker", "fetch failed: " + e.getMessage());
                }
            }
            mainHandler.post(() -> {
                loadingDialog.dismiss();
                if (all.isEmpty()) {
                    Toast.makeText(this, "No credit or loan accounts found.", Toast.LENGTH_SHORT).show();
                    return;
                }
                String[] labels = new String[all.size()];
                for (int i = 0; i < all.size(); i++) {
                    BankAccountModel m = all.get(i);
                    labels[i] = m.getInstitutionName()
                            + " – " + m.getDisplayType()
                            + " (…" + m.getLastFour() + ")"
                            + "  $" + formatBalance(m.getLedgerBalance());
                }
                new AlertDialog.Builder(this)
                        .setTitle("Link connected account")
                        .setItems(labels, (d, idx) -> {
                            BankAccountModel selected = all.get(idx);
                            String display = selected.getInstitutionName()
                                    + " " + selected.getDisplayType()
                                    + " …" + selected.getLastFour();
                            String amount = formatBalance(selected.getLedgerBalance());
                            linkedId[0]      = selected.getId();
                            linkedToken[0]   = selected.getToken();
                            linkedDisplay[0] = display;
                            if (nameField.getText() == null || nameField.getText().toString().trim().isEmpty()) {
                                nameField.setText(display);
                            }
                            costField.setText(amount);
                            bannerLabel.setText(display);
                            bannerView.setVisibility(View.VISIBLE);
                        })
                        .setNegativeButton("Cancel", null)
                        .show();
            });
        });
    }

    private boolean hasAnyLinkedExpenses() {
        if (expenseListStor == null) return false;
        for (ExpenseModel e : expenseListStor) {
            if (e.isLinkedToBank()) return true;
        }
        return false;
    }

    private String formatBalance(String raw) {
        if (raw == null || raw.isEmpty()) return "0.00";
        try {
            return String.format(Locale.US, "%.2f", Double.parseDouble(raw));
        } catch (NumberFormatException e) {
            return "0.00";
        }
    }

    private void saveNow() {
        try {
            handleStorage(WRITE);
        } catch (IOException | ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    private GoogleTasksHelper tasksHelper() {
        if (googleTasksHelper == null) googleTasksHelper = new GoogleTasksHelper(this);
        return googleTasksHelper;
    }

    @Override
    protected void onResume() {
        super.onResume();

        // Reload expense list if BankingActivity deleted linked credit entries while we were paused.
        SharedPreferences bankingPrefs = getSharedPreferences(
                BankingActivity.PREFS_NAME, MODE_PRIVATE);
        if (bankingPrefs.getBoolean(BankingActivity.KEY_BANKING_EXPENSE_CHANGED, false)) {
            bankingPrefs.edit().remove(BankingActivity.KEY_BANKING_EXPENSE_CHANGED).apply();
            reloadExpenseListFromDisk();
        }

        SharedPreferences calPrefs = getSharedPreferences("bujit_calendar_prefs", MODE_PRIVATE);
        boolean needsCheck = calPrefs.getBoolean("needs_sync_check", false);
        boolean pendingDisconnect = calPrefs.getBoolean("pending_disconnect", false);
        if (needsCheck || pendingDisconnect) {
            calPrefs.edit().remove("needs_sync_check").apply();
            if (pendingDisconnect) {
                triggerCalendarCleanup();
            } else if (GoogleTasksHelper.isCalendarSyncEnabled(this)) {
                triggerInitialCalendarSync();
            }
        }
    }

    private void reloadExpenseListFromDisk() {
        try {
            StorageManager manager = new StorageManager(getApplicationContext());
            ArrayList<ExpenseModel> fresh = manager.getStorageHolder().getExpenseList();
            expenseListStor.clear();
            expenseListStor.addAll(fresh);
            bringDataUpToDate(true);
            setFinalBalance();
        } catch (Exception e) {
            Log.e("Bujit", "reloadExpenseListFromDisk failed: " + e.getMessage());
        }
    }

    /*
    Creates Google Tasks for any expenses or income streams that do not yet have a
    task ID. Called on resume after the user enables Google Calendar sync in Settings.
    */
    private void triggerInitialCalendarSync() {
        if (expenseListStor == null || incomeStreamList == null) return;
        executor.execute(() -> {
            GoogleTasksHelper.SyncResult result =
                    tasksHelper().syncAll(expenseListStor, incomeStreamList);
            mainHandler.post(() -> {
                saveNow();
                if (result.failed > 0) {
                    Toast.makeText(this,
                            "Google Tasks sync: " + result.created + " created, "
                                    + result.failed + " failed.\nError: " + result.lastError,
                            Toast.LENGTH_LONG).show();
                } else if (result.created > 0) {
                    Toast.makeText(this,
                            result.created + " task(s) added to Bujit list in Google Tasks.\n"
                                    + "In Google Calendar, enable the Bujit list to see them.",
                            Toast.LENGTH_LONG).show();
                }
            });
        });
    }

    /*
    Deletes all Bujit tasks from Google Tasks and signs the user out of Google.
    Called on resume when a "pending_disconnect" flag is set by SettingsActivity.
    The cleanup runs while the Google token is still valid; the sign-out comes after.
    */
    private void triggerCalendarCleanup() {
        if (expenseListStor == null || incomeStreamList == null) return;
        executor.execute(() -> {
            tasksHelper().disconnectAndDeleteAll(expenseListStor, incomeStreamList);
            mainHandler.post(() -> {
                getSharedPreferences("bujit_calendar_prefs", MODE_PRIVATE)
                        .edit().remove("pending_disconnect").apply();
                GoogleTasksHelper.buildSignInClient(this).signOut();
                saveNow();
            });
        });
    }

    // Save data before app closed
    @Override
    protected void onPause() {
        super.onPause();
        try {
            goHomePage();
            handleStorage(WRITE);
        } catch (IOException | ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        executor.shutdown();
    }
}