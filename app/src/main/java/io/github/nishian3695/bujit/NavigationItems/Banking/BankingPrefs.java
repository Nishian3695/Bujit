package io.github.nishian3695.bujit.NavigationItems.Banking;

import android.content.Context;
import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;
import android.util.Log;
import org.json.JSONArray;
import org.json.JSONObject;
import java.nio.charset.StandardCharsets;
import java.security.KeyStore;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

/*
Secure token storage backed by the Android Keystore (AES-256-GCM).
Uses only standard javax.crypto APIs — no Tink, no EncryptedSharedPreferences,
no third-party crypto that R8 can accidentally strip in release builds.

Key v4 (bujit_banking_key_v4) is a hardware-backed AES-256-GCM key with no
user-authentication binding. The key is device-specific and non-exportable;
the auth-window requirement that existed on v3 caused UserNotAuthenticatedException
when multi-minute banking SDK flows (Plaid Link) exceeded the 300 second window,
silently losing tokens without propagating an error to the caller.

On first launch after upgrading from v2 or v3, migrateIfNeeded() re-encrypts all
stored data under v4 and deletes the legacy key.
*/
public class BankingPrefs {

    private static final String TAG = "BujitBanking";

    // v4: current key (hardware-backed AES-256-GCM, no user-auth binding)
    private static final String KEYSTORE_ALIAS = "bujit_banking_key_v4";
    // v3: intermediate key that had setUserAuthenticationRequired(true). Kept only for migration.
    private static final String KEYSTORE_ALIAS_V3 = "bujit_banking_key_v3";
    // v2: original legacy key. Kept only for migration; deleted afterward.
    private static final String KEYSTORE_ALIAS_LEGACY = "bujit_banking_key_v2";

    private static final String PREFS_FILE = "bujit_banking_v2";

    // Teller storage keys
    static final String KEY_TOKENS          = "tokens";
    static final String KEY_LINKED_ACCOUNTS = "linked_accounts";
    private static final String KEY_LAST_SYNC         = "last_sync";
    private static final String KEY_ACCOUNT_TOKEN_MAP = "account_token_map";

    // Plaid storage keys
    private static final String KEY_PLAID_TOKENS            = "plaid_tokens";
    private static final String KEY_PLAID_LINKED_ACCOUNTS   = "plaid_linked_accounts";
    private static final String KEY_PLAID_ACCOUNT_TOKEN_MAP = "plaid_account_token_map";

    // All keys whose values are encrypted (used for legacy-key migration).
    private static final String[] ALL_ENCRYPTED_KEYS = {
        KEY_TOKENS, KEY_LINKED_ACCOUNTS, KEY_ACCOUNT_TOKEN_MAP,
        KEY_PLAID_TOKENS, KEY_PLAID_LINKED_ACCOUNTS, KEY_PLAID_ACCOUNT_TOKEN_MAP,
    };

    // Migration

    // Re-encrypts all persisted data under the current v4 key, migrating from v3 or v2
    // as needed, then deletes the old key from the AndroidKeyStore.
    // Safe to call multiple times; a no-op once v4 is already active.
    public static void migrateIfNeeded(Context ctx) {
        try {
            KeyStore ks = KeyStore.getInstance("AndroidKeyStore");
            ks.load(null);
            if (ks.containsAlias(KEYSTORE_ALIAS)) return; // already on v4

            if (ks.containsAlias(KEYSTORE_ALIAS_V3)) {
                SecretKey v3Key = ((KeyStore.SecretKeyEntry)
                        ks.getEntry(KEYSTORE_ALIAS_V3, null)).getSecretKey();
                reEncryptAll(ctx, v3Key);
                ks.deleteEntry(KEYSTORE_ALIAS_V3);
                Log.d(TAG, "BankingPrefs: migrated from v3 to v4 key");
                return;
            }

            if (ks.containsAlias(KEYSTORE_ALIAS_LEGACY)) {
                SecretKey v2Key = ((KeyStore.SecretKeyEntry)
                        ks.getEntry(KEYSTORE_ALIAS_LEGACY, null)).getSecretKey();
                reEncryptAll(ctx, v2Key);
                ks.deleteEntry(KEYSTORE_ALIAS_LEGACY);
                Log.d(TAG, "BankingPrefs: migrated from v2 to v4 key");
            }
        } catch (Exception e) {
            Log.e(TAG, "BankingPrefs: migration failed — clearing banking data to stay functional", e);
            prefs(ctx).edit().clear().apply();
            try {
                KeyStore ks = KeyStore.getInstance("AndroidKeyStore");
                ks.load(null);
                if (ks.containsAlias(KEYSTORE_ALIAS_LEGACY)) ks.deleteEntry(KEYSTORE_ALIAS_LEGACY);
                if (ks.containsAlias(KEYSTORE_ALIAS_V3)) ks.deleteEntry(KEYSTORE_ALIAS_V3);
            } catch (Exception ignored) {}
        }
    }

