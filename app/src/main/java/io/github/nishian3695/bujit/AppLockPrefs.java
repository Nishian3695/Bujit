package io.github.nishian3695.bujit;

import android.content.Context;

// Stores whether the app's lock screen (PIN/biometric gate shown on launch) is turned on,
// persisted via SharedPreferences so the setting survives app restarts.
public class AppLockPrefs {
    private static final String PREFS = "bujit_lock_prefs";
    private static final String KEY_LOCK_ENABLED = "lock_enabled";

    // Reads whether the lock screen is currently enabled; defaults to false (unlocked) if never set.
    public static boolean isLockEnabled(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_LOCK_ENABLED, false);
    }

    // Turns the lock screen on or off and saves the choice for future app launches.
    public static void setLockEnabled(Context context, boolean enabled) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_LOCK_ENABLED, enabled)
                .apply();
    }
}
