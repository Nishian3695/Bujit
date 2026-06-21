package io.github.nishian3695.bujit.NavigationItems.Banking;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.R;
import java.util.List;

/*
RecyclerView adapter that displays a list of bank accounts in BankingActivity.
Each item shows the institution name, masked account number, type, and both
ledger and available balances formatted to two decimal places.
*/
public class BankAccountAdapter extends RecyclerView.Adapter<BankAccountViewHolder> {

    private final Context context;
    private final List<BankAccountModel> accounts;

    public BankAccountAdapter(Context context, List<BankAccountModel> accounts) {
        this.context = context;
        this.accounts = accounts;
    }

    @NonNull
    @Override
    public BankAccountViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.bank_account_item, parent, false);
        return new BankAccountViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull BankAccountViewHolder holder, int position) {
        BankAccountModel account = accounts.get(position);
        holder.institutionName.setText(account.getInstitutionName());
        holder.accountName.setText(account.getName());
        holder.accountType.setText(account.getDisplayType());
        String lastFourText = account.getLastFour() != null && !account.getLastFour().isEmpty()
                ? "••••" + account.getLastFour() : "";
        holder.lastFour.setText(lastFourText);
        holder.ledgerBalance.setText("Ledger: $" + formatBalance(account.getLedgerBalance()));
        holder.availableBalance.setText("Available: $" + formatBalance(account.getAvailableBalance()));
    }

    @Override
    public int getItemCount() {
        return accounts.size();
    }

    private String formatBalance(String raw) {
        if (raw == null || raw.isEmpty()) return "0.00";
        try {
            return String.format("%.2f", Double.parseDouble(raw));
        } catch (NumberFormatException e) {
            return raw;
        }
    }
}
