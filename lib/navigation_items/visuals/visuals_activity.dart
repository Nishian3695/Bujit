// Mirrors NavigationItems/Visuals/VisualsActivity.java in the original Java app:
// a Cash Flow tab (income vs expenses per pay period, GROSS or NET, by year) and
// a Categories tab (per-check spending by category, with and without credit
// cards). The numbers come from VisualsData; styling is a placeholder.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/money.dart';
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
        return ListView(
            padding: const EdgeInsets.all(12),
            children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        IconButton(
                            onPressed: () => setState(() => _year--),
                            icon: const Icon(Icons.chevron_left),
                            tooltip: "Previous year",
                        ),
                        Text("$_year"),
                        IconButton(
                            onPressed: () => setState(() => _year++),
                            icon: const Icon(Icons.chevron_right),
                            tooltip: "Next year",
                        ),
                    ],
                ),
                Center(
                    child: SegmentedButton<bool>(
                        segments: const [
                            ButtonSegment(value: true, label: Text("GROSS")),
                            ButtonSegment(value: false, label: Text("NET")),
                        ],
                        selected: {_gross},
                        onSelectionChanged: (selection) => setState(() => _gross = selection.first),
                    ),
                ),
                TutorialTarget(id: "cash_flow_chart", child: SizedBox(height: 260, child: _cashFlowChart(periods))),
                const Divider(),
                for (final CashFlowPeriod period in periods)
                    ListTile(
                        dense: true,
                        title: Text("${_shortDate(period.start)} – ${_shortDate(addDays(period.end, -1))}"
                            "${period.isHistory ? "" : " (projected)"}"),
                        subtitle: Text("In ${_money(period.income)} · Out ${_money(period.expenses)}"),
                        trailing: Text(_money(period.net),
                            style: TextStyle(color: period.net >= 0 ? Colors.green : Colors.red)),
                    ),
            ],
        );
    }

    // GROSS: income up (green) and expenses down (red) per period. NET: one bar,
    // green when income covered expenses, red when it didn't.
    Widget _cashFlowChart(List<CashFlowPeriod> periods) {
        final List<BarChartGroupData> groups = [
            for (int i = 0; i < periods.length; i++)
                BarChartGroupData(
                    x: i,
                    barRods: _gross
                        ? [
                            BarChartRodData(toY: periods[i].income, color: Colors.green, width: 4),
                            BarChartRodData(toY: -periods[i].expenses, color: Colors.red, width: 4),
                        ]
                        : [
                            BarChartRodData(
                                toY: periods[i].net,
                                color: periods[i].net >= 0 ? Colors.green : Colors.red,
                                width: 6,
                            ),
                        ],
                ),
        ];
        return BarChart(
            BarChartData(
                barGroups: groups,
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48)),
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
                                return Text(_shortDate(periods[index].start), style: const TextStyle(fontSize: 10));
                            },
                        ),
                    ),
                ),
            ),
        );
    }

    // ── Categories ──────────────────────────────────────────────────────────

    Widget _categoriesTab() {
        return ListView(
            padding: const EdgeInsets.all(12),
            children: [
                Text("Spending per check (${_data.payPeriodDays.toStringAsFixed(0)}-day pay period)"),
                const SizedBox(height: 8),
                const Text("All expenses"),
                _pie(_data.categoryAmounts(), _hiddenAll),
                const Divider(),
                const Text("Excluding credit cards"),
                _pie(_data.categoryAmounts(excludeCredit: true), _hiddenNoCards),
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
                SizedBox(
                    height: 200,
                    child: PieChart(PieChartData(
                        sections: [
                            for (final MapEntry<String, double> entry in amounts.entries)
                                if (!hidden.contains(entry.key))
                                    PieChartSectionData(
                                        value: entry.value,
                                        color: colorOf(entry.key),
                                        title: total > 0 ? "${(entry.value / total * 100).toStringAsFixed(0)}%" : "",
                                        radius: 70,
                                    ),
                        ],
                        centerSpaceRadius: 0,
                    )),
                ),
                for (final MapEntry<String, double> entry in amounts.entries)
                    CheckboxListTile(
                        dense: true,
                        value: !hidden.contains(entry.key),
                        secondary: Icon(Icons.circle, color: colorOf(entry.key), size: 14),
                        title: Text(entry.key),
                        subtitle: Text("${_money(entry.value)} per check"),
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
