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
import io.github.nishian3695.bujit.CustomListeners.CurrencyFormat;
import io.github.nishian3695.bujit.R;

/*
RecyclerView adapter for user-defined manual accounts shown in BankingActivity.
Each card mirrors the visual style of the linked-account cards. Tapping the pencil
icon opens an edit/delete dialog via the Listener callback.
*/
public class ManualAccountAdapter extends RecyclerView.Adapter<ManualAccountAdapter.ViewHolder> {

    // Notifies the host activity when the user taps the edit/delete pencil icon on a manual account.
    public interface Listener {
        void onEditClicked(ManualAccountModel account, int position);
    }

    private final Context context;
    private final List<ManualAccountModel> accounts;
    private final Listener listener;

    // Wires the adapter to the list of manual accounts and the edit-click callback.
    public ManualAccountAdapter(Context context, List<ManualAccountModel> accounts, Listener listener) {
        this.context  = context;
        this.accounts = accounts;
        this.listener = listener;
    }

    // Inflates a fresh manual-account card layout and wraps it in a ViewHolder.
    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.manual_account_item, parent, false);
        return new ViewHolder(view);
    }

    // Populates one card's views from its ManualAccountModel and wires the edit button.
    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        ManualAccountModel account = accounts.get(position);
        holder.accountType.setText(account.getAccountType());
        holder.accountName.setText(account.getName());
        holder.balance.setText("Balance: $" + CurrencyFormat.display(context, account.getBalance()));
        holder.editBtn.setOnClickListener(v -> {
            int pos = holder.getAdapterPosition();
            if (pos != RecyclerView.NO_POSITION) listener.onEditClicked(accounts.get(pos), pos);
        });
    }

    // Tells the RecyclerView how many manual account cards to display.
    @Override
    public int getItemCount() { return accounts.size(); }

    // Holds references to a manual-account card's child views.
    static class ViewHolder extends RecyclerView.ViewHolder {
        final TextView  accountType;
        final TextView  accountName;
        final TextView  balance;
        final ImageButton editBtn;

        // Looks up and caches every child view of the card once.
        ViewHolder(@NonNull View itemView) {
            super(itemView);
            accountType = itemView.findViewById(R.id.manual_account_type);
            accountName = itemView.findViewById(R.id.manual_account_name);
            balance     = itemView.findViewById(R.id.manual_account_balance);
            editBtn     = itemView.findViewById(R.id.manual_account_edit_btn);
        }
    }
}
