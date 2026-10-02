// Mirrors NavigationItems/Banking/BankingAuthException.java in the original Java
// app: the backend answered HTTP 401 -- the bank connection was revoked or
// expired (e.g. ITEM_LOGIN_REQUIRED), and the user must reconnect.
class BankingAuthException implements Exception {
    final String code;
    const BankingAuthException(this.code);
    @override
    String toString() => "Bank connection needs to be reconnected ($code)";
}

// Anything else that went wrong talking to the backend.
class BankingException implements Exception {
    final String message;
    const BankingException(this.message);
    @override
    String toString() => message;
}
