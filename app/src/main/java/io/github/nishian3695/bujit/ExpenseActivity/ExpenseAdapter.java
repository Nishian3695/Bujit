package io.github.nishian3695.bujit.ExpenseActivity;

import android.content.Context;
import android.content.res.ColorStateList;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CheckBox;
import android.widget.LinearLayout;
import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.CustomListeners.CurrencyFormat;
import io.github.nishian3695.bujit.Interfaces.ClickListener;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.ThemeHelper;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

/*
RecyclerView adapter for the expense list on the main screen.

Normal mode: tapping an item opens the edit dialog; long-pressing starts a
drag-to-reorder operation via ItemTouchHelper

Selection mode: entered by calling enterSelectionMode() from the host activity.
While active, tapping toggles item selection and the floating action button
becomes a home button. A hidden checkbox column slides in with an animation
by translating both the checkbox and the content row, so column widths appear
unchanged without triggering a layout reflow

SelectionCallback notifies the host Activity to update the action bar menu
(showing delete/edit actions when items are selected)
*/
public class ExpenseAdapter extends RecyclerView.Adapter<ExpenseViewHolder> {

    /*
    Notifies the host Activity when selection mode starts, ends, or the
    number of selected items changes so the action bar can be updated.
    */
    public interface SelectionCallback {
        void onEnterSelectionMode();
        void onExitSelectionMode();
        void onSelectionCountChanged(int count);
    }

    private static final int ANIM_DURATION = 180;

    Context context;
    ArrayList<ExpenseModel> expenseList;
    private final ClickListener clickListener;
    private final SelectionCallback selectionCallback;

    private boolean selectionMode = false;
    private final Set<Integer> selectedPositions = new HashSet<>();

    // Offset (px) by which content shifts right when selection mode is revealed.
    // Measured on first bind; falls back to 48dp (matches XML layout_width) until then.
    private float checkboxOffset = 0f;

    private RecyclerView recyclerView;
    private ItemTouchHelper itemTouchHelper;

