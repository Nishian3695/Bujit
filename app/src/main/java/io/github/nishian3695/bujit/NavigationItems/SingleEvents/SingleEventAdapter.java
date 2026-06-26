package io.github.nishian3695.bujit.NavigationItems.SingleEvents;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.R;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Locale;

public class SingleEventAdapter extends RecyclerView.Adapter<SingleEventAdapter.ViewHolder> {

    public interface ItemClickListener {
        void onItemClick(int position);
        void onItemLongClick(int position);
    }

    private final Context context;
    private final ArrayList<SingleEventModel> items;
    private final int expiryDays;
    private final ItemClickListener listener;

    public SingleEventAdapter(Context context, ArrayList<SingleEventModel> items,
                              int expiryDays, ItemClickListener listener) {
        this.context = context;
        this.items = items;
        this.expiryDays = expiryDays;
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(context).inflate(R.layout.single_event_item, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        SingleEventModel item = items.get(position);
        holder.name.setText(item.getName());

        String prefix = item.isDebit() ? "-" : "+";
        holder.amount.setText(String.format(Locale.US, "%s$%.2f", prefix, item.getAmount()));

        int colorRes = item.isDebit() ? R.color.balance_negative : R.color.balance_positive;
        int color = ContextCompat.getColor(context, colorRes);
        holder.amount.setTextColor(color);
        holder.colorBar.setBackgroundColor(color);

        LocalDate today = LocalDate.now();
        LocalDate expiresOn = item.getLastModifiedDate().plusDays(expiryDays);
        long daysLeft = ChronoUnit.DAYS.between(today, expiresOn);
        if (daysLeft <= 0) {
            holder.meta.setText("Expiring soon");
        } else if (daysLeft == 1) {
            holder.meta.setText("Expires tomorrow");
        } else {
            holder.meta.setText("Expires in " + daysLeft + " day" + (daysLeft == 1 ? "" : "s"));
        }

        holder.itemView.setOnClickListener(v -> {
            int pos = holder.getAdapterPosition();
            if (pos != RecyclerView.NO_POSITION && listener != null) listener.onItemClick(pos);
        });
        holder.itemView.setOnLongClickListener(v -> {
            int pos = holder.getAdapterPosition();
            if (pos != RecyclerView.NO_POSITION && listener != null) listener.onItemLongClick(pos);
            return true;
        });
    }

    @Override
    public int getItemCount() { return items.size(); }

    public SingleEventModel getItem(int position) { return items.get(position); }

    static class ViewHolder extends RecyclerView.ViewHolder {
        View colorBar;
        TextView name, amount, meta;

        ViewHolder(View v) {
            super(v);
            colorBar = v.findViewById(R.id.single_event_color_bar);
            name = v.findViewById(R.id.single_event_name);
            amount = v.findViewById(R.id.single_event_amount);
            meta = v.findViewById(R.id.single_event_meta);
        }
    }
}
