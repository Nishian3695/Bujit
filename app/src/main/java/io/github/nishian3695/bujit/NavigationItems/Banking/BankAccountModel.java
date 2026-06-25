package io.github.nishian3695.bujit.NavigationItems.Banking;

/*
Data model for a single bank account returned by the Teller API.
Holds identity fields (id, token, name, type, subtype, last-four, status,
institution name) and balance strings (ledger and available).
The access token is stored here so that balance-refresh calls can route
each account back to the correct Teller enrollment.
*/
public class BankAccountModel {
    private String id;
    private String name;
    private String token;
    private String type;
    private String subtype;
    private String lastFour;
    private String status;
    private String institutionName;
    private String ledgerBalance;
    private String availableBalance;
    // Credit limit reported by the provider (non-null only for credit-type accounts and only
    // when the provider exposes it directly, e.g. Plaid's balances.limit). Null means the
    // caller should fall back to ledger + available as an approximation.
    private String creditLimit;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getToken() { return token; }
    public void setToken(String token) { this.token = token; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getSubtype() { return subtype; }
    public void setSubtype(String subtype) { this.subtype = subtype; }

    public String getLastFour() { return lastFour; }
    public void setLastFour(String lastFour) { this.lastFour = lastFour; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getInstitutionName() { return institutionName; }
    public void setInstitutionName(String institutionName) { this.institutionName = institutionName; }

    public String getLedgerBalance() { return ledgerBalance; }
    public void setLedgerBalance(String ledgerBalance) { this.ledgerBalance = ledgerBalance; }

    public String getAvailableBalance() { return availableBalance; }
    public void setAvailableBalance(String availableBalance) { this.availableBalance = availableBalance; }

    public String getCreditLimit() { return creditLimit; }
    public void setCreditLimit(String creditLimit) { this.creditLimit = creditLimit; }

    // Formats type + subtype for display, e.g. "Depository - Checking"
    public String getDisplayType() {
        if (type == null || type.isEmpty()) return "";
        String t = capitalize(type);
        if (subtype != null && !subtype.isEmpty()) {
            return t + " – " + capitalize(subtype);
        }
        return t;
    }

    private String capitalize(String s) {
        if (s == null || s.isEmpty()) return s;
        return Character.toUpperCase(s.charAt(0)) + s.substring(1);
    }
}
