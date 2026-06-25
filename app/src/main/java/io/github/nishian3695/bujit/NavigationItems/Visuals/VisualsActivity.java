package io.github.nishian3695.bujit.NavigationItems.Visuals;

import android.content.res.TypedArray;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Bundle;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.RadioGroup;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import android.widget.TextView;
import com.github.mikephil.charting.charts.BarChart;
import com.github.mikephil.charting.charts.PieChart;
import com.github.mikephil.charting.components.Legend;
import com.github.mikephil.charting.components.MarkerView;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.data.BarData;
import com.github.mikephil.charting.data.BarDataSet;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.PieData;
import com.github.mikephil.charting.data.PieDataSet;
import com.github.mikephil.charting.data.PieEntry;
import com.github.mikephil.charting.formatter.ValueFormatter;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.listener.ChartTouchListener;
import com.github.mikephil.charting.listener.OnChartGestureListener;
import com.github.mikephil.charting.buffer.BarBuffer;
import com.github.mikephil.charting.interfaces.datasets.IBarDataSet;
import com.github.mikephil.charting.renderer.BarChartRenderer;
import com.github.mikephil.charting.utils.MPPointF;
import android.view.MotionEvent;
import java.util.function.BiFunction;
import com.google.android.material.tabs.TabLayout;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseActivity;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseModel;
import io.github.nishian3695.bujit.StorageManagement.CategoryManager;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamModel;
import io.github.nishian3695.bujit.R;
import io.github.nishian3695.bujit.StorageManagement.PeriodSnapshot;
import io.github.nishian3695.bujit.StorageManagement.StorageHolder;
import io.github.nishian3695.bujit.StorageManagement.StorageManager;
import io.github.nishian3695.bujit.ThemeHelper;
import io.github.nishian3695.bujit.Tutorial.TutorialManager;
import io.github.nishian3695.bujit.Tutorial.TutorialOverlayLayout;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

/*
Displays two chart views for the user's financial data.

Cash Flow tab — a 12-month BarChart.
  Green bars go upward for income (from income streams); red bars go downward for all
  expenses (both regular and credit-card entries). A GROSS/NET toggle is provided:
  GROSS shows both bars stacked from the zero line for each month; NET collapses them
  into a single bar (green = income > expenses, red = expenses > income).

Categories tab — two PieCharts showing estimated per-check spending broken down by
  inferred category (keyword-matched from expense names). The first chart includes all
  categories; the second excludes credit card entries. Both charts support a custom
  legend where tapping a category chip toggles it on/off.
*/
public class VisualsActivity extends AppCompatActivity {


    private ArrayList<ExpenseModel>      expenseList;
    private ArrayList<IncomeStreamModel> incomeList;
    private ArrayList<PeriodSnapshot>    snapshotList;
    private ArrayList<String>            categoryList;
    private BarChart             cashFlowChart;
    private PieChart             categoriesChart;
    private PieChart             perCheckChart;
    private LinearLayout         categoriesLegend;
    private LinearLayout         perCheckLegend;
    private final Set<String>    hiddenTop    = new HashSet<>();
    private final Set<String>    hiddenBottom = new HashSet<>();
    private View                 cashFlowPanel;
    private View                 categoriesPanel;
    private View                 legendExpensesRow;
    private View                 legendIncomeSwatch;
    private TextView             legendIncomeLabel;
    private float[]              grossIncomeTotals      = new float[0];
    private float[]              grossExpenseTotals     = new float[0];
    private boolean              grossLastTapWasExpense = false;
    private int                  yearOffset    = 0;
    private boolean              isGrossMode   = true;
    private TextView             tvPeriodRange;
    private int                  currentHighlightBarIdx = -1;
    private int                  currentHighlightDsIdx  = -1;
    private TutorialOverlayLayout tutorialOverlay;

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
        //noinspection unchecked
        incomeList = (ArrayList<IncomeStreamModel>) getIntent().getSerializableExtra("incomeList");
        //noinspection unchecked
        snapshotList = (ArrayList<PeriodSnapshot>) getIntent().getSerializableExtra("snapshotList");
        //noinspection unchecked
        categoryList = (ArrayList<String>) getIntent().getSerializableExtra("categoryList");

