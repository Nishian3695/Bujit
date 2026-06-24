package io.github.nishian3695.bujit;

import android.app.Application;
import com.google.firebase.appcheck.FirebaseAppCheck;
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory;

public class BujitApp extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        ThemeHelper.applyNightMode(this);
        FirebaseAppCheck.getInstance().installAppCheckProviderFactory(
                PlayIntegrityAppCheckProviderFactory.getInstance());
    }
}
