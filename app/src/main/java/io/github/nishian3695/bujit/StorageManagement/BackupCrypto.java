package io.github.nishian3695.bujit.StorageManagement;

import android.util.Base64;
import java.security.GeneralSecurityException;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import javax.crypto.Cipher;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.SecretKeySpec;
import org.json.JSONObject;

/*
Wraps a StorageManager JSON payload in passphrase-derived AES-256-GCM encryption for portable,
device-to-device backup files (as opposed to StorageManager's own encryption, which uses a
non-exportable AndroidKeyStore key and can never leave the device it was created on).

The output is a self-describing JSON envelope (format/version/kdf/iterations/salt/iv/ciphertext)
rather than a raw binary blob, so a corrupt or unrelated file can be rejected before any
decryption is attempted, and so the KDF iteration count can be raised in a future version
without breaking older backups (the count used is stored alongside the file, not hardcoded
on the read side).
*/
public class BackupCrypto {

    private static final String FORMAT = "bujit_backup";
    private static final int CURRENT_VERSION = 1;
    private static final String KDF = "PBKDF2WithHmacSHA256";
    private static final int ITERATIONS = 210_000;
    private static final int SALT_LENGTH = 16;
    private static final int KEY_BITS = 256;
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;
    private static final String PASSPHRASE_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"; // no 0/O/1/I/L

    // Why a decrypt failure can mean either a wrong passphrase or a corrupted file: AES-GCM's
    // authentication tag simply fails to verify in both cases, with no way to tell them apart.
    public enum Reason { MALFORMED_ENVELOPE, UNSUPPORTED_VERSION, WRONG_PASSPHRASE_OR_CORRUPT }

    public static class BackupCryptoException extends Exception {
        public final Reason reason;
        public BackupCryptoException(Reason reason, String message) {
            super(message);
            this.reason = reason;
        }
        public BackupCryptoException(Reason reason, String message, Throwable cause) {
            super(message, cause);
            this.reason = reason;
        }
    }

    private BackupCrypto() {}

    // Generates a random, unambiguous 20-character passphrase (no 0/O/1/I/L) grouped in
    // dash-separated blocks of 4, e.g. "K3F9-XPQR-7GHT-2LMN-8VDC" (~100 bits of entropy) — for
    // users who don't want to invent/remember their own passphrase.
    public static String generatePassphrase() {
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 20; i++) {
            if (i > 0 && i % 4 == 0) sb.append('-');
            sb.append(PASSPHRASE_ALPHABET.charAt(random.nextInt(PASSPHRASE_ALPHABET.length())));
        }
        return sb.toString();
    }

    // Encrypts a StorageManager JSON payload under a passphrase-derived key and returns the
    // finished envelope JSON string, ready to write directly to a backup file.
    public static String encrypt(String plaintextJson, char[] passphrase) throws GeneralSecurityException {
        SecureRandom random = new SecureRandom();
        byte[] salt = new byte[SALT_LENGTH];
        random.nextBytes(salt);

        SecretKeySpec key = deriveKey(passphrase, salt, ITERATIONS);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, key);
        byte[] iv = cipher.getIV();
        byte[] ciphertext = cipher.doFinal(plaintextJson.getBytes(java.nio.charset.StandardCharsets.UTF_8));

        try {
            JSONObject envelope = new JSONObject();
            envelope.put("format", FORMAT);
            envelope.put("version", CURRENT_VERSION);
            envelope.put("exportedAt", LocalDate.now().format(DATE_FMT));
            envelope.put("kdf", KDF);
            envelope.put("iterations", ITERATIONS);
            envelope.put("salt", Base64.encodeToString(salt, Base64.NO_WRAP));
            envelope.put("iv", Base64.encodeToString(iv, Base64.NO_WRAP));
            envelope.put("ciphertext", Base64.encodeToString(ciphertext, Base64.NO_WRAP));
            return envelope.toString();
        } catch (Exception e) {
            // JSONObject.put only throws on a null key, which never happens above.
            throw new IllegalStateException(e);
        }
    }

    // Decrypts an envelope produced by encrypt() and returns the plaintext StorageManager JSON.
    // Validates the envelope's shape and version before attempting decryption, so a malformed or
    // unrelated file is rejected with a clear reason rather than an opaque crypto exception.
    public static String decrypt(String envelopeJson, char[] passphrase) throws BackupCryptoException {
        JSONObject envelope;
        try {
            envelope = new JSONObject(envelopeJson);
        } catch (Exception e) {
            throw new BackupCryptoException(Reason.MALFORMED_ENVELOPE, "Not a valid backup file", e);
        }

        if (!envelope.has("format") || !envelope.has("version") || !envelope.has("salt")
                || !envelope.has("iv") || !envelope.has("ciphertext") || !envelope.has("iterations")) {
            throw new BackupCryptoException(Reason.MALFORMED_ENVELOPE, "Missing required backup fields");
        }
        if (!FORMAT.equals(envelope.optString("format", ""))) {
            throw new BackupCryptoException(Reason.MALFORMED_ENVELOPE, "Not a Bujit backup file");
        }
        int version = envelope.optInt("version", -1);
        if (version > CURRENT_VERSION) {
            throw new BackupCryptoException(Reason.UNSUPPORTED_VERSION,
                    "This backup requires a newer version of Bujit");
        }

        try {
            byte[] salt       = Base64.decode(envelope.getString("salt"), Base64.NO_WRAP);
            byte[] iv         = Base64.decode(envelope.getString("iv"), Base64.NO_WRAP);
            byte[] ciphertext = Base64.decode(envelope.getString("ciphertext"), Base64.NO_WRAP);
            int iterations    = envelope.getInt("iterations");

            SecretKeySpec key = deriveKey(passphrase, salt, iterations);
            Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
            cipher.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(128, iv));
            byte[] plaintext = cipher.doFinal(ciphertext);
            return new String(plaintext, java.nio.charset.StandardCharsets.UTF_8);
        } catch (GeneralSecurityException e) {
            // GCM auth tag mismatch — wrong passphrase and a corrupted file look identical here.
            throw new BackupCryptoException(Reason.WRONG_PASSPHRASE_OR_CORRUPT,
                    "Incorrect passphrase, or this file is corrupted", e);
        } catch (Exception e) {
            throw new BackupCryptoException(Reason.MALFORMED_ENVELOPE, "Malformed backup file", e);
        }
    }

    // Reads the export date from an already-parsed envelope for display in the pre-overwrite
    // import confirmation dialog; returns null if the field is missing or unparseable rather
    // than failing the whole import over a cosmetic detail.
    public static String readExportedAt(String envelopeJson) {
        try {
            return new JSONObject(envelopeJson).optString("exportedAt", null);
        } catch (Exception e) {
            return null;
        }
    }

    // Derives a 256-bit AES key from a passphrase via PBKDF2-HMAC-SHA256, then zeroes the
    // passphrase so it doesn't linger in memory any longer than necessary.
    private static SecretKeySpec deriveKey(char[] passphrase, byte[] salt, int iterations)
            throws GeneralSecurityException {
        try {
            SecretKeyFactory factory = SecretKeyFactory.getInstance(KDF);
            PBEKeySpec spec = new PBEKeySpec(passphrase, salt, iterations, KEY_BITS);
            byte[] keyBytes = factory.generateSecret(spec).getEncoded();
            try {
                return new SecretKeySpec(keyBytes, "AES");
            } finally {
                Arrays.fill(keyBytes, (byte) 0);
            }
        } finally {
            Arrays.fill(passphrase, '\0');
        }
    }
}
