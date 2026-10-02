// Mirrors NavigationItems/Banking/ManualAccountModel.java in the original Java app:
// an account the user tracks by hand (not linked through Plaid), with a name, a
// type and a balance. Accounts marked countsTowardBalance are the ones picked
// "From Accounts" when updating the balance (the Java app's manual linked ids):
// their balance changes move the current balance too (see BalanceModel.adjustAccount).
import 'dart:math';

class ManualAccountModel {
    static const List<String> accountTypes = ["Checking", "Savings", "Cash", "Investment", "Other"];

    final String id; // Stable id: expenses and single events refer to the account by it
    String name;
    String accountType;
    double balance;
    bool countsTowardBalance;

    ManualAccountModel({
        String? id,
        required this.name,
        this.accountType = "Savings",
        required this.balance,
        this.countsTowardBalance = false,
    }) : id = id ?? _newId();

    static final Random _random = Random.secure();

    // A random 128-bit id in hex (what Java's UUID.randomUUID() is for).
    static String _newId() =>
        List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, "0")).join();
}
