package io.github.nishian3695.bujit.NavigationItems.Banking;

import java.io.IOException;
import java.util.List;

/*
Common interface implemented by both TellerBackendClient and PlaidBackendClient.
Lets the rest of the app stay provider-agnostic; use BankingProviderConfig.createClient()
to obtain the correct implementation at runtime.
*/
public interface BankingApiClient {
    // Fetches every account visible under this client's access token.
    List<BankAccountModel> fetchAccounts() throws IOException;
    // Fetches a single account's [ledgerBalance, availableBalance] pair.
    float[] fetchAccountBalancePair(String accountId) throws IOException;
    // Fetches a single account's ledger balance.
    float fetchAccountBalance(String accountId) throws IOException;
    // Revokes the access token on the provider's server. Must be called before clearing
    // the token locally so the provider doesn't retain an active Item for a disconnected user.
    void revokeToken() throws IOException;
}