    private static void reEncryptAll(Context ctx, SecretKey oldKey) throws Exception {
        SharedPreferences.Editor editor = prefs(ctx).edit();
        for (String key : ALL_ENCRYPTED_KEYS) {
            String encoded = prefs(ctx).getString(key, null);
            if (encoded == null) continue;
            try {
                String plaintext = decryptWithKey(encoded, oldKey);
                editor.putString(key, encryptString(plaintext));
            } catch (Exception e) {
                Log.w(TAG, "Migration: dropping key '" + key + "' (cannot re-encrypt): " + e.getMessage());
                editor.remove(key);
            }
        }
        editor.apply();
    }

    // ── Public API ───────────────────────────────────────────────────────────

    public static Set<String> loadTokens(Context ctx) {
        return loadEncryptedSet(ctx, KEY_TOKENS);
    }

    public static void saveTokens(Context ctx, Set<String> tokens) {
        saveEncryptedSet(ctx, KEY_TOKENS, tokens);
    }

    public static Set<String> loadLinkedAccounts(Context ctx) {
        return loadEncryptedSet(ctx, KEY_LINKED_ACCOUNTS);
    }

    public static void saveLinkedAccounts(Context ctx, Set<String> accounts) {
        saveEncryptedSet(ctx, KEY_LINKED_ACCOUNTS, accounts);
    }

    public static long loadLastSync(Context ctx) {
        return prefs(ctx).getLong(KEY_LAST_SYNC, 0L);
    }

    public static void saveLastSync(Context ctx, long millis) {
        prefs(ctx).edit().putLong(KEY_LAST_SYNC, millis).apply();
    }

    public static String getTokenForAccount(Context ctx, String accountId) {
        if (accountId == null) return null;
        try {
            String encoded = prefs(ctx).getString(KEY_ACCOUNT_TOKEN_MAP, null);
            if (encoded == null) return null;
            return new JSONObject(decryptString(encoded)).optString(accountId, null);
        } catch (Exception e) {
            Log.e(TAG, "BankingPrefs.getTokenForAccount failed", e);
            return null;
        }
    }

    public static void saveAccountToken(Context ctx, String accountId, String token) {
        if (accountId == null || token == null) return;
        try {
            JSONObject map = new JSONObject();
            String existing = prefs(ctx).getString(KEY_ACCOUNT_TOKEN_MAP, null);
            if (existing != null) map = new JSONObject(decryptString(existing));
            map.put(accountId, token);
            prefs(ctx).edit().putString(KEY_ACCOUNT_TOKEN_MAP, encryptString(map.toString())).apply();
        } catch (Exception e) {
            Log.e(TAG, "BankingPrefs.saveAccountToken failed", e);
        }
    }

    // Plaid public API

    public static Set<String> loadPlaidTokens(Context ctx) {
        return loadEncryptedSet(ctx, KEY_PLAID_TOKENS);
    }

    public static void savePlaidTokens(Context ctx, Set<String> tokens) {
        saveEncryptedSet(ctx, KEY_PLAID_TOKENS, tokens);
    }

    public static Set<String> loadPlaidLinkedAccounts(Context ctx) {
        return loadEncryptedSet(ctx, KEY_PLAID_LINKED_ACCOUNTS);
    }

    public static void savePlaidLinkedAccounts(Context ctx, Set<String> accounts) {
        saveEncryptedSet(ctx, KEY_PLAID_LINKED_ACCOUNTS, accounts);
    }

    public static String getPlaidTokenForAccount(Context ctx, String accountId) {
        if (accountId == null) return null;
        try {
            String encoded = prefs(ctx).getString(KEY_PLAID_ACCOUNT_TOKEN_MAP, null);
            if (encoded == null) return null;
            return new JSONObject(decryptString(encoded)).optString(accountId, null);
        } catch (Exception e) {
            Log.e(TAG, "BankingPrefs.getPlaidTokenForAccount failed", e);
            return null;
        }
    }

    public static void savePlaidAccountToken(Context ctx, String accountId, String token) {
        if (accountId == null || token == null) return;
        try {
            JSONObject map = new JSONObject();
            String existing = prefs(ctx).getString(KEY_PLAID_ACCOUNT_TOKEN_MAP, null);
            if (existing != null) map = new JSONObject(decryptString(existing));
            map.put(accountId, token);
            prefs(ctx).edit().putString(KEY_PLAID_ACCOUNT_TOKEN_MAP, encryptString(map.toString())).apply();
        } catch (Exception e) {
            Log.e(TAG, "BankingPrefs.savePlaidAccountToken failed", e);
        }
    }

