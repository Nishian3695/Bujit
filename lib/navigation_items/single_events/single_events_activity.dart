// Mirrors NavigationItems/SingleEvents/SingleEventsActivity.java in the original Java app:
// one-off debits/credits applied immediately to the balance or a credit card.
// Effects are applied through SingleEventsLedger.
import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../dialogs/single_event_dialog.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import 'single_event_model.dart';
import 'single_events_ledger.dart';

class SingleEventsActivity extends StatefulWidget {
    final AppState state;
    const SingleEventsActivity({super.key, required this.state});

    @override
    State<SingleEventsActivity> createState() => _SingleEventsActivityState();
}

class _SingleEventsActivityState extends State<SingleEventsActivity> {
    SingleEventsLedger get _ledger => widget.state.data.singleEventsLedger;

    Future<void> _save() async {
        setState(() {});
        await widget.state.changed();
    }

    Future<void> _add() async {
        final SingleEventModel? draft = await showSingleEventDialog(
            context, cardNames: _ledger.cardNames.toList());
        if (draft == null) return;
        _ledger.add(draft);
        await _save();
    }

    Future<void> _edit(SingleEventModel event) async {
        final SingleEventModel? draft = await showSingleEventDialog(
            context,
            existing: event,
            cardNames: _ledger.cardNames.toList(),
            onRemove: () {
                _ledger.remove(event);
                _save();
            },
        );
        if (draft == null) return;
        _ledger.update(
            event,
            name: draft.name,
            amount: draft.amount,
            isDebit: draft.isDebit,
            target: draft.target,
            targetName: draft.targetName,
        );
        await _save();
    }

    // Shown (not applied or saved) while the tutorial is on this screen and the
    // list is empty, so it has something to point at -- the Java app's examples.
    static final List<SingleEventModel> _tutorialExamples = [
        SingleEventModel(name: "Spontaneous concert tickets", amount: 85.00, isDebit: true),
        SingleEventModel(name: "Won trivia night 🎉", amount: 50.00, isDebit: false),
        SingleEventModel(name: "Forgot to pack lunch", amount: 12.75, isDebit: true),
    ];

    @override
    Widget build(BuildContext context) {
        final List<SingleEventModel> saved = widget.state.data.singleEvents;
        final bool showExamples = saved.isEmpty
            && widget.state.tutorialStep?.screen == TutorialScreen.singleEvents;
        final List<SingleEventModel> events = showExamples ? _tutorialExamples : saved;
        final int expiryDays = widget.state.data.singleEventExpiryDays;
        return TutorialOverlay(
            state: widget.state,
            screen: TutorialScreen.singleEvents,
            child: Scaffold(
            appBar: AppBar(title: const Text("Single Events")),
            body: TutorialTarget(id: "single_events_list", child: events.isEmpty
                ? const Center(child: Text("No single events. Tap + to add a one-off expense or windfall."))
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                        final SingleEventModel event = events[index];
                        final String sign = event.isDebit ? "-" : "+";
                        final int daysLeft = event.daysUntilExpiry(expiryDays);
                        return ListTile(
                            title: Text(event.name),
                            subtitle: Text("${event.targetDisplayName} · clears in $daysLeft "
                                "day${daysLeft == 1 ? "" : "s"}"),
                            trailing: Text("$sign\$${event.amount.toStringAsFixed(2)}"),
                            onTap: showExamples ? null : () => _edit(event),
                        );
                    },
                )),
            floatingActionButton: FloatingActionButton(
                onPressed: _add,
                tooltip: "Add single event",
                child: const Icon(Icons.add),
            ),
            ),
        );
    }
}
