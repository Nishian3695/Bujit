package io.github.nishian3695.bujit.StorageManagement;

import android.content.Context;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import android.util.Log;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamModel;
import io.github.nishian3695.bujit.NavigationItems.SingleEvents.SingleEventModel;
import org.json.JSONArray;
import org.json.JSONObject;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

/*
Handles reading and writing the app's main data file using AES-256-GCM encryption
backed by the Android Keystore. Data is serialized to JSON and stored at:
  {filesDir}/BujitExpenseData/bujit_data_v2.enc

On first launch after upgrading from the old unencrypted Java-serialization format
(BujitExpenseDataBujitExpenseData), the legacy file is read, re-saved in encrypted
JSON form, and deleted so that user data is never left unencrypted on disk.

If the encrypted file is missing, empty, or unreadable (e.g. key lost after factory
reset), a fresh default StorageHolder is returned so the app stays functional.
*/
public class StorageManager {

    private static final String TAG          = "BujitStorage";
    private static final String KEYSTORE_ALIAS = "bujit_data_key_v1";
    private static final String DIR_NAME     = "BujitExpenseData";
    private static final String LEGACY_NAME  = "BujitExpenseDataBujitExpenseData";
    private static final String ENC_NAME     = "bujit_data_v2.enc";
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;

    private final File legacyFile;
    private final File encFile;
    private StorageHolder storageHolder;

    public StorageManager(Context context) throws IOException, ClassNotFoundException {
        File dir = new File(context.getFilesDir(), DIR_NAME);
        if (!dir.exists()) dir.mkdirs();
        legacyFile = new File(dir, LEGACY_NAME);
        encFile    = new File(dir, ENC_NAME);
        storageHolder = load();
    }

    public StorageHolder getStorageHolder() {
        return storageHolder;
    }

    public void writeData(StorageHolder holder) throws IOException {
        try {
            byte[] plaintext = toJson(holder).getBytes(StandardCharsets.UTF_8);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey());
            byte[] iv  = cipher.getIV();
            byte[] enc = cipher.doFinal(plaintext);
            byte[] out = new byte[iv.length + enc.length];
            System.arraycopy(iv,  0, out, 0,         iv.length);
            System.arraycopy(enc, 0, out, iv.length, enc.length);
            try (FileOutputStream fos = new FileOutputStream(encFile)) {
                fos.write(Base64.encode(out, Base64.NO_WRAP));
            }
        } catch (IOException e) {
            throw e;
        } catch (Exception e) {
            Log.e(TAG, "writeData failed", e);
            throw new IOException("writeData failed: " + e.getMessage(), e);
        }
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private StorageHolder load() {
        // 1. Try encrypted file first
        if (encFile.exists() && encFile.length() > 0) {
            try {
                return readEncrypted();
            } catch (Exception e) {
                Log.e(TAG, "Encrypted file unreadable, attempting legacy migration", e);
            }
        }
        // 2. Migrate from legacy unencrypted serialized file
        if (legacyFile.exists() && legacyFile.length() > 0) {
            try {
                StorageHolder holder = readLegacy();
                try {
                    writeData(holder);
                    //noinspection ResultOfMethodCallIgnored
                    legacyFile.delete();
                    Log.d(TAG, "Migrated storage from serialized to encrypted JSON");
                } catch (Exception ex) {
                    Log.e(TAG, "Could not write encrypted file after migration", ex);
                }
                return holder;
            } catch (Exception e) {
                Log.e(TAG, "Legacy migration failed, starting fresh", e);
            }
        }
        return new StorageHolder();
    }

