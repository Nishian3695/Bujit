// Settings' data and display features: comma separators, categories, clearing
// all data, and the app lock.
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/banking/manual_account_model.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_activity.dart';
import 'package:bujit/navigation_items/settings/category_manager_activity.dart';
import 'package:bujit/navigation_items/settings/settings_activity.dart';
import 'package:bujit/prefs/app_lock_prefs.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/utils/money.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppState _sampleState() {
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.0), tutorialSeen: true);
    seedSampleData(data.balance);
    return AppState(data);
}

class FakeDeviceAuth implements DeviceAuth {
    bool available = true;
    bool succeed = true;
    int asked = 0;

    @override
    Future<bool> isAvailable() async => available;
    @override
    Future<bool> authenticate(String reason) async {
        asked++;
        return succeed;
    }
}

void main() {
    tearDown(() => Money.useCommaSeparators = false);

    group("money formatting", () {
        test("plain and with comma separators", () {
            expect(Money.format(1234567.5), "\$1234567.50");
            expect(Money.format(-5110.0), "\$-5110.00");
            Money.useCommaSeparators = true;
            expect(Money.format(1234567.5), "\$1,234,567.50");
            expect(Money.format(-5110.0), "\$-5,110.00");
            expect(Money.format(999.999), "\$1,000.00");
            expect(Money.format(-0.001), "\$0.00");
        });

        testWidgets("the setting changes amounts on the home screen", (tester) async {
            final AppState state = _sampleState();
            await tester.pumpWidget(MaterialApp(home: ExpenseActivity(state: state)));
            expect(find.text("\$3500.00"), findsOneWidget);

            state.data.useCommaSeparators = true;
            await state.changed();
            await tester.pump();

            expect(find.text("\$3,500.00"), findsOneWidget);
            expect(find.text("\$-5,125.99"), findsOneWidget);
        });
    });

    group("categories", () {
        test("names are unique ignoring case, and Other is built in", () {
            final AppData data = _sampleState().data;
            expect(data.hasCategory("housing"), isTrue);
            expect(data.hasCategory("OTHER"), isTrue);
            expect(data.hasCategory("Pets"), isFalse);
        });

        test("removing one moves its expenses to Other", () {
            final AppData data = _sampleState().data;
            data.removeCategory("Housing");

            expect(data.categories, isNot(contains("Housing")));
            expect(data.balance.expenses.firstWhere((e) => e.name == "Rent").category, "Other");
        });

        testWidgets("the manager adds, rejects duplicates and removes", (tester) async {
            final AppState state = _sampleState();
            await tester.pumpWidget(MaterialApp(home: CategoryManagerActivity(state: state)));

            await tester.tap(find.byTooltip("Add category"));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField), "food");
            await tester.tap(find.text("Add"));
            await tester.pumpAndSettle();
            expect(find.text("Category already exists"), findsOneWidget);
            await tester.enterText(find.byType(TextField), "Pets");
            await tester.tap(find.text("Add"));
            await tester.pumpAndSettle();
            expect(state.data.categories.last, "Pets");

            await tester.tap(find.byTooltip("Remove Housing"));
            await tester.pumpAndSettle();
            expect(find.textContaining("will show as \"Other\""), findsOneWidget);
            await tester.tap(find.text("Remove"));
            await tester.pumpAndSettle();
            expect(state.data.categories, isNot(contains("Housing")));
            expect(state.balance.expenses.firstWhere((e) => e.name == "Rent").category, "Other");
        });
    });

    test("clearing all data resets settings and starts the tutorial over", () async {
        final AppState state = _sampleState();
        state.data
            ..includeNextCheck = true
            ..useCommaSeparators = true
            ..appLockEnabled = true
            ..categories.add("Pets");
        state.balance.manualAccounts.add(ManualAccountModel(name: "Savings", balance: 10.0));
        state.balance.expenses.clear();

        await state.clearAllData();

        expect(state.balance.expenses, isNotEmpty); // the sample data
        expect(state.balance.manualAccounts, isEmpty);
        expect(state.data.categories, isNot(contains("Pets")));
        expect(state.data.includeNextCheck, isFalse);
        expect(state.data.useCommaSeparators, isFalse);
        expect(state.data.appLockEnabled, isFalse);
        expect(state.data.tutorialSeen, isFalse);
        expect(state.data.tutorialStep, 0);
    });

    group("app lock", () {
        testWidgets("turning it on needs a screen lock and a successful unlock", (tester) async {
            final AppState state = _sampleState();
            final FakeDeviceAuth auth = FakeDeviceAuth()..available = false;
            state.deviceAuth = auth;
            await tester.pumpWidget(MaterialApp(home: SettingsActivity(state: state)));
            await tester.scrollUntilVisible(find.text("App lock"), 200);
            await tester.ensureVisible(find.text("App lock"));
            await tester.pumpAndSettle();

            await tester.tap(find.text("App lock"));
            await tester.pumpAndSettle();
            expect(state.data.appLockEnabled, isFalse);
            expect(find.textContaining("No screen lock set up"), findsOneWidget);

            auth
                ..available = true
                ..succeed = false;
            await tester.tap(find.text("App lock"));
            await tester.pumpAndSettle();
            expect(state.data.appLockEnabled, isFalse);

            auth.succeed = true;
            await tester.tap(find.text("App lock"));
            await tester.pumpAndSettle();
            expect(state.data.appLockEnabled, isTrue);
        });

        testWidgets("when on, the app opens locked and locks again after the background", (tester) async {
            final AppState state = _sampleState()..data.appLockEnabled = true;
            final FakeDeviceAuth auth = FakeDeviceAuth()..succeed = false;
            await tester.pumpWidget(MaterialApp(
                home: ExpenseActivity(state: state),
                builder: (context, child) => AppLockGate(state: state, auth: auth, child: child!),
            ));
            await tester.pumpAndSettle();
            expect(find.text("Bujit is locked"), findsOneWidget);
            expect(auth.asked, 1); // asked straight away

            auth.succeed = true;
            await tester.tap(find.text("Unlock"));
            await tester.pumpAndSettle();
            expect(find.text("Bujit is locked"), findsNothing);

            // To the background and back (no frames are drawn while it's away).
            auth.succeed = false;
            for (final AppLifecycleState lifecycle in const [AppLifecycleState.inactive, AppLifecycleState.hidden,
                    AppLifecycleState.paused, AppLifecycleState.hidden, AppLifecycleState.inactive,
                    AppLifecycleState.resumed]) {
                tester.binding.handleAppLifecycleStateChanged(lifecycle);
            }
            await tester.pumpAndSettle();
            expect(auth.asked, 3); // asked again on coming back
            expect(find.text("Bujit is locked"), findsOneWidget);

            auth.succeed = true;
            await tester.tap(find.text("Unlock"));
            await tester.pumpAndSettle();
            expect(find.text("Bujit is locked"), findsNothing);
        });

        testWidgets("when off, nothing is locked", (tester) async {
            final AppState state = _sampleState();
            await tester.pumpWidget(MaterialApp(
                home: ExpenseActivity(state: state),
                builder: (context, child) => AppLockGate(state: state, auth: FakeDeviceAuth(), child: child!),
            ));
            tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
            await tester.pump();
            expect(find.text("Bujit is locked"), findsNothing);
        });
    });
}
