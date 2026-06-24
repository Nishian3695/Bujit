package io.github.nishian3695.bujit.NavigationItems.Banking;

/*
Compile-time switch between banking data providers.
Change ACTIVE_PROVIDER to select which provider BankingActivity uses.
Both providers share the same BankAccountModel and UI; only the SDK launch
and backend client differ.

All Teller infrastructure is retained and fully functional — switching back
to TELLER requires only changing the constant below.
*/
public class BankingProviderConfig {

    public enum Provider {
        TELLER,
        PLAID
    }

    // Change this single line to switch providers.
    public static final Provider ACTIVE_PROVIDER = Provider.PLAID;
}