    private StorageHolder readEncrypted() throws Exception {
        byte[] raw = new byte[(int) encFile.length()];
        try (FileInputStream fis = new FileInputStream(encFile)) {
            //noinspection ResultOfMethodCallIgnored
            fis.read(raw);
        }
        byte[] combined = Base64.decode(raw, Base64.NO_WRAP);
        byte[] iv  = Arrays.copyOfRange(combined,  0, 12);
        byte[] enc = Arrays.copyOfRange(combined, 12, combined.length);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(), new GCMParameterSpec(128, iv));
        return fromJson(new String(cipher.doFinal(enc), StandardCharsets.UTF_8));
    }

    private StorageHolder readLegacy() throws Exception {
        try (ObjectInputStream ois = new ObjectInputStream(new FileInputStream(legacyFile))) {
            return (StorageHolder) ois.readObject();
        }
    }

    private SecretKey getOrCreateKey() throws Exception {
        KeyStore ks = KeyStore.getInstance("AndroidKeyStore");
        ks.load(null);
        if (ks.containsAlias(KEYSTORE_ALIAS)) {
            return ((KeyStore.SecretKeyEntry) ks.getEntry(KEYSTORE_ALIAS, null)).getSecretKey();
        }
        KeyGenerator kg = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore");
        kg.init(new KeyGenParameterSpec.Builder(KEYSTORE_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build());
        return kg.generateKey();
    }

    // ── JSON serialization ────────────────────────────────────────────────────

    private String toJson(StorageHolder h) throws Exception {
        JSONObject o = new JSONObject();
        o.put("currentBalance",   h.getCurrentBalance());
        o.put("averageCheck",     h.getAverageCheck());
        o.put("checkFrequency",   h.getCheckFrequency());
        o.put("checkFrequencyTag",
                h.getCheckFrequencyTag() != null ? h.getCheckFrequencyTag().name() : "WEEKS");
        o.put("curCheckDate",   dateOrNull(h.getCurCheckDate()));
        o.put("nextCheckDate",  dateOrNull(h.getNextCheckDate()));
        o.put("lastOpenedDate", dateOrNull(h.getLastOpenedDate()));

        JSONArray expenses = new JSONArray();
        if (h.getExpenseList() != null) {
            for (ExpenseModel e : h.getExpenseList()) expenses.put(expenseToJson(e));
        }
        o.put("expenseList", expenses);

        JSONArray streams = new JSONArray();
        if (h.getIncomeStreamList() != null) {
            for (IncomeStreamModel s : h.getIncomeStreamList()) streams.put(streamToJson(s));
        }
        o.put("incomeStreamList", streams);

        JSONArray snaps = new JSONArray();
        if (h.getPeriodSnapshots() != null) {
            for (PeriodSnapshot s : h.getPeriodSnapshots()) snaps.put(snapshotToJson(s));
        }
        o.put("periodSnapshots", snaps);

        JSONArray cats = new JSONArray();
        if (h.getCategoryList() != null) {
            for (String c : h.getCategoryList()) cats.put(c);
        }
        o.put("categoryList", cats);

        JSONArray singleEvents = new JSONArray();
        if (h.getSingleEventList() != null) {
            for (SingleEventModel se : h.getSingleEventList()) singleEvents.put(singleEventToJson(se));
        }
        o.put("singleEventList", singleEvents);
        o.put("manualBalanceAddition", h.getManualBalanceAddition());

        return o.toString();
    }

    private StorageHolder fromJson(String json) throws Exception {
        JSONObject o = new JSONObject(json);
        StorageHolder h = new StorageHolder();
        h.setCurrentBalance((float) o.optDouble("currentBalance", 0.0));
        h.setAverageCheck(  (float) o.optDouble("averageCheck",   0.0));
        h.setCheckFrequency(o.optInt("checkFrequency", 1));
        h.setCheckFrequencyTag(parseUnit(o.optString("checkFrequencyTag", "WEEKS"), ChronoUnit.WEEKS));
        h.setCurCheckDate(  parseDate(o.optString("curCheckDate",   null)));
        h.setNextCheckDate( parseDate(o.optString("nextCheckDate",  null)));
        h.setLastOpenedDate(parseDate(o.optString("lastOpenedDate", null)));

        JSONArray expenses = o.optJSONArray("expenseList");
        ArrayList<ExpenseModel> expList = new ArrayList<>();
        if (expenses != null) {
            for (int i = 0; i < expenses.length(); i++) {
                ExpenseModel e = jsonToExpense(expenses.getJSONObject(i));
                if (e != null) expList.add(e);
            }
        }
        h.setExpenseList(expList);

        JSONArray streams = o.optJSONArray("incomeStreamList");
        ArrayList<IncomeStreamModel> streamList = new ArrayList<>();
        if (streams != null) {
            for (int i = 0; i < streams.length(); i++) {
                IncomeStreamModel s = jsonToStream(streams.getJSONObject(i));
                if (s != null) streamList.add(s);
            }
        }
        h.setIncomeStreamList(streamList);

        JSONArray snaps = o.optJSONArray("periodSnapshots");
        ArrayList<PeriodSnapshot> snapList = new ArrayList<>();
        if (snaps != null) {
            for (int i = 0; i < snaps.length(); i++) {
                PeriodSnapshot s = jsonToSnapshot(snaps.getJSONObject(i));
                if (s != null) snapList.add(s);
            }
        }
        h.setPeriodSnapshots(snapList);

        JSONArray cats = o.optJSONArray("categoryList");
        ArrayList<String> catList = new ArrayList<>();
        if (cats != null && cats.length() > 0) {
            for (int i = 0; i < cats.length(); i++) catList.add(cats.optString(i));
        } else {
            catList = CategoryManager.getDefaults();
        }
        h.setCategoryList(catList);

        JSONArray seArr = o.optJSONArray("singleEventList");
        ArrayList<SingleEventModel> seList = new ArrayList<>();
        if (seArr != null) {
            for (int i = 0; i < seArr.length(); i++) {
                SingleEventModel se = jsonToSingleEvent(seArr.getJSONObject(i));
                if (se != null) seList.add(se);
            }
        }
        h.setSingleEventList(seList);
        h.setManualBalanceAddition((float) o.optDouble("manualBalanceAddition", 0.0));

        return h;
    }

    private JSONObject expenseToJson(ExpenseModel e) throws Exception {
        JSONObject o = new JSONObject();
        o.put("name",         e.getName());
        o.put("cost",         e.getCost());
        o.put("date",         dateOrNull(e.getDate()));
        o.put("frequency",    e.getFrequency());
        o.put("frequencyTag", e.getFrequencyTag() != null ? e.getFrequencyTag().name() : "MONTHS");
        o.put("isVariable",   e.getIsVariable());
        o.put("status",       e.getStatus());
        o.put("partPaid",     e.getPartPaid());
        o.put("shownDate",    dateOrNull(e.getShownDate()));
        o.put("shownCost",    e.getShownCost());
        o.put("shownStatus",  e.getShownStatus());
        o.put("isCredit",     e.getIsCredit());
        o.put("creditLimit",  e.getCreditLimit());
        o.put("linkedAccountId",      strOrNull(e.getLinkedAccountId()));
        o.put("linkedAccountDisplay", strOrNull(e.getLinkedAccountDisplay()));
        o.put("googleTaskId",         strOrNull(e.getGoogleTaskId()));
        o.put("calendarNotif",        e.isCalendarNotificationsEnabled());
        o.put("category",             e.getCategory());
        return o;
    }

    private ExpenseModel jsonToExpense(JSONObject o) {
        try {
            LocalDate date = parseDate(o.optString("date", null));
            if (date == null) date = LocalDate.now();
            ChronoUnit tag = parseUnit(o.optString("frequencyTag", "MONTHS"), ChronoUnit.MONTHS);
            ExpenseModel e = new ExpenseModel(
                    o.optString("name", ""),
                    o.optString("cost", "0.00"),
                    date,
                    o.optInt("frequency", 1),
                    tag,
                    o.optBoolean("isVariable", false));
            e.setStatus(o.optInt("status", -1));
            e.setPartPaid(o.optInt("partPaid", 0));
            LocalDate shownDate = parseDate(o.optString("shownDate", null));
            if (shownDate != null) e.setShownDate(shownDate);
            e.setShownCost(o.optString("shownCost", o.optString("cost", "0.00")));
            e.setShownStatus(o.optInt("shownStatus", -1));
            e.setIsCredit(o.optBoolean("isCredit", false));
            e.setCreditLimit(o.optString("creditLimit", "1.00"));
            String lid = o.isNull("linkedAccountId")      ? null : o.optString("linkedAccountId",      null);
            String ldi = o.isNull("linkedAccountDisplay") ? null : o.optString("linkedAccountDisplay", null);
            if (lid != null) e.setLinkedAccount(lid, null, ldi);
            String tid = o.isNull("googleTaskId") ? null : o.optString("googleTaskId", null);
            if (tid != null) e.setGoogleTaskId(tid);
            e.setCalendarNotificationsEnabled(o.optBoolean("calendarNotif", true));
            e.setCategory(o.optString("category", "Other"));
            return e;
        } catch (Exception ex) {
            Log.e(TAG, "jsonToExpense failed", ex);
            return null;
        }
    }

    private JSONObject streamToJson(IncomeStreamModel s) throws Exception {
        JSONObject o = new JSONObject();
        o.put("name",         s.getName());
        o.put("amount",       s.getAmount());
        o.put("checkDate",    s.getCheckDate());
        o.put("frequency",    s.getFrequency());
        o.put("frequencyTag", s.getFrequencyTag());
        o.put("selected",     s.isSelected());
        o.put("googleTaskId", strOrNull(s.getGoogleTaskId()));
        return o;
    }

    private IncomeStreamModel jsonToStream(JSONObject o) {
        try {
            IncomeStreamModel s = new IncomeStreamModel(
                    o.optString("name", ""),
                    o.optString("amount", "0.00"),
                    o.optString("checkDate", ""),
                    o.optInt("frequency", 1),
                    o.optInt("frequencyTag", 1));
            s.setSelected(o.optBoolean("selected", false));
            String tid = o.isNull("googleTaskId") ? null : o.optString("googleTaskId", null);
            if (tid != null) s.setGoogleTaskId(tid);
            return s;
        } catch (Exception e) {
            Log.e(TAG, "jsonToStream failed", e);
            return null;
        }
    }

    private JSONObject singleEventToJson(SingleEventModel se) throws Exception {
        JSONObject o = new JSONObject();
        o.put("id",               se.getId());
        o.put("name",             se.getName());
        o.put("amount",           se.getAmount());
        o.put("isDebit",          se.isDebit());
        o.put("createdDate",      dateOrNull(se.getCreatedDate()));
        o.put("lastModifiedDate", dateOrNull(se.getLastModifiedDate()));
        o.put("appliedAmount",    se.getAppliedAmount());
        return o;
    }

    private SingleEventModel jsonToSingleEvent(JSONObject o) {
        try {
            String name = o.optString("name", "");
            float amount = (float) o.optDouble("amount", 0.0);
            boolean isDebit = o.optBoolean("isDebit", true);
            SingleEventModel se = new SingleEventModel(name, amount, isDebit);
            LocalDate modified = parseDate(o.optString("lastModifiedDate", null));
            if (modified != null) se.setLastModifiedDate(modified);
            return se;
        } catch (Exception e) {
            Log.e(TAG, "jsonToSingleEvent failed", e);
            return null;
        }
    }

    private JSONObject snapshotToJson(PeriodSnapshot s) throws Exception {
        JSONObject o = new JSONObject();
        o.put("periodStart",  s.getPeriodStart().format(DATE_FMT));
        o.put("incomeTotal",  s.getIncomeTotal());
        o.put("expenseTotal", s.getExpenseTotal());
        return o;
    }

    private PeriodSnapshot jsonToSnapshot(JSONObject o) {
        try {
            LocalDate start = parseDate(o.optString("periodStart", null));
            if (start == null) return null;
            return new PeriodSnapshot(
                    start,
                    (float) o.optDouble("incomeTotal",  0.0),
                    (float) o.optDouble("expenseTotal", 0.0));
        } catch (Exception e) {
            Log.e(TAG, "jsonToSnapshot failed", e);
            return null;
        }
    }

    // ── Field helpers ─────────────────────────────────────────────────────────

    private Object dateOrNull(LocalDate d) {
        return d != null ? d.format(DATE_FMT) : JSONObject.NULL;
    }

    private Object strOrNull(String s) {
        return s != null ? s : JSONObject.NULL;
    }

    private LocalDate parseDate(String s) {
        if (s == null || s.isEmpty() || s.equals("null")) return null;
        try { return LocalDate.parse(s, DATE_FMT); } catch (Exception e) { return null; }
    }

    private ChronoUnit parseUnit(String s, ChronoUnit fallback) {
        try { return ChronoUnit.valueOf(s); } catch (Exception e) { return fallback; }
    }
}
