package io.github.nishian3695.bujit.NavigationItems.Banking;

import java.io.IOException;
import java.util.List;

/*
Contract for fetching bank data from the Plaid API (via the backend proxy).
Mirrors TellerApi so BankingActivity can swap implementations without changing
any UI or storage logic.
*/
interface PlaidApi {
    // Fetches every account visible under this client's access token.
    List<BankAccountModel> fetchAccounts() throws IOException;
    // Fetches a single account's [ledgerBalance, availableBalance] pair.
    float[] fetchAccountBalancePair(String accountId) throws IOException;
    // Fetches a single account's ledger balance.
    float fetchAccountBalance(String accountId) throws IOException;
}
