// Google sign-in for Google Tasks sync, through the google_sign_in plugin. The
// Java app's GoogleTasksHelper.buildSignInClient/getAccessToken equivalent.
import 'package:google_sign_in/google_sign_in.dart';
import '../../config/google_config.dart';
import 'google_tasks_helper.dart';

class GoogleTasksAccount implements TasksAccount {
    static const List<String> scopes = ["https://www.googleapis.com/auth/tasks"];

    final GoogleSignIn _signIn = GoogleSignIn.instance;
    Future<void>? _initialized;
    bool _triedRestore = false;

    @override
    bool get isConfigured => GoogleConfig.isConfigured;

    Future<void> _ready() => _initialized ??= _signIn.initialize(
        clientId: GoogleConfig.isIos ? GoogleConfig.iosClientId : null,
        serverClientId: GoogleConfig.webClientId.isEmpty ? null : GoogleConfig.webClientId,
    );

    @override
    Future<String?> connect() async {
        if (!isConfigured) throw const TasksAuthException("Google sign-in isn't set up in this build");
        try {
            await _ready();
            final GoogleSignInAccount account = await _signIn.authenticate(scopeHint: scopes);
            await account.authorizationClient.authorizeScopes(scopes);
            return account.email;
        } on GoogleSignInException catch (e) {
            if (e.code == GoogleSignInExceptionCode.canceled) return null;
            throw TasksAuthException("Google sign-in failed: ${e.description ?? e.code.name}");
        }
    }

    @override
    Future<String> accessToken() async {
        if (!isConfigured) throw const TasksAuthException("Google sign-in isn't set up in this build");
        await _ready();
        GoogleSignInClientAuthorization? authorization =
            await _signIn.authorizationClient.authorizationForScopes(scopes);
        if (authorization == null && !_triedRestore) {
            // After a restart iOS needs the previous sign-in restored first.
            _triedRestore = true;
            try {
                await _signIn.attemptLightweightAuthentication();
            } on GoogleSignInException {
                // Fall through to the error below.
            }
            authorization = await _signIn.authorizationClient.authorizationForScopes(scopes);
        }
        if (authorization == null) {
            throw const TasksAuthException(
                "Google Tasks needs permission again: turn sync off and back on in Settings");
        }
        return authorization.accessToken;
    }

    @override
    Future<void> invalidate(String token) async {
        await _ready();
        await _signIn.authorizationClient.clearAuthorizationToken(accessToken: token);
    }

    @override
    Future<void> disconnect() async {
        await _ready();
        await _signIn.disconnect();
    }
}
