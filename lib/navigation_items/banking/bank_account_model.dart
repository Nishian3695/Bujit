// Mirrors NavigationItems/Banking/BankAccountModel.java in the original Java app:
// one account at a linked bank, as the backend's /plaid/accounts returns it,
// with its latest balances. LinkedItem is one linked bank login (a Plaid
// "Item"), holding the access token its accounts are fetched with.

class LinkedItem {
    final String key; // Local id; accounts point at their item by it
    final String accessToken; // Plaid access token (kept in the encrypted database, never in backups)
    String institution;
    // The bank connection was revoked or expired (HTTP 401): reconnect to keep syncing.
    bool needsRelink;

    LinkedItem({required this.key, required this.accessToken, this.institution = "", this.needsRelink = false});
}

class BankAccountModel {
    final String id; // Plaid account_id
    String itemKey; // The LinkedItem it belongs to
    String name;
    String type; // depository, credit, loan, investment, ...
    String subtype; // checking, savings, credit card, ...
    String mask; // Last four digits
    String institution;
    double? ledger; // Current balance (what a card or loan owes)
    double? available;
    double? limit; // Credit limit, when the bank reports one
    // Picked "From Accounts" in Update Balance: its balance is part of the current balance.
    bool countsTowardBalance;

    BankAccountModel({
        required this.id,
        required this.itemKey,
        required this.name,
        this.type = "",
        this.subtype = "",
        this.mask = "",
        this.institution = "",
        this.ledger,
        this.available,
        this.limit,
        this.countsTowardBalance = false,
    });

    bool get isCredit => type.toLowerCase() == "credit";
    bool get isLoan => type.toLowerCase() == "loan";
    // Money you have (what can make up the balance or pay for things), not money owed.
    bool get isCash => !isCredit && !isLoan;

    // "Depository – Checking", as in the Java app.
    String get displayType {
        if (type.isEmpty) return "";
        final String t = _capitalize(type);
        return subtype.isEmpty ? t : "$t – ${_capitalize(subtype)}";
    }

    // "Chase Checking …1234".
    String get displayName => [
        if (institution.isNotEmpty) institution,
        name,
        if (mask.isNotEmpty) "…$mask",
    ].join(" ");

    static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
