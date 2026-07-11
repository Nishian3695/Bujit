package io.github.nishian3695.bujit;

import android.app.Activity;
import android.content.res.TypedArray;
import android.view.View;
import android.view.WindowInsets;
import androidx.activity.ComponentActivity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.widget.TextView;
import androidx.activity.EdgeToEdge;
import androidx.activity.SystemBarStyle;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.core.content.ContextCompat;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import com.google.android.material.card.MaterialCardView;
import com.google.android.material.floatingactionbutton.FloatingActionButton;

/*
Centralised helper for all theme and accent-color concerns.

Accent colors: six named presets (blue, purple, green, orange, teal, rose) each
backed by a dedicated Material theme variant, plus a "custom" path that stores
a hex string and tints UI elements manually at runtime.

Night mode: light / dark / system, applied via AppCompatDelegate. Must be called
from Application.onCreate() (BujitApp) so it takes effect before any Activity draws.

Manual tinting methods (tintFab, tintPrimaryText, tintPrimaryCard, tintSwipeRefresh)
are no-ops for preset colors, which inherit tinting from the Material theme. They
only apply the custom hex color so that all activities share a single tinting path.
*/
public class ThemeHelper {

    public static final String PREFS           = "bujit_settings";
    public static final String KEY_COLOR       = "accent_color";
    public static final String KEY_MODE        = "night_mode";
    public static final String KEY_CUSTOM_HEX  = "custom_hex";

    // Enables edge-to-edge display for an activity: makes the status bar transparent, colors the
    // action bar's container to match the theme, and pushes toolbar content below the status bar
    // so nothing is obscured.
    public static void enableEdgeToEdge(ComponentActivity activity) {
        // Read colorPrimary from the current theme rather than getAccentColor() so that
        // custom accent colors (which intentionally do not recolor the action bar per
        // tintActionBar's no-op contract) are excluded. This gives the same "system
        // dependent" color the action bar had before the edge-to-edge migration.
        TypedArray ta = activity.getTheme()
                .obtainStyledAttributes(new int[]{ android.R.attr.colorPrimary });
        int themeColor = ta.getColor(0, getAccentColor(activity));
        ta.recycle();

        EdgeToEdge.enable(activity,
                SystemBarStyle.dark(themeColor),
                SystemBarStyle.auto(Color.TRANSPARENT, Color.TRANSPARENT));

        // Extend ActionBarContainer behind the status bar so nothing bleeds through the
        // transparent status bar. The background fills the status bar area; paddingTop
        // pushes the Toolbar content (title, buttons) below the status bar so they
        // remain in their normal position.
        View decorView = activity.getWindow().getDecorView();
        decorView.post(() -> {
            View abContainer = decorView.findViewById(
                    androidx.appcompat.R.id.action_bar_container);
            if (abContainer == null) return;
            WindowInsets wi = decorView.getRootWindowInsets();
            int statusBarTop = (wi != null) ? wi.getSystemWindowInsetTop() : 0;
            abContainer.setBackgroundColor(themeColor);
            abContainer.setPaddingRelative(0, statusBarTop, 0, 0);
        });
    }

