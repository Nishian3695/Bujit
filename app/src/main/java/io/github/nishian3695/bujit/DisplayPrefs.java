package io.github.nishian3695.bujit;

import android.content.Context;

// Stores display preferences persisted via SharedPreferences: whether currency amounts render
// with thousands separators (e.g. $3,000,000.00 vs $3000000.00), and whether the after-check
// balance also includes the next check's income.
public class DisplayPrefs {
    private static final String PREFS = "bujit_display_prefs";
    private static final String KEY_COMMA_SEPARATORS = "use_comma_separators";
    private static final String KEY_INCLUDE_NEXT_CHECK = "include_next_check";

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

    // Reads whether the home screen's after-check balance should also include the next check's
    // projected income (shown as "Next Check"); defaults to false (off) if never set.
    public static boolean includeNextCheck(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_INCLUDE_NEXT_CHECK, false);
    }

    // Turns next-check income inclusion on or off and saves the choice for future app launches.
    public static void setIncludeNextCheck(Context context, boolean enabled) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_INCLUDE_NEXT_CHECK, enabled)
                .apply();
    }
}
