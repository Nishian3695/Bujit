package io.github.nishian3695.bujit.NavigationItems.Banking;

import java.io.IOException;
import java.util.List;

/*
Common interface implemented by both TellerBackendClient and PlaidBackendClient.
Lets the rest of the app stay provider-agnostic; use BankingProviderConfig.createClient()
to obtain the correct implementation at runtime.
*/
public interface BankingApiClient {
    List<BankAccountModel> fetchAccounts() throws IOException;
    float[] fetchAccountBalancePair(String accountId) throws IOException;
    float fetchAccountBalance(String accountId) throws IOException;
}
