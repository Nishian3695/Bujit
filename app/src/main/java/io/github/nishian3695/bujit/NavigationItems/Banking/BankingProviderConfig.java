package io.github.nishian3695.bujit.NavigationItems.Banking;

import android.content.Context;
import android.util.Log;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.appcheck.FirebaseAppCheck;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import io.teller.connect.sdk.Environment;
import java.util.concurrent.TimeUnit;
import okhttp3.OkHttpClient;

/*
Compile-time switch between banking data providers.
Change ACTIVE_PROVIDER to select which provider BankingActivity uses.
Both providers share the same BankAccountModel and UI; only the SDK launch
and backend client differ.

Also owns the shared OkHttpClient factory and Firebase helper used by both backend clients.
TLS is validated by Android's system trust store (Google-managed Cloud Run certificates).
Firebase ID-token auth is the primary request authentication mechanism; Firebase App Check
provider factories are installed in BujitApp for future enforcement when ENFORCE_APP_CHECK
is enabled on the backend.
*/
public class BankingProviderConfig {

    public enum Provider {
        TELLER,
        PLAID
    }

    // Change this single line to switch providers.
    public static final Provider ACTIVE_PROVIDER = Provider.PLAID;

    // Change this to Environment.SANDBOX or Environment.DEVELOPMENT.
    public static final Environment TELLER_ENV = Environment.SANDBOX;

    private static final String TAG = "BujitBanking";
    static final String BACKEND_HOST = "tellerproxy-kswzrkdipq-uc.a.run.app";

    // Builds the OkHttpClient shared by both PlaidBackendClient and TellerBackendClient.
    static OkHttpClient buildSecureHttpClient() {
        return new OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(15, TimeUnit.SECONDS)
                .build();
    }

    // Returns the correct backend client for the active provider.
    public static BankingApiClient createClient(Context ctx, String token, String idToken, String appCheckToken) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            return new PlaidBackendClient(ctx, token, idToken, appCheckToken);
        }
        return new TellerBackendClient(ctx, token, idToken, appCheckToken);
    }

    // Revokes the given access token on the provider's server.
    // Best-effort: failures are logged but do not block local cleanup.
    public static void revokeToken(Context ctx, String token, String idToken, String appCheckToken) {
        try {
            createClient(ctx, token, idToken, appCheckToken).revokeToken();
        } catch (Exception e) {
            Log.w(TAG, "revokeToken: server-side revocation failed (proceeding with local cleanup): "
                    + e.getMessage());
        }
    }

    // Returns the access token stored for a given account ID under the active provider.
    public static String getTokenForAccount(Context ctx, String accountId) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            return BankingPrefs.getPlaidTokenForAccount(ctx, accountId);
        }
        return BankingPrefs.getTokenForAccount(ctx, accountId);
    }

    // Persists the account to token mapping for the active provider.
    public static void saveAccountToken(Context ctx, String accountId, String token) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            BankingPrefs.savePlaidAccountToken(ctx, accountId, token);
        } else {
            BankingPrefs.saveAccountToken(ctx, accountId, token);
        }
    }

    // Returns all stored tokens for the active provider.
    public static java.util.Set<String> loadTokens(Context ctx) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            return BankingPrefs.loadPlaidTokens(ctx);
        }
        return BankingPrefs.loadTokens(ctx);
    }

    // Returns the set of linked account composite keys ("token|accountId") for the active provider.
    public static java.util.Set<String> loadLinkedAccounts(Context ctx) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            return BankingPrefs.loadPlaidLinkedAccounts(ctx);
        }
        return BankingPrefs.loadLinkedAccounts(ctx);
    }

    // Persists linked account composite keys for the active provider.
    public static void saveLinkedAccounts(Context ctx, java.util.Set<String> composites) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            BankingPrefs.savePlaidLinkedAccounts(ctx, composites);
        } else {
            BankingPrefs.saveLinkedAccounts(ctx, composites);
        }
    }

    // Fetches a Firebase ID token on the calling thread (must be a background thread).
    // Returns null on failure; callers should handle null gracefully.
    public static String fetchFirebaseIdToken() {
        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        if (user == null) return null;
        try {
            return Tasks.await(user.getIdToken(false)).getToken();
        } catch (Exception e) {
            Log.e(TAG, "fetchFirebaseIdToken failed: " + e.getMessage());
            return null;
        }
    }

    // Fetches a Firebase App Check token on the calling thread (must be a background thread).
    // Returns null on failure; callers should handle null gracefully.
    public static String fetchAppCheckToken() {
        try {
            return Tasks.await(FirebaseAppCheck.getInstance().getToken(false)).getToken();
        } catch (Exception e) {
            Log.e(TAG, "fetchAppCheckToken failed: " + e.getMessage());
            return null;
        }
    }
}
