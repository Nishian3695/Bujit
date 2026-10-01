// Class to manage the balance of the user
import 'package:bujit/utils/frequency_unit.dart';
import 'package:bujit/navigation_items/income_streams/income_stream_model.dart';
import 'package:bujit/navigation_items/expense_activity/expense_model.dart';

class BalanceModel {
    double currentBalance;
    late double _shownBalance;
    late double _afterBalance; // Balance after the income and deductions
    DateTime lastUpdated;
    DateTime currentPeriodStart;
    DateTime currentPeriodEnd;
    late DateTime _shownPeriod, _afterPeriod;
    int projectFrequency; // Frequency in days for projecting the balance
    FrequencyUnit projectFrequencyUnits; // Tag to track frequency for projection
    List<ExpenseModel> expenses = []; // List of expenses
    List<IncomeStreamModel> incomeStreams = []; // List of income streams
    IncomeStreamModel? activeIncome; // The income stream driving projectForward()

    BalanceModel({
        required this.currentBalance,
        required this.lastUpdated,
        required this.currentPeriodStart,
        required this.currentPeriodEnd,
        required this.projectFrequency,
        required this.projectFrequencyUnits,
    }) {
        _shownBalance = currentBalance;
        _shownPeriod = currentPeriodStart;
    }

    // Methods

    // Project to period
    void projectToPeriod(DateTime start, DateTime end) {
        _shownBalance = currentBalance;
        _shownPeriod = start;
        _afterPeriod = end;
        _afterBalance = _shownBalance;
        double netBalanceChange = 0.00;

        // Update the shown balances with income
        for (IncomeStreamModel income in incomeStreams) {
            income.toPeriod(start, end);
            _shownBalance += income.catchUpAmount;
            netBalanceChange += income.periodAmount;
        }

        // Update the shown balances with expenses
        for (ExpenseModel expense in expenses) {
            expense.toPeriod(start, end);
            _shownBalance -= expense.catchUpAmount;
            netBalanceChange -= expense.periodAmount;
        }
        _afterBalance = _shownBalance + netBalanceChange;
    }

    // Make recent
    void makeRecent() {
        final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        projectToPeriod(today, currentPeriodEnd);
    }

    // Advance forward by active stream amount
    void projectForward() {
        if (activeIncome == null) {
            // TODO: Raise Toast warning
            return; // No active income stream to project forward
        }
        // Grab the active income stream's next period start
        final (DateTime, DateTime) newPeriod = activeIncome!.advancePeriod(_shownPeriod);
        _shownPeriod = newPeriod.$1;
        _afterPeriod = newPeriod.$2;

        projectToPeriod(_shownPeriod, _afterPeriod);
    }


    // Getters
    double get shownBalance => _shownBalance;
    double get afterBalance => _afterBalance;
    DateTime get shownPeriod => _shownPeriod;
    DateTime get afterPeriod => _afterPeriod;
}