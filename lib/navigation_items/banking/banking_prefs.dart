// Linked banks (the Java app's BankingActivity/BankingPrefs logic plus its balance
// syncs in ExpenseActivity and CreditUtilActivity), kept apart from the screens
// so it can be tested against a fake backend:
//   - linking a bank through Plaid Link, and reconnecting an expired one;
//   - syncing balances: at most every 15 minutes on opening, or on demand
//     (pull to refresh). Linked accounts picked for the balance set it (with
//     counted manual accounts and additional funds), and items linked to an
//     account (cards, loans) take its balance -- and a card its limit;
//   - disconnecting: the access token is revoked with Plaid, and what the bank's
//     accounts paid for or set the amount of keeps its last amount, paid from
//     the balance. (The Java app deleted linked expenses and cards; keeping them
//     loses nothing.)
import 'dart:math';
import 'package:logging/logging.dart';
import '../../storage_management/app_data_store.dart';
import '../expense_activity/balance_model.dart';
import '../expense_activity/credit_model.dart';
import '../expense_activity/expense_item.dart';
import '../expense_activity/funding_source.dart';
import 'bank_account_model.dart';
import 'banking_auth_exception.dart';
import 'plaid_api.dart';
import 'plaid_backend_client.dart';

class BankSyncResult {
    bool synced = false; // Some bank answered
    final List<String> needsRelink = []; // Institutions whose connection expired
    String? error; // The last other failure
}

final Logger _logger = Logger("BujitBanking");

class BankingService {
    static const Duration refreshInterval = Duration(minutes: 15); // The Java app's BALANCE_TTL_MS

    final PlaidBackendClient backend;
    final PlaidLinkLauncher launcher;

    BankingService(this.backend, this.launcher);

    bool get isConfigured => backend.auth.isConfigured;

    // Links a bank through Plaid Link and fetches its accounts. With [replacing]
    // (reconnecting an expired bank), the new accounts take over the old ones'
    // settings and links. Returns the institution's name, or null if the user
    // left Plaid Link. Throws BankingException/BankingAuthException on failure.
    Future<String?> linkBank(AppData data, {LinkedItem? replacing, DateTime? now}) async {
        final String publicToken;
        {
            final String? token = await launcher.open(await backend.createLinkToken());
            if (token == null) return null;
            publicToken = token;
        }
        final LinkedItem item = LinkedItem(key: _newKey(), accessToken: await backend.exchangePublicToken(publicToken));
        final List<BankAccountModel> accounts = await backend.fetchAccounts(item);
        item.institution = accounts.isEmpty ? "" : accounts.first.institution;
        final BalanceModel balance = data.balance;
        data.linkedItems.add(item);
        balance.linkedAccounts.addAll(accounts);
        if (replacing != null) {
            final List<BankAccountModel> old =
                balance.linkedAccounts.where((a) => a.itemKey == replacing.key).toList();
            for (final BankAccountModel previous in old) {
                final BankAccountModel? match = _sameAccount(previous, accounts);
                if (match != null) _moveReferences(balance, previous, match);
            }
            await _forget(data, {replacing.key}, revoke: true);
        }
        data.lastBankSync = now ?? DateTime.now();
        balance.applyLinkedBalances();
        _applyLinkedItems(balance);
        return item.institution;
    }

