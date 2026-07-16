package io.github.nishian3695.bujit;

import android.content.Context;

// Stores whether currency amounts should render with thousands separators
// (e.g. $3,000,000.00 vs $3000000.00), persisted via SharedPreferences.
public class DisplayPrefs {
    private static final String PREFS = "bujit_display_prefs";
    private static final String KEY_COMMA_SEPARATORS = "use_comma_separators";

    // Reads whether comma-separated currency display is enabled; defaults to false (off) if never set.
    public static boolean useCommaSeparators(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_COMMA_SEPARATORS, false);
    }

    // Turns comma-separated currency display on or off and saves the choice for future app launches.
    public static void setUseCommaSeparators(Context context, boolean enabled) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_COMMA_SEPARATORS, enabled)
                .apply();
    }
}
