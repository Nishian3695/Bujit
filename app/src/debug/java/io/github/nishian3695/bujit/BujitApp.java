package io.github.nishian3695.bujit;

import android.app.Application;
import com.google.firebase.appcheck.FirebaseAppCheck;
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory;

/*
Debug variant of BujitApp. Replaces the Play Integrity App Check provider with the
Debug provider so that development/CI builds can reach the backend without a real
Play Integrity attestation. A debug secret token is auto-logged on first run;
register it in the Firebase console under App Check → Apps → Manage debug tokens.
*/
public class BujitApp extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        ThemeHelper.applyNightMode(this);
        FirebaseAppCheck.getInstance().installAppCheckProviderFactory(
                DebugAppCheckProviderFactory.getInstance());
    }
}
