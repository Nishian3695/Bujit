package io.github.nishian3695.bujit;

import android.app.Application;

/*
Custom Application class for Bujit.
Runs once when the app process starts, before any Activity is created.
Used to apply the user's saved light/dark/system night mode preference
globally so it takes effect before the first screen draws.
*/
public class BujitApp extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        ThemeHelper.applyNightMode(this);
    }
}
