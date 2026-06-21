package io.github.nishian3695.bujit.NavigationItems.Banking;

import android.view.View;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.R;

/*
ViewHolder for a single bank account card (bank_account_item.xml).
Holds references to the institution name, account name and type,
masked last-four digits, and both ledger and available balance labels.
*/
public class BankAccountViewHolder extends RecyclerView.ViewHolder {
    final TextView institutionName;
    final TextView accountName;
    final TextView accountType;
    final TextView lastFour;
    final TextView ledgerBalance;
    final TextView availableBalance;

    public BankAccountViewHolder(@NonNull View itemView) {
        super(itemView);
        institutionName  = itemView.findViewById(R.id.bank_institution_name);
        accountName      = itemView.findViewById(R.id.bank_account_name);
        accountType      = itemView.findViewById(R.id.bank_account_type);
        lastFour         = itemView.findViewById(R.id.bank_last_four);
        ledgerBalance    = itemView.findViewById(R.id.bank_ledger_balance);
        availableBalance = itemView.findViewById(R.id.bank_available_balance);
    }
}
