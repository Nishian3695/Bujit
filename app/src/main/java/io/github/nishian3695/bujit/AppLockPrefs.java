package io.github.nishian3695.bujit;

import android.content.Context;

public class AppLockPrefs {
    private static final String PREFS = "bujit_lock_prefs";
    private static final String KEY_LOCK_ENABLED = "lock_enabled";

    public static boolean isLockEnabled(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_LOCK_ENABLED, false);
    }

    public static void setLockEnabled(Context context, boolean enabled) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_LOCK_ENABLED, enabled)
                .apply();
    }
}
