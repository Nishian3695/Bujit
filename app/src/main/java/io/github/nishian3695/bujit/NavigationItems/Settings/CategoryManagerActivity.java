package io.github.nishian3695.bujit.NavigationItems.Settings;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.StorageManagement.CategoryManager;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import io.github.nishian3695.bujit.ThemeHelper;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;

/*
Lets the user manage their spending category list: drag to reorder, add new categories,
and remove existing ones. Every confirmed change is written to storage immediately.
"Other" is always the fallback and is not editable here.
*/
public class CategoryManagerActivity extends AppCompatActivity {

    private static final String TAG = "CategoryManager";

    private StorageManager storageManager;
    private StorageHolder  storageHolder;
    private ArrayList<String> categories;
    private CategoryAdapter adapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_category_manager);
        ThemeHelper.tintActionBar(this);

        ViewCompat.setOnApplyWindowInsetsListener(
                ((ViewGroup) findViewById(android.R.id.content)).getChildAt(0),
                (v, insets) -> {
                    Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
                    v.setPadding(0, bars.top, 0, bars.bottom);
                    return WindowInsetsCompat.CONSUMED;
                });

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Categories");
        }

        try {
            storageManager = new StorageManager(this);
            storageHolder  = storageManager.getStorageHolder();
        } catch (IOException | ClassNotFoundException e) {
            storageHolder = new StorageHolder();
        }

        categories = new ArrayList<>(storageHolder.getCategoryList());

        RecyclerView recycler = findViewById(R.id.category_recycler);
        recycler.setLayoutManager(new LinearLayoutManager(this));
        adapter = new CategoryAdapter();
        recycler.setAdapter(adapter);

        final boolean[] dragged = {false};

        ItemTouchHelper.SimpleCallback dragCallback = new ItemTouchHelper.SimpleCallback(
                ItemTouchHelper.UP | ItemTouchHelper.DOWN, 0) {

            @Override public boolean isLongPressDragEnabled() { return false; }

            @Override
            public boolean onMove(@NonNull RecyclerView rv,
                                  @NonNull RecyclerView.ViewHolder from,
                                  @NonNull RecyclerView.ViewHolder to) {
                int f = from.getAdapterPosition();
                int t = to.getAdapterPosition();
                if (f == RecyclerView.NO_POSITION || t == RecyclerView.NO_POSITION) return false;
                Collections.swap(categories, f, t);
                adapter.notifyItemMoved(f, t);
                dragged[0] = true;
                return true;
            }

            @Override public void onSwiped(@NonNull RecyclerView.ViewHolder vh, int dir) {}

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
                // Save immediately when the drag gesture ends
                if (dragged[0]) {
                    dragged[0] = false;
                    saveNow();
                }
            }
        };
        ItemTouchHelper ith = new ItemTouchHelper(dragCallback);
        ith.attachToRecyclerView(recycler);
        adapter.setItemTouchHelper(ith);

        FloatingActionButton fab = findViewById(R.id.category_add_fab);
        ThemeHelper.tintFab(fab, this);
        fab.setOnClickListener(v -> showAddDialog());
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) { finish(); return true; }
        return super.onOptionsItemSelected(item);
    }

    public static final String KEY_CATEGORIES_CHANGED = "categories_changed";

    private void saveNow() {
        storageHolder.setCategoryList(new ArrayList<>(categories));
        try {
            storageManager.writeData(storageHolder);
            getSharedPreferences("bujit_prefs", MODE_PRIVATE)
                    .edit().putBoolean(KEY_CATEGORIES_CHANGED, true).apply();
        } catch (IOException e) {
            Log.e(TAG, "Failed to save categories", e);
        }
    }

    private boolean isDuplicate(String name) {
        if (CategoryManager.OTHER.equalsIgnoreCase(name)) return true;
        for (String existing : categories) {
            if (existing.equalsIgnoreCase(name)) return true;
        }
        return false;
    }

    private void showAddDialog() {
        EditText input = new EditText(this);
        input.setHint("Category name");
        input.setInputType(android.text.InputType.TYPE_CLASS_TEXT | android.text.InputType.TYPE_TEXT_FLAG_CAP_WORDS);
        int padPx = (int)(16 * getResources().getDisplayMetrics().density);
        FrameLayout container = new FrameLayout(this);
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.setMargins(padPx, 0, padPx, 0);
        input.setLayoutParams(lp);
        container.addView(input);

        AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("New Category")
                .setView(container)
                .setPositiveButton("Add", null)
                .setNegativeButton("Cancel", null)
                .create();

        dialog.setOnShowListener(d -> {
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> {
                String name = input.getText().toString().trim();
                if (name.isEmpty()) {
                    input.setError("Name is required");
                    return;
                }
                if (isDuplicate(name)) {
                    input.setError("Category already exists");
                    return;
                }
                categories.add(name);
                adapter.notifyItemInserted(categories.size() - 1);
                saveNow();
                dialog.dismiss();
            });
        });
        dialog.show();
    }

    // ── Adapter ──────────────────────────────────────────────────────────────

    private class CategoryAdapter extends RecyclerView.Adapter<CategoryAdapter.VH> {

        private ItemTouchHelper itemTouchHelper;

        void setItemTouchHelper(ItemTouchHelper ith) { this.itemTouchHelper = ith; }

        @NonNull @Override
        public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View v = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.category_item, parent, false);
            return new VH(v);
        }

        @Override
        public void onBindViewHolder(@NonNull VH holder, int position) {
            holder.name.setText(categories.get(position));
            holder.dragHandle.setOnTouchListener((v, event) -> {
                if (event.getActionMasked() == android.view.MotionEvent.ACTION_DOWN) {
                    itemTouchHelper.startDrag(holder);
                }
                return false;
            });
            holder.deleteBtn.setOnClickListener(v -> {
                int pos = holder.getAdapterPosition();
                if (pos == RecyclerView.NO_POSITION) return;
                String catName = categories.get(pos);
                new AlertDialog.Builder(CategoryManagerActivity.this)
                        .setTitle("Remove Category")
                        .setMessage("Remove \"" + catName + "\"? Expenses tagged with this category will show as \"Other\".")
                        .setPositiveButton("Remove", (d, w) -> {
                            categories.remove(pos);
                            notifyItemRemoved(pos);
                            for (io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel e
                                    : storageHolder.getExpenseList()) {
                                if (catName.equalsIgnoreCase(e.getCategory())) {
                                    e.setCategory(CategoryManager.OTHER);
                                }
                            }
                            saveNow();
                        })
                        .setNegativeButton("Cancel", null)
                        .show();
            });
        }

        @Override public int getItemCount() { return categories.size(); }

        class VH extends RecyclerView.ViewHolder {
            final TextView name;
            final TextView dragHandle;
            final View     deleteBtn;
            VH(View v) {
                super(v);
                name       = v.findViewById(R.id.category_name);
                dragHandle = v.findViewById(R.id.category_drag_handle);
                deleteBtn  = v.findViewById(R.id.category_delete_btn);
            }
        }
    }
}