    // Wires the adapter to the expense data list plus the two callback interfaces the host
    // activity uses to react to taps and selection-mode changes.
    public ExpenseAdapter(Context context, ArrayList<ExpenseModel> expenseList,
                          ClickListener clickListener, SelectionCallback selectionCallback) {
        this.context = context;
        this.expenseList = expenseList;
        this.clickListener = clickListener;
        this.selectionCallback = selectionCallback;
        // Fallback matches the 48dp fixed layout_width; overwritten on first bind.
        checkboxOffset = TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP, 48f,
                context.getResources().getDisplayMetrics());
    }

    // Keeps a reference to the attached RecyclerView so selection animations can be applied to
    // its currently visible children directly.
    @Override
    public void onAttachedToRecyclerView(@NonNull RecyclerView rv) {
        super.onAttachedToRecyclerView(rv);
        recyclerView = rv;
    }

    // Clears the RecyclerView reference to avoid leaking it once this adapter is detached.
    @Override
    public void onDetachedFromRecyclerView(@NonNull RecyclerView rv) {
        super.onDetachedFromRecyclerView(rv);
        recyclerView = null;
    }

    // Inflates a fresh expense row layout and wraps it in a ViewHolder.
    @NonNull
    @Override
    public ExpenseViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View expenseView = LayoutInflater.from(context)
                .inflate(R.layout.expense_layout, parent, false);
        ExpenseViewHolder holder = new ExpenseViewHolder(expenseView);
        return holder;
    }

    // Populates one row's views from its ExpenseModel: name, date, rate, cost, status, linked-bank
    // indicator, credit-utilization bar (credit cards only), selection checkbox state, and the
    // tap/long-press handlers for click, selection-toggle, and drag-start.
    @Override
    public void onBindViewHolder(@NonNull ExpenseViewHolder holder, int position) {
        ExpenseModel anExpense = expenseList.get(position);
        holder.expenseName.setText(anExpense.getName());
        holder.expenseStartDate.setText(expenseDateToString(anExpense.getShownDate()));
        holder.expenseRate.setText(rateString(anExpense, context));
        holder.expenseCost.setText("$" + CurrencyFormat.display(context, anExpense.getShownCost()));
        ThemeHelper.tintPrimaryText(holder.expenseCost, context);
        holder.expenseStatus.setText(anExpense.getShownStatusAsString());
        holder.linkedIndicator.setVisibility(
                anExpense.isLinkedToBank() ? View.VISIBLE : View.GONE);

        // Show the utilization bar for credit card entries; hide it for regular expenses.
        if (anExpense.getIsCredit()) {
            int utilPct = 0;
            try {
                float debt  = Float.parseFloat(anExpense.getCost());
                float limit = Float.parseFloat(anExpense.getCreditLimit());
                if (limit > 0) utilPct = Math.min(100, Math.round(debt / limit * 100));
            } catch (NumberFormatException ignored) {}
            int color = utilPct < 30 ? R.color.balance_positive
                      : utilPct < 70 ? R.color.util_warning
                      :                R.color.balance_negative;
            holder.creditUtilBar.setProgress(utilPct);
            holder.creditUtilBar.setProgressTintList(
                    ColorStateList.valueOf(ContextCompat.getColor(context, color)));
            holder.creditUtilBar.setVisibility(View.VISIBLE);
        } else {
            holder.creditUtilBar.setVisibility(View.GONE);
        }

        // Refine offset once checkbox is actually laid out.
        holder.checkBox.post(() -> {
            if (holder.checkBox.getWidth() > 0) {
                checkboxOffset = holder.checkBox.getWidth();
            }
        });

        // Set immediate (non-animated) state -- animations only run on the visible
        // items directly when entering/exiting selection mode.
        applySelectionState(holder.checkBox, holder.expenseContent, selectionMode, false);

        holder.checkBox.setOnCheckedChangeListener(null);
        holder.checkBox.setChecked(selectedPositions.contains(position));

        holder.expenseItem.setOnClickListener(v -> {
            int pos = holder.getAdapterPosition();
            if (pos == RecyclerView.NO_POSITION) return;
            if (selectionMode) {
                toggleSelection(pos);
            } else {
                clickListener.onPositionClicked(pos);
            }
        });

        holder.expenseItem.setOnLongClickListener(v -> {
            int pos = holder.getAdapterPosition();
            if (pos == RecyclerView.NO_POSITION) return true;
            if (selectionMode) {
                // Already selecting -- long-press just toggles like a tap.
                toggleSelection(pos);
            } else if (itemTouchHelper != null) {
                // Not selecting -- start a drag to reorder.
                itemTouchHelper.startDrag(holder);
            }
            return true;
        });
    }

    // Tells the RecyclerView how many rows to display.
    @Override
    public int getItemCount() {
        return expenseList.size();
    }

    // Returns the expense model backing the row at the given adapter position.
    public ExpenseModel getItem(int position) {
        return expenseList.get(position);
    }

    // Gives the adapter a reference to the drag-to-reorder helper so long-press can start a drag.
    public void setItemTouchHelper(ItemTouchHelper helper) {
        this.itemTouchHelper = helper;
    }

    // Selection mode

    // Turns on multi-select mode, notifies the host activity, and animates the checkbox column
    // into view on all currently visible rows.
    public void enterSelectionMode() {
        selectionMode = true;
        if (selectionCallback != null) selectionCallback.onEnterSelectionMode();
        animateVisibleItems(true);
        // Off-screen items will bind correctly via onBindViewHolder when scrolled to.
    }

    // Turns off multi-select mode, clears the selection, notifies the host activity, and animates
    // the checkbox column back out before eventually rebinding all rows.
    public void exitSelectionMode() {
        if (!selectionMode) return;
        selectionMode = false;
        selectedPositions.clear();
        if (selectionCallback != null) selectionCallback.onExitSelectionMode();
        animateVisibleItems(false);
        // After animation completes, rebind so off-screen items reset too.
        if (recyclerView != null) {
            recyclerView.postDelayed(this::notifyDataSetChanged, ANIM_DURATION + 20L);
        } else {
            notifyDataSetChanged();
        }
    }

    // Returns whether the adapter is currently in multi-select mode.
    public boolean isInSelectionMode() {
        return selectionMode;
    }

    // Returns a copy of the currently selected row positions.
    public Set<Integer> getSelectedPositions() {
        return new HashSet<>(selectedPositions);
    }

    // Returns true if every row is currently selected.
    public boolean isAllSelected() {
        return !expenseList.isEmpty() && selectedPositions.size() == expenseList.size();
    }

    // Toggles between "select everything" and "select nothing", used by the toolbar's select-all action.
    public void selectAll() {
        if (isAllSelected()) {
            selectedPositions.clear();
            notifyDataSetChanged();
            if (selectionCallback != null) selectionCallback.onSelectionCountChanged(0);
        } else {
            for (int i = 0; i < expenseList.size(); i++) {
                selectedPositions.add(i);
            }
            notifyDataSetChanged();
            if (selectionCallback != null) selectionCallback.onSelectionCountChanged(selectedPositions.size());
        }
    }

    // Flips one row's selected state, notifies the host activity of the new count, and
    // automatically exits selection mode if the last selected item was just deselected.
    private void toggleSelection(int position) {
        if (selectedPositions.contains(position)) {
            selectedPositions.remove(position);
        } else {
            selectedPositions.add(position);
        }
        notifyItemChanged(position);
        if (selectionCallback != null) {
            selectionCallback.onSelectionCountChanged(selectedPositions.size());
        }
        if (selectedPositions.isEmpty()) {
            exitSelectionMode();
        }
    }

    // Animation helpers

    // Applies the checkbox slide-in/out animation to every row currently visible on screen
    // (off-screen rows pick up the correct state naturally when they're bound).
    private void animateVisibleItems(boolean entering) {
        if (recyclerView == null) { notifyDataSetChanged(); return; }
        for (int i = 0; i < recyclerView.getChildCount(); i++) {
            View child = recyclerView.getChildAt(i);
            CheckBox cb = child.findViewById(R.id.expense_checkbox);
            LinearLayout content = child.findViewById(R.id.expense_content);
            if (cb != null && content != null) {
                applySelectionState(cb, content, entering, true);
            }
        }
    }

    /*
    Slides the checkbox in/out and shifts the content row accordingly.
    In non-selection mode the checkbox is translated off-screen to the left
    (clipped by the parent) and the content fills that space, so the column
    widths look identical in both modes -- there is no layout reflow.
    */
    private void applySelectionState(CheckBox cb, LinearLayout content,
                                     boolean inSelection, boolean animate) {
        if (animate) {
            if (inSelection) {
                cb.setTranslationX(-checkboxOffset);
                cb.setAlpha(0f);
                cb.setVisibility(View.VISIBLE);
                cb.animate().translationX(0f).alpha(1f).setDuration(ANIM_DURATION).start();
                content.animate().translationX(checkboxOffset).setDuration(ANIM_DURATION).start();
            } else {
                cb.animate().translationX(-checkboxOffset).alpha(0f).setDuration(ANIM_DURATION)
                        .withEndAction(() -> {
                            cb.setVisibility(View.GONE);
                            cb.setTranslationX(0f);
                        }).start();
                content.animate().translationX(0f).setDuration(ANIM_DURATION).start();
            }
        } else {
            if (inSelection) {
                cb.setTranslationX(0f);
                cb.setAlpha(1f);
                cb.setVisibility(View.VISIBLE);
                content.setTranslationX(checkboxOffset);
            } else {
                cb.setAlpha(0f);
                cb.setVisibility(View.GONE);
                cb.setTranslationX(0f);
                content.setTranslationX(0f);
            }
        }
    }

    // Utility

    // Builds the compact "$cost/unit" label shown under an expense's name (e.g. "$15.99/mo").
    private static String rateString(ExpenseModel expense, Context context) {
        int freq = expense.getFrequency();
        java.time.temporal.ChronoUnit tag = expense.getFrequencyTag();
        String unit;
        if (tag == java.time.temporal.ChronoUnit.DAYS) {
            unit = freq == 1 ? "day" : freq + "d";
        } else if (tag == java.time.temporal.ChronoUnit.WEEKS) {
            unit = freq == 1 ? "wk" : freq + "wk";
        } else if (tag == java.time.temporal.ChronoUnit.MONTHS) {
            unit = freq == 1 ? "mo" : freq + "mo";
        } else if (tag == java.time.temporal.ChronoUnit.YEARS) {
            unit = freq == 1 ? "yr" : freq + "yr";
        } else {
            unit = "period";
        }
        return "$" + CurrencyFormat.display(context, expense.getCost()) + "/" + unit;
    }

    // Formats a date for display in the row (MM/dd/yyyy).
    private String expenseDateToString(LocalDate date) {
        return date.format(DateTimeFormatter.ofPattern("MM/dd/yyyy", Locale.US));
    }
}
