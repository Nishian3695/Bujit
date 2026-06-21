package io.github.nishian3695.bujit.NavigationItems.Settings;

import android.accounts.Account;
import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;
import com.google.android.gms.auth.UserRecoverableAuthException;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamModel;
import com.google.android.gms.auth.GoogleAuthUtil;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.Scope;
import org.json.JSONObject;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;
import okhttp3.ResponseBody;

/*
Manages Google Tasks sync for Bujit expenses and income streams.
*/
public class GoogleTasksHelper {

    private static final String TAG = "GoogleTasksHelper";

    public static final String TASKS_SCOPE      = "oauth2:https://www.googleapis.com/auth/tasks";
    private static final String TASKS_BASE      = "https://tasks.googleapis.com/tasks/v1";
    private static final String PREFS_NAME      = "bujit_calendar_prefs";
    public static final String KEY_SYNC_ENABLED = "sync_enabled";
    private static final String KEY_LIST_ID     = "bujit_task_list_id";
    private static final String BUJIT_LIST_NAME = "Bujit";
    private static final MediaType JSON         = MediaType.get("application/json; charset=utf-8");

    // Result of a bulk sync operation
    public static class SyncResult {
        public final int created;
        public final int failed;
        public final String lastError;
        SyncResult(int created, int failed, String lastError) {
            this.created   = created;
            this.failed    = failed;
            this.lastError = lastError;
        }
    }

    private final Context context;
    private final OkHttpClient client;
    private final SharedPreferences prefs;

