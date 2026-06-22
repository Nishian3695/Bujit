package io.github.nishian3695.bujit.NavigationItems.IncomeStreams;

import android.app.DatePickerDialog;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.WindowCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.CustomListeners.CurrencyEditTextWatcher;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import io.github.nishian3695.bujit.ThemeHelper;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.textfield.TextInputLayout;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Locale;

/*
Activity for managing income streams (pay sources).

Each income stream represents a paycheck: a name, amount, start date, and recurrence
frequency. The user can have multiple streams (e.g. two part-time jobs). Exactly one
stream is marked "selected" at a time; that stream drives the balance projection in
ExpenseActivity.

The activity receives the current stream list via Intent extras, shows it in a
RecyclerView, and returns the updated list to ExpenseActivity via setResult when
the user navigates back.

Changes are also persisted directly to disk in onPause() as a safety net in case
the activity is killed before onActivityResult fires.
*/
public class IncomeStreamsActivity extends AppCompatActivity {

    private static final String VIEW_FORMAT    = "EEEE, MMMM d, yyyy";
    private static final String STORE_FORMAT   = "yyyy.MM.dd";
    private static final String COMPARE_FORMAT = "yyyyMMdd";

    private static final String[] FREQ_LABELS       = {"Weekly", "Biweekly", "Monthly", "Yearly", "Custom"};
    private static final int[]    FREQ_TAGS          = {1, 1, 2, 3};
    private static final int[]    FREQ_MAGS          = {1, 2, 1, 1};
    private static final int      CUSTOM_INDEX       = 4;
    private static final String[] CUSTOM_UNIT_LABELS = {"Days", "Weeks", "Months", "Years"};
    private static final int[]    CUSTOM_UNIT_TAGS   = {0, 1, 2, 3};

