package io.github.nishian3695.bujit.NavigationItems.CreditUtil;

import android.content.Context;
import android.content.res.ColorStateList;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.CustomListeners.CurrencyFormat;
import io.github.nishian3695.bujit.ExpenseActivity.CreditModel;
import io.github.nishian3695.bujit.Interfaces.ClickListener;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.ThemeHelper;
import java.util.ArrayList;

/*
RecyclerView adapter that displays the list of credit cards in CreditUtilActivity.
Each item shows the card name, current debt, credit limit, and a color-coded
utilization percentage and progress bar (green < 30%, yellow < 70%, red >= 70%).
Long-press opens the edit dialog via the supplied ClickListener.
*/
public class CreditAdapter extends RecyclerView.Adapter<CreditViewHolder> {

    Context context;
    ArrayList<CreditModel> creditList;
    private ClickListener clickListener;

    // Wires the adapter to the list of credit-card expenses and the click callback.
    public CreditAdapter(Context context, ArrayList<CreditModel> creditList, ClickListener clickListener) {
        this.context = context;
        this.creditList = creditList;
        this.clickListener = clickListener;
    }

    // Inflates a fresh credit card row layout and wraps it in a ViewHolder.
    @NonNull
    @Override
    public CreditViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View creditView = LayoutInflater.from(context).inflate(R.layout.credit_layout, parent, false);
        return new CreditViewHolder(creditView, clickListener);
    }

    // Populates one row's views from its CreditModel: name, debt, limit, and a color-coded
    // utilization percentage/progress bar.
    @Override
    public void onBindViewHolder(@NonNull CreditViewHolder holder, int position) {
        CreditModel credit = creditList.get(position);

        holder.creditLinkedIndicator.setVisibility(
                credit.isLinkedToBank() ? View.VISIBLE : View.GONE);

        holder.creditName.setText(credit.getName());
        holder.creditDebt.setText("$" + formatAmount(credit.getCost()));
        ThemeHelper.tintPrimaryText(holder.creditDebt, context);
        holder.creditLimit.setText("$" + formatAmount(credit.getCreditLimit()));

        // Compute utilization percentage for color and progress
        int utilPct = 0;
        try {
            float debt  = Float.parseFloat(credit.getCost());
            float limit = Float.parseFloat(credit.getCreditLimit());
            if (limit > 0) utilPct = Math.min(100, Math.round(debt / limit * 100));
        } catch (NumberFormatException ignored) {}

        holder.creditUtil.setText(utilPct + "%");
        holder.creditUtilBar.setProgress(utilPct);

        int color = utilColor(utilPct);
        holder.creditUtil.setTextColor(ContextCompat.getColor(context, color));
        holder.creditUtilBar.setProgressTintList(
                ColorStateList.valueOf(ContextCompat.getColor(context, color)));
    }

    // Tells the RecyclerView how many credit card rows to display.
    @Override
    public int getItemCount() {
        return creditList.size();
    }

    // Returns the expense model backing the row at the given adapter position.
    public CreditModel getItem(int position) {
        return creditList.get(position);
    }

    // Maps a utilization percentage to a color: green under 30%, yellow under 70%, red at/above.
    private int utilColor(int pct) {
        if (pct < 30) return R.color.balance_positive;
        if (pct < 70) return R.color.util_warning;
        return R.color.balance_negative;
    }

    // Parses a raw amount string and re-formats it for display, defaulting to "0.00".
    private String formatAmount(String raw) {
        if (raw == null || raw.isEmpty()) return "0.00";
        try { return CurrencyFormat.display(context, raw); }
        catch (NumberFormatException e) { return "0.00"; }
    }
}
