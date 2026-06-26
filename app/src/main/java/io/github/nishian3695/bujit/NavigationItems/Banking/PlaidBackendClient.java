package io.github.nishian3695.bujit.NavigationItems.Banking;

import android.content.Context;
import android.util.Log;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

/*
HTTP client that proxies Plaid API calls through the Firebase Cloud Function backend.
The Plaid client_id and secret live in Firebase Secret Manager, not in the APK.

All requests carry a Firebase ID token (Authorization: Bearer) so the backend can
reject unauthenticated callers. TLS is validated by Android's system trust store
against the Google-managed Cloud Run certificate; no additional pinning is applied.

HTTP 401 responses are surfaced as BankingAuthException to signal that the stored
access token has been revoked and the user must re-link their bank account.
*/
public class PlaidBackendClient implements PlaidApi, BankingApiClient {

    private static final String TAG     = "BujitBanking";
    private static final String BASE    = "https://" + BankingProviderConfig.BACKEND_HOST;
    private static final MediaType JSON = MediaType.get("application/json; charset=utf-8");

    private final OkHttpClient http;
    private final String accessToken;
    private final String firebaseIdToken;

    public PlaidBackendClient(Context context, String accessToken, String firebaseIdToken) {
        this.accessToken     = accessToken;
        this.firebaseIdToken = firebaseIdToken;
        this.http            = BankingProviderConfig.buildSecureHttpClient();
    }

    // Requests a Plaid link_token from the backend so the Plaid Link SDK can be initialized.
    public static String fetchLinkToken(Context context, String firebaseIdToken) throws IOException {
        OkHttpClient http = BankingProviderConfig.buildSecureHttpClient();
        RequestBody body = RequestBody.create("{}", JSON);
        Request request = new Request.Builder()
                .url(BASE + "/plaid/link/token")
                .header("Authorization", "Bearer " + (firebaseIdToken != null ? firebaseIdToken : ""))
                .post(body)
                .build();
        Log.d(TAG, "PlaidBackendClient: POST /plaid/link/token");
        try (Response response = http.newCall(request).execute()) {
            Log.d(TAG, "PlaidBackendClient: /plaid/link/token → HTTP " + response.code());
            checkForAuthError(response);
            if (!response.isSuccessful()) {
                String err = response.body() != null ? response.body().string() : "(no body)";
                throw new IOException("Backend /plaid/link/token failed: HTTP " + response.code() + " " + err);
            }
            JSONObject json = new JSONObject(response.body().string());
            return json.getString("link_token");
        } catch (JSONException e) {
            throw new IOException("Failed to parse link_token response: " + e.getMessage(), e);
        }
    }

    // Exchanges a Plaid public_token (from the SDK callback) for a permanent access_token.
    public static String exchangePublicToken(Context context, String publicToken,
            String firebaseIdToken) throws IOException {
        OkHttpClient http = BankingProviderConfig.buildSecureHttpClient();
        String bodyStr;
        try {
            bodyStr = new JSONObject().put("public_token", publicToken).toString();
        } catch (JSONException e) {
            throw new IOException("Failed to build exchange request body", e);
        }
        RequestBody body = RequestBody.create(bodyStr, JSON);
        Request request = new Request.Builder()
                .url(BASE + "/plaid/exchange")
                .header("Authorization", "Bearer " + (firebaseIdToken != null ? firebaseIdToken : ""))
                .post(body)
                .build();
        Log.d(TAG, "PlaidBackendClient: POST /plaid/exchange");
        try (Response response = http.newCall(request).execute()) {
            Log.d(TAG, "PlaidBackendClient: /plaid/exchange → HTTP " + response.code());
            checkForAuthError(response);
            if (!response.isSuccessful()) {
                String err = response.body() != null ? response.body().string() : "(no body)";
                throw new IOException("Backend /plaid/exchange failed: HTTP " + response.code() + " " + err);
            }
            JSONObject json = new JSONObject(response.body().string());
            return json.getString("access_token");
        } catch (JSONException e) {
            throw new IOException("Failed to parse access_token response: " + e.getMessage(), e);
        }
    }

    @Override
    public void revokeToken() throws IOException {
        RequestBody body = RequestBody.create("{}", JSON);
        Request request = new Request.Builder()
                .url(BASE + "/plaid/remove")
                .header("X-Plaid-Token", accessToken)
                .header("Authorization", "Bearer " + (firebaseIdToken != null ? firebaseIdToken : ""))
                .post(body)
                .build();
        Log.d(TAG, "PlaidBackendClient: POST /plaid/remove");
        try (Response response = http.newCall(request).execute()) {
            Log.d(TAG, "PlaidBackendClient: /plaid/remove → HTTP " + response.code());
            if (!response.isSuccessful()) {
                String err = response.body() != null ? response.body().string() : "(no body)";
                throw new IOException("Backend /plaid/remove failed: HTTP " + response.code() + " " + err);
            }
        }
    }

