// Mirrors NavigationItems/Visuals/VisualsActivity.java in the original Java app:
// a Cash Flow tab (income vs expenses per pay period, GROSS or NET, by year) and
// a Categories tab (per-check spending by category, with and without credit
// cards). Added here: a Net Balance tab (the accounts' total over time, recorded
// and projected). The numbers come from VisualsData.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/money.dart';
import '../../utils/theme_helper.dart';
import '../../utils/ui.dart';
import '../../app_state.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import '../../utils/date_utils.dart';
import '../../utils/frequency_unit.dart';
import '../expense_activity/balance_model.dart';
import '../expense_activity/credit_model.dart';
import '../expense_activity/expense_item.dart';
import '../income_streams/income_stream_model.dart';
import 'visuals_data.dart';

class VisualsActivity extends StatefulWidget {
    final AppState state;
    const VisualsActivity({super.key, required this.state});

    @override
    State<VisualsActivity> createState() => _VisualsActivityState();
}

class _VisualsActivityState extends State<VisualsActivity> {
    late final VisualsData _data = VisualsData(widget.state.balance, widget.state.data.categories);
    int _year = todayDate().year;
    bool _gross = true;
    int? _tapped; // The cash flow bar whose amounts are showing (tap a bar; tap again to hide)
    final Set<String> _hiddenAll = {};
    final Set<String> _hiddenNoCards = {};
    // The net balance chart's timeframe (how much it shows at once), whether it's
    // centered on today or starts today, and which timeframe is showing (0 = the
    // one with today in it; -1 the one before, and so on).
    int _netRangeCount = 6;
    _RangeUnit _netRangeUnit = _RangeUnit.months;
    final TextEditingController _netRangeField = TextEditingController(text: "6");
    bool _netCentered = true;
    int _netWindow = 0;
    final Set<String> _hiddenNet = {}; // Accounts left out of the net balance
    final Set<Object> _excludedNet = {}; // Expenses and income streams left out of its projection

    static const List<Color> _palette = [
        Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink,
        Colors.indigo, Colors.brown, Colors.cyan, Colors.lime, Colors.deepOrange,
    ];

    static String _money(double value) => Money.format(value);
    static String _shortDate(DateTime date) => "${date.month}/${date.day}";

    @override
    void dispose() {
        _netRangeField.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return TutorialOverlay(
            state: widget.state,
            screen: TutorialScreen.visuals,
            child: DefaultTabController(
                length: 3,
                child: Scaffold(
                    appBar: AppBar(
                        title: const Text("Visuals"),
                        bottom: const PreferredSize(
                            preferredSize: Size.fromHeight(kTextTabBarHeight),
                            child: TutorialTarget(
                                id: "visuals_tabs",
                                child: TabBar(tabs: [
                                    Tab(text: "Cash Flow"), Tab(text: "Categories"), Tab(text: "Net Balance"),
                                ]),
                            ),
                        ),
                    ),
                    body: TabBarView(children: [_cashFlowTab(), _categoriesTab(), _netBalanceTab()]),
                ),
            ),
        );
    }

    // ── Cash Flow ───────────────────────────────────────────────────────────

