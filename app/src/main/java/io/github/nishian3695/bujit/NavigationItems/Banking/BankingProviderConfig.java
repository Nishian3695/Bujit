package io.github.nishian3695.bujit.NavigationItems.Banking;

import android.content.Context;

/*
Compile-time switch between banking data providers.
Change ACTIVE_PROVIDER to select which provider BankingActivity uses.
Both providers share the same BankAccountModel and UI; only the SDK launch
and backend client differ.
*/
public class BankingProviderConfig {

    public enum Provider {
        TELLER,
        PLAID
    }

    // Change this single line to switch providers.
    public static final Provider ACTIVE_PROVIDER = Provider.PLAID;

    // Returns the correct backend client for the active provider.
    // Use this everywhere instead of constructing TellerBackendClient or PlaidBackendClient directly.
    public static BankingApiClient createClient(Context ctx, String token, String idToken) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            return new PlaidBackendClient(ctx, token, idToken);
        }
        return new TellerBackendClient(ctx, token, idToken);
    }

    // Returns the access token stored for a given account ID under the active provider.
    public static String getTokenForAccount(Context ctx, String accountId) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            return BankingPrefs.getPlaidTokenForAccount(ctx, accountId);
        }
        return BankingPrefs.getTokenForAccount(ctx, accountId);
    }

    // Persists the account to token mapping for the active provider.
    // Call this whenever an account is linked to an expense or credit entry so the token
    // can be recovered after app restart (the transient field on ExpenseModel is not serialized).
    public static void saveAccountToken(Context ctx, String accountId, String token) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            BankingPrefs.savePlaidAccountToken(ctx, accountId, token);
        } else {
            BankingPrefs.saveAccountToken(ctx, accountId, token);
        }
    }

    // Returns all stored tokens for the active provider.
    public static java.util.Set<String> loadTokens(Context ctx) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            return BankingPrefs.loadPlaidTokens(ctx);
        }
        return BankingPrefs.loadTokens(ctx);
    }

    // Returns the set of linked account composite keys ("token|accountId") for the active provider.
    public static java.util.Set<String> loadLinkedAccounts(Context ctx) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            return BankingPrefs.loadPlaidLinkedAccounts(ctx);
        }
        return BankingPrefs.loadLinkedAccounts(ctx);
    }

    // Persists linked account composite keys for the active provider.
    public static void saveLinkedAccounts(Context ctx, java.util.Set<String> composites) {
        if (ACTIVE_PROVIDER == Provider.PLAID) {
            BankingPrefs.savePlaidLinkedAccounts(ctx, composites);
        } else {
            BankingPrefs.saveLinkedAccounts(ctx, composites);
        }
    }
}