    @Override
    public List<BankAccountModel> fetchAccounts() throws IOException {
        Log.d(TAG, "PlaidBackendClient: GET /plaid/accounts");
        List<BankAccountModel> accounts = new ArrayList<>();
        try (Response response = http.newCall(buildRequest("/plaid/accounts")).execute()) {
            Log.d(TAG, "PlaidBackendClient: /plaid/accounts → HTTP " + response.code());
            checkForAuthError(response);
            if (!response.isSuccessful()) {
                String errorBody = response.body() != null ? response.body().string() : "(no body)";
                Log.e(TAG, "PlaidBackendClient: /plaid/accounts error body: " + errorBody);
                throw new IOException("Backend /plaid/accounts failed: HTTP " + response.code());
            }
            JSONArray json = new JSONArray(response.body().string());
            for (int i = 0; i < json.length(); i++) {
                JSONObject obj    = json.getJSONObject(i);
                BankAccountModel account = new BankAccountModel();
                account.setId(obj.optString("id"));
                account.setName(obj.optString("name"));
                account.setToken(accessToken);
                account.setType(obj.optString("type"));
                account.setSubtype(obj.optString("subtype"));
                account.setLastFour(obj.optString("mask"));
                account.setStatus(obj.optString("status", "active"));
                account.setInstitutionName(obj.optString("institution_name"));
                account.setLedgerBalance(obj.optString("ledger", "—"));
                account.setAvailableBalance(obj.optString("available", "—"));
                if (!obj.isNull("limit")) account.setCreditLimit(obj.optString("limit"));
                accounts.add(account);
            }
        } catch (JSONException e) {
            throw new IOException("Failed to parse /plaid/accounts response: " + e.getMessage(), e);
        }
        return accounts;
    }

    @Override
    public float[] fetchAccountBalancePair(String accountId) throws IOException {
        String path = "/plaid/accounts/" + accountId + "/balance";
        Log.d(TAG, "PlaidBackendClient: GET " + path);
        try (Response r = http.newCall(buildRequest(path)).execute()) {
            checkForAuthError(r);
            if (!r.isSuccessful())
                throw new IOException("Backend " + path + " failed: HTTP " + r.code());
            JSONObject bal  = new JSONObject(r.body().string());
            float ledger    = parseFloatSafe(bal.optString("ledger",    "0"));
            float available = parseFloatSafe(bal.optString("available", "0"));
            float limit     = !bal.isNull("limit") ? parseFloatSafe(bal.optString("limit", "0")) : 0f;
            return new float[]{ledger, available, limit};
        } catch (JSONException e) {
            throw new IOException("Parse error for " + accountId + ": " + e.getMessage(), e);
        }
    }

    @Override
    public float fetchAccountBalance(String accountId) throws IOException {
        String path = "/plaid/accounts/" + accountId + "/balance";
        Log.d(TAG, "PlaidBackendClient: GET " + path);
        try (Response r = http.newCall(buildRequest(path)).execute()) {
            checkForAuthError(r);
            if (!r.isSuccessful())
                throw new IOException("Backend " + path + " failed: HTTP " + r.code());
            JSONObject bal = new JSONObject(r.body().string());
            return Float.parseFloat(bal.optString("ledger", "0"));
        } catch (JSONException | NumberFormatException e) {
            throw new IOException("Parse error for " + accountId + ": " + e.getMessage(), e);
        }
    }

    private Request buildRequest(String path) {
        return new Request.Builder()
                .url(BASE + path)
                .header("X-Plaid-Token", accessToken)
                .header("Authorization", "Bearer " + (firebaseIdToken != null ? firebaseIdToken : ""))
                .build();
    }

    // Throws BankingAuthException when the backend returns HTTP 401, which signals that the
    // Plaid access token is revoked (ITEM_LOGIN_REQUIRED or ACCESS_NOT_GRANTED).
    // The response body is consumed here to extract the error code for logging.
    private static void checkForAuthError(Response response) throws IOException {
        if (response.code() == 401) {
            String errorCode = "AUTH_REQUIRED";
            try {
                if (response.body() != null) {
                    JSONObject body = new JSONObject(response.body().string());
                    errorCode = body.optString("error", errorCode);
                }
            } catch (Exception ignored) {}
            Log.w(TAG, "Plaid 401 received: " + errorCode);
            throw new BankingAuthException(errorCode);
        }
    }

    private float parseFloatSafe(String s) {
        try { return Float.parseFloat(s); } catch (NumberFormatException e) { return 0f; }
    }
}
