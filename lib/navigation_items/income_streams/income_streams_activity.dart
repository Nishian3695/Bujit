// Mirrors NavigationItems/IncomeStreams/IncomeStreamsActivity.java in the original Java app:
// add, edit and delete income streams, and choose the active one (whose paydays
// set the pay periods on the home screen).
import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../dialogs/income_stream_dialog.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import '../../utils/date_utils.dart';
import '../expense_activity/balance_model.dart';
import 'income_stream_model.dart';

class IncomeStreamsActivity extends StatefulWidget {
    final AppState state;
    const IncomeStreamsActivity({super.key, required this.state});

    @override
    State<IncomeStreamsActivity> createState() => _IncomeStreamsActivityState();
}

class _IncomeStreamsActivityState extends State<IncomeStreamsActivity> {
    BalanceModel get _balance => widget.state.balance;

    Future<void> _save() async {
        setState(() {});
        await widget.state.changed();
    }

    // The first stream added becomes active, so there's always one while any exist.
    Future<void> _add() async {
        final IncomeStreamModel? stream = await showIncomeStreamDialog(context);
        if (stream == null) return;
        _balance.incomeStreams.add(stream);
        _balance.activeIncome ??= stream;
        await _save();
    }

    Future<void> _edit(int index) async {
        final IncomeStreamModel old = _balance.incomeStreams[index];
        final IncomeStreamModel? edited = await showIncomeStreamDialog(
            context,
            existing: old,
            onDelete: () => _delete(old),
        );
        if (edited == null) return;
        _balance.incomeStreams[index] = edited;
        if (identical(_balance.activeIncome, old)) _balance.activeIncome = edited;
        await _save();
    }

    // Deleting the active stream hands the role to the next one, if any.
    void _delete(IncomeStreamModel stream) {
        _balance.incomeStreams.remove(stream);
        if (identical(_balance.activeIncome, stream)) {
            _balance.activeIncome = _balance.incomeStreams.isEmpty ? null : _balance.incomeStreams.first;
        }
        _save();
    }

    Future<void> _makeActive(IncomeStreamModel stream) async {
        _balance.activeIncome = stream;
        await _save();
    }

    @override
    Widget build(BuildContext context) {
        final List<IncomeStreamModel> streams = _balance.incomeStreams;
        return TutorialOverlay(
            state: widget.state,
            screen: TutorialScreen.incomeStreams,
            child: Scaffold(
            appBar: AppBar(title: const Text("Income Streams")),
            body: TutorialTarget(id: "income_list", child: streams.isEmpty
                ? const Center(child: Text("No income streams yet. Tap + to add one."))
                : RadioGroup<IncomeStreamModel>(
                    groupValue: _balance.activeIncome,
                    onChanged: (stream) { if (stream != null) _makeActive(stream); },
                    child: ListView.builder(
                        itemCount: streams.length,
                        itemBuilder: (context, index) {
                            final IncomeStreamModel stream = streams[index];
                            final DateTime next = stream.paydayAfter(addDays(todayDate(), -1));
                            return ListTile(
                                leading: Radio<IncomeStreamModel>(value: stream),
                                title: Text(stream.name),
                                subtitle: Text("\$${stream.amount.toStringAsFixed(2)} · ${stream.displayString()}"
                                    " · next ${next.toString().split(' ')[0]}"),
                                onTap: () => _edit(index),
                            );
                        },
                    ),
                )),
            floatingActionButton: TutorialTarget(
                id: "income_add",
                child: FloatingActionButton(
                    onPressed: _add,
                    tooltip: "Add income stream",
                    child: const Icon(Icons.add),
                ),
            ),
            ),
        );
    }
}
