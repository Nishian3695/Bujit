package io.github.nishian3695.bujit;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;
import com.google.firebase.appcheck.FirebaseAppCheck;

public class BujitApp extends Application {

    public static volatile boolean needsAuth = false;
    private static volatile boolean promptShowing = false;
    private int startedCount = 0;

    @Override
    public void onCreate() {
        super.onCreate();
        ThemeHelper.applyNightMode(this);
        FirebaseAppCheck.getInstance().installAppCheckProviderFactory(
                StandardIntegrityAppCheckProvider.factory());
        registerActivityLifecycleCallbacks(new ActivityLifecycleCallbacks() {
            @Override public void onActivityCreated(Activity a, Bundle b) {}
            @Override public void onActivityStarted(Activity a) {
                if (startedCount == 0) needsAuth = true;
                startedCount++;
            }
            @Override public void onActivityResumed(Activity a) {
                maybeShowLockPrompt(a);
            }
            @Override public void onActivityPaused(Activity a) {}
            @Override public void onActivityStopped(Activity a) { startedCount--; }
            @Override public void onActivitySaveInstanceState(Activity a, Bundle b) {}
            @Override public void onActivityDestroyed(Activity a) {}
        });
    }

    private static void maybeShowLockPrompt(Activity a) {
        if (!(a instanceof FragmentActivity)) return;
        if (!needsAuth || !AppLockPrefs.isLockEnabled(a) || promptShowing) return;
        needsAuth = false;
        promptShowing = true;
        BiometricPrompt.PromptInfo info = new BiometricPrompt.PromptInfo.Builder()
                .setTitle("Bujit")
                .setSubtitle("Authenticate to access your budget")
                .setAllowedAuthenticators(
                        BiometricManager.Authenticators.BIOMETRIC_STRONG |
                        BiometricManager.Authenticators.DEVICE_CREDENTIAL)
                .build();
        new BiometricPrompt((FragmentActivity) a, ContextCompat.getMainExecutor(a),
                new BiometricPrompt.AuthenticationCallback() {
                    @Override
                    public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult r) {
                        promptShowing = false;
                    }
                    @Override public void onAuthenticationFailed() {}
                    @Override
                    public void onAuthenticationError(int code, CharSequence msg) {
                        promptShowing = false;
                        if (code == BiometricPrompt.ERROR_CANCELED) {
                            needsAuth = true;
                            return;
                        }
                        a.finishAffinity();
                    }
                }).authenticate(info);
    }
}
