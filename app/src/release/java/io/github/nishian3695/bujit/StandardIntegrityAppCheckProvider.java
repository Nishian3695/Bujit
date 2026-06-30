package io.github.nishian3695.bujit;

import android.content.Context;
import android.util.Log;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.TaskCompletionSource;
import com.google.android.gms.tasks.Tasks;
import com.google.android.play.core.integrity.IntegrityManagerFactory;
import com.google.android.play.core.integrity.StandardIntegrityManager;
import com.google.firebase.appcheck.AppCheckProvider;
import com.google.firebase.appcheck.AppCheckProviderFactory;
import com.google.firebase.appcheck.AppCheckToken;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

class StandardIntegrityAppCheckProvider implements AppCheckProvider {
    private static final String TAG = "StdIntegrityProvider";

    private static final long CLOUD_PROJECT_NUMBER = 533939418471L;

    private final Context context;
    private final Executor executor = Executors.newSingleThreadExecutor();
    private volatile StandardIntegrityManager.StandardIntegrityTokenProvider tokenProvider;

    private StandardIntegrityAppCheckProvider(Context context) {
        this.context = context.getApplicationContext();
    }

    static AppCheckProviderFactory factory() {
        return firebaseApp -> new StandardIntegrityAppCheckProvider(
                firebaseApp.getApplicationContext());
    }

    @Override
    public Task<AppCheckToken> getToken() {
        TaskCompletionSource<AppCheckToken> tcs = new TaskCompletionSource<>();
        executor.execute(() -> {
            try {
                String piToken = acquireIntegrityToken();
                tcs.setResult(exchangeWithBackend(piToken));
            } catch (Exception e) {
                Log.e(TAG, "getToken failed", e);
                tcs.setException(e);
            }
        });
        return tcs.getTask();
    }

    private String acquireIntegrityToken() throws Exception {
        if (tokenProvider == null) {
            StandardIntegrityManager mgr = IntegrityManagerFactory.createStandard(context);
            tokenProvider = Tasks.await(mgr.prepareIntegrityToken(
                    StandardIntegrityManager.PrepareIntegrityTokenRequest.builder()
                            .setCloudProjectNumber(CLOUD_PROJECT_NUMBER)
                            .build()));
        }
        return Tasks.await(
                tokenProvider.request(
                        StandardIntegrityManager.StandardIntegrityTokenRequest.builder()
                                .build())).token();
    }

    private AppCheckToken exchangeWithBackend(String piToken) throws Exception {
        String urlStr = "https://tellerproxy-kswzrkdipq-uc.a.run.app/exchangeIntegrityToken";
        HttpURLConnection conn = (HttpURLConnection) new URL(urlStr).openConnection();
        conn.setConnectTimeout(15_000);
        conn.setReadTimeout(15_000);
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);
        byte[] body = new JSONObject()
                .put("integrityToken", piToken)
                .toString()
                .getBytes(StandardCharsets.UTF_8);
        try (OutputStream os = conn.getOutputStream()) {
            os.write(body);
        }

        int code = conn.getResponseCode();
        StringBuilder sb = new StringBuilder();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(
                code < 400 ? conn.getInputStream() : conn.getErrorStream(),
                StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) sb.append(line);
        }
        if (code != 200) throw new Exception("exchangeIntegrityToken HTTP " + code + ": " + sb);

        JSONObject resp = new JSONObject(sb.toString());
        String token = resp.getString("token");
        long ttlMillis = resp.optLong("ttlMillis", 3_600_000L);
        return new Token(token, System.currentTimeMillis() + ttlMillis);
    }

    private static final class Token extends AppCheckToken {
        private final String token;
        private final long expireTimeMillis;

        Token(String token, long expireTimeMillis) {
            this.token = token;
            this.expireTimeMillis = expireTimeMillis;
        }

        @Override public String getToken() { return token; }
        @Override public long getExpireTimeMillis() { return expireTimeMillis; }
    }
}
