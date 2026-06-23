package io.github.nishian3695.bujit.Tutorial;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.PorterDuffXfermode;
import android.graphics.RectF;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.TextView;
import io.github.nishian3695.bujit.R;

public class TutorialOverlayLayout extends FrameLayout {

    private final Paint overlayPaint;
    private final Paint clearPaint;
    private final RectF spotRect = new RectF();
    private boolean hasSpotlight = false;

    private final View     tooltipCard;
    private final TextView tvTitle;
    private final TextView tvMessage;
    private final Button   btnNext;
    private final Button   btnSkip;

    public TutorialOverlayLayout(Context context) {
        super(context);
        // Software layer required for PorterDuff.CLEAR to work on a ViewGroup canvas
        setLayerType(LAYER_TYPE_SOFTWARE, null);
        setWillNotDraw(false);

        overlayPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        overlayPaint.setColor(Color.argb(185, 0, 0, 0));

        clearPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        clearPaint.setXfermode(new PorterDuffXfermode(PorterDuff.Mode.CLEAR));

        tooltipCard = LayoutInflater.from(context)
                .inflate(R.layout.tutorial_tooltip, this, false);
        tvTitle   = tooltipCard.findViewById(R.id.tutorial_tooltip_title);
        tvMessage = tooltipCard.findViewById(R.id.tutorial_tooltip_message);
        btnNext   = tooltipCard.findViewById(R.id.btn_tutorial_next);
        btnSkip   = tooltipCard.findViewById(R.id.btn_tutorial_skip);
        addView(tooltipCard);

        setAlpha(0f);
        animate().alpha(1f).setDuration(220).start();
        // Block touches on the overlay background; tooltip buttons handle their own clicks
        setOnTouchListener((v, e) -> true);
    }

    @Override
    protected void dispatchDraw(Canvas canvas) {
        canvas.drawRect(0, 0, getWidth(), getHeight(), overlayPaint);
        if (hasSpotlight && !spotRect.isEmpty()) {
            canvas.drawRoundRect(spotRect, dpToPx(12), dpToPx(12), clearPaint);
        }
        super.dispatchDraw(canvas);
    }

    public void showStep(View target, String title, String message,
                         String nextText, Runnable onNext, Runnable onSkip) {
        tvTitle.setText(title);
        tvMessage.setText(message);
        btnNext.setText(nextText);
        btnNext.setOnClickListener(v -> { if (onNext != null) onNext.run(); });
        btnSkip.setOnClickListener(v -> { if (onSkip != null) onSkip.run(); });

        if (target != null) {
            hasSpotlight = true;
            target.post(() -> measureAndPositionSpotlight(target));
        } else {
            hasSpotlight = false;
            spotRect.setEmpty();
            invalidate();
            positionTooltipCenter();
        }

        setVisibility(VISIBLE);
    }

    private void measureAndPositionSpotlight(View target) {
        int pad = dpToPx(16);
        int[] overlayLoc = new int[2];
        int[] targetLoc  = new int[2];
        getLocationOnScreen(overlayLoc);
        target.getLocationOnScreen(targetLoc);

        float left   = targetLoc[0] - overlayLoc[0] - pad;
        float top    = targetLoc[1] - overlayLoc[1] - pad;
        float right  = left + target.getWidth()  + pad * 2f;
        float bottom = top  + target.getHeight() + pad * 2f;
        spotRect.set(left, top, right, bottom);

        invalidate();
        tooltipCard.post(() -> positionTooltipNearSpot(top, bottom));
    }

    private void positionTooltipNearSpot(float spotTop, float spotBottom) {
        int margin = dpToPx(16);
        LayoutParams lp = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
        lp.setMargins(margin, 0, margin, 0);
        lp.gravity = Gravity.TOP;

        float screenMid  = getHeight() / 2f;
        int   tooltipH   = tooltipCard.getHeight();

        if (spotTop > screenMid) {
            int desired = (int) spotTop - tooltipH - dpToPx(16);
            lp.topMargin = Math.max(margin, desired);
        } else {
            int desired = (int) spotBottom + dpToPx(16);
            int maxTop  = getHeight() - tooltipH - margin;
            lp.topMargin = Math.min(desired, maxTop);
        }
        tooltipCard.setLayoutParams(lp);
    }

    private void positionTooltipCenter() {
        post(() -> {
            LayoutParams lp = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT);
            lp.gravity = Gravity.CENTER_VERTICAL;
            lp.setMargins(dpToPx(24), 0, dpToPx(24), 0);
            tooltipCard.setLayoutParams(lp);
        });
    }

    private int dpToPx(int dp) {
        return Math.round(dp * getResources().getDisplayMetrics().density);
    }
}
