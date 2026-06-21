package io.github.nishian3695.bujit.ExpenseActivity;

import android.view.View;
import android.widget.CheckBox;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.R;

/*
ViewHolder for a single row in the expense list (expense_layout.xml).
Holds references to the checkbox (selection mode), the content column container,
and the individual text fields shown in each row.
*/
public class ExpenseViewHolder extends RecyclerView.ViewHolder {
    CheckBox checkBox;
    LinearLayout expenseItem;
    LinearLayout expenseContent;
    TextView expenseName, expenseStartDate, expenseRate, expenseCost, expenseStatus;
    View linkedIndicator;

    public ExpenseViewHolder(@NonNull View itemView) {
        super(itemView);
        checkBox         = itemView.findViewById(R.id.expense_checkbox);
        expenseItem      = itemView.findViewById(R.id.expense_table_item);
        expenseContent   = itemView.findViewById(R.id.expense_content);
        linkedIndicator  = itemView.findViewById(R.id.linked_indicator);
        expenseName      = itemView.findViewById(R.id.expense_name);
        expenseStartDate = itemView.findViewById(R.id.expense_date);
        expenseRate      = itemView.findViewById(R.id.expense_rate);
        expenseCost      = itemView.findViewById(R.id.expense_cost);
        expenseStatus    = itemView.findViewById(R.id.expense_status);
    }
}