    private ArrayList<IncomeStreamModel> streamList;
    private IncomeStreamAdapter adapter;
    private RecyclerView recyclerView;
    private View emptyState;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);
        WindowCompat.setDecorFitsSystemWindows(getWindow(), true);
        setContentView(R.layout.activity_income_streams);
        ThemeHelper.tintActionBar(this);

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Income Streams");
        }

        //noinspection unchecked
        streamList = (ArrayList<IncomeStreamModel>)
                getIntent().getSerializableExtra("incomeStreamList");
        if (streamList == null) streamList = new ArrayList<>();

        recyclerView = findViewById(R.id.income_streams_list);
        emptyState   = findViewById(R.id.income_streams_empty_state);

        FloatingActionButton fab = findViewById(R.id.income_streams_fab);
        ThemeHelper.tintFab(fab, this);

        adapter = new IncomeStreamAdapter(this, streamList, new IncomeStreamAdapter.Listener() {
            @Override
            public void onSelect(int position) {
                for (int i = 0; i < streamList.size(); i++) {
                    streamList.get(i).setSelected(i == position);
                }
                adapter.notifyDataSetChanged();
            }

            @Override
            public void onEdit(int position) {
                showAddEditDialog(position);
            }

            @Override
            public void onDelete(int position) {
                IncomeStreamModel target = streamList.get(position);
                new AlertDialog.Builder(IncomeStreamsActivity.this)
                        .setTitle("Remove Income Stream")
                        .setMessage("Remove \"" + target.getName() + "\"?")
                        .setPositiveButton("Remove", (d, w) -> {
                            boolean wasSelected = target.isSelected();
                            streamList.remove(position);
                            adapter.notifyItemRemoved(position);
                            if (wasSelected && !streamList.isEmpty()) {
                                streamList.get(0).setSelected(true);
                                adapter.notifyItemChanged(0);
                            }
                            updateUiState();
                        })
                        .setNegativeButton("Cancel", null)
                        .show();
            }
        });

        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(adapter);

        fab.setOnClickListener(v -> showAddEditDialog(-1));

        updateUiState();
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            returnResult();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onBackPressed() {
        returnResult();
    }

    private void returnResult() {
        Intent result = new Intent();
        result.putExtra("incomeStreamList", streamList);
        setResult(RESULT_OK, result);
        finish();
    }

    // Add / Edit dialog

    private void showAddEditDialog(int position) {
        boolean isEdit = position >= 0;
        IncomeStreamModel existing = isEdit ? streamList.get(position) : null;

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(isEdit ? "Edit Income Stream" : "Add Income Stream");

        View dialogView = LayoutInflater.from(this)
                .inflate(R.layout.add_income_stream_dialog, null);
        builder.setView(dialogView);

        TextInputLayout   nameLayout    = dialogView.findViewById(R.id.income_stream_name_layout);
        EditText          nameInput     = dialogView.findViewById(R.id.income_stream_name_input);
        TextInputLayout   amountLayout  = dialogView.findViewById(R.id.income_stream_amount_layout);
        EditText          amountInput   = dialogView.findViewById(R.id.income_stream_amount_input);
        Button            dateButton    = dialogView.findViewById(R.id.income_stream_date_button);
        AutoCompleteTextView freqInput  = dialogView.findViewById(R.id.income_stream_freq_input);
        View              customSection = dialogView.findViewById(R.id.income_stream_custom_freq_section);
        TextInputLayout   customMagLayout = dialogView.findViewById(R.id.income_stream_custom_mag_layout);
        EditText          customMagInput  = dialogView.findViewById(R.id.income_stream_custom_mag_input);
        AutoCompleteTextView customUnitInput = dialogView.findViewById(R.id.income_stream_custom_unit_input);

        amountInput.addTextChangedListener(new CurrencyEditTextWatcher(amountInput));

        // Frequency dropdown
        ArrayAdapter<String> freqAdapter = new ArrayAdapter<>(
                this, R.layout.expense_dropdown_item, FREQ_LABELS);
        freqInput.setAdapter(freqAdapter);

        ArrayAdapter<String> unitAdapter = new ArrayAdapter<>(
                this, R.layout.expense_dropdown_item, CUSTOM_UNIT_LABELS);
        customUnitInput.setAdapter(unitAdapter);

        // Date picker state
        final Calendar dateState = Calendar.getInstance();
        truncateCalendar(dateState);

        if (isEdit) {
            nameInput.setText(existing.getName());
            amountInput.setText(existing.getAmount());

            // Pre-fill date
            String[] parts = existing.getCheckDate().split("\\.");
            dateState.set(Integer.parseInt(parts[0]),
                    Integer.parseInt(parts[1]) - 1,
                    Integer.parseInt(parts[2]));

            // Pre-fill frequency
            int freq = existing.getFrequency();
            int tag  = existing.getFrequencyTag();
            int freqIndex = resolveFreqIndex(freq, tag);
            freqInput.setText(FREQ_LABELS[freqIndex], false);
            if (freqIndex == CUSTOM_INDEX) {
                customSection.setVisibility(View.VISIBLE);
                customMagInput.setText(String.valueOf(freq));
                int unitIdx = Math.max(0, Math.min(3, tag));
                customUnitInput.setText(CUSTOM_UNIT_LABELS[unitIdx], false);
            } else {
                customSection.setVisibility(View.GONE);
                customUnitInput.setText(CUSTOM_UNIT_LABELS[1], false);
            }
        } else {
            freqInput.setText(FREQ_LABELS[0], false); // default Weekly
            customSection.setVisibility(View.GONE);
            customUnitInput.setText(CUSTOM_UNIT_LABELS[1], false);
        }

        dateButton.setText(calendarToString(dateState, VIEW_FORMAT));
        dateButton.setOnClickListener(v -> {
            int y = dateState.get(Calendar.YEAR);
            int m = dateState.get(Calendar.MONTH);
            int d = dateState.get(Calendar.DAY_OF_MONTH);
            new DatePickerDialog(this, (picker, year, month, day) -> {
                dateState.set(year, month, day);
                dateButton.setText(calendarToString(dateState, VIEW_FORMAT));
            }, y, m, d).show();
        });

        freqInput.setOnItemClickListener((parent, v, pos, id) ->
                customSection.setVisibility(pos == CUSTOM_INDEX ? View.VISIBLE : View.GONE));

        builder.setNegativeButton("Cancel", null);
        builder.setPositiveButton(isEdit ? "Save" : "Add", null);

        AlertDialog dialog = builder.create();
        dialog.setOnShowListener(d -> {
            Button positive = ((AlertDialog) d).getButton(AlertDialog.BUTTON_POSITIVE);
            positive.setOnClickListener(v -> {
                String name      = nameInput.getText().toString().trim();
                String amountStr = amountInput.getText().toString().trim();

                boolean valid = true;
                if (name.isEmpty()) {
                    nameLayout.setError("Name is required");
                    valid = false;
                } else {
                    nameLayout.setError(null);
                }
                if (amountStr.isEmpty()) {
                    amountLayout.setError("Amount is required");
                    valid = false;
                } else {
                    amountLayout.setError(null);
                }

                int selIndex = Arrays.asList(FREQ_LABELS)
                        .indexOf(freqInput.getText().toString());
                if (selIndex < 0) selIndex = 0;

                int savedFreqTag, savedFreqMag;
                if (selIndex == CUSTOM_INDEX) {
                    String magStr = customMagInput.getText() != null
                            ? customMagInput.getText().toString().trim() : "";
                    if (magStr.isEmpty()) {
                        customMagLayout.setError("Required");
                        valid = false;
                    } else {
                        int mag = 0;
                        try { mag = Integer.parseInt(magStr); } catch (NumberFormatException ignored) {}
                        if (mag <= 0) {
                            customMagLayout.setError("Must be at least 1");
                            valid = false;
                        } else {
                            customMagLayout.setError(null);
                        }
                    }
                    int unitIdx = Arrays.asList(CUSTOM_UNIT_LABELS)
                            .indexOf(customUnitInput.getText().toString());
                    if (unitIdx < 0) unitIdx = 1;
                    savedFreqTag = CUSTOM_UNIT_TAGS[unitIdx];
                    savedFreqMag = valid ? Integer.parseInt(
                            customMagInput.getText().toString().trim()) : 1;
                } else {
                    savedFreqTag = FREQ_TAGS[selIndex];
                    savedFreqMag = FREQ_MAGS[selIndex];
                }

                if (!valid) return;

                // Walk start date back if in the future
                Calendar today      = Calendar.getInstance();
                int      setDateInt = Integer.parseInt(calendarToString(dateState, COMPARE_FORMAT));
                int      todayInt   = Integer.parseInt(calendarToString(today, COMPARE_FORMAT));
                int      calField   = tagToCalendarField(savedFreqTag);
                while (setDateInt > todayInt) {
                    dateState.add(calField, -savedFreqMag);
                    setDateInt = Integer.parseInt(calendarToString(dateState, COMPARE_FORMAT));
                }

                String checkDateStr = calendarToString(dateState, STORE_FORMAT);

                if (isEdit) {
                    existing.setName(name);
                    existing.setAmount(amountStr);
                    existing.setCheckDate(checkDateStr);
                    existing.setFrequency(savedFreqMag);
                    existing.setFrequencyTag(savedFreqTag);
                    adapter.notifyItemChanged(position);
                } else {
                    IncomeStreamModel newStream = new IncomeStreamModel(
                            name, amountStr, checkDateStr, savedFreqMag, savedFreqTag);
                    // Auto-select if this is the first stream
                    if (streamList.isEmpty()) newStream.setSelected(true);
                    streamList.add(newStream);
                    adapter.notifyItemInserted(streamList.size() - 1);
                    updateUiState();
                }

                dialog.dismiss();
            });
        });

        dialog.show();
    }

    // UI state

    private void updateUiState() {
        if (streamList.isEmpty()) {
            emptyState.setVisibility(View.VISIBLE);
            recyclerView.setVisibility(View.GONE);
        } else {
            emptyState.setVisibility(View.GONE);
            recyclerView.setVisibility(View.VISIBLE);
        }
    }

    // Persist to storage

    private void persistToStorage() {
        try {
            StorageManager manager = new StorageManager(getApplicationContext());
            StorageHolder holder = manager.getStorageHolder();
            holder.setIncomeStreamList(streamList);
            manager.writeData(holder);
        } catch (Exception e) {
            Log.e("IncomeStreams", "Failed to persist: " + e.getMessage());
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        persistToStorage();
    }

    // Helpers

    // Maps a stored (freq, tag) pair back to its position in the FREQ_LABELS dropdown array
    private int resolveFreqIndex(int freq, int tag) {
        if (freq == 1 && tag == 1) return 0; // Weekly
        if (freq == 2 && tag == 1) return 1; // Biweekly
        if (freq == 1 && tag == 2) return 2; // Monthly
        if (freq == 1 && tag == 3) return 3; // Yearly
        return CUSTOM_INDEX;
    }

    private int tagToCalendarField(int tag) {
        switch (tag) {
            case 0: return Calendar.DAY_OF_MONTH;
            case 2: return Calendar.MONTH;
            case 3: return Calendar.YEAR;
            default: return Calendar.WEEK_OF_YEAR;
        }
    }

    private String calendarToString(Calendar calendar, String format) {
        return new SimpleDateFormat(format, Locale.US).format(calendar.getTime());
    }

    // Zeroes the time fields (hour, minute, second, millisecond) on a Calendar instance
    private void truncateCalendar(Calendar cal) {
        for (int field : new int[]{
                Calendar.HOUR, Calendar.MINUTE, Calendar.SECOND, Calendar.MILLISECOND}) {
            cal.set(field, 0);
        }
    }
}
