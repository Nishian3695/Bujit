package io.github.nishian3695.bujit.NavigationItems.SingleEvents;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
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
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import io.github.nishian3695.bujit.ThemeHelper;
import java.util.ArrayList;
import java.util.Locale;

public class SingleEventsActivity extends AppCompatActivity {

    public static final String KEY_CHANGED = "single_events_changed";

    private StorageManager storageManager;
    private StorageHolder storageHolder;
    private ArrayList<SingleEventModel> eventList;
    private float curBalance;
    private SingleEventAdapter adapter;
    private int expiryDays;
    private View emptyView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);
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
            curBalance = storageHolder.getCurrentBalance();
        } catch (Exception e) {
            Log.e("SingleEvents", "load failed: " + e.getMessage());
            eventList = new ArrayList<>();
            curBalance = 0f;
        }

        cleanupExpired();

        // Newest-first order
        eventList.sort((a, b) -> b.getLastModifiedDate().compareTo(a.getLastModifiedDate()));

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

    private void cleanupExpired() {
        boolean any = false;
        java.util.Iterator<SingleEventModel> it = eventList.iterator();
        while (it.hasNext()) {
            if (it.next().isExpired(expiryDays)) {
                it.remove();
                any = true;
            }
        }
        if (any) saveData(false);
    }

    private void showEventDialog(SingleEventModel existing, int position) {
        boolean isAdd = (existing == null);

        View dialogView = LayoutInflater.from(this).inflate(R.layout.add_single_event_layout, null);
        TextInputLayout nameLayout = dialogView.findViewById(R.id.add_single_event_name);
        TextInputLayout amountLayout = dialogView.findViewById(R.id.add_single_event_amount);
        EditText nameField = dialogView.findViewById(R.id.single_event_name_input);
        EditText amountField = dialogView.findViewById(R.id.single_event_amount_input);
        MaterialButtonToggleGroup typeToggle = dialogView.findViewById(R.id.single_event_type_toggle);

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

                if (isAdd) {
                    SingleEventModel model = new SingleEventModel(name, amount, isDebit);
                    curBalance += model.getAppliedAmount();
                    eventList.add(0, model);
                    adapter.notifyItemInserted(0);
                } else {
                    String oldName = existing.getName();
                    float delta = existing.applyUpdate(amount, isDebit);
                    existing.setName(name);
                    curBalance += delta;
                    eventList.sort((a, b) -> b.getLastModifiedDate().compareTo(a.getLastModifiedDate()));
                    adapter.notifyDataSetChanged();
                }

                saveData(true);
                updateEmptyState();
                dialog.dismiss();
            });
        });

        dialog.show();
    }

    private void showDeleteConfirmation(int position) {
        if (position < 0 || position >= eventList.size()) return;
        SingleEventModel item = eventList.get(position);
        new AlertDialog.Builder(this)
                .setTitle("Remove Event")
                .setMessage("Remove \"" + item.getName() + "\"? Its effect on your balance will be undone.")
                .setPositiveButton("Remove", (d, w) -> {
                    curBalance -= item.getAppliedAmount();
                    eventList.remove(position);
                    adapter.notifyItemRemoved(position);
                    saveData(true);
                    updateEmptyState();
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    private void saveData(boolean flagChanged) {
        try {
            storageHolder.setSingleEventList(eventList);
            storageHolder.setCurrentBalance(curBalance);
            storageManager.writeData(storageHolder);
            if (flagChanged) {
                getSharedPreferences("bujit_prefs", MODE_PRIVATE)
                        .edit().putBoolean(KEY_CHANGED, true).apply();
            }
        } catch (Exception e) {
            Log.e("SingleEvents", "save failed: " + e.getMessage());
        }
    }

    private int getExpiryDays() {
        return getSharedPreferences("bujit_prefs", MODE_PRIVATE)
                .getInt("single_event_expiry_days", 30);
    }

    private void updateEmptyState() {
        if (emptyView != null) {
            emptyView.setVisibility(eventList.isEmpty() ? View.VISIBLE : View.GONE);
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) { finish(); return true; }
        return super.onOptionsItemSelected(item);
    }
}
