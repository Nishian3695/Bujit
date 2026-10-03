// Mirrors NavigationItems/Visuals/VisualsActivity.java in the original Java app:
// a Cash Flow tab (income vs expenses per pay period, GROSS or NET, by year) and
// a Categories tab (per-check spending by category, with and without credit
// cards). The numbers come from VisualsData.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/money.dart';
import '../../utils/theme_helper.dart';
import '../../utils/ui.dart';
import '../../app_state.dart';
import '../../tutorial/tutorial_manager.dart';
import '../../tutorial/tutorial_overlay_layout.dart';
import '../../utils/date_utils.dart';
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

    static const List<Color> _palette = [
        Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.pink,
        Colors.indigo, Colors.brown, Colors.cyan, Colors.lime, Colors.deepOrange,
    ];

    static String _money(double value) => Money.format(value);
    static String _shortDate(DateTime date) => "${date.month}/${date.day}";

    @override
    Widget build(BuildContext context) {
        return TutorialOverlay(
            state: widget.state,
            screen: TutorialScreen.visuals,
            child: DefaultTabController(
                length: 2,
                child: Scaffold(
                    appBar: AppBar(
                        title: const Text("Visuals"),
                        bottom: const PreferredSize(
                            preferredSize: Size.fromHeight(kTextTabBarHeight),
                            child: TutorialTarget(
                                id: "visuals_tabs",
                                child: TabBar(tabs: [Tab(text: "Cash Flow"), Tab(text: "Categories")]),
                            ),
                        ),
                    ),
                    body: TabBarView(children: [_cashFlowTab(), _categoriesTab()]),
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
}
