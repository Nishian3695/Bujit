package io.github.nishian3695.bujit.NavigationItems.Banking;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import java.util.List;
import java.util.Locale;
import io.github.nishian3695.bujit.R;

/*
RecyclerView adapter for user-defined manual accounts shown in BankingActivity.
Each card mirrors the visual style of the linked-account cards. Tapping the pencil
icon opens an edit/delete dialog via the Listener callback.
*/
public class ManualAccountAdapter extends RecyclerView.Adapter<ManualAccountAdapter.ViewHolder> {

    public interface Listener {
        void onEditClicked(ManualAccountModel account, int position);
    }

    private final Context context;
    private final List<ManualAccountModel> accounts;
    private final Listener listener;

    public ManualAccountAdapter(Context context, List<ManualAccountModel> accounts, Listener listener) {
        this.context  = context;
        this.accounts = accounts;
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.manual_account_item, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        ManualAccountModel account = accounts.get(position);
        holder.accountType.setText(account.getAccountType());
        holder.accountName.setText(account.getName());
        holder.balance.setText(String.format(Locale.US, "Balance: $%.2f", account.getBalance()));
        holder.editBtn.setOnClickListener(v -> {
            int pos = holder.getAdapterPosition();
            if (pos != RecyclerView.NO_POSITION) listener.onEditClicked(accounts.get(pos), pos);
        });
    }

    @Override
    public int getItemCount() { return accounts.size(); }

    static class ViewHolder extends RecyclerView.ViewHolder {
        final TextView  accountType;
        final TextView  accountName;
        final TextView  balance;
        final ImageButton editBtn;

        ViewHolder(@NonNull View itemView) {
            super(itemView);
            accountType = itemView.findViewById(R.id.manual_account_type);
            accountName = itemView.findViewById(R.id.manual_account_name);
            balance     = itemView.findViewById(R.id.manual_account_balance);
            editBtn     = itemView.findViewById(R.id.manual_account_edit_btn);
        }
    }
}
