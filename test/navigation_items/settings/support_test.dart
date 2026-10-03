// Settings' support rows: the tip jar (against a fake store), the CSV template
// choice, the disclaimer, and Credit Utilization's totals row.
import 'dart:async';
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/credit_util/credit_util_activity.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/settings/settings_activity.dart';
import 'package:bujit/navigation_items/settings/tip_jar.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTipStore implements TipStore {
    bool available = true;
    final List<String> bought = [];
    final StreamController<String> _purchased = StreamController.broadcast();

    void finish(String productId) => _purchased.add(productId);

    @override
    Future<bool> isAvailable() async => available;
    @override
    Future<Map<String, String>> prices(Set<String> productIds) async =>
        {"tip_small": "€1,09", "tip_medium": "€3,29"}; // tip_large isn't set up in the store
    @override
    Future<bool> buy(String productId) async {
        bought.add(productId);
        return true;
    }
    @override
    Stream<String> get purchased => _purchased.stream;
}

AppState _sampleState() {
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.0), tutorialSeen: true);
    seedSampleData(data.balance);
    return AppState(data);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
}

void main() {
    group("tip jar", () {
        test("store prices replace the defaults; unknown products can't be bought", () async {
            final FakeTipStore store = FakeTipStore();
            final TipJar jar = TipJar(store);
            expect(jar.price(Tip.small), "\$0.99");

            await jar.load();

            expect(jar.price(Tip.small), "€1,09");
            expect(jar.price(Tip.large), "\$4.99");
            expect(await jar.give(Tip.medium), isTrue);
            expect(await jar.give(Tip.large), isFalse);
            expect(store.bought, ["tip_medium"]);
        });

        test("an unavailable store sells nothing", () async {
            final TipJar jar = TipJar(FakeTipStore()..available = false);
            await jar.load();
            expect(await jar.give(Tip.small), isFalse);
        });

        testWidgets("Settings shows the prices, buys, and says thanks when a purchase finishes", (tester) async {
            final FakeTipStore store = FakeTipStore();
            final AppState state = _sampleState()..tipJar = TipJar(store);
            await state.tipJar!.load();
            await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: state)));
            await _scrollTo(tester, find.text("☕  €1,09"));

            await tester.tap(find.text("☕  €1,09"));
            await tester.pump();
            expect(store.bought, ["tip_small"]);

            store.finish("tip_small");
            await tester.pump();
            await tester.pump();
            expect(find.text("Thank you for your support!"), findsOneWidget);

            await tester.tap(find.text("❤️  \$4.99"));
            await tester.pumpAndSettle();
            expect(find.text("Store unavailable — try again later"), findsOneWidget);
        });
    });

    testWidgets("Get CSV template offers saving or sharing", (tester) async {
        await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: _sampleState())));
        await _scrollTo(tester, find.text("Get CSV template"));

        await tester.tap(find.text("Get CSV template"));
        await tester.pumpAndSettle();

        expect(find.text("Save to device"), findsOneWidget);
        expect(find.text("Share"), findsOneWidget);
    });

    testWidgets("Settings lists the support and legal rows, and shows the disclaimer", (tester) async {
        await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: _sampleState())));
        for (final String row in ["Help / Suggestions", "CSV import reference", "Website", "Privacy Policy",
                "Plaid Legal and Privacy Policy"]) {
            await _scrollTo(tester, find.text(row));
            expect(find.text(row), findsOneWidget);
        }
        await _scrollTo(tester, find.text("Disclaimer"));
        await tester.tap(find.text("Disclaimer"));
        await tester.pumpAndSettle();
        expect(find.textContaining("It does not constitute financial advice."), findsOneWidget);
    });

    testWidgets("Credit Utilization totals every card", (tester) async {
        await tester.pumpWidget(MaterialApp(home: CreditUtilActivity(state: _sampleState())));
        // 450 + 1200 + 6000 = 7650 of 2000 + 3000 + 6200 = 11200 -> 68%
        expect(find.textContaining("Owed  \$7650.00", findRichText: true), findsOneWidget);
        expect(find.textContaining("Total limit  \$11200.00", findRichText: true), findsOneWidget);
        expect(find.text("68%"), findsOneWidget);
    });
}