    // Applies the saved preset accent color's Material theme variant to an activity. Must be
    // called before super.onCreate(). "blue" and "custom" both fall through to the manifest's
    // default theme (custom colors are applied at runtime via the tint* methods instead).
    public static void applyAccentTheme(Activity activity) {
        String color = activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_COLOR, "blue");
        switch (color) {
            case "purple": activity.setTheme(R.style.Theme_Bujit_Purple); break;
            case "green":  activity.setTheme(R.style.Theme_Bujit_Green);  break;
            case "orange": activity.setTheme(R.style.Theme_Bujit_Orange); break;
            case "teal":   activity.setTheme(R.style.Theme_Bujit_Teal);   break;
            case "rose":   activity.setTheme(R.style.Theme_Bujit_Rose);   break;
            // "blue" stays as the manifest default — no setTheme needed
        }
    }

    // Applies the saved light/dark/system night-mode preference app-wide via AppCompatDelegate.
    // Must be called from Application.onCreate() so it takes effect before any Activity draws.
    public static void applyNightMode(Context context) {
        String mode = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_MODE, "system");
        switch (mode) {
            case "light": AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO);            break;
            case "dark":  AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES);           break;
            default:      AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM); break;
        }
    }

    // Persists the chosen preset accent color key (e.g. "blue", "purple").
    public static void saveColor(Context context, String color) {
        prefs(context).edit().putString(KEY_COLOR, color).apply();
    }

    // Persists the chosen night-mode preference ("light", "dark", or "system").
    public static void saveMode(Context context, String mode) {
        prefs(context).edit().putString(KEY_MODE, mode).apply();
    }

    // Persists a custom accent color hex string and switches the active color key to "custom".
    public static void saveCustomColor(Context context, String hex) {
        prefs(context).edit()
                .putString(KEY_COLOR, "custom")
                .putString(KEY_CUSTOM_HEX, hex)
                .apply();
    }

    // Returns the currently saved accent color key, defaulting to "blue".
    public static String getSavedColor(Context context) {
        return prefs(context).getString(KEY_COLOR, "blue");
    }

    // Returns the currently saved night-mode preference, defaulting to "system".
    public static String getSavedMode(Context context) {
        return prefs(context).getString(KEY_MODE, "system");
    }

    // Returns true if the user has selected a custom (non-preset) accent color.
    public static boolean isCustomColor(Context context) {
        return "custom".equals(getSavedColor(context));
    }

    /** Returns the stored custom hex as a parsed ARGB int, defaulting to blue. */
    public static int customColor(Context context) {
        String hex = prefs(context).getString(KEY_CUSTOM_HEX, "#2979FF");
        try {
            return Color.parseColor(hex);
        } catch (IllegalArgumentException e) {
            return 0xFF2979FF;
        }
    }

    /*
    Returns the resolved accent color integer for whatever is currently saved and
    handles both predefined keys and custom hex.
    */
    public static int getAccentColor(Context context) {
        if (isCustomColor(context)) return customColor(context);
        switch (getSavedColor(context)) {
            case "purple": return ContextCompat.getColor(context, R.color.accent_purple);
            case "green":  return ContextCompat.getColor(context, R.color.accent_green);
            case "orange": return ContextCompat.getColor(context, R.color.accent_orange);
            case "teal":   return ContextCompat.getColor(context, R.color.accent_teal);
            case "rose":   return ContextCompat.getColor(context, R.color.accent_rose);
            default:       return ContextCompat.getColor(context, R.color.primary_blue);
        }
    }

    // Tints a FAB to the current accent color (works for both preset and custom colors).
    // Call after setContentView for every FAB.
    public static void tintFab(FloatingActionButton fab, Context context) {
        fab.setBackgroundTintList(ColorStateList.valueOf(getAccentColor(context)));
    }

    /*
    For custom colors only: sets a TextView's text color to the current accent color.
    Preset themes handle this automatically via colorPrimary; this bridges the gap for custom.
    */
    public static void tintPrimaryText(TextView tv, Context context) {
        if (tv == null || !isCustomColor(context)) return;
        tv.setTextColor(getAccentColor(context));
    }

    /*
    For custom colors only: sets a MaterialCardView's background color to the current accent color.
    Preset themes handle this automatically via colorPrimary; this bridges the gap for custom.
    */
    public static void tintPrimaryCard(android.view.View view, Context context) {
        if (!isCustomColor(context) || !(view instanceof MaterialCardView)) return;
        ((MaterialCardView) view).setCardBackgroundColor(getAccentColor(context));
    }

    //For custom colors only: sets the SwipeRefreshLayout spinner color to the current accent color.
    public static void tintSwipeRefresh(SwipeRefreshLayout srl, Context context) {
        if (!isCustomColor(context)) return;
        srl.setColorSchemeColors(getAccentColor(context));
    }

    /*
    No-op stub kept for call-site compatibility. The action bar and status bar are
    intentionally left to the default theme color for custom accent choices -- only
    secondary elements (check bar card, FAB, balance text, etc.) receive the custom tint.
    */
    public static void tintActionBar(Activity activity) {
        // Intentionally empty: action bar is not recolored for custom accent colors.
    }

    // Returns this app's theme-settings SharedPreferences file.
    private static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }
}
