package io.github.nishian3695.bujit.NavigationItems.Banking;

import java.io.IOException;
import java.util.List;

/*
Contract for fetching bank data from the Teller API (via the backend proxy).
fetchAccounts returns all enrolled accounts for a given access token.
fetchAccountBalancePair returns {ledger, available, creditLimit} for one account.
creditLimit is 0 for Teller (not exposed by the API; caller falls back to ledger + available).
fetchAccountBalance returns just the ledger balance for one account.
*/
interface TellerApi {
    // Fetches every account enrolled under this client's access token.
    List<BankAccountModel> fetchAccounts() throws IOException;
    // Fetches a single account's [ledger, available, creditLimit] balance triple.
    float[] fetchAccountBalancePair(String accountId) throws IOException;
    // Fetches a single account's ledger balance.
    float fetchAccountBalance(String accountId) throws IOException;
}
