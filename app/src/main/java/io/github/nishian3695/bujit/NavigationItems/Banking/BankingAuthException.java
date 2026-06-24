package io.github.nishian3695.bujit.NavigationItems.Banking;

import java.io.IOException;

/*
Thrown when the backend returns HTTP 401 for a banking API call, indicating
that the stored access token has been revoked or has expired and the user
must re-link their bank account.
*/
public class BankingAuthException extends IOException {
    public BankingAuthException(String errorCode) {
        super(errorCode);
    }
}
