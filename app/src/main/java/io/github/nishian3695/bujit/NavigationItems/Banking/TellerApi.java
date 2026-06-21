package io.github.nishian3695.bujit.NavigationItems.Banking;

import java.io.IOException;
import java.util.List;

/*
Contract for fetching bank data from the Teller API (via the backend proxy).
fetchAccounts returns all enrolled accounts for a given access token.
fetchAccountBalancePair returns {ledger, available} balances for one account.
fetchAccountBalance returns just the ledger balance for one account.
*/
interface TellerApi {
    List<BankAccountModel> fetchAccounts() throws IOException;
    float[] fetchAccountBalancePair(String accountId) throws IOException;
    float fetchAccountBalance(String accountId) throws IOException;
}
