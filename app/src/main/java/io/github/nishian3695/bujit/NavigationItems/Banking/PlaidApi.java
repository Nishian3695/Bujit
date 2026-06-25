package io.github.nishian3695.bujit.NavigationItems.Banking;

import java.io.IOException;
import java.util.List;

/*
Contract for fetching bank data from the Plaid API (via the backend proxy).
Mirrors TellerApi so BankingActivity can swap implementations without changing
any UI or storage logic.
*/
interface PlaidApi {
    List<BankAccountModel> fetchAccounts() throws IOException;
    float[] fetchAccountBalancePair(String accountId) throws IOException;
    float fetchAccountBalance(String accountId) throws IOException;
}
