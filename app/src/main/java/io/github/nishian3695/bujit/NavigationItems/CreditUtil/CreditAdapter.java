package io.github.nishian3695.bujit.NavigationItems.CreditUtil;

import android.content.Context;
import android.content.res.ColorStateList;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.Interfaces.ClickListener;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.ThemeHelper;
import java.util.ArrayList;
import java.util.Locale;

/*
RecyclerView adapter that displays the list of credit cards in CreditUtilActivity.
Each item shows the card name, current debt, credit limit, and a color-coded
utilization percentage and progress bar (green < 30%, yellow < 70%, red >= 70%).
Long-press opens the edit dialog via the supplied ClickListener.
*/
public class CreditAdapter extends RecyclerView.Adapter<CreditViewHolder> {

    Context context;
    ArrayList<ExpenseModel> creditList;
    private ClickListener clickListener;

    public CreditAdapter(Context context, ArrayList<ExpenseModel> creditList, ClickListener clickListener) {
        this.context = context;
        this.creditList = creditList;
        this.clickListener = clickListener;
    }

    @NonNull
    @Override
    public CreditViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View creditView = LayoutInflater.from(context).inflate(R.layout.credit_layout, parent, false);
        return new CreditViewHolder(creditView, clickListener);
    }

    @Override
    public void onBindViewHolder(@NonNull CreditViewHolder holder, int position) {
        ExpenseModel credit = creditList.get(position);

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

    @Override
    public int getItemCount() {
        return creditList.size();
    }

    public ExpenseModel getItem(int position) {
        return creditList.get(position);
    }

    private int utilColor(int pct) {
        if (pct < 30) return R.color.balance_positive;
        if (pct < 70) return R.color.util_warning;
        return R.color.balance_negative;
    }

    private String formatAmount(String raw) {
        if (raw == null || raw.isEmpty()) return "0.00";
        try { return String.format(Locale.US, "%.2f", Double.parseDouble(raw)); }
        catch (NumberFormatException e) { return "0.00"; }
    }
}
