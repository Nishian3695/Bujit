package io.github.nishian3695.bujit.NavigationItems.Banking;

import android.content.Context;
import android.util.Log;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

/*
HTTP client that proxies Plaid API calls through the Firebase Cloud Function backend.
The Plaid client_id and secret live in Firebase Secret Manager, not in the APK.

Expected backend endpoints (all under the same proxy base URL as Teller):

  POST /plaid/link/token
    Headers: Authorization: Bearer <firebaseIdToken>
    Response: { "link_token": "link-sandbox-..." }

  POST /plaid/exchange
    Headers: Authorization: Bearer <firebaseIdToken>
    Body:     { "public_token": "public-sandbox-..." }
    Response: { "access_token": "access-sandbox-..." }

  GET /plaid/accounts
    Headers: Authorization: Bearer <firebaseIdToken>
             X-Plaid-Token: <accessToken>
    Response: JSON array where each element has:
      {
        "id":               "account_id from Plaid",
        "name":             "account name",
        "type":             "depository",
        "subtype":          "checking",
        "mask":             "0000",
        "institution_name": "Chase",
        "ledger":           "110.00",
        "available":        "100.00"
      }

  GET /plaid/accounts/{id}/balance
    Headers: Authorization: Bearer <firebaseIdToken>
             X-Plaid-Token: <accessToken>
    Response: { "ledger": "110.00", "available": "100.00" }

All instance methods are blocking and must be called from a background thread.
Static methods (fetchLinkToken, exchangePublicToken) are also blocking.
*/
public class PlaidBackendClient implements PlaidApi, BankingApiClient {

    private static final String TAG              = "BujitBanking";
    private static final String BACKEND_BASE_URL = "https://tellerproxy-kswzrkdipq-uc.a.run.app";
    private static final MediaType JSON          = MediaType.get("application/json; charset=utf-8");

    private final OkHttpClient http;
    private final String accessToken;
    private final String firebaseIdToken;

    public PlaidBackendClient(Context context, String accessToken, String firebaseIdToken) {
        this.accessToken     = accessToken;
        this.firebaseIdToken = firebaseIdToken;
        this.http = new OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(15, TimeUnit.SECONDS)
                .build();
    }

    // Requests a Plaid link_token from the backend so the Plaid Link SDK can be initialized.
    // Returns the raw link_token string.
    public static String fetchLinkToken(Context context, String firebaseIdToken) throws IOException {
        OkHttpClient http = new OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(15, TimeUnit.SECONDS)
                .build();
        RequestBody body = RequestBody.create("{}", MediaType.get("application/json; charset=utf-8"));
        Request request = new Request.Builder()
                .url(BACKEND_BASE_URL + "/plaid/link/token")
                .header("Authorization", "Bearer " + (firebaseIdToken != null ? firebaseIdToken : ""))
                .post(body)
                .build();
        Log.d(TAG, "PlaidBackendClient: POST /plaid/link/token");
        try (Response response = http.newCall(request).execute()) {
            Log.d(TAG, "PlaidBackendClient: /plaid/link/token → HTTP " + response.code());
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
    // The backend calls Plaid's /item/public_token/exchange and returns the access_token.
    public static String exchangePublicToken(Context context, String publicToken, String firebaseIdToken) throws IOException {
        OkHttpClient http = new OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(15, TimeUnit.SECONDS)
                .build();
        String bodyStr;
        try {
            bodyStr = new JSONObject().put("public_token", publicToken).toString();
        } catch (JSONException e) {
            throw new IOException("Failed to build exchange request body", e);
        }
        RequestBody body = RequestBody.create(bodyStr, MediaType.get("application/json; charset=utf-8"));
        Request request = new Request.Builder()
                .url(BACKEND_BASE_URL + "/plaid/exchange")
                .header("Authorization", "Bearer " + (firebaseIdToken != null ? firebaseIdToken : ""))
                .post(body)
                .build();
        Log.d(TAG, "PlaidBackendClient: POST /plaid/exchange");
        try (Response response = http.newCall(request).execute()) {
            Log.d(TAG, "PlaidBackendClient: /plaid/exchange → HTTP " + response.code());
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
    public List<BankAccountModel> fetchAccounts() throws IOException {
        Log.d(TAG, "PlaidBackendClient: GET /plaid/accounts");
        List<BankAccountModel> accounts = new ArrayList<>();
        try (Response response = http.newCall(buildRequest("/plaid/accounts")).execute()) {
            Log.d(TAG, "PlaidBackendClient: /plaid/accounts → HTTP " + response.code());
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
            if (!r.isSuccessful())
                throw new IOException("Backend " + path + " failed: HTTP " + r.code());
            JSONObject bal      = new JSONObject(r.body().string());
            float ledger        = parseFloatSafe(bal.optString("ledger",    "0"));
            float available     = parseFloatSafe(bal.optString("available", "0"));
            return new float[]{ledger, available};
        } catch (JSONException e) {
            throw new IOException("Parse error for " + accountId + ": " + e.getMessage(), e);
        }
    }

    @Override
    public float fetchAccountBalance(String accountId) throws IOException {
        String path = "/plaid/accounts/" + accountId + "/balance";
        Log.d(TAG, "PlaidBackendClient: GET " + path);
        try (Response r = http.newCall(buildRequest(path)).execute()) {
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
                .url(BACKEND_BASE_URL + path)
                .header("X-Plaid-Token", accessToken)
                .header("Authorization", "Bearer " + (firebaseIdToken != null ? firebaseIdToken : ""))
                .build();
    }

    private float parseFloatSafe(String s) {
        try { return Float.parseFloat(s); } catch (NumberFormatException e) { return 0f; }
    }
}
