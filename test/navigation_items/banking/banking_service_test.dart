// Linked banks against a fake Bujit backend: linking through Plaid Link, syncing
// balances into the current balance, cards and loans, expired connections and
// reconnecting, disconnecting, and paying from linked accounts.
import 'dart:convert';
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/banking/bank_account_model.dart';
import 'package:bujit/navigation_items/banking/banking_auth_exception.dart';
import 'package:bujit/navigation_items/banking/banking_prefs.dart';
import 'package:bujit/navigation_items/banking/manual_account_model.dart';
import 'package:bujit/navigation_items/banking/plaid_api.dart';
import 'package:bujit/navigation_items/banking/plaid_backend_client.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/credit_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';
import 'package:bujit/navigation_items/expense_activity/funding_source.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/storage_management/database/app_database.dart';
import 'package:bujit/utils/frequency_unit.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final DateTime today = DateTime(2026, 10, 1);
final DateTime noon = DateTime(2026, 10, 1, 12);

class FakeAuth implements BankingAuth {
    @override
    bool get isConfigured => true;
    @override
    Future<String> idToken() async => "firebase-id";
    @override
    Future<String?> appCheckToken() async => "app-check";
}

class FakeLauncher implements PlaidLinkLauncher {
    String? publicToken = "public-1";
    String? openedWith;
    @override
    Future<String?> open(String linkToken) async {
        openedWith = linkToken;
        return publicToken;
    }
}

// The backend: access tokens -> the accounts behind them (as /plaid/accounts returns them).
class FakeBackend {
    final Map<String, List<Map<String, Object?>>> accounts = {};
    final Set<String> revoked = {}; // 401 from now on
    final List<String> removed = [];
    final List<http.Request> requests = [];
    String nextAccessToken = "access-1";

    late final http.Client client = MockClient((request) async {
        requests.add(request);
        if (request.headers["Authorization"] != "Bearer firebase-id" ||
            request.headers["X-Firebase-AppCheck"] != "app-check") {
            return http.Response('{"error":"UNAUTHENTICATED"}', 403);
        }
        final String? token = request.headers["X-Plaid-Token"];
        http.Response json(Object body) => http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
        switch (request.url.path) {
            case "/plaid/link/token":
                return json({"link_token": "link-sandbox-1"});
            case "/plaid/exchange":
                final String body = (jsonDecode(request.body) as Map)["public_token"];
                return json({"access_token": body == "public-1" ? nextAccessToken : "?"});
            case "/plaid/accounts":
                if (revoked.contains(token)) return http.Response('{"error":"ITEM_LOGIN_REQUIRED"}', 401);
                return json(accounts[token] ?? []);
            case "/plaid/remove":
                removed.add(token!);
                return json({});
        }
        return http.Response("", 404);
    });
}

Map<String, Object?> _account(String id, String type, String subtype, String mask, Object? ledger,
        {Object? available, Object? limit, String institution = "Chase", String name = "Account"}) =>
    {"id": id, "name": name, "type": type, "subtype": subtype, "mask": mask, "institution_name": institution,
        "ledger": ledger, "available": available, "limit": limit};

late FakeBackend backend;
late FakeLauncher launcher;
late BankingService service;
late AppData data;

