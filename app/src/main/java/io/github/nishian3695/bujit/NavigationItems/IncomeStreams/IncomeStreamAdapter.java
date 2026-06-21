package io.github.nishian3695.bujit.NavigationItems.IncomeStreams;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.ThemeHelper;
import java.util.List;

/*
RecyclerView adapter for the income streams list in IncomeStreamsActivity.
Each card shows the stream name and pay details, highlights the currently
selected (active) stream with an accent-colored border and "Active" badge,
and exposes select/edit/delete callbacks through the Listener interface.
*/
public class IncomeStreamAdapter extends RecyclerView.Adapter<IncomeStreamViewHolder> {

    public interface Listener {
        void onSelect(int position);
        void onEdit(int position);
        void onDelete(int position);
    }

    private final Context context;
    private final List<IncomeStreamModel> streams;
    private final Listener listener;

    public IncomeStreamAdapter(Context context, List<IncomeStreamModel> streams, Listener listener) {
        this.context = context;
        this.streams = streams;
        this.listener = listener;
    }

    @NonNull
    @Override
    public IncomeStreamViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(context)
                .inflate(R.layout.income_stream_item, parent, false);
        return new IncomeStreamViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull IncomeStreamViewHolder holder, int position) {
        IncomeStreamModel stream = streams.get(position);

        holder.streamName.setText(stream.getName());
        holder.streamDetails.setText(
                "$" + stream.getAmount() + "  ·  " + stream.getFrequencyDisplayString());

        boolean selected = stream.isSelected();
        holder.activeBadge.setVisibility(selected ? View.VISIBLE : View.GONE);

        int accentColor = ThemeHelper.getAccentColor(context);
        if (selected) {
            holder.card.setStrokeColor(accentColor);
            holder.card.setStrokeWidth(
                    (int) (context.getResources().getDisplayMetrics().density * 2));
        } else {
            holder.card.setStrokeWidth(0);
        }
        holder.activeBadge.setTextColor(accentColor);

        holder.itemView.setOnClickListener(v -> {
            int pos = holder.getAdapterPosition();
            if (pos != RecyclerView.NO_ID) listener.onSelect(pos);
        });
        holder.editIcon.setOnClickListener(v -> {
            int pos = holder.getAdapterPosition();
            if (pos != RecyclerView.NO_ID) listener.onEdit(pos);
        });
        holder.deleteIcon.setOnClickListener(v -> {
            int pos = holder.getAdapterPosition();
            if (pos != RecyclerView.NO_ID) listener.onDelete(pos);
        });
    }

    @Override
    public int getItemCount() {
        return streams.size();
    }
}
