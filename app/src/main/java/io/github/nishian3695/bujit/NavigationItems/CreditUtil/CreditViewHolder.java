package io.github.nishian3695.bujit.NavigationItems.CreditUtil;

import android.view.View;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.Interfaces.ClickListener;
import io.github.nishian3695.bujit.R;
import java.lang.ref.WeakReference;

/*
ViewHolder for a single credit card row (credit_layout.xml).
Displays the card name, current debt, credit limit, utilization percentage,
 and a color-coded progress bar. Click and long-click events are forwarded
 to the ClickListener supplied at construction time via a WeakReference.
*/
public class CreditViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener, View.OnLongClickListener {
    LinearLayout creditLinearLayout;
    View creditLinkedIndicator;
    TextView creditName, creditDebt, creditLimit, creditUtil;
    ProgressBar creditUtilBar;
    WeakReference<ClickListener> listenerReference;

    public CreditViewHolder(@NonNull View itemView, ClickListener clickListener) {
        super(itemView);

        listenerReference = new WeakReference<>(clickListener);

        creditLinearLayout   = itemView.findViewById(R.id.credit_linear_layout);
        creditLinkedIndicator = itemView.findViewById(R.id.credit_linked_indicator);
        creditName  = itemView.findViewById(R.id.credit_name);
        creditDebt  = itemView.findViewById(R.id.credit_debt);
        creditLimit = itemView.findViewById(R.id.credit_limit);
        creditUtil  = itemView.findViewById(R.id.credit_util);
        creditUtilBar = itemView.findViewById(R.id.credit_util_bar);

        creditLinearLayout.setOnClickListener(this);
        creditLinearLayout.setOnLongClickListener(this);
    }

    @Override
    public void onClick(View view) {
        listenerReference.get().onPositionClicked(getAdapterPosition());
    }

    @Override
    public boolean onLongClick(View view) {
        listenerReference.get().onLongClicked(getAdapterPosition());
        return true;
    }
}
