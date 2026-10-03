package io.github.nishian3695.bujit

import android.content.Context
import android.util.Base64
import org.json.JSONArray
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

// Reads what the Java app left on this device, so an update from it keeps the user's
// data (see lib/storage_management/java_migration.dart). Same package and signing key,
// so its files, preferences and Android Keystore keys are this app's too:
//   - files/BujitExpenseData/bujit_data_v2.enc: base64(IV(12) + AES-GCM(StorageManager JSON)),
//     key "bujit_data_key_v1" (StorageManager.readEncrypted);
//   - its plain SharedPreferences (display, lock, disclaimer, tutorial, expiry);
//   - bank links in "bujit_banking_v2": AES-GCM-encrypted JSON string sets, key
//     "bujit_banking_key_v4" (or v3/v2 if the Java app never re-keyed them; BankingPrefs).
// Nothing is changed until markMigrated(), which renames the data file (kept as a backup).
object JavaMigration {
    private const val DATA_DIR = "BujitExpenseData"
    private const val DATA_FILE = "bujit_data_v2.enc"
    private const val DATA_KEY = "bujit_data_key_v1"
    private val BANKING_KEYS = listOf("bujit_banking_key_v4", "bujit_banking_key_v3", "bujit_banking_key_v2")

    private fun dataFile(context: Context) = File(File(context.filesDir, DATA_DIR), DATA_FILE)

    fun read(context: Context): Map<String, Any?> {
        val file = dataFile(context)
        if (!file.exists() || file.length() == 0L) return mapOf("data" to null)
        val result = mutableMapOf<String, Any?>()
        result["data"] = decrypt(String(file.readBytes(), Charsets.UTF_8), key(DATA_KEY))

        fun prefs(name: String) = context.getSharedPreferences(name, Context.MODE_PRIVATE)
        result["prefs"] = mapOf(
            "includeNextCheck" to prefs("bujit_display_prefs").getBoolean("include_next_check", false),
            "useCommaSeparators" to prefs("bujit_display_prefs").getBoolean("use_comma_separators", false),
            "appLockEnabled" to prefs("bujit_lock_prefs").getBoolean("lock_enabled", false),
            "disclaimerAccepted" to prefs("bujit_legal_prefs").getBoolean("disclaimer_accepted", false),
            "tutorialSeen" to prefs("bujit_tutorial_prefs").getBoolean("tutorial_seen", false),
            "singleEventExpiryDays" to prefs("bujit_prefs").getInt("single_event_expiry_days", 30),
            // ThemeHelper's settings: "system"/"light"/"dark", the accent's key, "#RRGGBB".
            "nightMode" to prefs("bujit_settings").getString("night_mode", "system"),
            "accentColor" to prefs("bujit_settings").getString("accent_color", "blue"),
            "customHex" to prefs("bujit_settings").getString("custom_hex", "#2979FF"),
        )

        // Bank links: best effort -- without them the user just links the bank again.
        val banking = prefs("bujit_banking_v2")
        result["lastBankSync"] = banking.getLong("last_sync", 0L)
        val bankingKey = BANKING_KEYS.firstNotNullOfOrNull { alias -> keyOrNull(alias) }
        fun set(name: String): List<String> {
            val encoded = banking.getString(name, null) ?: return emptyList()
            return try {
                val array = JSONArray(decrypt(encoded, bankingKey ?: return emptyList()))
                List(array.length()) { array.getString(it) }
            } catch (e: Exception) {
                emptyList()
            }
        }
        result["plaidTokens"] = set("plaid_tokens")
        result["plaidLinkedAccounts"] = set("plaid_linked_accounts") // "token|accountId"
        result["manualLinkedIds"] = set("manual_linked_ids")
        return result
    }

    // After a successful import: keeps the Java data as bujit_data_v2.enc.migrated, so
    // it isn't imported again but isn't lost either.
    fun markMigrated(context: Context): Boolean {
        val file = dataFile(context)
        return !file.exists() || file.renameTo(File(file.parentFile, "$DATA_FILE.migrated"))
    }

    private fun decrypt(encoded: String, key: SecretKey): String {
        val combined = Base64.decode(encoded.trim(), Base64.NO_WRAP)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, combined.copyOfRange(0, 12)))
        return String(cipher.doFinal(combined.copyOfRange(12, combined.size)), Charsets.UTF_8)
    }

    private fun key(alias: String): SecretKey =
        keyOrNull(alias) ?: throw IllegalStateException("The Java app's key $alias isn't on this device")

    private fun keyOrNull(alias: String): SecretKey? {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        return (keyStore.getEntry(alias, null) as? KeyStore.SecretKeyEntry)?.secretKey
    }
}
