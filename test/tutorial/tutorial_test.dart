// The guided tutorial: steps in order, Next/Skip, moving between screens, replay.
import 'package:bujit/app_state.dart';
import 'package:bujit/navigation_items/expense_activity/balance_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_activity.dart';
import 'package:bujit/navigation_items/screens.dart';
import 'package:bujit/storage_management/app_data_store.dart';
import 'package:bujit/tutorial/tutorial_manager.dart';
import 'package:bujit/utils/sample_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AppState _freshState({int step = 0}) {
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.0), tutorialStep: step);
    seedSampleData(data.balance);
    return AppState(data);
}

Future<AppState> _pumpHome(WidgetTester tester, {int step = 0}) async {
    final AppState state = _freshState(step: step);
    await tester.pumpWidget(MaterialApp(home: ExpenseActivity(state: state)));
    await tester.pumpAndSettle(); // the spotlight measures its target after the first frame
    return state;
}

void main() {
    testWidgets("a fresh start shows the first step", (tester) async {
        await _pumpHome(tester);

        expect(find.text("Navigate pay periods"), findsOneWidget);
        expect(find.text("Next"), findsOneWidget);
        expect(find.text("Skip"), findsOneWidget);
    });

    testWidgets("Next moves through the steps", (tester) async {
        final AppState state = await _pumpHome(tester);
        await tester.tap(find.text("Next"));
        await tester.pumpAndSettle();

        expect(state.data.tutorialStep, 1);
        expect(find.text("Balance at a glance"), findsOneWidget);
        expect(find.text("Navigate pay periods"), findsNothing);
    });

    testWidgets("Skip ends the tutorial", (tester) async {
        final AppState state = await _pumpHome(tester);
        await tester.tap(find.text("Skip"));
        await tester.pumpAndSettle();

        expect(state.data.tutorialSeen, isTrue);
        expect(find.text("Navigate pay periods"), findsNothing);
        // The screen underneath works again.
        await tester.tap(find.byTooltip("Next check"));
        await tester.pump();
        expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets("the menu step opens Income Streams, which shows its own step", (tester) async {
        final int menuStep = TutorialManager.steps.indexWhere((s) => s.targetId == "menu_button");
        await _pumpHome(tester, step: menuStep);
        expect(find.text("Navigation menu"), findsOneWidget);

        await tester.tap(find.text("Next"));
        await tester.pumpAndSettle();

        expect(find.text("Income Streams"), findsWidgets); // the screen's title and the step's
        expect(find.textContaining("The active stream"), findsOneWidget);
        expect(find.text("Main Job"), findsOneWidget);
    });

    testWidgets("Single Events shows examples during its step only", (tester) async {
        final int eventsStep = TutorialManager.steps.indexWhere((s) => s.targetId == "single_events_list");
        final int beforeEvents = eventsStep - 1; // The step that opens Single Events
        final AppState state = _freshState(step: beforeEvents);
        await tester.pumpWidget(MaterialApp(home: screenFor(TutorialManager.steps[beforeEvents].screen, state)));
        await tester.pumpAndSettle();
        expect(find.text("Spontaneous concert tickets"), findsNothing);

        await tester.tap(find.text("Next"));
        await tester.pumpAndSettle();

        expect(find.text("Spontaneous concert tickets"), findsOneWidget);
        expect(state.data.singleEvents, isEmpty); // not saved
        expect(state.balance.currentBalance, 3500.0); // not applied
    });

    testWidgets("the screen keeps its state when the overlay comes and goes", (tester) async {
        final AppState state = _freshState()..data.tutorialSeen = true;
        await tester.pumpWidget(MaterialApp(home: ExpenseActivity(state: state)));
        await tester.tap(find.byTooltip("Next check"));
        await tester.pump();
        expect(find.byIcon(Icons.home), findsOneWidget);

        await state.replayTutorial();
        await tester.pumpAndSettle();
        expect(find.text("Navigate pay periods"), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget); // still on the projected check
    });

    testWidgets("replaying starts over", (tester) async {
        final AppState state = _freshState(step: 5)..data.tutorialSeen = true;
        await state.replayTutorial();

        expect(state.data.tutorialStep, 0);
        expect(state.tutorialStep!.title, "Navigate pay periods");
    });

    test("finishing the last step marks the tutorial seen", () async {
        final AppState state = _freshState(step: TutorialManager.steps.length - 1);
        await state.advanceTutorial();

        expect(state.data.tutorialSeen, isTrue);
        expect(state.tutorialStep, isNull);
    });
}
