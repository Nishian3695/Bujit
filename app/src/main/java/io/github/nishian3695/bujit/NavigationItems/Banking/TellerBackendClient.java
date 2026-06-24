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
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

/*
HTTP client that proxies Teller API calls through the Firebase Cloud Function backend.
The mTLS certificate and private key live in Firebase Secret Manager, not in the APK,
so this client never needs to bundle sensitive credentials.

Each request carries two authentication headers:
X-Teller-Token -- the Teller enrollment access token for the enrolled bank
Authorization -- a Firebase ID token so the Cloud Function can verify the caller

All methods are blocking and must be called from a background thread.
*/
public class TellerBackendClient implements TellerApi, BankingApiClient {

    private static final String TAG = "BujitBanking";
    private static final String BACKEND_BASE_URL = "https://tellerproxy-kswzrkdipq-uc.a.run.app";

    private final OkHttpClient http;
    private final String accessToken;
    private final String firebaseIdToken;

    public TellerBackendClient(Context context, String accessToken, String firebaseIdToken) {
        this.accessToken = accessToken;
        this.firebaseIdToken = firebaseIdToken;
        this.http = new OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(15, TimeUnit.SECONDS)
                .build();
    }

    @Override
    public List<BankAccountModel> fetchAccounts() throws IOException {
        Log.d(TAG, "TellerBackendClient: GET /accounts");
        List<BankAccountModel> accounts = new ArrayList<>();
        try (Response response = http.newCall(buildRequest("/accounts")).execute()) {
            Log.d(TAG, "TellerBackendClient: /accounts → HTTP " + response.code());
            if (!response.isSuccessful()) {
                String errorBody = response.body() != null ? response.body().string() : "(no body)";
                Log.e(TAG, "TellerBackendClient: /accounts error body: " + errorBody);
                throw new IOException("Backend /accounts failed: HTTP " + response.code());
            }
            JSONArray json = new JSONArray(response.body().string());
            for (int i = 0; i < json.length(); i++) {
                JSONObject obj = json.getJSONObject(i);
                BankAccountModel account = new BankAccountModel();
                account.setId(obj.optString("id"));
                account.setName(obj.optString("name"));
                account.setToken(accessToken);
                account.setType(obj.optString("type"));
                account.setSubtype(obj.optString("subtype"));
                account.setLastFour(obj.optString("last_four"));
                account.setStatus(obj.optString("status"));
                JSONObject institution = obj.optJSONObject("institution");
                if (institution != null) {
                    account.setInstitutionName(institution.optString("name"));
                }
                accounts.add(account);
            }
        } catch (JSONException e) {
            throw new IOException("Failed to parse backend /accounts response: " + e.getMessage(), e);
        }

        for (BankAccountModel account : accounts) {
            String path = "/accounts/" + account.getId() + "/balances";
            try (Response r = http.newCall(buildRequest(path)).execute()) {
                if (r.isSuccessful()) {
                    JSONObject bal = new JSONObject(r.body().string());
                    account.setLedgerBalance(bal.optString("ledger", "—"));
                    account.setAvailableBalance(bal.optString("available", "—"));
                }
            } catch (Exception e) {
                Log.w(TAG, "TellerBackendClient: balance fetch failed for "
                        + account.getName() + ": " + e.getMessage());
                account.setLedgerBalance("—");
                account.setAvailableBalance("—");
            }
        }

        return accounts;
    }

    @Override
    public float[] fetchAccountBalancePair(String accountId) throws IOException {
        String path = "/accounts/" + accountId + "/balances";
        Log.d(TAG, "TellerBackendClient: GET " + path);
        try (Response r = http.newCall(buildRequest(path)).execute()) {
            if (!r.isSuccessful())
                throw new IOException("Backend " + path + " failed: HTTP " + r.code());
            JSONObject bal = new JSONObject(r.body().string());
            float ledger    = parseFloatSafe(bal.optString("ledger",    "0"));
            float available = parseFloatSafe(bal.optString("available", "0"));
            return new float[]{ledger, available};
        } catch (JSONException e) {
            throw new IOException("Parse error for " + accountId + ": " + e.getMessage(), e);
        }
    }

    @Override
    public float fetchAccountBalance(String accountId) throws IOException {
        String path = "/accounts/" + accountId + "/balances";
        Log.d(TAG, "TellerBackendClient: GET " + path);
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
                .header("X-Teller-Token", accessToken)
                .header("Authorization", "Bearer " + firebaseIdToken)
                .build();
    }

    private float parseFloatSafe(String s) {
        try { return Float.parseFloat(s); } catch (NumberFormatException e) { return 0f; }
    }
}
