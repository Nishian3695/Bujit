package io.github.nishian3695.bujit.NavigationItems.Visuals;

import android.content.res.TypedArray;
import android.graphics.Color;
import android.os.Bundle;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RadioGroup;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import android.widget.TextView;
import com.github.mikephil.charting.charts.BarChart;
import com.github.mikephil.charting.charts.HorizontalBarChart;
import com.github.mikephil.charting.components.MarkerView;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.data.BarData;
import com.github.mikephil.charting.data.BarDataSet;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter;
import com.github.mikephil.charting.formatter.ValueFormatter;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.listener.ChartTouchListener;
import com.github.mikephil.charting.listener.OnChartGestureListener;
import com.github.mikephil.charting.utils.MPPointF;
import android.view.MotionEvent;
import java.util.function.BiFunction;
import com.google.android.material.tabs.TabLayout;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamModel;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.ThemeHelper;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/*
Displays two chart views for the user's financial data.

Cash Flow tab — a 12-month BarChart (5 months back, current month, 6 months forward).
  Green bars go upward for income (from income streams); red bars go downward for all
  expenses (both regular and credit-card entries). A GROSS/NET toggle is provided:
  GROSS shows both bars stacked from the zero line for each month; NET collapses them
  into a single bar (green = income > expenses, red = expenses > income).

Categories tab — a HorizontalBarChart grouping expenses by inferred category using
  keyword matching on the expense name. Each bar shows the estimated monthly cost
  for that category. Plaid transaction-level categorization is a future enhancement.
*/
public class VisualsActivity extends AppCompatActivity {

    // Category definitions: {name, comma-separated keywords}
    private static final String[][] CATEGORY_RULES = {
        {"Housing",       "rent,mortgage,hoa,lease"},
        {"Food",          "food,grocery,groceries,restaurant,dining,doordash,ubereats,grubhub,meal,coffee"},
        {"Transport",     "car,gas,fuel,uber,lyft,transit,bus,train,parking,auto,vehicle"},
        {"Entertainment", "netflix,hulu,disney+,disney,spotify,apple,youtube,gaming,game,movie,music,streaming"},
        {"Utilities",     "electric,electricity,water,internet,phone,utility,utilities,cell,cable,broadband"},
        {"Healthcare",    "doctor,dental,medical,health,pharmacy,prescription,gym,fitness"},
        {"Shopping",      "amazon,shopping,clothes,clothing,target,walmart"},
        {"Subscriptions", "subscription,membership,club"},
    };

    private static final String[] CATEGORY_ORDER = {
        "Housing", "Food", "Transport", "Entertainment",
        "Utilities", "Healthcare", "Shopping", "Subscriptions",
        "Credit Cards", "Other",
    };

