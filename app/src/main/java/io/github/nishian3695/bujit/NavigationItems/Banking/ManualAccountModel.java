package io.github.nishian3695.bujit.NavigationItems.Banking;

import java.io.Serializable;
import java.util.UUID;

/*
Data model for a user-defined bank account that is not connected via Plaid or Teller.
The user supplies a name, account type, and balance manually and updates them as needed.
The balance is included in the main balance calculation alongside any synced accounts.
*/
public class ManualAccountModel implements Serializable {

    private String id;
    private String name;
    private String accountType;
    private float balance;

    public ManualAccountModel(String name, String accountType, float balance) {
        this.id          = UUID.randomUUID().toString();
        this.name        = name;
        this.accountType = accountType;
        this.balance     = balance;
    }

    public String getId()          { return id; }
    public void   setId(String id) { this.id = id; }

    public String getName()             { return name; }
    public void   setName(String name)  { this.name = name; }

    public String getAccountType()                    { return accountType; }
    public void   setAccountType(String accountType)  { this.accountType = accountType; }

    public float getBalance()              { return balance; }
    public void  setBalance(float balance) { this.balance = balance; }
}
