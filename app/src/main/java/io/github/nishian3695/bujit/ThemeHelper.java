package io.github.nishian3695.bujit;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.widget.TextView;
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

    public static void applyNightMode(Context context) {
        String mode = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_MODE, "system");
        switch (mode) {
            case "light": AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO);            break;
            case "dark":  AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES);           break;
            default:      AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM); break;
        }
    }

    public static void saveColor(Context context, String color) {
        prefs(context).edit().putString(KEY_COLOR, color).apply();
    }

    public static void saveMode(Context context, String mode) {
        prefs(context).edit().putString(KEY_MODE, mode).apply();
    }

    public static void saveCustomColor(Context context, String hex) {
        prefs(context).edit()
                .putString(KEY_COLOR, "custom")
                .putString(KEY_CUSTOM_HEX, hex)
                .apply();
    }

    public static String getSavedColor(Context context) {
        return prefs(context).getString(KEY_COLOR, "blue");
    }

    public static String getSavedMode(Context context) {
        return prefs(context).getString(KEY_MODE, "system");
    }

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

    // Tints a FAB to the current accent color. Call after setContentView for every FAB
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

    private static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }
}
