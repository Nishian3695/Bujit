package io.github.nishian3695.bujit.NavigationItems.IncomeStreams;

import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.recyclerview.widget.RecyclerView;
import io.github.nishian3695.bujit.R;
import com.google.android.material.card.MaterialCardView;

/*
ViewHolder for a single income stream card (income_stream_item.xml).
Shows the stream name, pay amount and frequency, an "Active" badge
when the stream is selected, and edit/delete icon buttons.
*/
public class IncomeStreamViewHolder extends RecyclerView.ViewHolder {
    public final MaterialCardView card;
    public final TextView streamName;
    public final TextView streamDetails;
    public final TextView activeBadge;
    public final ImageView editIcon;
    public final ImageView deleteIcon;

    public IncomeStreamViewHolder(View itemView) {
        super(itemView);
        card         = itemView.findViewById(R.id.income_stream_card);
        streamName   = itemView.findViewById(R.id.income_stream_name);
        streamDetails = itemView.findViewById(R.id.income_stream_details);
        activeBadge  = itemView.findViewById(R.id.income_stream_active_badge);
        editIcon     = itemView.findViewById(R.id.income_stream_edit_icon);
        deleteIcon   = itemView.findViewById(R.id.income_stream_delete_icon);
    }
}