    // Syncs every linked bank's balances, unless the last sync was under 15
    // minutes ago and [force] is off.
    Future<BankSyncResult> refresh(AppData data, {bool force = false, DateTime? now}) async {
        final BankSyncResult result = BankSyncResult();
        final DateTime time = now ?? DateTime.now();
        final DateTime? last = data.lastBankSync;
        if (data.linkedItems.isEmpty) return result;
        if (!force && last != null && time.difference(last) < refreshInterval) return result;
        final BalanceModel balance = data.balance;
        for (final LinkedItem item in data.linkedItems) {
            try {
                final List<BankAccountModel> fetched = await backend.fetchAccounts(item);
                item.needsRelink = false;
                // Imported logins (from the Java app) learn their bank's name here.
                if (item.institution.isEmpty && fetched.isNotEmpty) item.institution = fetched.first.institution;
                for (final BankAccountModel account in fetched) {
                    final BankAccountModel? existing = balance.linkedAccount(account.id);
                    if (existing == null) {
                        balance.linkedAccounts.add(account);
                    } else {
                        existing
                            ..name = account.name
                            ..type = account.type
                            ..subtype = account.subtype
                            ..mask = account.mask
                            ..institution = account.institution
                            ..ledger = account.ledger
                            ..available = account.available
                            ..limit = account.limit;
                    }
                }
                result.synced = true;
            } on BankingAuthException catch (e) {
                _logger.warning("${item.institution}: connection expired", e);
                item.needsRelink = true;
                result.needsRelink.add(item.institution.isEmpty ? "A bank" : item.institution);
            } catch (e, stack) {
                _logger.severe("Syncing ${item.institution} failed", e, stack);
                result.error = "$e";
            }
        }
        if (result.synced) {
            data.lastBankSync = time;
            _applyPendingPicks(data);
            balance.applyLinkedBalances();
            _applyLinkedItems(balance);
        }
        return result;
    }

    // Accounts the Java app counted toward the balance, now that a sync lists them.
    static void _applyPendingPicks(AppData data) {
        for (final BankAccountModel account in data.balance.linkedAccounts) {
            if (data.pendingLinkedBalanceIds.remove(account.id) && account.isCash) account.countsTowardBalance = true;
        }
    }

    // Disconnects the banks with [itemKeys] (see the notes at the top).
    Future<void> disconnect(AppData data, Set<String> itemKeys) => _forget(data, itemKeys, revoke: true);

    Future<void> _forget(AppData data, Set<String> itemKeys, {required bool revoke}) async {
        for (final LinkedItem item in data.linkedItems.where((i) => itemKeys.contains(i.key)).toList()) {
            if (revoke) {
                try {
                    await backend.removeItem(item.accessToken);
                } catch (_) {
                    // Best effort, as in the Java app: forget it here regardless.
                }
            }
        }
        data.linkedItems.removeWhere((i) => itemKeys.contains(i.key));
        data.balance.linkedAccountsRemoved({
            for (final BankAccountModel a in data.balance.linkedAccounts)
                if (itemKeys.contains(a.itemKey)) a.id,
        });
    }

    // Cards and expenses linked to an account take its latest balance; a card also
    // its limit, when the bank reports one (else balance + available credit) --
    // the Java app's rules, which leave the limit alone when neither is known.
    static void _applyLinkedItems(BalanceModel balance) {
        for (final ExpenseItem item in balance.expenses) {
            final BankAccountModel? account = balance.linkedAccount(item.linkedAccountId);
            final double? ledger = account?.ledger;
            if (account == null || ledger == null) continue;
            item.amount = ledger.abs();
            if (item is CreditModel) {
                final double? limit = account.limit;
                final double? available = account.available;
                if (limit != null && limit > 0) {
                    item.creditLimit = limit;
                } else if (available != null && available > 0) {
                    item.creditLimit = ledger + available;
                }
                item.displayBalance = item.amount;
            }
        }
    }

    // The account at a reconnected bank that's the same as [previous]: same last
    // four digits and type (Plaid gives reconnected accounts new ids).
    static BankAccountModel? _sameAccount(BankAccountModel previous, List<BankAccountModel> accounts) {
        for (final BankAccountModel a in accounts) {
            if (a.mask == previous.mask && a.type == previous.type && a.subtype == previous.subtype) return a;
        }
        return null;
    }

    static void _moveReferences(BalanceModel balance, BankAccountModel from, BankAccountModel to) {
        to.countsTowardBalance = from.countsTowardBalance;
        for (final ExpenseItem item in balance.expenses) {
            if (item.linkedAccountId == from.id) item.linkedAccountId = to.id;
            if (item.source == FundingSource.linkedAccount && item.sourceId == from.id) item.sourceId = to.id;
        }
        from.countsTowardBalance = false;
    }

    static final Random _random = Random.secure();
    static String _newKey() =>
        List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, "0")).join();
}