    public GoogleTasksHelper(Context context) {
        this.context = context.getApplicationContext();
        this.client  = new OkHttpClient();
        this.prefs   = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    public static GoogleSignInClient buildSignInClient(Context context) {
        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestEmail()
                .requestScopes(new Scope("https://www.googleapis.com/auth/tasks"))
                .build();
        return GoogleSignIn.getClient(context, gso);
    }

    public static boolean isCalendarSyncEnabled(Context context) {
        GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(context);
        if (account == null) return false;
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getBoolean(KEY_SYNC_ENABLED, false);
    }

    // Must run on background thread.
    private String getAccessToken() throws Exception {
        GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(context);
        if (account == null) throw new IllegalStateException("Not signed in to Google");
        Account googleAccount = account.getAccount();
        if (googleAccount == null) throw new IllegalStateException("No Android account for Google sign-in");
        try {
            return GoogleAuthUtil.getToken(context, googleAccount, TASKS_SCOPE);
        } catch (UserRecoverableAuthException e) {
            throw new Exception("Tasks permission not granted. Please disconnect and reconnect Google in Settings.", e);
        }
    }

    // Returns the stored "Bujit" task list ID, or creates the list if it doesn't exist yet.
    // Must run on background thread.
    private String getOrCreateBujitList(String token) throws Exception {
        String saved = prefs.getString(KEY_LIST_ID, null);
        // "@default" is a stale value from old code — ignore it and create a real Bujit list.
        if (saved != null && !saved.equals("@default")) {
            Request verify = new Request.Builder()
                    .url(TASKS_BASE + "/users/@me/lists/" + saved)
                    .header("Authorization", "Bearer " + token)
                    .get()
                    .build();
            try (Response vResp = client.newCall(verify).execute()) {
                if (vResp.isSuccessful()) return saved;
                // List was deleted externally — clear the stale ID and fall through to recreate.
                Log.d(TAG, "Bujit task list missing (deleted?), will recreate.");
                prefs.edit().remove(KEY_LIST_ID).apply();
            }
        }

        // Search existing lists first to avoid creating duplicates (e.g. after app reinstall).
        Request listReq = new Request.Builder()
                .url(TASKS_BASE + "/users/@me/lists?maxResults=100")
                .header("Authorization", "Bearer " + token)
                .get()
                .build();
        try (Response listResp = client.newCall(listReq).execute()) {
            if (listResp.isSuccessful()) {
                JSONObject json = new JSONObject(bodyString(listResp));
                if (json.has("items")) {
                    org.json.JSONArray items = json.getJSONArray("items");
                    for (int i = 0; i < items.length(); i++) {
                        JSONObject item = items.getJSONObject(i);
                        if (BUJIT_LIST_NAME.equals(item.optString("title"))) {
                            String found = item.getString("id");
                            prefs.edit().putString(KEY_LIST_ID, found).apply();
                            Log.d(TAG, "Found existing Bujit task list: " + found);
                            return found;
                        }
                    }
                }
            }
        }

        // No existing list -- create one.
        JSONObject body = new JSONObject();
        body.put("title", BUJIT_LIST_NAME);
        Request req = new Request.Builder()
                .url(TASKS_BASE + "/users/@me/lists")
                .header("Authorization", "Bearer " + token)
                .post(RequestBody.create(body.toString(), JSON))
                .build();
        try (Response resp = client.newCall(req).execute()) {
            String raw = bodyString(resp);
            if (!resp.isSuccessful())
                throw new Exception("Create list failed (" + resp.code() + "): " + raw);
            String listId = new JSONObject(raw).getString("id");
            prefs.edit().putString(KEY_LIST_ID, listId).apply();
            Log.d(TAG, "Created Bujit task list: " + listId);
            return listId;
        }
    }

    private String expenseDueDate(ExpenseModel e) {
        LocalDate date = e.getDate();
        LocalDate today = LocalDate.now();
        while (date.isBefore(today)) {
            date = date.plus(e.getFrequency(), e.getFrequencyTag());
        }
        return date.format(DateTimeFormatter.ISO_LOCAL_DATE) + "T00:00:00.000Z";
    }

    private String incomeDueDate(IncomeStreamModel s) {
        LocalDate date = LocalDate.parse(s.getCheckDate(),
                DateTimeFormatter.ofPattern("yyyy.MM.dd"));
        LocalDate today = LocalDate.now();
        ChronoUnit unit;
        switch (s.getFrequencyTag()) {
            case 0:  unit = ChronoUnit.DAYS;   break;
            case 2:  unit = ChronoUnit.MONTHS; break;
            case 3:  unit = ChronoUnit.YEARS;  break;
            default: unit = ChronoUnit.WEEKS;  break;
        }
        while (date.isBefore(today)) {
            date = date.plus(s.getFrequency(), unit);
        }
        return date.format(DateTimeFormatter.ISO_LOCAL_DATE) + "T00:00:00.000Z";
    }

    private JSONObject buildExpenseTask(ExpenseModel expense) throws Exception {
        JSONObject task = new JSONObject();
        task.put("title", expense.getName() + " — $" + expense.getCost());
        task.put("notes", "Every " + expense.getFrequency() + " "
                + expense.getFrequencyTag().toString().toLowerCase() + "(s)\nBujit Budget Expense");
        task.put("status", "needsAction");
        if (expense.isCalendarNotificationsEnabled()) {
            task.put("due", expenseDueDate(expense));
        }
        return task;
    }

    private JSONObject buildIncomeTask(IncomeStreamModel stream) throws Exception {
        JSONObject task = new JSONObject();
        task.put("title", "Paycheck: " + stream.getName() + " — $" + stream.getAmount());
        task.put("notes", stream.getFrequencyDisplayString() + "\nBujit Income Stream");
        task.put("status", "needsAction");
        task.put("due", incomeDueDate(stream));
        return task;
    }

    // Creates a Google Task for an expense. Returns the task ID on success, null on failure.
    // Must run on background thread.
    public String createExpenseTask(ExpenseModel expense) throws Exception {
        String token  = getAccessToken();
        String listId = getOrCreateBujitList(token);
        JSONObject body = buildExpenseTask(expense);
        Request req = new Request.Builder()
                .url(TASKS_BASE + "/lists/" + listId + "/tasks")
                .header("Authorization", "Bearer " + token)
                .post(RequestBody.create(body.toString(), JSON))
                .build();
        try (Response resp = client.newCall(req).execute()) {
            String raw = bodyString(resp);
            if (!resp.isSuccessful())
                throw new Exception("Create expense task failed (" + resp.code() + "): " + raw);
            Log.d(TAG, "Created expense task: " + expense.getName());
            return new JSONObject(raw).getString("id");
        }
    }

    // Updates the Google Task for an expense. Must run on background thread.
    public void updateExpenseTask(ExpenseModel expense) throws Exception {
        if (expense.getGoogleTaskId() == null) return;
        String token  = getAccessToken();
        String listId = prefs.getString(KEY_LIST_ID, null);
        if (listId == null) return;
        JSONObject body = buildExpenseTask(expense);
        body.put("id", expense.getGoogleTaskId());
        Request req = new Request.Builder()
                .url(TASKS_BASE + "/lists/" + listId + "/tasks/" + expense.getGoogleTaskId())
                .header("Authorization", "Bearer " + token)
                .put(RequestBody.create(body.toString(), JSON))
                .build();
        try (Response resp = client.newCall(req).execute()) {
            if (!resp.isSuccessful())
                throw new Exception("Update task failed (" + resp.code() + "): " + bodyString(resp));
            Log.d(TAG, "Updated expense task: " + expense.getName());
        }
    }

    // Creates a Google Task for an income stream. Returns the task ID on success, null on failure.
    // Must run on background thread.
    public String createIncomeTask(IncomeStreamModel stream) throws Exception {
        String token  = getAccessToken();
        String listId = getOrCreateBujitList(token);
        JSONObject body = buildIncomeTask(stream);
        Request req = new Request.Builder()
                .url(TASKS_BASE + "/lists/" + listId + "/tasks")
                .header("Authorization", "Bearer " + token)
                .post(RequestBody.create(body.toString(), JSON))
                .build();
        try (Response resp = client.newCall(req).execute()) {
            String raw = bodyString(resp);
            if (!resp.isSuccessful())
                throw new Exception("Create income task failed (" + resp.code() + "): " + raw);
            Log.d(TAG, "Created income task: " + stream.getName());
            return new JSONObject(raw).getString("id");
        }
    }

    // Deletes a task by ID. Must run on background thread.
    public void deleteTask(String taskId) {
        if (taskId == null) return;
        String listId = prefs.getString(KEY_LIST_ID, null);
        if (listId == null) return;
        try {
            String token = getAccessToken();
            Request req = new Request.Builder()
                    .url(TASKS_BASE + "/lists/" + listId + "/tasks/" + taskId)
                    .header("Authorization", "Bearer " + token)
                    .delete()
                    .build();
            client.newCall(req).execute().close();
            Log.d(TAG, "Deleted task: " + taskId);
        } catch (Exception e) {
            Log.w(TAG, "deleteTask failed: " + e.getMessage());
        }
    }

    // Creates tasks for all items that don't already have one.
    // Returns a SyncResult with created/failed counts. Must run on background thread.
    public SyncResult syncAll(ArrayList<ExpenseModel> expenses, ArrayList<IncomeStreamModel> streams) {
        int created = 0, failed = 0;
        String lastError = null;
        for (ExpenseModel e : expenses) {
            if (e.getGoogleTaskId() == null) {
                try {
                    e.setGoogleTaskId(createExpenseTask(e));
                    created++;
                } catch (Exception ex) {
                    failed++;
                    lastError = ex.getMessage();
                    Log.e(TAG, "syncAll expense failed: " + ex.getMessage());
                }
            }
        }
        for (IncomeStreamModel s : streams) {
            if (s.getGoogleTaskId() == null) {
                try {
                    s.setGoogleTaskId(createIncomeTask(s));
                    created++;
                } catch (Exception ex) {
                    failed++;
                    lastError = ex.getMessage();
                    Log.e(TAG, "syncAll income failed: " + ex.getMessage());
                }
            }
        }
        return new SyncResult(created, failed, lastError);
    }

    // Deletes all synced tasks and clears stored IDs. Must run on background thread.
    public void disconnectAndDeleteAll(ArrayList<ExpenseModel> expenses,
                                       ArrayList<IncomeStreamModel> streams) {
        for (ExpenseModel e : expenses) {
            deleteTask(e.getGoogleTaskId());
            e.setGoogleTaskId(null);
        }
        for (IncomeStreamModel s : streams) {
            deleteTask(s.getGoogleTaskId());
            s.setGoogleTaskId(null);
        }
        prefs.edit().remove(KEY_SYNC_ENABLED).remove(KEY_LIST_ID).apply();
    }

    private static String bodyString(Response resp) {
        try {
            ResponseBody b = resp.body();
            return b != null ? b.string() : "";
        } catch (Exception e) {
            return "";
        }
    }
}