        // When launched from the tutorial (no extras), load directly from storage so charts populate.
        if (expenseList == null && incomeList == null) {
            try {
                StorageHolder h = new StorageManager(this).getStorageHolder();
                expenseList  = h.getExpenseList()     != null ? h.getExpenseList()     : new ArrayList<>();
                incomeList   = h.getIncomeStreamList() != null ? h.getIncomeStreamList() : new ArrayList<>();
                snapshotList = h.getPeriodSnapshots()  != null ? h.getPeriodSnapshots()  : new ArrayList<>();
                categoryList = h.getCategoryList();
            } catch (Exception ignored) {
                expenseList  = new ArrayList<>();
                incomeList   = new ArrayList<>();
                snapshotList = new ArrayList<>();
            }
        } else {
            if (expenseList  == null) expenseList  = new ArrayList<>();
            if (incomeList   == null) incomeList   = new ArrayList<>();
            if (snapshotList == null) snapshotList = new ArrayList<>();
        }
        if (categoryList == null) categoryList = CategoryManager.getDefaults();

        cashFlowChart    = findViewById(R.id.cash_flow_chart);
        categoriesChart  = findViewById(R.id.categories_chart);
        perCheckChart    = findViewById(R.id.per_check_chart);
        categoriesLegend = findViewById(R.id.categories_legend);
        perCheckLegend   = findViewById(R.id.per_check_legend);
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
        buildPerCheckChart();
    }

    // ── Cash Flow ────────────────────────────────────────────────────────────

    private void buildCashFlowChart(boolean gross) {
        isGrossMode = gross;
        currentHighlightBarIdx = -1;
        currentHighlightDsIdx  = -1;
        int green     = ContextCompat.getColor(this, R.color.balance_positive);
        int red       = ContextCompat.getColor(this, R.color.balance_negative);
        int textColor = getThemeTextColor();
        int gridColor = resolveAttrColor(R.attr.colorControlHighlight);

        // ── Determine pay period from the selected income stream ─────────
        int payFreq        = 1;
        ChronoUnit payUnit = ChronoUnit.MONTHS;
        LocalDate payAnchor = LocalDate.now().withDayOfMonth(1);
        if (!incomeList.isEmpty()) {
            // Prefer the user-selected stream; fall back to shortest period if none is marked
            IncomeStreamModel primary = null;
            for (IncomeStreamModel inc : incomeList) {
                if (inc.isSelected()) { primary = inc; break; }
            }
            if (primary == null) {
                double bestDays = Double.MAX_VALUE;
                for (IncomeStreamModel inc : incomeList) {
                    int f = inc.getFrequency();
                    if (f <= 0) continue;
                    ChronoUnit u = incomeFreqToChronoUnit(inc.getFrequencyTag());
                    double d = periodToDays(f, u);
                    if (d < bestDays) { bestDays = d; primary = inc; }
                }
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
        DateTimeFormatter periodLabelFmt = DateTimeFormatter.ofPattern("MMM'. 'd", Locale.US);
        DateTimeFormatter markerDateFmt  = DateTimeFormatter.ofPattern("MMM'. 'd", Locale.US);
        LocalDate today = LocalDate.now();

        for (int i = 0; i < numBars; i++) {
            LocalDate periodStart = payDates.get(i);
            LocalDate periodEnd   = (i + 1 < numBars) ? payDates.get(i + 1) : yearEnd;
            periodLabels[i] = periodStart.format(periodLabelFmt);

            // Fully-elapsed periods: use stored snapshot; zeros if no snapshot exists yet.
            if (!periodEnd.isAfter(today)) {
                PeriodSnapshot snap = findSnapshot(periodStart);
                if (snap != null) {
                    incomeTotals[i]  = snap.getIncomeTotal();
                    expenseTotals[i] = snap.getExpenseTotal();
                }
                continue;
            }

            // Current and future periods: project from recurring rules.
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

        if (tvPeriodRange != null) {
            tvPeriodRange.setText(String.valueOf(displayYear));
            if (yearOffset != 0) {
                tvPeriodRange.setTextColor(resolveAttrColor(android.R.attr.colorPrimary));
                tvPeriodRange.setOnClickListener(v -> {
                    yearOffset = 0;
                    buildCashFlowChart(isGrossMode);
                });
            } else {
                tvPeriodRange.setTextColor(getThemeTextColor());
                tvPeriodRange.setOnClickListener(null);
            }
        }

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
        // setLabelCount with force=false gives MPAndroidChart a density hint so it
        // renders all numBars labels rather than its default ~6.
        xAxis.setGranularity(1f);
        xAxis.setGranularityEnabled(true);
        xAxis.setLabelCount(numBars, false);
        xAxis.setAxisMinimum(-0.5f);
        xAxis.setAxisMaximum(numBars - 0.5f);
        xAxis.setCenterAxisLabels(false);

        YAxis leftAxis = cashFlowChart.getAxisLeft();
        leftAxis.resetAxisMinimum();
        leftAxis.resetAxisMaximum();
        leftAxis.setSpaceBottom(3f);
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
        cashFlowChart.setExtraBottomOffset(10f);

        BarData barData;
        if (gross) {
            boolean[] futureFlags = new boolean[numBars];
            List<BarEntry> incomeEntries  = new ArrayList<>();
            List<BarEntry> expenseEntries = new ArrayList<>();
            List<Integer>  incomeColors   = new ArrayList<>();
            List<Integer>  expenseColors  = new ArrayList<>();
            for (int i = 0; i < numBars; i++) {
                futureFlags[i] = payDates.get(i).isAfter(today);
                incomeEntries.add(new BarEntry(i, incomeTotals[i]));
                expenseEntries.add(new BarEntry(i, -expenseTotals[i]));
                incomeColors.add(green);
                expenseColors.add(red);
            }
            BarDataSet incomeSet = new BarDataSet(incomeEntries, "Income");
            incomeSet.setColors(incomeColors);
            incomeSet.setDrawValues(false);
            BarDataSet expenseSet = new BarDataSet(expenseEntries, "Expenses");
            expenseSet.setColors(expenseColors);
            expenseSet.setDrawValues(false);
            barData = new BarData(incomeSet, expenseSet);
            barData.setBarWidth(0.7f);
            cashFlowChart.setRenderer(new HatchedBarChartRenderer(cashFlowChart, futureFlags));
            cashFlowChart.setData(barData);
            // Disable auto-highlight: with two overlapping datasets at the same x,
            // MPAndroidChart always picks dataset 0. We handle highlighting ourselves
            // in onChartSingleTapped so we can target whichever bar was actually tapped.
            cashFlowChart.setHighlightPerTapEnabled(false);

            final List<LocalDate> grossPayDates = payDates;
            cashFlowChart.setOnChartGestureListener(new OnChartGestureListener() {
                @Override public void onChartGestureStart(MotionEvent me, ChartTouchListener.ChartGesture cg) {}
                @Override public void onChartGestureEnd(MotionEvent me, ChartTouchListener.ChartGesture cg) {}
                @Override public void onChartLongPressed(MotionEvent me) {}
                @Override public void onChartDoubleTapped(MotionEvent me) {}
                @Override public void onChartSingleTapped(MotionEvent me) {
                    // Convert tap pixel → data coordinates.
                    float[] zeroInPixels = {0f, 0f};
                    cashFlowChart.getTransformer(YAxis.AxisDependency.LEFT)
                            .pointValuesToPixel(zeroInPixels);
                    grossLastTapWasExpense = me.getY() > zeroInPixels[1];

                    float[] tapPt = {me.getX(), me.getY()};
                    cashFlowChart.getTransformer(YAxis.AxisDependency.LEFT)
                            .pixelsToValue(tapPt);
                    int barIdx = Math.round(tapPt[0]);

                    if (barIdx < 0 || barIdx >= grossIncomeTotals.length) {
                        cashFlowChart.highlightValue(null, false);
                        currentHighlightBarIdx = -1;
                        currentHighlightDsIdx  = -1;
                        return;
                    }

                    // Reject taps that are in the empty column space above/below the bar.
                    // tapPt[1] is now in data-space: positive = above zero, negative = below.
                    float dataY = tapPt[1];
                    boolean onBar;
                    if (grossLastTapWasExpense) {
                        float barFloor = -grossExpenseTotals[barIdx];
                        onBar = grossExpenseTotals[barIdx] > 0f && dataY <= 0f && dataY >= barFloor;
                    } else {
                        float barTop = grossIncomeTotals[barIdx];
                        onBar = grossIncomeTotals[barIdx] > 0f && dataY >= 0f && dataY <= barTop;
                    }

                    if (!onBar) {
                        cashFlowChart.highlightValue(null, false);
                        currentHighlightBarIdx = -1;
                        currentHighlightDsIdx  = -1;
                        return;
                    }

                    int dsIdx = grossLastTapWasExpense ? 1 : 0;
                    if (barIdx == currentHighlightBarIdx && dsIdx == currentHighlightDsIdx) {
                        cashFlowChart.highlightValue(null, false);
                        currentHighlightBarIdx = -1;
                        currentHighlightDsIdx  = -1;
                    } else {
                        cashFlowChart.highlightValue(barIdx, dsIdx, false);
                        currentHighlightBarIdx = barIdx;
                        currentHighlightDsIdx  = dsIdx;
                    }
                }
                @Override public void onChartFling(MotionEvent me1, MotionEvent me2, float vX, float vY) {}
                @Override public void onChartScale(MotionEvent me, float scX, float scY) {}
                @Override public void onChartTranslate(MotionEvent me, float dX, float dY) {}
            });
            cashFlowChart.setMarker(new ChartMarker((e, h) -> {
                int idx = Math.round(e.getX());
                String dateStr = (idx >= 0 && idx < grossPayDates.size())
                        ? grossPayDates.get(idx).format(markerDateFmt) : "";
                if (grossLastTapWasExpense) {
                    float val = (idx >= 0 && idx < grossExpenseTotals.length) ? grossExpenseTotals[idx] : 0f;
                    return "Expenses: $" + String.format(Locale.US, "%.2f", val) + "\n" + dateStr;
                } else {
                    float val = (idx >= 0 && idx < grossIncomeTotals.length) ? grossIncomeTotals[idx] : 0f;
                    return "Income: $" + String.format(Locale.US, "%.2f", val) + "\n" + dateStr;
                }
            }, true));
            if (legendIncomeSwatch != null) legendIncomeSwatch.setVisibility(View.VISIBLE);
            if (legendIncomeLabel  != null) legendIncomeLabel.setText("Income");
            if (legendExpensesRow  != null) legendExpensesRow.setVisibility(View.VISIBLE);
        } else {
            grossLastTapWasExpense = false;
            boolean[] futureFlags = new boolean[numBars];
            List<BarEntry> netEntries = new ArrayList<>();
            List<Integer>  colors     = new ArrayList<>();
            float maxNet = 0f, minNet = 0f;
            final float[] netValues = new float[numBars];
            for (int i = 0; i < numBars; i++) {
                futureFlags[i] = payDates.get(i).isAfter(today);
                float net = incomeTotals[i] - expenseTotals[i];
                netValues[i] = net;
                netEntries.add(new BarEntry(i, net));
                int baseColor = net >= 0 ? green : red;
                colors.add(baseColor);
                if (net > maxNet) maxNet = net;
                if (net < minNet) minNet = net;
            }
            BarDataSet netSet = new BarDataSet(netEntries, "Net");
            netSet.setColors(colors);
            netSet.setDrawValues(false);
            barData = new BarData(netSet);
            barData.setBarWidth(0.6f);
            cashFlowChart.setRenderer(new HatchedBarChartRenderer(cashFlowChart, futureFlags));
            cashFlowChart.setData(barData);
            cashFlowChart.setHighlightPerTapEnabled(false);
            float pad = Math.max(Math.abs(maxNet), Math.abs(minNet)) * 0.12f;
            if (pad < 1f) pad = 10f;
            leftAxis.setAxisMinimum(Math.min(minNet, 0f) - pad);
            leftAxis.setAxisMaximum(Math.max(maxNet, 0f) + pad);
            final List<LocalDate> netPayDates = payDates;
            cashFlowChart.setOnChartGestureListener(new OnChartGestureListener() {
                @Override public void onChartGestureStart(MotionEvent me, ChartTouchListener.ChartGesture cg) {}
                @Override public void onChartGestureEnd(MotionEvent me, ChartTouchListener.ChartGesture cg) {}
                @Override public void onChartLongPressed(MotionEvent me) {}
                @Override public void onChartDoubleTapped(MotionEvent me) {}
                @Override public void onChartSingleTapped(MotionEvent me) {
                    float[] tapPt = {me.getX(), me.getY()};
                    cashFlowChart.getTransformer(YAxis.AxisDependency.LEFT)
                            .pixelsToValue(tapPt);
                    int barIdx = Math.round(tapPt[0]);

                    if (barIdx < 0 || barIdx >= netValues.length) {
                        cashFlowChart.highlightValue(null, false);
                        currentHighlightBarIdx = -1;
                        currentHighlightDsIdx  = -1;
                        return;
                    }

                    float netVal = netValues[barIdx];
                    float dataY  = tapPt[1];
                    boolean onBar = netVal >= 0f
                            ? (netVal > 0f && dataY >= 0f && dataY <= netVal)
                            : (netVal < 0f && dataY <= 0f && dataY >= netVal);

                    if (!onBar) {
                        cashFlowChart.highlightValue(null, false);
                        currentHighlightBarIdx = -1;
                        currentHighlightDsIdx  = -1;
                        return;
                    }
                    if (barIdx == currentHighlightBarIdx) {
                        cashFlowChart.highlightValue(null, false);
                        currentHighlightBarIdx = -1;
                        currentHighlightDsIdx  = -1;
                    } else {
                        cashFlowChart.highlightValue(barIdx, 0, false);
                        currentHighlightBarIdx = barIdx;
                        currentHighlightDsIdx  = 0;
                    }
                }
                @Override public void onChartFling(MotionEvent me1, MotionEvent me2, float vX, float vY) {}
                @Override public void onChartScale(MotionEvent me, float scX, float scY) {}
                @Override public void onChartTranslate(MotionEvent me, float dX, float dY) {}
            });
            cashFlowChart.setMarker(new ChartMarker((e, h) -> {
                int idx = Math.round(e.getX());
                String dateStr = (idx >= 0 && idx < netPayDates.size())
                        ? netPayDates.get(idx).format(markerDateFmt) : "";
                float val = e.getY();
                String sign = val >= 0 ? "+" : "-";
                return "Net: " + sign + "$" + String.format(Locale.US, "%.2f", Math.abs(val))
                        + "\n" + dateStr;
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
        double payPeriodDays = getPayPeriodDays();
        Map<String, Float> amounts = buildCategoryAmounts(false, payPeriodDays);
        buildPieChart(categoriesChart, categoriesLegend, amounts, hiddenTop,
                this::buildCategoriesChart);
    }

    private void buildPerCheckChart() {
        double payPeriodDays = getPayPeriodDays();
        Map<String, Float> amounts = buildCategoryAmounts(true, payPeriodDays);
        buildPieChart(perCheckChart, perCheckLegend, amounts, hiddenBottom,
                this::buildPerCheckChart);
    }

    private Map<String, Float> buildCategoryAmounts(boolean excludeCredit, double payPeriodDays) {
        Map<String, Float> amounts = new LinkedHashMap<>();
        // Seed in user category order first so the chart respects that order
        for (String cat : categoryList) amounts.put(cat, 0f);
        amounts.put(CategoryManager.CREDIT_CARDS, 0f);
        amounts.put(CategoryManager.OTHER, 0f);
        for (ExpenseModel e : expenseList) {
            if (excludeCredit && e.getIsCredit()) continue;
            float pc = perCheckEquivalent(e, payPeriodDays);
            if (pc <= 0) continue;
            String cat = e.getIsCredit()
                    ? CategoryManager.CREDIT_CARDS
                    : e.getCategory();
            if (cat == null || cat.isEmpty()) cat = CategoryManager.OTHER;
            amounts.merge(cat, pc, Float::sum);
        }
        return amounts;
    }

    private void buildPieChart(PieChart chart, LinearLayout legendContainer,
                                Map<String, Float> amounts, Set<String> hidden,
                                Runnable rebuild) {
        List<String>   allCats   = new ArrayList<>();
        List<Integer>  allColors = new ArrayList<>();
        List<PieEntry> entries   = new ArrayList<>();
        List<Integer>  colors    = new ArrayList<>();

        amounts.entrySet().stream()
                .filter(en -> en.getValue() > 0.01f)
                .sorted((a, b) -> Float.compare(b.getValue(), a.getValue()))
                .forEach(en -> {
                    String name  = en.getKey();
                    int    color = categoryColor(name);
                    allCats.add(name);
                    allColors.add(color);
                    if (!hidden.contains(name)) {
                        entries.add(new PieEntry(en.getValue(), name));
                        colors.add(color);
                    }
                });

        buildLegend(legendContainer, allCats, allColors, hidden, rebuild);

        if (allCats.isEmpty()) {
            chart.setVisibility(View.GONE);
            legendContainer.setVisibility(View.GONE);
            return;
        }
        chart.setVisibility(View.VISIBLE);
        legendContainer.setVisibility(View.VISIBLE);

        if (entries.isEmpty()) {
            chart.clear();
            chart.invalidate();
            return;
        }

        PieDataSet dataSet = new PieDataSet(entries, "");
        dataSet.setColors(colors);
        dataSet.setValueTextSize(10f);
        dataSet.setValueTextColor(Color.WHITE);
        dataSet.setSliceSpace(2f);
        dataSet.setSelectionShift(8f);
        dataSet.setValueFormatter(new ValueFormatter() {
            @Override public String getFormattedValue(float value) {
                return String.format(Locale.US, "%.0f%%", value);
            }
        });

        PieData pieData = new PieData(dataSet);
        chart.setData(pieData);
        chart.setUsePercentValues(true);
        chart.getDescription().setEnabled(false);
        chart.getLegend().setEnabled(false);
        chart.setDrawHoleEnabled(true);
        chart.setHoleRadius(38f);
        chart.setTransparentCircleRadius(43f);
        chart.setHoleColor(Color.TRANSPARENT);
        chart.setDrawEntryLabels(false);
        chart.setHighlightPerTapEnabled(true);
        chart.setMarker(new ChartMarker((e, h) -> {
            PieEntry pe = (PieEntry) e;
            return pe.getLabel() + "\n$" + String.format(Locale.US, "%.2f", pe.getValue()) + "/check";
        }));
        chart.animateY(700);
        chart.invalidate();
    }

    private void buildLegend(LinearLayout container, List<String> names, List<Integer> colors,
                              Set<String> hidden, Runnable rebuild) {
        container.removeAllViews();
        float density    = getResources().getDisplayMetrics().density;
        int   swatchSize = (int)(12 * density);
        int   gap        = (int)(6 * density);
        int   padH       = (int)(8 * density);
        int   padV       = (int)(6 * density);

        TypedValue ripple = new TypedValue();
        getTheme().resolveAttribute(android.R.attr.selectableItemBackground, ripple, true);

        LinearLayout row = null;
        for (int i = 0; i < names.size(); i++) {
            if (i % 2 == 0) {
                row = new LinearLayout(this);
                row.setOrientation(LinearLayout.HORIZONTAL);
                container.addView(row, new LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT));
            }

            final String name  = names.get(i);
            final int    color = colors.get(i);
            boolean      off   = hidden.contains(name);

            LinearLayout item = new LinearLayout(this);
            item.setOrientation(LinearLayout.HORIZONTAL);
            item.setGravity(Gravity.CENTER_VERTICAL);
            item.setPadding(padH, padV, padH, padV);
            item.setClickable(true);
            item.setFocusable(true);
            item.setBackgroundResource(ripple.resourceId);

            View swatch = new View(this);
            swatch.setBackgroundColor(off ? withAlpha(color, 0x60) : color);
            LinearLayout.LayoutParams swatchLp = new LinearLayout.LayoutParams(swatchSize, swatchSize);
            swatchLp.setMarginEnd(gap);
            swatch.setLayoutParams(swatchLp);
            item.addView(swatch);

            TextView label = new TextView(this);
            label.setText(name);
            label.setTextSize(11f);
            label.setTextColor(getThemeTextColor());
            if (off) {
                label.setPaintFlags(label.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
                label.setAlpha(0.4f);
            }
            item.addView(label);

            item.setOnClickListener(v -> {
                if (hidden.contains(name)) hidden.remove(name);
                else hidden.add(name);
                rebuild.run();
            });

            if (row != null) {
                row.addView(item, new LinearLayout.LayoutParams(
                        0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
            }
        }
        if (names.size() % 2 != 0 && row != null) {
            row.addView(new View(this), new LinearLayout.LayoutParams(
                    0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f));
        }
    }

    // ── Data helpers ─────────────────────────────────────────────────────────

    private PeriodSnapshot findSnapshot(LocalDate periodStart) {
        if (snapshotList == null) return null;
        for (PeriodSnapshot s : snapshotList) {
            if (s.getPeriodStart().equals(periodStart)) return s;
        }
        return null;
    }

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

    // Returns the selected income stream's pay-period length in days (defaults to 30.44 if none set).
    private double getPayPeriodDays() {
        for (IncomeStreamModel inc : incomeList) {
            if (inc.isSelected()) {
                int f = inc.getFrequency();
                if (f > 0) return periodToDays(f, incomeFreqToChronoUnit(inc.getFrequencyTag()));
            }
        }
        double best = Double.MAX_VALUE;
        for (IncomeStreamModel inc : incomeList) {
            int f = inc.getFrequency();
            if (f <= 0) continue;
            double d = periodToDays(f, incomeFreqToChronoUnit(inc.getFrequencyTag()));
            if (d < best) best = d;
        }
        return (best == Double.MAX_VALUE || best <= 0) ? 30.44 : best;
    }

    // Converts a recurring expense cost to its per-pay-period dollar amount.
    private float perCheckEquivalent(ExpenseModel e, double payPeriodDays) {
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

        return cost * ((float) payPeriodDays / daysPerPeriod);
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
    protected void onResume() {
        super.onResume();
        maybeShowTutorial();
    }

    @Override
    protected void onPause() {
        removeTutorialOverlay();
        super.onPause();
    }

    private void maybeShowTutorial() {
        if (!TutorialManager.hasStepsForActivity(this, VisualsActivity.class)) return;
        showTutorialStep(TutorialManager.getCurrentStep(this));
    }

    private void showTutorialStep(int step) {
        TutorialManager.StepDef def = TutorialManager.STEPS[step];
        removeTutorialOverlay();

        // Switch to the Categories tab before spotlighting views inside it (panel is GONE otherwise).
        if (def.viewId == R.id.categories_chart) {
            TabLayout tabs = findViewById(R.id.visuals_tab_layout);
            if (tabs != null && tabs.getTabAt(1) != null) tabs.selectTab(tabs.getTabAt(1));
        }

        tutorialOverlay = new TutorialOverlayLayout(this);

        View target = def.viewId != 0 ? findViewById(def.viewId) : null;
        boolean isLast = (step == TutorialManager.STEPS.length - 1);
        String nextText = def.nextActivity != null ? "Next ›" : (isLast ? "Done" : "Next");

        tutorialOverlay.showStep(target, def.title, def.message, nextText,
            () -> {
                TutorialManager.advance(this);
                removeTutorialOverlay();
                if (def.nextActivity != null) {
                    startActivity(new android.content.Intent(this, def.nextActivity));
                } else if (TutorialManager.hasStepsForActivity(this, VisualsActivity.class)) {
                    showTutorialStep(TutorialManager.getCurrentStep(this));
                }
            },
            () -> {
                TutorialManager.markDone(this);
                removeTutorialOverlay();
                android.content.Intent home = new android.content.Intent(this, ExpenseActivity.class);
                home.addFlags(android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP
                        | android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP);
                startActivity(home);
            });

        ((ViewGroup) getWindow().getDecorView())
                .addView(tutorialOverlay, new ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT));
    }

    private void removeTutorialOverlay() {
        if (tutorialOverlay != null) {
            ViewGroup p = (ViewGroup) tutorialOverlay.getParent();
            if (p != null) p.removeView(tutorialOverlay);
            tutorialOverlay = null;
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

    // ── Hatched renderer ─────────────────────────────────────────────────────
    // Draws diagonal stripes over bars that represent projected (future) periods
    // so they are distinguishable by texture, not just by colour or opacity.

    private static class HatchedBarChartRenderer extends BarChartRenderer {
        private final boolean[] futureFlags;
        private final Paint     hatchPaint;

        HatchedBarChartRenderer(BarChart chart, boolean[] futureFlags) {
            super(chart, chart.getAnimator(), chart.getViewPortHandler());
            this.futureFlags = futureFlags;
            hatchPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
            hatchPaint.setStyle(Paint.Style.STROKE);
            hatchPaint.setColor(Color.argb(110, 255, 255, 255));
            hatchPaint.setStrokeWidth(3f);
        }

        @Override
        public void drawData(Canvas c) {
            super.drawData(c);
            if (mBarBuffers == null) return;
            BarData bd = mChart.getBarData();
            if (bd == null) return;
            for (int dsIdx = 0; dsIdx < bd.getDataSetCount(); dsIdx++) {
                if (dsIdx >= mBarBuffers.length || mBarBuffers[dsIdx] == null) continue;
                IBarDataSet dataSet = bd.getDataSetByIndex(dsIdx);
                float[] b = mBarBuffers[dsIdx].buffer;
                int n = dataSet.getEntryCount();
                for (int i = 0; i < n; i++) {
                    int barIdx = (int) dataSet.getEntryForIndex(i).getX();
                    if (barIdx < 0 || barIdx >= futureFlags.length || !futureFlags[barIdx]) continue;
                    int base = i * 4;
                    if (base + 3 >= b.length) continue;
                    float left   = b[base];
                    float top    = b[base + 1];
                    float right  = b[base + 2];
                    float bottom = b[base + 3];
                    float t  = Math.min(top, bottom);
                    float bm = Math.max(top, bottom);
                    if (bm - t < 2f || right - left < 2f) continue;
                    c.save();
                    c.clipRect(left, t, right, bm);
                    float h       = bm - t;
                    float spacing = 14f;
                    float x       = left - h;
                    while (x < right) {
                        c.drawLine(x, bm, x + h, t, hatchPaint);
                        x += spacing;
                    }
                    c.restore();
                }
            }
        }
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
