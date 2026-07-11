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

// RecyclerView adapter for the single events list in SingleEventsActivity.
// Each row shows the event name, signed dollar amount (colored green/red), the funding
// source it's attributed to, and an expiry countdown based on when it was last modified.
public class SingleEventAdapter extends RecyclerView.Adapter<SingleEventAdapter.ViewHolder> {

    // Notifies the host activity when the user taps or long-presses an event row.
    public interface ItemClickListener {
        void onItemClick(int position);
        void onItemLongClick(int position);
    }

    private final Context context;
    private final ArrayList<SingleEventModel> items;
    private final int expiryDays;
    private final ItemClickListener listener;

    // Wires the adapter to the list of single events, the configured expiry window, and the
    // tap/long-press callback.
    public SingleEventAdapter(Context context, ArrayList<SingleEventModel> items,
                              int expiryDays, ItemClickListener listener) {
        this.context = context;
        this.items = items;
        this.expiryDays = expiryDays;
        this.listener = listener;
    }

    // Inflates a fresh single event row layout and wraps it in a ViewHolder.
    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(context).inflate(R.layout.single_event_item, parent, false);
        return new ViewHolder(v);
    }

    // Populates one row's views from its SingleEventModel: name, signed/colored amount, funding
    // source label, expiry countdown text, and the click/long-click handlers.
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
        String expiry;
        if (daysLeft <= 0) {
            expiry = "Expiring soon";
        } else if (daysLeft == 1) {
            expiry = "Expires tomorrow";
        } else {
            expiry = "Expires in " + daysLeft + " days";
        }
        String displayName = item.getTargetDisplayName();
        if (displayName != null && !"BALANCE".equals(item.getTargetType())) {
            holder.meta.setText(displayName + " · " + expiry);
        } else {
            holder.meta.setText(expiry);
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

    // Tells the RecyclerView how many event rows to display.
    @Override
    public int getItemCount() { return items.size(); }

    // Returns the event model backing the row at the given adapter position.
    public SingleEventModel getItem(int position) { return items.get(position); }

    // Holds references to a single event row's child views.
    static class ViewHolder extends RecyclerView.ViewHolder {
        View colorBar;
        TextView name, amount, meta;

        // Looks up and caches every child view of the row once.
        ViewHolder(View v) {
            super(v);
            colorBar = v.findViewById(R.id.single_event_color_bar);
            name = v.findViewById(R.id.single_event_name);
            amount = v.findViewById(R.id.single_event_amount);
            meta = v.findViewById(R.id.single_event_meta);
        }
    }
}