    private ArrayList<ExpenseModel>      expenseList;
    private ArrayList<IncomeStreamModel> incomeList;
    private BarChart             cashFlowChart;
    private HorizontalBarChart   categoriesChart;
    private View                 cashFlowPanel;
    private View                 categoriesPanel;
    private View                 legendExpensesRow;
    private View                 legendIncomeSwatch;
    private TextView             legendIncomeLabel;
    private String[]             categoryAxisLabels  = new String[0];
    private float[]              grossIncomeTotals      = new float[0];
    private float[]              grossExpenseTotals     = new float[0];
    private boolean              grossLastTapWasExpense = false;
    private int                  yearOffset    = 0;
    private boolean              isGrossMode   = true;
    private TextView             tvPeriodRange;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        ThemeHelper.applyAccentTheme(this);
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_visuals);
        ThemeHelper.tintActionBar(this);

        ViewCompat.setOnApplyWindowInsetsListener(
                ((ViewGroup) findViewById(android.R.id.content)).getChildAt(0),
                (v, insets) -> {
                    Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
                    v.setPadding(0, bars.top, 0, bars.bottom);
                    return WindowInsetsCompat.CONSUMED;
                });

        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("Visuals");
        }

        //noinspection unchecked
        expenseList = (ArrayList<ExpenseModel>) getIntent().getSerializableExtra("expenseList");
        if (expenseList == null) expenseList = new ArrayList<>();
        //noinspection unchecked
        incomeList = (ArrayList<IncomeStreamModel>) getIntent().getSerializableExtra("incomeList");
        if (incomeList == null) incomeList = new ArrayList<>();

        cashFlowChart    = findViewById(R.id.cash_flow_chart);
        categoriesChart  = findViewById(R.id.categories_chart);
        cashFlowPanel    = findViewById(R.id.cash_flow_panel);
        categoriesPanel  = findViewById(R.id.categories_panel);
        legendExpensesRow  = findViewById(R.id.legend_expenses_row);
        legendIncomeSwatch = findViewById(R.id.legend_income_swatch);
        legendIncomeLabel  = findViewById(R.id.legend_income_label);
        tvPeriodRange      = findViewById(R.id.tv_period_range);

        findViewById(R.id.btn_period_prev).setOnClickListener(v -> {
            yearOffset--;
            buildCashFlowChart(isGrossMode);
        });
        findViewById(R.id.btn_period_next).setOnClickListener(v -> {
            yearOffset++;
            buildCashFlowChart(isGrossMode);
        });

        // Tab switching
        TabLayout tabs = findViewById(R.id.visuals_tab_layout);
        tabs.addTab(tabs.newTab().setText("Cash Flow"));
        tabs.addTab(tabs.newTab().setText("Categories"));
        tabs.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override public void onTabSelected(TabLayout.Tab tab) {
                boolean cashFlow = tab.getPosition() == 0;
                cashFlowPanel.setVisibility(cashFlow ? View.VISIBLE : View.GONE);
                categoriesPanel.setVisibility(cashFlow ? View.GONE : View.VISIBLE);
            }
            @Override public void onTabUnselected(TabLayout.Tab tab) {}
            @Override public void onTabReselected(TabLayout.Tab tab) {}
        });

        // GROSS / NET toggle
        RadioGroup modeGroup = findViewById(R.id.cash_flow_mode_group);
        modeGroup.setOnCheckedChangeListener((group, checkedId) ->
                buildCashFlowChart(checkedId == R.id.rb_gross));

        buildCashFlowChart(true);
        buildCategoriesChart();
    }

    // ── Cash Flow ────────────────────────────────────────────────────────────

    private void buildCashFlowChart(boolean gross) {
        isGrossMode = gross;
        int green     = ContextCompat.getColor(this, R.color.balance_positive);
        int red       = ContextCompat.getColor(this, R.color.balance_negative);
        int textColor = getThemeTextColor();
        int gridColor = resolveAttrColor(R.attr.colorControlHighlight);

        // ── Determine pay period from the most frequent income stream ──────
        int payFreq        = 1;
        ChronoUnit payUnit = ChronoUnit.MONTHS;
        LocalDate payAnchor = LocalDate.now().withDayOfMonth(1);
        if (!incomeList.isEmpty()) {
            IncomeStreamModel primary = null;
            double bestDays = Double.MAX_VALUE;
            for (IncomeStreamModel inc : incomeList) {
                int f = inc.getFrequency();
                if (f <= 0) continue;
                ChronoUnit u = incomeFreqToChronoUnit(inc.getFrequencyTag());
                double d = periodToDays(f, u);
                if (d < bestDays) { bestDays = d; primary = inc; }
            }
            if (primary != null) {
                payFreq   = primary.getFrequency();
                payUnit   = incomeFreqToChronoUnit(primary.getFrequencyTag());
                try {
                    payAnchor = LocalDate.parse(primary.getCheckDate(),
                            DateTimeFormatter.ofPattern("yyyy.MM.dd"));
                } catch (Exception ignored) {}
            }
        }

        // ── Generate all pay dates within the display year ─────────────────
        int displayYear   = LocalDate.now().getYear() + yearOffset;
        LocalDate yearStart = LocalDate.of(displayYear, 1, 1);
        LocalDate yearEnd   = LocalDate.of(displayYear + 1, 1, 1);

        List<LocalDate> payDates = new ArrayList<>();
        LocalDate cursor = payAnchor;
        int safety = 0;
        while (!cursor.isBefore(yearStart) && safety++ < 10000) cursor = cursor.minus(payFreq, payUnit);
        safety = 0;
        while (cursor.isBefore(yearEnd) && safety++ < 10000) {
            if (!cursor.isBefore(yearStart)) payDates.add(cursor);
            cursor = cursor.plus(payFreq, payUnit);
        }
        if (payDates.isEmpty()) {
            for (int m = 1; m <= 12; m++) payDates.add(LocalDate.of(displayYear, m, 1));
        }

        int numBars = payDates.size();
        float[] incomeTotals  = new float[numBars];
        float[] expenseTotals = new float[numBars];
        String[] periodLabels = new String[numBars];
        DateTimeFormatter dayFmt3    = DateTimeFormatter.ofPattern("d",     Locale.US);
        DateTimeFormatter monthDayFmt = DateTimeFormatter.ofPattern("MMM d", Locale.US);
        LocalDate today = LocalDate.now();

        for (int i = 0; i < numBars; i++) {
            LocalDate periodStart = payDates.get(i);
            LocalDate periodEnd   = (i + 1 < numBars) ? payDates.get(i + 1) : yearEnd;
            boolean newMonth = (i == 0)
                    || !periodStart.getMonth().equals(payDates.get(i - 1).getMonth());
            // Month boundaries get "MMM d"; other periods just show the day.
            // At -90° rotation these single-line labels never overlap.
            periodLabels[i] = newMonth
                    ? periodStart.format(monthDayFmt)
                    : periodStart.format(dayFmt3);

            // TODO: replace with stored transaction history for past periods.
            // Until data persistence is implemented, past periods show $0.
            if (periodStart.isBefore(today)) continue;

            for (IncomeStreamModel inc : incomeList) {
                float amt;
                try { amt = Float.parseFloat(inc.getAmount()); }
                catch (NumberFormatException ex) { continue; }
                if (amt <= 0) continue;
                int occ = countIncomeOccurrencesInMonth(inc, periodStart, periodEnd);
                if (occ > 0) incomeTotals[i] += occ * amt;
            }
            for (ExpenseModel e : expenseList) {
                float cost;
                try { cost = Float.parseFloat(e.getCost()); }
                catch (NumberFormatException ex) { continue; }
                if (cost <= 0) continue;
                int occ = countOccurrencesInMonth(e, periodStart, periodEnd);
                if (occ > 0) expenseTotals[i] += occ * cost;
            }
        }

        if (tvPeriodRange != null) tvPeriodRange.setText(String.valueOf(displayYear));

        grossIncomeTotals  = new float[numBars];
        grossExpenseTotals = new float[numBars];
        System.arraycopy(incomeTotals,  0, grossIncomeTotals,  0, numBars);
        System.arraycopy(expenseTotals, 0, grossExpenseTotals, 0, numBars);

        // ── Chart configuration — clear first so mode switches don't bleed ─
        cashFlowChart.clear();
        cashFlowChart.getDescription().setEnabled(false);
        cashFlowChart.getLegend().setEnabled(false);
        cashFlowChart.setDrawGridBackground(false);
        cashFlowChart.setDrawBorders(false);
        cashFlowChart.setScaleEnabled(false);
        cashFlowChart.setPinchZoom(false);
        cashFlowChart.setDragEnabled(false);
        cashFlowChart.setHighlightPerTapEnabled(true);
        cashFlowChart.setHighlightFullBarEnabled(true);

        final String[] labels = periodLabels;
        ValueFormatter periodFmt = new ValueFormatter() {
            @Override public String getFormattedValue(float value) {
                int idx = (int) value;
                if (idx < 0 || idx >= labels.length) return "";
                return labels[idx];
            }
        };

        XAxis xAxis = cashFlowChart.getXAxis();
        xAxis.setPosition(XAxis.XAxisPosition.BOTTOM);
        xAxis.setDrawGridLines(false);
        xAxis.setTextColor(textColor);
        xAxis.setTextSize(8f);
        xAxis.setLabelRotationAngle(-90f);
        xAxis.setValueFormatter(periodFmt);
        // Granularity=1 places labels only at integer x positions (bar centres).
        // Avoid setLabelCount with force=true — it would also emit a label at the
        // axis minimum (-0.5) which the formatter maps to index 0, duplicating it.
        xAxis.setGranularity(1f);
        xAxis.setGranularityEnabled(true);
        xAxis.setAxisMinimum(-0.5f);
        xAxis.setAxisMaximum(numBars - 0.5f);
        xAxis.setCenterAxisLabels(false);

        YAxis leftAxis = cashFlowChart.getAxisLeft();
        leftAxis.resetAxisMinimum();
        leftAxis.resetAxisMaximum();
        leftAxis.setTextColor(textColor);
        leftAxis.setTextSize(10f);
        leftAxis.setGridColor(gridColor);
        leftAxis.setDrawZeroLine(true);
        leftAxis.setZeroLineColor(textColor);
        leftAxis.setZeroLineWidth(1.2f);
        leftAxis.setValueFormatter(new ValueFormatter() {
            @Override public String getFormattedValue(float value) {
                return "$" + Math.abs(Math.round(value));
            }
        });
        cashFlowChart.getAxisRight().setEnabled(false);

        BarData barData;
        if (gross) {
            List<BarEntry> incomeEntries  = new ArrayList<>();
            List<BarEntry> expenseEntries = new ArrayList<>();
            List<Integer>  incomeColors   = new ArrayList<>();
            List<Integer>  expenseColors  = new ArrayList<>();
            for (int i = 0; i < numBars; i++) {
                boolean future = payDates.get(i).isAfter(today);
                incomeEntries.add(new BarEntry(i, incomeTotals[i]));
                expenseEntries.add(new BarEntry(i, -expenseTotals[i]));
                incomeColors.add(future ? withAlpha(green, 0x80) : green);
                expenseColors.add(future ? withAlpha(red,   0x80) : red);
            }
            BarDataSet incomeSet = new BarDataSet(incomeEntries, "Income");
            incomeSet.setColors(incomeColors);
            incomeSet.setDrawValues(false);
            BarDataSet expenseSet = new BarDataSet(expenseEntries, "Expenses");
            expenseSet.setColors(expenseColors);
            expenseSet.setDrawValues(false);
            barData = new BarData(incomeSet, expenseSet);
            barData.setBarWidth(0.7f);
            cashFlowChart.setData(barData);
            // Disable auto-highlight: with two overlapping datasets at the same x,
            // MPAndroidChart always picks dataset 0. We handle highlighting ourselves
            // in onChartSingleTapped so we can target whichever bar was actually tapped.
            cashFlowChart.setHighlightPerTapEnabled(false);

            cashFlowChart.setOnChartGestureListener(new OnChartGestureListener() {
                @Override public void onChartGestureStart(MotionEvent me, ChartTouchListener.ChartGesture cg) {}
                @Override public void onChartGestureEnd(MotionEvent me, ChartTouchListener.ChartGesture cg) {}
                @Override public void onChartLongPressed(MotionEvent me) {}
                @Override public void onChartDoubleTapped(MotionEvent me) {}
                @Override public void onChartSingleTapped(MotionEvent me) {
                    float[] zeroInPixels = {0f, 0f};
                    cashFlowChart.getTransformer(YAxis.AxisDependency.LEFT)
                            .pointValuesToPixel(zeroInPixels);
                    grossLastTapWasExpense = me.getY() > zeroInPixels[1];

                    // Auto-highlight is disabled for GROSS mode; apply it manually so
                    // we can target the correct dataset (0=income, 1=expenses).
                    float[] tapPt = {me.getX(), me.getY()};
                    cashFlowChart.getTransformer(YAxis.AxisDependency.LEFT)
                            .pixelsToValue(tapPt);
                    int barIdx = Math.round(tapPt[0]);
                    int dsIdx  = grossLastTapWasExpense ? 1 : 0;
                    if (barIdx >= 0 && barIdx < grossIncomeTotals.length) {
                        cashFlowChart.highlightValue(barIdx, dsIdx, false);
                    }
                }
                @Override public void onChartFling(MotionEvent me1, MotionEvent me2, float vX, float vY) {}
                @Override public void onChartScale(MotionEvent me, float scX, float scY) {}
                @Override public void onChartTranslate(MotionEvent me, float dX, float dY) {}
            });
            cashFlowChart.setMarker(new ChartMarker((e, h) -> {
                int idx = Math.round(e.getX());
                if (grossLastTapWasExpense) {
                    float val = (idx >= 0 && idx < grossExpenseTotals.length) ? grossExpenseTotals[idx] : 0f;
                    return "Expenses: $" + String.format(Locale.US, "%.2f", val);
                } else {
                    float val = (idx >= 0 && idx < grossIncomeTotals.length) ? grossIncomeTotals[idx] : 0f;
                    return "Income: $" + String.format(Locale.US, "%.2f", val);
                }
            }, true));
            if (legendIncomeSwatch != null) legendIncomeSwatch.setVisibility(View.VISIBLE);
            if (legendIncomeLabel  != null) legendIncomeLabel.setText("Income");
            if (legendExpensesRow  != null) legendExpensesRow.setVisibility(View.VISIBLE);
        } else {
            cashFlowChart.setOnChartGestureListener(null);
            grossLastTapWasExpense = false;
            List<BarEntry> netEntries = new ArrayList<>();
            List<Integer>  colors     = new ArrayList<>();
            float maxNet = 0f, minNet = 0f;
            for (int i = 0; i < numBars; i++) {
                boolean future = payDates.get(i).isAfter(today);
                float net = incomeTotals[i] - expenseTotals[i];
                netEntries.add(new BarEntry(i, net));
                int baseColor = net >= 0 ? green : red;
                colors.add(future ? withAlpha(baseColor, 0x80) : baseColor);
                if (net > maxNet) maxNet = net;
                if (net < minNet) minNet = net;
            }
            BarDataSet netSet = new BarDataSet(netEntries, "Net");
            netSet.setColors(colors);
            netSet.setDrawValues(false);
            barData = new BarData(netSet);
            barData.setBarWidth(0.6f);
            cashFlowChart.setData(barData);
            float pad = Math.max(Math.abs(maxNet), Math.abs(minNet)) * 0.12f;
            if (pad < 1f) pad = 10f;
            leftAxis.setAxisMinimum(Math.min(minNet, 0f) - pad);
            leftAxis.setAxisMaximum(Math.max(maxNet, 0f) + pad);
            cashFlowChart.setMarker(new ChartMarker((e, h) -> {
                float val = e.getY();
                String sign = val >= 0 ? "+" : "-";
                return "Net: " + sign + "$" + String.format(Locale.US, "%.2f", Math.abs(val));
            }, true));
            if (legendIncomeSwatch != null) legendIncomeSwatch.setVisibility(View.GONE);
            if (legendIncomeLabel  != null) legendIncomeLabel.setText("Net Change");
            if (legendExpensesRow  != null) legendExpensesRow.setVisibility(View.GONE);
        }

        cashFlowChart.animateY(700);
        cashFlowChart.invalidate();
    }

    // ── Categories ───────────────────────────────────────────────────────────

    private void buildCategoriesChart() {
        int textColor = getThemeTextColor();

        // Sum monthly-equivalent cost per category
        Map<String, Float> amounts = new LinkedHashMap<>();
        for (String cat : CATEGORY_ORDER) amounts.put(cat, 0f);

        for (ExpenseModel e : expenseList) {
            float monthly = monthlyEquivalent(e);
            if (monthly <= 0) continue;
            amounts.merge(inferCategory(e), monthly, Float::sum);
        }

        // Sort descending by amount, drop zeros
        List<String> cats = new ArrayList<>();
        List<Float>  vals = new ArrayList<>();
        amounts.entrySet().stream()
                .filter(en -> en.getValue() > 0.01f)
                .sorted((a, b) -> Float.compare(b.getValue(), a.getValue()))
                .forEach(en -> { cats.add(en.getKey()); vals.add(en.getValue()); });

        if (cats.isEmpty()) {
            categoriesChart.setVisibility(View.GONE);
            return;
        }

        int n = cats.size();

        // Build entries bottom-to-top so the highest bar appears at the top visually
        List<BarEntry> entries   = new ArrayList<>();
        List<Integer>  barColors = new ArrayList<>();
        categoryAxisLabels = new String[n];
        for (int i = 0; i < n; i++) {
            int rev = n - 1 - i;
            entries.add(new BarEntry(i, vals.get(rev)));
            barColors.add(categoryColor(cats.get(rev)));
            categoryAxisLabels[i] = cats.get(rev);
        }

        BarDataSet dataSet = new BarDataSet(entries, "");
        dataSet.setColors(barColors);
        dataSet.setDrawValues(true);
        dataSet.setValueTextColor(textColor);
        dataSet.setValueTextSize(10f);
        dataSet.setValueFormatter(new ValueFormatter() {
            @Override public String getFormattedValue(float value) {
                return "$" + Math.round(value) + "/mo";
            }
        });

        BarData barData = new BarData(dataSet);
        barData.setBarWidth(0.55f);
        categoriesChart.setData(barData);

        // Adjust chart height so each bar has ~52dp of vertical space
        float density = getResources().getDisplayMetrics().density;
        ViewGroup.LayoutParams lp = categoriesChart.getLayoutParams();
        lp.height = (int)(Math.max(200, n * 52) * density);
        categoriesChart.setLayoutParams(lp);

        categoriesChart.getDescription().setEnabled(false);
        categoriesChart.getLegend().setEnabled(false);
        categoriesChart.setDrawGridBackground(false);
        categoriesChart.setDrawBorders(false);
        categoriesChart.setScaleEnabled(false);
        categoriesChart.setPinchZoom(false);
        categoriesChart.setHighlightPerTapEnabled(true);
        categoriesChart.setDrawValueAboveBar(true);

        // Explicit axis bounds ensure every bar label is rendered; setLabelCount with
        // "force" conflicts with granularity in HorizontalBarChart and drops labels.
        XAxis xAxis = categoriesChart.getXAxis();
        xAxis.setValueFormatter(new IndexAxisValueFormatter(categoryAxisLabels));
        xAxis.setAxisMinimum(-0.5f);
        xAxis.setAxisMaximum(n - 0.5f);
        xAxis.setGranularity(1f);
        xAxis.setTextColor(textColor);
        xAxis.setTextSize(11f);
        xAxis.setDrawGridLines(false);
        xAxis.setDrawAxisLine(false);

        categoriesChart.getAxisLeft().setEnabled(false);
        categoriesChart.getAxisRight().setEnabled(false);

        final String[] snapLabels = categoryAxisLabels;
        categoriesChart.setMarker(new ChartMarker((e, h) -> {
            int idx = Math.round(e.getX());
            String cat = (idx >= 0 && idx < snapLabels.length) ? snapLabels[idx] : "?";
            return cat + ": $" + Math.round(e.getY()) + "/mo";
        }));

        categoriesChart.animateX(700);
        categoriesChart.invalidate();
    }

    // ── Data helpers ─────────────────────────────────────────────────────────

    // Returns the number of times this income stream pays within [start, end).
    private int countIncomeOccurrencesInMonth(IncomeStreamModel inc, LocalDate start, LocalDate end) {
        String raw = inc.getCheckDate();
        if (raw == null || raw.isEmpty()) return 0;
        LocalDate date;
        try {
            date = LocalDate.parse(raw, DateTimeFormatter.ofPattern("yyyy.MM.dd"));
        } catch (Exception ex) {
            return 0;
        }
        int freq = inc.getFrequency();
        ChronoUnit tag = incomeFreqToChronoUnit(inc.getFrequencyTag());
        if (freq <= 0) return 0;

        int safety = 0;
        while (!date.isBefore(start) && safety++ < 3650) date = date.minus(freq, tag);

        int count = 0;
        safety = 0;
        while (date.isBefore(end) && safety++ < 3650) {
            if (!date.isBefore(start)) count++;
            date = date.plus(freq, tag);
        }
        return count;
    }

    // IncomeStreamModel uses int codes (0=Days, 1=Weeks, 2=Months, 3=Years).
    private ChronoUnit incomeFreqToChronoUnit(int tag) {
        switch (tag) {
            case 0:  return ChronoUnit.DAYS;
            case 1:  return ChronoUnit.WEEKS;
            case 2:  return ChronoUnit.MONTHS;
            case 3:  return ChronoUnit.YEARS;
            default: return ChronoUnit.MONTHS;
        }
    }

    // Returns the number of times this expense falls within [start, end).
    private int countOccurrencesInMonth(ExpenseModel e, LocalDate start, LocalDate end) {
        LocalDate date = e.getDate();
        if (date == null) return 0;

        if (e.getIsCredit()) {
            // Credit cards in this model are single upcoming payments: makeCurrent() advances
            // expenseDate to the next due date and zeroes the cost once paid. Only project
            // the one occurrence whose due date falls within this pay period.
            return (!date.isBefore(start) && date.isBefore(end)) ? 1 : 0;
        }

        int freq = e.getFrequency();
        ChronoUnit tag = e.getFrequencyTag();
        if (freq <= 0 || tag == null) return 0;

        // Step backward until date is strictly before start
        int safety = 0;
        while (!date.isBefore(start) && safety++ < 3650) {
            date = date.minus(freq, tag);
        }

        // Count occurrences in [start, end)
        int count = 0;
        safety = 0;
        while (date.isBefore(end) && safety++ < 3650) {
            if (!date.isBefore(start)) count++;
            date = date.plus(freq, tag);
        }
        return count;
    }

    // Converts a recurring expense cost to its average monthly dollar amount.
    private float monthlyEquivalent(ExpenseModel e) {
        float cost;
        try { cost = Float.parseFloat(e.getCost()); }
        catch (NumberFormatException ex) { return 0f; }
        if (cost <= 0) return 0f;

        int freq = e.getFrequency();
        ChronoUnit tag = e.getFrequencyTag();
        float daysPerPeriod;
        if      (ChronoUnit.DAYS.equals(tag))   daysPerPeriod = freq;
        else if (ChronoUnit.WEEKS.equals(tag))  daysPerPeriod = freq * 7f;
        else if (ChronoUnit.MONTHS.equals(tag)) daysPerPeriod = freq * 30.44f;
        else if (ChronoUnit.YEARS.equals(tag))  daysPerPeriod = freq * 365.25f;
        else                                    daysPerPeriod = 30.44f;

        return cost * (30.44f / daysPerPeriod);
    }

    // Infers a spending category by keyword-matching the expense name.
    private String inferCategory(ExpenseModel e) {
        if (e.getIsCredit()) return "Credit Cards";
        String name = e.getName() != null ? e.getName().toLowerCase(Locale.US) : "";
        for (String[] rule : CATEGORY_RULES) {
            for (String kw : rule[1].split(",")) {
                if (name.contains(kw.trim())) return rule[0];
            }
        }
        return "Other";
    }

    private int categoryColor(String category) {
        switch (category) {
            case "Housing":       return 0xFF5C6BC0;
            case "Food":          return 0xFFEF6C00;
            case "Transport":     return 0xFF0288D1;
            case "Entertainment": return 0xFF7B1FA2;
            case "Utilities":     return 0xFF00838F;
            case "Healthcare":    return 0xFFE53935;
            case "Shopping":      return 0xFFF06292;
            case "Subscriptions": return 0xFF43A047;
            case "Credit Cards":  return 0xFFFF7043;
            default:              return 0xFF78909C;
        }
    }

    // ── Chart helpers ────────────────────────────────────────────────────────

    private int withAlpha(int color, int alpha) {
        return Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color));
    }

    private double periodToDays(int freq, ChronoUnit unit) {
        switch (unit) {
            case DAYS:   return freq;
            case WEEKS:  return freq * 7.0;
            case MONTHS: return freq * 30.44;
            case YEARS:  return freq * 365.25;
            default:     return freq * 30.44;
        }
    }

    // ── Theme helpers ────────────────────────────────────────────────────────

    private int getThemeTextColor() {
        int[] attrs = { android.R.attr.textColorPrimary };
        TypedArray ta = obtainStyledAttributes(attrs);
        try {
            return ta.getColor(0, Color.BLACK);
        } finally {
            ta.recycle();
        }
    }

    private int resolveAttrColor(int attr) {
        int[] attrs = { attr };
        TypedArray ta = obtainStyledAttributes(attrs);
        try {
            return ta.getColor(0, Color.GRAY);
        } finally {
            ta.recycle();
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    // ── Marker popup ─────────────────────────────────────────────────────────

    private class ChartMarker extends MarkerView {
        private final TextView label;
        private final BiFunction<Entry, Highlight, String> formatter;
        private final boolean isCashFlow;
        private Entry lastEntry;

        ChartMarker(BiFunction<Entry, Highlight, String> fmt) {
            this(fmt, false);
        }

        ChartMarker(BiFunction<Entry, Highlight, String> fmt, boolean cashFlow) {
            super(VisualsActivity.this, R.layout.marker_chart_value);
            label = findViewById(R.id.marker_text);
            formatter = fmt;
            isCashFlow = cashFlow;
        }

        @Override
        public void refreshContent(Entry e, Highlight highlight) {
            lastEntry = e;
            label.setText(formatter.apply(e, highlight));
            super.refreshContent(e, highlight);
        }

        @Override
        public MPPointF getOffset() {
            float w = getWidth();
            float h = getHeight();
            if (!isCashFlow || lastEntry == null) {
                return new MPPointF(-w / 2f, -h);
            }
            if (grossLastTapWasExpense) {
                // Anchor is at the income bar tip; shift the marker down to the expense bar tip.
                int idx = Math.round(lastEntry.getX());
                if (idx >= 0 && idx < grossExpenseTotals.length && grossExpenseTotals[idx] > 0) {
                    float[] expPts = {lastEntry.getX(), -grossExpenseTotals[idx]};
                    float[] incPts = {lastEntry.getX(),  lastEntry.getY()};
                    cashFlowChart.getTransformer(YAxis.AxisDependency.LEFT).pointValuesToPixel(expPts);
                    cashFlowChart.getTransformer(YAxis.AxisDependency.LEFT).pointValuesToPixel(incPts);
                    return new MPPointF(-w / 2f, expPts[1] - incPts[1]);
                }
            }
            // NET or GROSS income: above positive bars, below negative bars.
            return lastEntry.getY() < 0
                    ? new MPPointF(-w / 2f, 0f)
                    : new MPPointF(-w / 2f, -h);
        }
    }
}
