package io.github.nishian3695.bujit;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.Shader;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.view.View;

/*
HSV color wheel with an integrated brightness strip.
Top: circular hue (angle) + saturation (radius) selector.
Bottom strip: value/brightness selector (black → full-brightness color).
*/
public class ColorWheelView extends View {

    public interface OnColorChangedListener {
        void onColorChanged(int color);
    }

    private static final int   STRIP_HEIGHT_DP  = 36;
    private static final int   GAP_DP           = 12;
    private static final float SELECTOR_RING_DP = 10f;

    private Bitmap wheelBitmap;
    private Bitmap stripBitmap;
    private final Paint bitmapPaint  = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.DITHER_FLAG);
    private final Paint selectorPaint = new Paint(Paint.ANTI_ALIAS_FLAG);

    private float wheelRadius;
    private float wheelCx, wheelCy;
    private float stripLeft, stripRight, stripTop, stripBottom;
    private float selectorRadius;

    private float hue = 0f;
    private float saturation = 1f;
    private float value = 1f;

    private OnColorChangedListener listener;

    public ColorWheelView(Context context) { super(context); init(context); }
    public ColorWheelView(Context context, AttributeSet attrs) { super(context, attrs); init(context); }
    public ColorWheelView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle); init(context);
    }

    private void init(Context context) {
        selectorRadius = SELECTOR_RING_DP * context.getResources().getDisplayMetrics().density;
    }

    public void setOnColorChangedListener(OnColorChangedListener l) { this.listener = l; }

    public int getColor() {
        return Color.HSVToColor(new float[]{hue, saturation, value});
    }

    public void setColor(int color) {
        float[] hsv = new float[3];
        Color.colorToHSV(color, hsv);
        hue = hsv[0];
        saturation = hsv[1];
        value = hsv[2];
        rebuildStripBitmap();
        invalidate();
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldW, int oldH) {
        if (w <= 0 || h <= 0) return;
        float density = getResources().getDisplayMetrics().density;
        float stripH = STRIP_HEIGHT_DP * density;
        float gap    = GAP_DP * density;

        int wheelSize = (int) Math.min(w, h - stripH - gap);
        wheelRadius = wheelSize / 2f;
        wheelCx = w / 2f;
        wheelCy = wheelSize / 2f;

        stripLeft   = wheelCx - wheelRadius;
        stripRight  = wheelCx + wheelRadius;
        stripTop    = wheelCy * 2 + gap;
        stripBottom = stripTop + stripH;

        buildWheelBitmap(wheelSize);
        rebuildStripBitmap();
    }

    private void buildWheelBitmap(int size) {
        if (size <= 0) return;
        Bitmap bm = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
        float cx = size / 2f;
        float[] hsv = {0f, 0f, 1f};
        int[] pixels = new int[size * size];
        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                float dx = x - cx, dy = y - cx;
                float dist = (float) Math.sqrt(dx * dx + dy * dy);
                if (dist > cx) {
                    pixels[y * size + x] = 0;
                    continue;
                }
                float angle = (float) Math.toDegrees(Math.atan2(dy, dx));
                if (angle < 0) angle += 360f;
                hsv[0] = angle;
                hsv[1] = dist / cx;
                pixels[y * size + x] = Color.HSVToColor(hsv);
            }
        }
        bm.setPixels(pixels, 0, size, 0, 0, size, size);
        wheelBitmap = bm;
    }

    // Strip must be rebuilt whenever hue or saturation changes.
    private void rebuildStripBitmap() {
        int w = (int)(stripRight - stripLeft);
        int h = (int)(stripBottom - stripTop);
        if (w <= 0 || h <= 0) return;
        Bitmap bm = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888);
        Canvas c  = new Canvas(bm);
        int fullColor = Color.HSVToColor(new float[]{hue, saturation, 1f});
        LinearGradient grad = new LinearGradient(0, 0, w, 0,
                new int[]{Color.BLACK, fullColor}, null, Shader.TileMode.CLAMP);
        Paint p = new Paint();
        p.setShader(grad);
        c.drawRect(0, 0, w, h, p);
        stripBitmap = bm;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        if (wheelBitmap == null || stripBitmap == null) return;

        // Wheel
        canvas.drawBitmap(wheelBitmap, wheelCx - wheelRadius, 0, bitmapPaint);
        if (value < 1f) {
            // Darken wheel to reflect current brightness
            Paint overlay = new Paint();
            overlay.setColor(Color.BLACK);
            overlay.setAlpha((int)((1f - value) * 255));
            canvas.drawCircle(wheelCx, wheelCy, wheelRadius, overlay);
        }

        // Brightness strip
        float corner = (stripBottom - stripTop) / 2f;
        RectF stripRect = new RectF(stripLeft, stripTop, stripRight, stripBottom);
        canvas.save();
        canvas.clipRect(stripRect);
        canvas.drawBitmap(stripBitmap, stripLeft, stripTop, bitmapPaint);
        canvas.restore();
        Paint borderPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
        borderPaint.setStyle(Paint.Style.STROKE);
        borderPaint.setColor(0x30000000);
        borderPaint.setStrokeWidth(2f);
        canvas.drawRoundRect(stripRect, corner, corner, borderPaint);

        // Wheel selector
        double rad = Math.toRadians(hue);
        float sx = (float)(wheelCx + Math.cos(rad) * saturation * wheelRadius);
        float sy = (float)(wheelCy + Math.sin(rad) * saturation * wheelRadius);
        drawSelector(canvas, sx, sy);

        // Strip selector
        float bx = stripLeft + value * (stripRight - stripLeft);
        float by = (stripTop + stripBottom) / 2f;
        drawSelector(canvas, bx, by);
    }

    private void drawSelector(Canvas canvas, float x, float y) {
        selectorPaint.setStyle(Paint.Style.FILL);
        selectorPaint.setColor(getColor());
        canvas.drawCircle(x, y, selectorRadius, selectorPaint);

        selectorPaint.setStyle(Paint.Style.STROKE);
        selectorPaint.setColor(Color.WHITE);
        selectorPaint.setStrokeWidth(3f);
        canvas.drawCircle(x, y, selectorRadius, selectorPaint);

        selectorPaint.setStyle(Paint.Style.STROKE);
        selectorPaint.setColor(0x60000000);
        selectorPaint.setStrokeWidth(1f);
        canvas.drawCircle(x, y, selectorRadius + 2f, selectorPaint);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        int action = event.getActionMasked();
        if (action != MotionEvent.ACTION_DOWN && action != MotionEvent.ACTION_MOVE) return true;

        float x = event.getX(), y = event.getY();

        if (y <= stripTop) {
            float dx = x - wheelCx, dy = y - wheelCy;
            float dist = (float) Math.sqrt(dx * dx + dy * dy);
            if (dist <= wheelRadius + selectorRadius) {
                float angle = (float) Math.toDegrees(Math.atan2(dy, dx));
                if (angle < 0) angle += 360f;
                hue = angle;
                saturation = Math.min(1f, dist / wheelRadius);
                rebuildStripBitmap();
            }
        } else {
            value = Math.max(0f, Math.min(1f, (x - stripLeft) / (stripRight - stripLeft)));
        }

        invalidate();
        if (listener != null) listener.onColorChanged(getColor());
        return true;
    }
}
