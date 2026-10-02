// Mirrors StorageManagement/BackupCrypto.java in the original Java app, and reads
// and writes the same files: a backup is a JSON envelope
//   {format: "bujit_backup", version: 1, exportedAt, kdf, iterations, salt, iv, ciphertext}
// whose ciphertext is the data JSON (see BackupJson) encrypted with AES-256-GCM
// under a key derived from a passphrase with PBKDF2-HMAC-SHA256. As in Java's
// Cipher output, the 16-byte GCM tag is appended to the ciphertext, and the IV
// is 12 bytes. The iteration count is read from the file, so older or newer
// counts still decrypt.
import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import '../../utils/date_utils.dart';

enum BackupFailure { malformedEnvelope, unsupportedVersion, wrongPassphraseOrCorrupt }

class BackupCryptoException implements Exception {
    final BackupFailure reason;
    final String message;
    const BackupCryptoException(this.reason, this.message);

    // The Java app's error dialog wording.
    String get title => switch (reason) {
        BackupFailure.unsupportedVersion => "Update Required",
        BackupFailure.malformedEnvelope => "Not a Backup File",
        BackupFailure.wrongPassphraseOrCorrupt => "Import Failed",
    };

    String get explanation => switch (reason) {
        BackupFailure.unsupportedVersion => "This backup was created with a newer version of Bujit and can't be "
            "read by this version. Please update the app and try again.",
        BackupFailure.malformedEnvelope => "This doesn't look like a Bujit backup file. Please select a "
            ".bujitbackup file exported from Bujit.",
        BackupFailure.wrongPassphraseOrCorrupt => "Incorrect passphrase, or this file is corrupted. Please check "
            "the passphrase and try again.",
    };

    @override
    String toString() => message;
}

class BackupCrypto {
    static const String format = "bujit_backup";
    static const int currentVersion = 1;
    static const String kdf = "PBKDF2WithHmacSHA256";
    static const int iterations = 210000;
    static const int _saltLength = 16;
    static const int _ivLength = 12;
    static const int _tagLength = 16;
    static const String _passphraseAlphabet = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"; // no 0/O/1/I/L

    static final Random _random = Random.secure();
    static final AesGcm _aes = AesGcm.with256bits(nonceLength: _ivLength);

    // A random 20-character passphrase in dash-separated blocks of 4, e.g.
    // "K3F9-XPQR-7GHT-2MNV-8VDC" (~100 bits), for people who'd rather not make one up.
    static String generatePassphrase() {
        final StringBuffer buffer = StringBuffer();
        for (int i = 0; i < 20; i++) {
            if (i > 0 && i % 4 == 0) buffer.write("-");
            buffer.write(_passphraseAlphabet[_random.nextInt(_passphraseAlphabet.length)]);
        }
        return buffer.toString();
    }

    // Encrypts [plaintextJson] and returns the envelope JSON to write to a file.
    // [iterationCount] is only lowered by tests.
    static Future<String> encrypt(String plaintextJson, String passphrase,
            {int iterationCount = iterations, DateTime? today}) async {
        final List<int> salt = _randomBytes(_saltLength);
        final List<int> iv = _randomBytes(_ivLength);
        final SecretKey key = await _deriveKey(passphrase, salt, iterationCount);
        final SecretBox box = await _aes.encrypt(utf8.encode(plaintextJson), secretKey: key, nonce: iv);
        final DateTime day = dateOnly(today ?? todayDate());
        return jsonEncode({
            "format": format,
            "version": currentVersion,
            "exportedAt": "${day.year.toString().padLeft(4, "0")}-${day.month.toString().padLeft(2, "0")}"
                "-${day.day.toString().padLeft(2, "0")}",
            "kdf": kdf,
            "iterations": iterationCount,
            "salt": base64.encode(salt),
            "iv": base64.encode(iv),
            "ciphertext": base64.encode([...box.cipherText, ...box.mac.bytes]),
        });
    }

    // Decrypts an envelope from encrypt() (or the Java app) and returns the data JSON.
    // The envelope is checked before decrypting, so an unrelated file gets a clear reason.
    static Future<String> decrypt(String envelopeJson, String passphrase) async {
        final Map<String, dynamic> envelope;
        try {
            envelope = jsonDecode(envelopeJson) as Map<String, dynamic>;
        } catch (_) {
            throw const BackupCryptoException(BackupFailure.malformedEnvelope, "Not a valid backup file");
        }
        for (final String field in const ["format", "version", "salt", "iv", "ciphertext", "iterations"]) {
            if (!envelope.containsKey(field)) {
                throw const BackupCryptoException(BackupFailure.malformedEnvelope, "Missing required backup fields");
            }
        }
        if (envelope["format"] != format) {
            throw const BackupCryptoException(BackupFailure.malformedEnvelope, "Not a Bujit backup file");
        }
        final Object? version = envelope["version"];
        if (version is! int || version > currentVersion) {
            throw const BackupCryptoException(
                BackupFailure.unsupportedVersion, "This backup requires a newer version of Bujit");
        }
        final List<int> salt, iv, sealed;
        final int iterationCount;
        try {
            salt = base64.decode(envelope["salt"] as String);
            iv = base64.decode(envelope["iv"] as String);
            sealed = base64.decode(envelope["ciphertext"] as String);
            iterationCount = envelope["iterations"] as int;
        } catch (_) {
            throw const BackupCryptoException(BackupFailure.malformedEnvelope, "Malformed backup file");
        }
        if (sealed.length < _tagLength || iterationCount <= 0) {
            throw const BackupCryptoException(BackupFailure.malformedEnvelope, "Malformed backup file");
        }
        try {
            final SecretKey key = await _deriveKey(passphrase, salt, iterationCount);
            final List<int> plaintext = await _aes.decrypt(
                SecretBox(
                    sealed.sublist(0, sealed.length - _tagLength),
                    nonce: iv,
                    mac: Mac(sealed.sublist(sealed.length - _tagLength)),
                ),
                secretKey: key,
            );
            return utf8.decode(plaintext);
        } on SecretBoxAuthenticationError {
            // A wrong passphrase and a damaged file look the same to GCM.
            throw const BackupCryptoException(
                BackupFailure.wrongPassphraseOrCorrupt, "Incorrect passphrase, or this file is corrupted");
        } catch (_) {
            throw const BackupCryptoException(BackupFailure.malformedEnvelope, "Malformed backup file");
        }
    }

    // The envelope's export date (YYYY-MM-DD) for the import confirmation, or null.
    static String? readExportedAt(String envelopeJson) {
        try {
            final Object? date = (jsonDecode(envelopeJson) as Map<String, dynamic>)["exportedAt"];
            return date is String ? date : null;
        } catch (_) {
            return null;
        }
    }

    // PBKDF2-HMAC-SHA256 over the passphrase's UTF-8 bytes (what Java's PBEKeySpec uses).
    static Future<SecretKey> _deriveKey(String passphrase, List<int> salt, int iterationCount) =>
        Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterationCount, bits: 256)
            .deriveKeyFromPassword(password: passphrase, nonce: salt);

    static List<int> _randomBytes(int length) => List.generate(length, (_) => _random.nextInt(256));
}