    public static void clearPlaid(Context ctx) {
        prefs(ctx).edit()
                .remove(KEY_PLAID_TOKENS)
                .remove(KEY_PLAID_LINKED_ACCOUNTS)
                .remove(KEY_PLAID_ACCOUNT_TOKEN_MAP)
                .apply();
    }

    public static void clear(Context ctx) {
        prefs(ctx).edit().clear().apply();
        try {
            KeyStore ks = KeyStore.getInstance("AndroidKeyStore");
            ks.load(null);
            if (ks.containsAlias(KEYSTORE_ALIAS)) ks.deleteEntry(KEYSTORE_ALIAS);
            if (ks.containsAlias(KEYSTORE_ALIAS_V3)) ks.deleteEntry(KEYSTORE_ALIAS_V3);
            if (ks.containsAlias(KEYSTORE_ALIAS_LEGACY)) ks.deleteEntry(KEYSTORE_ALIAS_LEGACY);
        } catch (Exception e) {
            Log.e(TAG, "BankingPrefs.clear: keystore cleanup failed", e);
        }
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private static SharedPreferences prefs(Context ctx) {
        return ctx.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE);
    }

    private static Set<String> loadEncryptedSet(Context ctx, String key) {
        try {
            String encoded = prefs(ctx).getString(key, null);
            if (encoded == null) return Collections.emptySet();
            return decryptSet(encoded);
        } catch (Exception e) {
            Log.e(TAG, "BankingPrefs.load(" + key + ") failed", e);
            return Collections.emptySet();
        }
    }

    private static void saveEncryptedSet(Context ctx, String key, Set<String> values) {
        try {
            prefs(ctx).edit().putString(key, encryptSet(values)).apply();
        } catch (Exception e) {
            Log.e(TAG, "BankingPrefs.save(" + key + ") failed", e);
        }
    }

    private static SecretKey getOrCreateKey() throws Exception {
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

    private static String encryptSet(Set<String> values) throws Exception {
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey());
        byte[] iv  = cipher.getIV();
        byte[] enc = cipher.doFinal(
                new JSONArray(new ArrayList<>(values)).toString()
                        .getBytes(StandardCharsets.UTF_8));
        byte[] out = new byte[iv.length + enc.length];
        System.arraycopy(iv,  0, out, 0,         iv.length);
        System.arraycopy(enc, 0, out, iv.length, enc.length);
        return Base64.encodeToString(out, Base64.NO_WRAP);
    }

    private static Set<String> decryptSet(String encoded) throws Exception {
        byte[] combined = Base64.decode(encoded, Base64.NO_WRAP);
        byte[] iv  = Arrays.copyOfRange(combined,  0, 12);
        byte[] enc = Arrays.copyOfRange(combined, 12, combined.length);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(), new GCMParameterSpec(128, iv));
        JSONArray arr = new JSONArray(new String(cipher.doFinal(enc), StandardCharsets.UTF_8));
        Set<String> result = new HashSet<>();
        for (int i = 0; i < arr.length(); i++) result.add(arr.getString(i));
        return result;
    }

    private static String encryptString(String plaintext) throws Exception {
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateKey());
        byte[] iv  = cipher.getIV();
        byte[] enc = cipher.doFinal(plaintext.getBytes(StandardCharsets.UTF_8));
        byte[] out = new byte[iv.length + enc.length];
        System.arraycopy(iv,  0, out, 0,         iv.length);
        System.arraycopy(enc, 0, out, iv.length, enc.length);
        return Base64.encodeToString(out, Base64.NO_WRAP);
    }

    private static String decryptString(String encoded) throws Exception {
        byte[] combined = Base64.decode(encoded, Base64.NO_WRAP);
        byte[] iv  = Arrays.copyOfRange(combined,  0, 12);
        byte[] enc = Arrays.copyOfRange(combined, 12, combined.length);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(), new GCMParameterSpec(128, iv));
        return new String(cipher.doFinal(enc), StandardCharsets.UTF_8);
    }

    // Decrypts using an explicitly supplied key — used during v2→v3 migration
    // so both keys can be accessed simultaneously.
    private static String decryptWithKey(String encoded, SecretKey key) throws Exception {
        byte[] combined = Base64.decode(encoded, Base64.NO_WRAP);
        byte[] iv  = Arrays.copyOfRange(combined,  0, 12);
        byte[] enc = Arrays.copyOfRange(combined, 12, combined.length);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(128, iv));
        return new String(cipher.doFinal(enc), StandardCharsets.UTF_8);
    }
}