void main() {
    setUp(() {
        backend = FakeBackend();
        launcher = FakeLauncher();
        service = BankingService(
            PlaidBackendClient(host: "backend.test", auth: FakeAuth(), client: backend.client), launcher);
        data = AppData(balance: BalanceModel(currentBalance: 1000.0, lastUpdated: today));
        backend.accounts["access-1"] = [
            _account("chk", "depository", "checking", "1111", "2500.50", available: "2400.00", name: "Checking"),
            _account("sav", "depository", "savings", "2222", 10000, name: "Savings"),
            _account("cc", "credit", "credit card", "3333", "640.25", available: "1359.75", limit: null, name: "Sapphire"),
            _account("car", "loan", "auto", "4444", 8200, name: "Auto Loan"),
        ];
    });

    group("linking", () {
        test("Plaid Link's public token becomes an access token, and the bank's accounts are listed", () async {
            expect(await service.linkBank(data, now: noon), "Chase");

            expect(launcher.openedWith, "link-sandbox-1");
            final LinkedItem item = data.linkedItems.single;
            expect(item.accessToken, "access-1");
            expect(item.institution, "Chase");
            final BankAccountModel checking = data.balance.linkedAccount("chk")!;
            expect(checking.ledger, 2500.5); // string amounts are read too
            expect(checking.available, 2400.0);
            expect(checking.displayName, "Chase Checking …1111");
            expect(checking.displayType, "Depository – Checking");
            expect(checking.isCash, isTrue);
            expect(data.balance.linkedAccount("cc")!.limit, isNull);
            expect(data.lastBankSync, noon);
            // Nothing counts toward the balance until picked.
            expect(data.balance.currentBalance, 1000.0);
            // Every call carries the Firebase tokens; account calls the access token.
            final http.Request accountsCall = backend.requests.firstWhere((r) => r.url.path == "/plaid/accounts");
            expect(accountsCall.headers["X-Plaid-Token"], "access-1");
        });

        test("leaving Plaid Link links nothing", () async {
            launcher.publicToken = null;

            expect(await service.linkBank(data), isNull);
            expect(data.linkedItems, isEmpty);
            expect(backend.requests.map((r) => r.url.path), ["/plaid/link/token"]);
        });
    });

    group("syncing", () {
        setUp(() async {
            await service.linkBank(data, now: noon);
        });

        test("accounts picked for the balance set it, with counted manual accounts and additional funds", () async {
            final ManualAccountModel cash = ManualAccountModel(name: "Cash", balance: 40.0);
            data.balance.manualAccounts.add(cash);
            data.balance.setBalanceFromAccounts({"chk", cash.id}, 10.0);
            expect(data.balance.currentBalance, 2500.5 + 40.0 + 10.0);

            backend.accounts["access-1"]![0]["ledger"] = "1800.00"; // money left checking
            final BankSyncResult result = await service.refresh(data, force: true, now: noon);

            expect(result.synced, isTrue);
            expect(data.balance.currentBalance, 1800.0 + 40.0 + 10.0);
        });

        test("without linked accounts in the balance, syncing leaves it alone", () async {
            data.balance.currentBalance = 777.0;
            await service.refresh(data, force: true, now: noon);
            expect(data.balance.currentBalance, 777.0);
        });

        test("a typed balance unpicks linked accounts", () {
            data.balance.setBalanceFromAccounts({"chk"}, 0.0);
            data.balance.setBalanceTyped(500.0, 0.0);
            expect(data.balance.linkedAccount("chk")!.countsTowardBalance, isFalse);
        });

        test("cards and loans can't make up the balance", () {
            data.balance.setBalanceFromAccounts({"chk", "cc", "car"}, 0.0);
            expect(data.balance.currentBalance, 2500.5);
        });

        test("at most every 15 minutes unless forced", () async {
            final int before = backend.requests.length;

            await service.refresh(data, now: noon.add(const Duration(minutes: 14)));
            expect(backend.requests.length, before);
            await service.refresh(data, now: noon.add(const Duration(minutes: 15)));
            expect(backend.requests.length, before + 1);
            await service.refresh(data, force: true, now: noon.add(const Duration(minutes: 16)));
            expect(backend.requests.length, before + 2);
        });

        test("a linked card takes its balance, and its limit from the bank (or balance + available)", () async {
            final CreditModel card = CreditModel(name: "Sapphire", amount: 0.0, creditLimit: 5000.0,
                startDate: DateTime(2026, 10, 20), frequency: 1, frequencyUnits: FrequencyUnit.monthly,
                linkedAccountId: "cc");
            data.balance.expenses.add(card);

            await service.refresh(data, force: true, now: noon);
            expect(card.amount, 640.25);
            expect(card.creditLimit, 640.25 + 1359.75); // no limit reported

            backend.accounts["access-1"]![2]["limit"] = 2500;
            await service.refresh(data, force: true, now: noon);
            expect(card.creditLimit, 2500.0);

            backend.accounts["access-1"]![2]
                ..["limit"] = null
                ..["available"] = null;
            await service.refresh(data, force: true, now: noon);
            expect(card.creditLimit, 2500.0); // neither known: left alone
        });

        test("a linked expense takes the account's balance", () async {
            final ExpenseModel loan = ExpenseModel(name: "Car", amount: 300.0, startDate: DateTime(2026, 10, 15),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly, linkedAccountId: "car");
            data.balance.expenses.add(loan);

            await service.refresh(data, force: true, now: noon);

            expect(loan.amount, 8200.0);
        });

        test("an expired connection is reported, keeps its accounts, and others still sync", () async {
            backend.nextAccessToken = "access-2";
            backend.accounts["access-2"] = [_account("bofa", "depository", "checking", "9999", 50, institution: "BofA")];
            await service.linkBank(data, now: noon);
            backend.revoked.add("access-1");
            backend.accounts["access-2"]![0]["ledger"] = 75;

            final BankSyncResult result = await service.refresh(data, force: true, now: noon);

            expect(result.needsRelink, ["Chase"]);
            expect(data.linkedItems.first.needsRelink, isTrue);
            expect(data.balance.linkedAccount("chk"), isNotNull);
            expect(data.balance.linkedAccount("bofa")!.ledger, 75.0);
        });

        test("reconnecting moves settings and links to the new accounts and revokes the old login", () async {
            data.balance.setBalanceFromAccounts({"chk"}, 0.0);
            final ExpenseModel rent = ExpenseModel(name: "Rent", amount: 1200.0, startDate: DateTime(2026, 10, 15),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly,
                source: FundingSource.linkedAccount, sourceId: "chk");
            data.balance.expenses.add(rent);
            final LinkedItem old = data.linkedItems.single..needsRelink = true;
            // Plaid gives the reconnected bank's accounts new ids.
            backend.nextAccessToken = "access-2";
            backend.accounts["access-2"] = [
                _account("chk-2", "depository", "checking", "1111", 2600, name: "Checking"),
            ];

            await service.linkBank(data, replacing: old, now: noon);

            expect(data.linkedItems.single.accessToken, "access-2");
            expect(backend.removed, ["access-1"]);
            expect(data.balance.linkedAccount("chk"), isNull);
            expect(data.balance.linkedAccount("chk-2")!.countsTowardBalance, isTrue);
            expect(rent.sourceId, "chk-2");
            expect(data.balance.currentBalance, 2600.0);
        });

        test("disconnecting revokes access; what used its accounts keeps its last amount, paid from the balance", () async {
            final CreditModel card = CreditModel(name: "Sapphire", amount: 640.25, creditLimit: 2000.0,
                startDate: DateTime(2026, 10, 20), frequency: 1, frequencyUnits: FrequencyUnit.monthly,
                linkedAccountId: "cc");
            final ExpenseModel rent = ExpenseModel(name: "Rent", amount: 1200.0, startDate: DateTime(2026, 10, 15),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly,
                source: FundingSource.linkedAccount, sourceId: "chk");
            data.balance.expenses.addAll([card, rent]);

            await service.disconnect(data, {data.linkedItems.single.key});

            expect(backend.removed, ["access-1"]);
            expect(data.linkedItems, isEmpty);
            expect(data.balance.linkedAccounts, isEmpty);
            expect(data.balance.expenses, hasLength(2)); // nothing deleted
            expect(card.linkedAccountId, isNull);
            expect(card.amount, 640.25);
            expect(rent.source, FundingSource.balance);
        });
    });

    group("paying from a linked account", () {
        late ExpenseModel rent;
        setUp(() async {
            await service.linkBank(data, now: noon);
            rent = ExpenseModel(name: "Rent", amount: 1200.0, startDate: DateTime(2026, 10, 15),
                frequency: 1, frequencyUnits: FrequencyUnit.monthly,
                source: FundingSource.linkedAccount, sourceId: "chk");
            data.balance.expenses.add(rent);
        });

        test("isn't deducted here when it comes due: the bank's balance shows it at the next sync", () {
            data.balance.makeRecent(today: DateTime(2026, 10, 16));
            expect(data.balance.currentBalance, 1000.0);
        });

        test("counts in projections only if the account is part of the balance", () {
            final window = data.balance.window(0, today: DateTime(2026, 10, 14));
            expect(data.balance.hitsBalance(rent), isFalse);
            data.balance.setBalanceFromAccounts({"chk"}, 0.0);
            expect(data.balance.hitsBalance(rent), isTrue);
            expect(data.balance.expensesForCheck(window), greaterThanOrEqualTo(1200.0));
        });

        test("is offered in Paid from, by its bank name", () {
            expect(data.balance.paymentOptions(forCard: false).map((o) => o.label),
                containsAllInOrder(["Current Balance", "Chase Checking …1111", "Chase Savings …2222"]));
            expect(data.balance.paidFromLabel(rent), "Chase Checking …1111");
        });
    });

    test("the link token request names the platform (iOS gets an OAuth redirect from the backend)", () async {
        await service.linkBank(data, now: noon);
        final http.Request android = backend.requests.firstWhere((r) => r.url.path == "/plaid/link/token");
        expect(jsonDecode(android.body), {"platform": "android"});

        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        try {
            await service.backend.createLinkToken();
        } finally {
            debugDefaultTargetPlatformOverride = null;
        }
        final http.Request ios = backend.requests.lastWhere((r) => r.url.path == "/plaid/link/token");
        expect(jsonDecode(ios.body), {"platform": "ios"});
    });

    test("the backend's errors", () async {
        final PlaidBackendClient client = PlaidBackendClient(host: "backend.test", auth: FakeAuth(),
            client: MockClient((_) async => http.Response("boom", 500)));
        await expectLater(client.createLinkToken(), throwsA(isA<BankingException>()));
        final PlaidBackendClient expired = PlaidBackendClient(host: "backend.test", auth: FakeAuth(),
            client: MockClient((_) async => http.Response('{"error":"ITEM_LOGIN_REQUIRED"}', 401)));
        await expectLater(expired.fetchAccounts(LinkedItem(key: "k", accessToken: "a")),
            throwsA(isA<BankingAuthException>().having((e) => e.code, "code", "ITEM_LOGIN_REQUIRED")));
        // A 401 before any bank is involved is the backend refusing the app, not an expired bank.
        final PlaidBackendClient refused = PlaidBackendClient(host: "backend.test", auth: FakeAuth(),
            client: MockClient((_) async => http.Response('{"error":"Missing App Check token"}', 401)));
        await expectLater(refused.createLinkToken(), throwsA(isA<BankingException>().having(
            (e) => e.message, "message", "Bujit's server refused the request (Missing App Check token)")));
    });

    test("links, accounts and the last sync are saved; access tokens never go in backups", () async {
        await service.linkBank(data, now: noon);
        data.balance.setBalanceFromAccounts({"sav"}, 0.0);
        data.balance.expenses.add(ExpenseModel(name: "Car", amount: 300.0, startDate: today, frequency: 1,
            frequencyUnits: FrequencyUnit.monthly, linkedAccountId: "car"));
        final AppDataStore store = AppDataStore(AppDatabase(NativeDatabase.memory()));

        await store.save(data);
        final AppData loaded = (await store.load())!;

        expect(loaded.linkedItems.single.accessToken, "access-1");
        expect(loaded.balance.linkedAccounts.map((a) => a.id), ["chk", "sav", "cc", "car"]);
        expect(loaded.balance.linkedAccount("sav")!.countsTowardBalance, isTrue);
        expect(loaded.balance.linkedAccount("cc")!.available, 1359.75);
        expect(loaded.balance.expenses.single.linkedAccountId, "car");
        expect(loaded.lastBankSync, noon);
    });

    test("AppState: linking saves, and clearing all data disconnects banks", () async {
        final AppState state = AppState(data)..banking = service;

        expect(await state.linkBank(), "Chase");
        expect(state.canLinkBanks, isTrue);
        await state.clearAllData();

        expect(backend.removed, ["access-1"]);
        expect(state.data.linkedItems, isEmpty);
        expect(state.balance.linkedAccounts, isEmpty);
    });
}
