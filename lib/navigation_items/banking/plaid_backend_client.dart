// Mirrors NavigationItems/Banking/PlaidBackendClient.java in the original Java app:
// Plaid calls go through the Bujit backend (Cloud Run), which holds the Plaid
// client id and secret. Every request carries a Firebase ID token
// (Authorization: Bearer) and a Firebase App Check token (X-Firebase-AppCheck);
// calls about one bank login also carry its access token (X-Plaid-Token).
//   POST /plaid/link/token {platform} -> {link_token}   start Plaid Link
//   POST /plaid/exchange   {public_token} -> {access_token}
//   GET  /plaid/accounts   -> [{id, name, type, subtype, mask, institution_name, ledger, available, limit}]
//   POST /plaid/remove     revoke the access token with Plaid
// HTTP 401 on a call about a linked bank means its connection must be re-linked
// (BankingAuthException); on other calls, the backend refused the app itself
// (e.g. "Missing App Check token"), which is a BankingException.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'bank_account_model.dart';
import 'banking_auth_exception.dart';

// The Firebase tokens the backend checks (see FirebaseBankingAuth).
abstract class BankingAuth {
    // False when this build has no Firebase config (see lib/config/firebase_config.dart).
    bool get isConfigured;
    Future<String> idToken();
    Future<String?> appCheckToken();
}

class PlaidBackendClient {
    final String host;
    final BankingAuth auth;
    final http.Client _client;

    PlaidBackendClient({required this.host, required this.auth, http.Client? client})
        : _client = client ?? http.Client();

    // The backend sets up Plaid Link for this platform (iOS needs a redirect URI for
    // banks that log in on their own site).
    Future<String> createLinkToken() async => (await _post("/plaid/link/token", {
        "platform": defaultTargetPlatform == TargetPlatform.iOS ? "ios" : "android",
    }))["link_token"] as String;

    Future<String> exchangePublicToken(String publicToken) async =>
        (await _post("/plaid/exchange", {"public_token": publicToken}))["access_token"] as String;

    // Revokes an access token with Plaid (call before forgetting it, as the Java app does).
    Future<void> removeItem(String accessToken) => _post("/plaid/remove", {}, accessToken: accessToken);

    // Every account under one bank login, with its balances.
    Future<List<BankAccountModel>> fetchAccounts(LinkedItem item) async {
        final http.Response response = await _client.get(
            Uri.https(host, "/plaid/accounts"),
            headers: await _headers(accessToken: item.accessToken),
        );
        final Object? json = _decode(response, "/plaid/accounts", aboutBank: true);
        if (json is! List) throw const BankingException("Unexpected /plaid/accounts response");
        return [
            for (final Object? o in json)
                if (o is Map<String, dynamic>)
                    BankAccountModel(
                        id: "${o["id"]}",
                        itemKey: item.key,
                        name: (o["name"] ?? "") as String,
                        type: (o["type"] ?? "") as String,
                        subtype: (o["subtype"] ?? "") as String,
                        mask: (o["mask"] ?? "") as String,
                        institution: (o["institution_name"] ?? "") as String,
                        ledger: _amount(o["ledger"]),
                        available: _amount(o["available"]),
                        limit: _amount(o["limit"]),
                    ),
        ];
    }

    Future<Map<String, dynamic>> _post(String path, Map<String, Object?> body, {String? accessToken}) async {
        final http.Response response = await _client.post(
            Uri.https(host, path),
            headers: {
                ...await _headers(accessToken: accessToken),
                "Content-Type": "application/json; charset=utf-8",
            },
            body: jsonEncode(body),
        );
        final Object? json = _decode(response, path, aboutBank: accessToken != null);
        return json is Map<String, dynamic> ? json : const {};
    }

    Future<Map<String, String>> _headers({String? accessToken}) async => {
        "Authorization": "Bearer ${await auth.idToken()}",
        "X-Firebase-AppCheck": await auth.appCheckToken() ?? "",
        "X-Plaid-Token": ?accessToken,
    };

    static Object? _decode(http.Response response, String path, {required bool aboutBank}) {
        final String text = utf8.decode(response.bodyBytes);
        if (response.statusCode == 401) {
            String code = "AUTH_REQUIRED";
            try {
                code = (jsonDecode(text) as Map<String, dynamic>)["error"] as String? ?? code;
            } catch (_) {}
            if (aboutBank) throw BankingAuthException(code);
            throw BankingException("Bujit's server refused the request ($code)");
        }
        if (response.statusCode >= 300) throw BankingException("Backend $path failed: HTTP ${response.statusCode}");
        try {
            return text.isEmpty ? null : jsonDecode(text);
        } on FormatException {
            throw BankingException("Unexpected $path response");
        }
    }

    // Balances may arrive as numbers or strings (the Java app read them with optString); null/"—" = unknown.
    static double? _amount(Object? value) {
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value);
        return null;
    }
}