    Widget _cashFlowTab() {
        final List<CashFlowPeriod> periods = _data.cashFlow(_year);
        final BujitColors colors = BujitColors.of(context);
        return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
                Card(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                        child: Column(
                            children: [
                                Row(
                                    children: [
                                        IconButton(
                                            onPressed: () => setState(() { _year--; _tapped = null; }),
                                            icon: const Icon(Icons.chevron_left),
                                            tooltip: "Previous year",
                                        ),
                                        Expanded(child: Text("$_year", textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.titleLarge)),
                                        IconButton(
                                            onPressed: () => setState(() { _year++; _tapped = null; }),
                                            icon: const Icon(Icons.chevron_right),
                                            tooltip: "Next year",
                                        ),
                                    ],
                                ),
                                SegmentedButton<bool>(
                                    segments: const [
                                        ButtonSegment(value: true, label: Text("GROSS")),
                                        ButtonSegment(value: false, label: Text("NET")),
                                    ],
                                    selected: {_gross},
                                    showSelectedIcon: false,
                                    onSelectionChanged: (selection) => setState(() => _gross = selection.first),
                                ),
                                const SizedBox(height: 16),
                                TutorialTarget(id: "cash_flow_chart",
                                    child: SizedBox(height: 240, child: _cashFlowChart(periods))),
                            ],
                        ),
                    ),
                ),
                const SectionLabel("Pay periods"),
                for (final CashFlowPeriod period in periods)
                    ListTile(
                        title: Text.rich(TextSpan(children: [
                            TextSpan(text: "${shortDate(period.start)} – ${shortDate(addDays(period.end, -1))}",
                                style: RowStyles.title),
                            if (!period.isHistory)
                                TextSpan(text: "  projected", style: RowStyles.details(context)),
                        ])),
                        subtitle: Text("In ${_money(period.income)} · Out ${_money(period.expenses)}",
                            style: RowStyles.details(context)),
                        trailing: Text(_money(period.net), style: RowStyles.amount(context,
                            color: colors.forAmount(period.net))),
                    ),
            ],
        );
    }

    // As in the Java app, one bar per period filling most of its slot (70% wide in
    // GROSS, 60% in NET). GROSS: income up (green) and expenses down (red) from
    // the same bar. NET: green when income covered expenses, red when it didn't.
    // Projected periods are lighter (the Java app hatched them). Tapping a bar
    // shows its amounts.
    Widget _cashFlowChart(List<CashFlowPeriod> periods) => LayoutBuilder(builder: (context, constraints) {
        final BujitColors colors = BujitColors.of(context);
        final ColorScheme scheme = Theme.of(context).colorScheme;
        const double axisWidth = 44;
        final double slot = (constraints.maxWidth - axisWidth) / periods.length.clamp(1, 1000);
        final double width = slot * (_gross ? 0.7 : 0.6);
        final BorderRadius rounded = BorderRadius.circular((width / 6).clamp(0.0, 4.0));
        Color shade(Color color, CashFlowPeriod period) => period.isHistory ? color : color.withValues(alpha: 0.55);
        final List<BarChartGroupData> groups = [
            for (int i = 0; i < periods.length; i++)
                BarChartGroupData(
                    x: i,
                    showingTooltipIndicators: i == _tapped ? [0] : const [],
                    barRods: [
                        _gross
                            ? BarChartRodData(
                                fromY: -periods[i].expenses,
                                toY: periods[i].income,
                                width: width,
                                borderRadius: rounded,
                                color: Colors.transparent,
                                rodStackItems: [
                                    BarChartRodStackItem(-periods[i].expenses, 0, shade(colors.negative, periods[i])),
                                    BarChartRodStackItem(0, periods[i].income, shade(colors.positive, periods[i])),
                                ],
                            )
                            : BarChartRodData(
                                toY: periods[i].net,
                                width: width,
                                borderRadius: rounded,
                                color: shade(colors.forAmount(periods[i].net), periods[i]),
                            ),
                    ],
                ),
        ];
        final TextStyle axis = TextStyle(fontSize: 10, color: scheme.onSurfaceVariant);
        return BarChart(
            BarChartData(
                barGroups: groups,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                    handleBuiltInTouches: false,
                    touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) return;
                        final int? index = response?.spot?.touchedBarGroupIndex;
                        setState(() => _tapped = index == _tapped ? null : index);
                    },
                    touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => scheme.inverseSurface,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final CashFlowPeriod period = periods[group.x];
                            final String dates = "${shortDate(period.start)} – ${shortDate(addDays(period.end, -1))}";
                            return BarTooltipItem(
                                _gross
                                    ? "$dates\nIn ${_money(period.income)}\nOut ${_money(period.expenses)}"
                                    : "$dates\nNet ${_money(period.net)}",
                                TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                            );
                        },
                    ),
                ),
                gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                        color: value == 0 ? scheme.outline : scheme.outlineVariant.withValues(alpha: 0.6),
                        strokeWidth: value == 0 ? 1 : 0.5,
                    ),
                ),
                titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: axisWidth,
                        getTitlesWidget: (value, meta) {
                            // The chart's own top and bottom (e.g. 2.4K) crowd the
                            // round gridline labels next to them, so only those show.
                            final bool edge = value == meta.max || value == meta.min;
                            if (edge && value % meta.appliedInterval != 0) return const SizedBox.shrink();
                            return SideTitleWidget(meta: meta, child: Text(meta.formattedValue, style: axis));
                        },
                    )),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                                final int index = value.toInt();
                                // Label every few periods so they don't overlap.
                                final int step = (periods.length / 6).ceil().clamp(1, 1000);
                                if (index < 0 || index >= periods.length || index % step != 0) {
                                    return const SizedBox.shrink();
                                }
                                return Text(_shortDate(periods[index].start), style: axis);
                            },
                        ),
                    ),
                ),
            ),
        );
    });

    // ── Categories ──────────────────────────────────────────────────────────

    Widget _categoriesTab() {
        return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text("Spending per check (${_data.payPeriodDays.toStringAsFixed(0)}-day pay period)",
                        style: RowStyles.details(context)),
                ),
                const SectionLabel("All expenses"),
                Card(child: _pie(_data.categoryAmounts(), _hiddenAll)),
                const SectionLabel("Excluding credit cards"),
                Card(child: _pie(_data.categoryAmounts(excludeCredit: true), _hiddenNoCards)),
            ],
        );
    }

    // A pie of the visible categories, with a legend where tapping a category
    // hides or shows it (as in the Java app).
    Widget _pie(Map<String, double> amounts, Set<String> hidden) {
        if (amounts.isEmpty) {
            return const Padding(padding: EdgeInsets.all(16), child: Text("No expenses to show."));
        }
        final List<String> names = amounts.keys.toList();
        Color colorOf(String name) => _palette[names.indexOf(name) % _palette.length];
        final double total = amounts.entries
            .where((e) => !hidden.contains(e.key))
            .fold(0.0, (sum, e) => sum + e.value);
        return Column(
            children: [
                const SizedBox(height: 16),
                SizedBox(
                    height: 220,
                    child: Stack(
                        alignment: Alignment.center,
                        children: [
                            PieChart(PieChartData(
                                sections: [
                                    for (final MapEntry<String, double> entry in amounts.entries)
                                        if (!hidden.contains(entry.key))
                                            PieChartSectionData(
                                                value: entry.value,
                                                color: colorOf(entry.key),
                                                title: total > 0 && entry.value / total >= 0.05
                                                    ? "${(entry.value / total * 100).toStringAsFixed(0)}%" : "",
                                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                                    color: Colors.white),
                                                radius: 48,
                                            ),
                                ],
                                centerSpaceRadius: 58,
                                sectionsSpace: 2,
                            )),
                            // The donut's middle: the total of the categories shown.
                            Figure(label: "PER CHECK", value: _money(total)),
                        ],
                    ),
                ),
                const SizedBox(height: 8),
                for (final MapEntry<String, double> entry in amounts.entries)
                    CheckboxListTile(
                        value: !hidden.contains(entry.key),
                        secondary: Icon(Icons.circle, color: colorOf(entry.key), size: 14),
                        title: Text(entry.key, style: RowStyles.title),
                        subtitle: Text("${_money(entry.value)} per check", style: RowStyles.details(context)),
                        onChanged: (shown) => setState(() {
                            if (shown == true) {
                                hidden.remove(entry.key);
                            } else {
                                hidden.add(entry.key);
                            }
                        }),
                    ),
            ],
        );
    }

    // ── Net Balance ─────────────────────────────────────────────────────────

    // [day] moved by [count] of the timeframe's units.
    DateTime _netShift(DateTime day, int count) => switch (_netRangeUnit) {
        _RangeUnit.days => addDays(day, count),
        _RangeUnit.weeks => addDays(day, 7 * count),
        _RangeUnit.months => _addMonths(day, count),
        _RangeUnit.years => _addMonths(day, 12 * count),
    };

    // [months] months from [day], on the same day of the month or the month's last.
    static DateTime _addMonths(DateTime day, int months) {
        final DateTime first = DateTime(day.year, day.month + months, 1);
        final int last = DateTime(first.year, first.month + 1, 0).day;
        return DateTime(first.year, first.month, day.day < last ? day.day : last);
    }

    // The window on screen: one timeframe long, starting today or centered on it,
    // moved by whole timeframes with the arrows or a swipe.
    (DateTime, DateTime) _netWindowDates(DateTime today) {
        final int span = daysBetween(today, _netShift(today, _netRangeCount));
        final DateTime base = _netCentered ? addDays(today, -(span ~/ 2)) : today;
        return (_netShift(base, _netWindow * _netRangeCount), _netShift(base, (_netWindow + 1) * _netRangeCount));
    }

    void _moveNetWindow(int by) => setState(() => _netWindow += by);

    Widget _netBalanceTab() {
        final DateTime today = todayDate();
        final (DateTime start, DateTime end) = _netWindowDates(today);
        final List<NetPoint> history = _data.netHistory(DateTime(1900));
        final List<NetPoint> projection = _data.netProjection(end.isAfter(today) ? end : today,
            today: today, excluded: _excludedNet);
        // History, then the projection (its first point is today, which history
        // usually already ends on).
        final bool endsToday = history.isNotEmpty && !history.last.date.isBefore(projection.first.date);
        final List<NetPoint> points = [...history, ...projection.skip(endsToday ? 1 : 0)];
        final double? change = _netChange(points, start, end);
        final BujitColors colors = BujitColors.of(context);
        final TextStyle details = RowStyles.details(context);
        return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
                Card(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                        child: Column(
                            children: [
                                Row(
                                    children: [
                                        IconButton(
                                            onPressed: () => _moveNetWindow(-1),
                                            icon: const Icon(Icons.chevron_left),
                                            tooltip: "Previous timeframe",
                                        ),
                                        Expanded(child: Figure(
                                            label: "NET BALANCE · ${shortDate(start)} – ${shortDate(end)}",
                                            value: change == null
                                                ? "—"
                                                : "${change > 0 ? "+" : ""}${_money(change)}",
                                            color: change == null ? null : colors.forAmount(change),
                                        )),
                                        IconButton(
                                            onPressed: () => _moveNetWindow(1),
                                            icon: const Icon(Icons.chevron_right),
                                            tooltip: "Next timeframe",
                                        ),
                                    ],
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: SizedBox(height: 260, child: _netChart(points, start, end, today)),
                                ),
                                Row(
                                    children: [
                                        IconButton(
                                            onPressed: _netWindow == 0 ? null : () => setState(() => _netWindow = 0),
                                            icon: const Icon(Icons.today),
                                            tooltip: "Back to today",
                                        ),
                                        Expanded(child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                                children: [
                                                    _lineKey(dashed: false),
                                                    Text(" Recorded", style: details),
                                                    const SizedBox(width: 20),
                                                    _lineKey(dashed: true),
                                                    Text(" Projected", style: details),
                                                ],
                                            ),
                                        )),
                                        IconButton(
                                            onPressed: _openNetSettings,
                                            icon: const Icon(Icons.tune),
                                            tooltip: "Chart settings",
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                ),
                Card(child: _includedItems(history)),
            ],
        );
    }

    // How the net balance moved over [start]..[end]: from the balance going into
    // the window (or its first point, if nothing came before) to its last point.
    // Null when nothing in it is known.
    double? _netChange(List<NetPoint> points, DateTime start, DateTime end) {
        NetPoint? first;
        NetPoint? last;
        for (final NetPoint p in points) {
            if (p.date.isAfter(end)) break;
            if (!p.date.isAfter(start) || first == null) first = p;
            last = p;
        }
        if (first == null || last == null || last.date.isBefore(start)) return null;
        return last.total(_hiddenNet) - first.total(_hiddenNet);
    }

    // The chart's settings: the timeframe (any number of days, weeks, months or
    // years, up to ten years) and whether it's centered on today or starts today.
    // Changes apply as they're made and go back to the window with today in it.
    void _openNetSettings() {
        showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, setSheet) {
                void update(VoidCallback change) {
                    setState(() {
                        change();
                        _netWindow = 0;
                    });
                    setSheet(() {});
                }
                final bool one = _netRangeCount == 1;
                return Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(sheetContext).bottom),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text("Chart settings", style: Theme.of(sheetContext).textTheme.titleMedium),
                            const SizedBox(height: 16),
                            Row(
                                children: [
                                    const Expanded(child: Text("Timeframe", overflow: TextOverflow.ellipsis)),
                                    // Dropped a little so its outline's top edge isn't clipped.
                                    Padding(padding: const EdgeInsets.only(top: 4), child: SizedBox(
                                        width: 56,
                                        child: TextField(
                                            controller: _netRangeField,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            textAlign: TextAlign.center,
                                            maxLength: 4,
                                            decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                                border: OutlineInputBorder(),
                                                counterText: "",
                                            ),
                                            onChanged: (text) {
                                                final int? count = int.tryParse(text);
                                                if (count == null || count < 1) return;
                                                update(() => _netRangeCount = count.clamp(1, _netRangeUnit.max));
                                            },
                                        ),
                                    )),
                                    const SizedBox(width: 12),
                                    DropdownButton<_RangeUnit>(
                                        value: _netRangeUnit,
                                        underline: const SizedBox.shrink(),
                                        items: [
                                            for (final _RangeUnit unit in _RangeUnit.values)
                                                DropdownMenuItem(value: unit,
                                                    child: Text(one ? unit.singular : unit.name)),
                                        ],
                                        onChanged: (unit) => update(() {
                                            _netRangeUnit = unit!;
                                            if (_netRangeCount > unit.max) {
                                                _netRangeCount = unit.max;
                                                _netRangeField.text = "${unit.max}";
                                            }
                                        }),
                                    ),
                                ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                                width: double.infinity,
                                child: SegmentedButton<bool>(
                                    segments: const [
                                        ButtonSegment(value: true, label: Text("Centered on Today")),
                                        ButtonSegment(value: false, label: Text("Starting from Today")),
                                    ],
                                    selected: {_netCentered},
                                    showSelectedIcon: false,
                                    onSelectionChanged: (selection) => update(() => _netCentered = selection.first),
                                ),
                            ),
                        ],
                    ),
                );
            }),
        );
    }

    // The folded list of what the net balance includes: every account (in the
    // history and the projection) and every income stream and expense (in the
    // projection only -- nothing per item was recorded).
    Widget _includedItems(List<NetPoint> history) {
        final List<NetLegendItem> accounts = _data.netLegend(history);
        final List<IncomeStreamModel> streams = widget.state.balance.incomeStreams;
        final List<ExpenseItem> expenses = [
            for (final ExpenseItem e in widget.state.balance.expenses)
                if (e is! CreditModel && !e.hasEnded) e,
        ];
        final int total = accounts.length + streams.length + expenses.length;
        final int left = accounts.where((a) => _hiddenNet.contains(a.key)).length
            + streams.where(_excludedNet.contains).length
            + expenses.where(_excludedNet.contains).length;
        final TextStyle details = RowStyles.details(context);
        Widget check({required bool value, required String title, required String subtitle,
                required void Function(bool shown) onChanged, IconData? icon}) =>
            CheckboxListTile(
                value: value,
                dense: true,
                secondary: icon == null ? null : Icon(icon),
                title: Text(title, style: RowStyles.title),
                subtitle: Text(subtitle, style: details),
                onChanged: (shown) => setState(() => onChanged(shown == true)),
            );
        void toggle<T>(Set<T> set, T item, bool shown) => shown ? set.remove(item) : set.add(item);
        return ExpansionTile(
            key: const PageStorageKey("net_included_items"),
            shape: const Border(),
            title: const Text("Included items", style: RowStyles.title),
            subtitle: Text(left == 0 ? "All $total included" : "${total - left} of $total included",
                style: details),
            children: [
                const SectionLabel("Accounts", padding: EdgeInsets.fromLTRB(16, 4, 16, 2)),
                for (final NetLegendItem item in accounts)
                    check(
                        value: !_hiddenNet.contains(item.key),
                        icon: _netIcon(item.key),
                        title: item.name,
                        subtitle: item.amount == null ? "No longer tracked" : _money(item.amount!),
                        onChanged: (shown) => toggle(_hiddenNet, item.key, shown),
                    ),
                if (streams.isNotEmpty || expenses.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text("Recurring items change only the projection.", style: details),
                    ),
                if (streams.isNotEmpty) const SectionLabel("Income", padding: EdgeInsets.fromLTRB(16, 12, 16, 2)),
                for (final IncomeStreamModel stream in streams)
                    check(
                        value: !_excludedNet.contains(stream),
                        icon: Icons.payments_outlined,
                        title: stream.name,
                        subtitle: "${_money(stream.amount)} · ${stream.displayString()}",
                        onChanged: (shown) => toggle<Object>(_excludedNet, stream, shown),
                    ),
                if (expenses.isNotEmpty) const SectionLabel("Expenses", padding: EdgeInsets.fromLTRB(16, 12, 16, 2)),
                for (final ExpenseItem expense in expenses)
                    check(
                        value: !_excludedNet.contains(expense),
                        icon: Icons.receipt_long_outlined,
                        title: expense.name,
                        subtitle: "${_money(expense.amount)} · "
                            "${describeFrequency(expense.frequency, expense.frequencyUnits, days: expense.monthDays)}",
                        onChanged: (shown) => toggle<Object>(_excludedNet, expense, shown),
                    ),
                const SizedBox(height: 8),
            ],
        );
    }

    static IconData _netIcon(String key) {
        if (key == BalanceModel.balanceKey) return Icons.account_balance_wallet_outlined;
        if (key.startsWith("card:")) return Icons.credit_card;
        if (key.startsWith("linked:")) return Icons.account_balance_outlined;
        return Icons.savings_outlined;
    }

    // A short solid or dashed stroke, for the chart's key.
    Widget _lineKey({required bool dashed}) => CustomPaint(
        size: const Size(22, 10),
        painter: _LineKeyPainter(Theme.of(context).colorScheme.onSurfaceVariant, dashed),
    );

    // The selected accounts' total over [start]..[end]: recorded history solid
    // up to today, then the projection dashed. Each segment is its own line so it
    // can have its own color: green when it rises or holds level, red when it
    // drops. A dot on
    // each point takes the color of the segment leading to it (when there's room
    // for dots); the first point has nothing before it, so it's green. Days are
    // counted from a fixed date so everything shares the x axis.
    Widget _netChart(List<NetPoint> points, DateTime start, DateTime end, DateTime today) =>
        LayoutBuilder(builder: (context, constraints) =>
            _netLineChart(points, start, end, today, constraints.maxWidth));

    Widget _netLineChart(List<NetPoint> points, DateTime start, DateTime end, DateTime today, double width) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final BujitColors colors = BujitColors.of(context);
        final DateTime origin = DateTime(2000);
        double x(DateTime date) => daysBetween(origin, date).toDouble();
        final List<FlSpot> spots = [for (final NetPoint p in points) FlSpot(x(p.date), p.total(_hiddenNet))];
        // The segment into point [i]: green unless it drops (by more than rounding).
        Color colorTo(int i) => spots[i].y >= spots[i - 1].y - 0.005 ? colors.positive : colors.negative;
        final double minX = x(start);
        final double maxX = x(end);
        // The points in the window, plus one either side so the line runs off its edges.
        int from = spots.indexWhere((s) => s.x >= minX);
        int to = spots.lastIndexWhere((s) => s.x <= maxX);
        if (from < 0) from = spots.length;
        from = from > 0 ? from - 1 : 0;
        to = to < spots.length - 1 ? to + 1 : to;
        // A little room above and below, so the highest and lowest dots aren't cut off.
        final Iterable<double> ys = [for (int i = from; i <= to && i < spots.length; i++) spots[i].y];
        final double? low = ys.isEmpty ? null : ys.reduce((a, b) => a < b ? a : b);
        final double? high = ys.isEmpty ? null : ys.reduce((a, b) => a > b ? a : b);
        final double pad = low == null ? 0 : (high! - low > 0 ? (high - low) * 0.08 : 10);
        // Dots sized to the room between points, and left off when they'd run together.
        const double axisWidth = 44;
        final int places = {for (final FlSpot s in spots) if (s.x >= minX && s.x <= maxX) s.x}.length;
        final double dotRadius = places == 0 ? 0.0 : ((width - axisWidth) / places / 4).clamp(0.0, 3.5);
        final bool dots = dotRadius >= 1.5;
        FlDotPainter dot(Color color) => FlDotCirclePainter(radius: dotRadius, color: color, strokeWidth: 0);
        final List<LineChartBarData> segments = [
            for (int i = from + 1; i <= to; i++)
                LineChartBarData(
                    spots: [spots[i - 1], spots[i]],
                    color: colorTo(i),
                    barWidth: 2.5,
                    dashArray: spots[i].x > x(today) ? const [6, 4] : null,
                    dotData: const FlDotData(show: false),
                ),
            // The dots go on an invisible line drawn last, so no segment covers them.
            if (from <= to)
                LineChartBarData(
                    spots: spots.sublist(from, to + 1),
                    color: Colors.transparent,
                    barWidth: 0,
                    dotData: FlDotData(
                        show: dots || spots.length == 1,
                        getDotPainter: (spot, percent, bar, index) =>
                            dot(from + index == 0 ? colors.positive : colorTo(from + index)),
                    ),
                ),
        ];
        final TextStyle axis = TextStyle(fontSize: 10, color: scheme.onSurfaceVariant);
        return LineChart(
            LineChartData(
                minX: minX,
                maxX: maxX,
                minY: low == null ? null : low - pad,
                maxY: high == null ? null : high + pad,
                lineBarsData: segments,
                clipData: const FlClipData.horizontal(),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(verticalLines: [
                    if (x(today) >= minX && x(today) <= maxX)
                        VerticalLine(x: x(today), color: scheme.outline, strokeWidth: 1, dashArray: const [2, 3]),
                ]),
                lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => scheme.inverseSurface,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (touched) {
                            // Neighboring segments share their end points: list each point once.
                            final Set<(double, double)> shown = {};
                            return [
                                for (final LineBarSpot spot in touched)
                                    shown.add((spot.x, spot.y))
                                        ? LineTooltipItem(
                                            "${shortDate(addDays(origin, spot.x.round()))}"
                                            "${spot.x > x(today) ? " (projected)" : ""}\n${_money(spot.y)}",
                                            TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                                        )
                                        : null,
                            ];
                        },
                    ),
                ),
                gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                        color: value == 0 ? scheme.outline : scheme.outlineVariant.withValues(alpha: 0.6),
                        strokeWidth: value == 0 ? 1 : 0.5,
                    ),
                ),
                titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: axisWidth,
                        getTitlesWidget: (value, meta) {
                            // As in the cash flow chart: only round values at the edges.
                            final bool edge = value == meta.max || value == meta.min;
                            if (edge && value % meta.appliedInterval != 0) return const SizedBox.shrink();
                            return SideTitleWidget(meta: meta, child: Text(meta.formattedValue, style: axis));
                        },
                    )),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: ((maxX - minX) / 4).clamp(1.0, double.infinity),
                            getTitlesWidget: (value, meta) {
                                // The chart's own ends crowd the evenly spaced labels.
                                if (value == meta.max || value == meta.min) return const SizedBox.shrink();
                                return SideTitleWidget(meta: meta,
                                    child: Text(_shortDate(addDays(origin, value.round())), style: axis));
                            },
                        ),
                    ),
                ),
            ),
        );
    }
}

// How the net balance chart's range is counted, and the most of each (ten years).
enum _RangeUnit {
    days(3653), weeks(522), months(120), years(10);

    final int max;
    const _RangeUnit(this.max);

    String get singular => name.substring(0, name.length - 1);
}

class _LineKeyPainter extends CustomPainter {
    final Color color;
    final bool dashed;
    const _LineKeyPainter(this.color, this.dashed);

    @override
    void paint(Canvas canvas, Size size) {
        final Paint paint = Paint()
            ..color = color
            ..strokeWidth = 2.5;
        final double y = size.height / 2;
        if (!dashed) {
            canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
            return;
        }
        for (double start = 0; start < size.width; start += 10) {
            canvas.drawLine(Offset(start, y), Offset((start + 6).clamp(0, size.width), y), paint);
        }
    }

    @override
    bool shouldRepaint(_LineKeyPainter old) => old.color != color || old.dashed != dashed;
}
