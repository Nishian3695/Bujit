package io.github.nishian3695.bujit.Tutorial;

import android.content.Context;
import android.content.SharedPreferences;
import io.github.nishian3695.bujit.ExpenseActivity.ExpenseActivity;
import io.github.nishian3695.bujit.NavigationItems.Banking.BankingActivity;
import io.github.nishian3695.bujit.NavigationItems.CreditUtil.CreditUtilActivity;
import io.github.nishian3695.bujit.NavigationItems.IncomeStreams.IncomeStreamsActivity;
import io.github.nishian3695.bujit.NavigationItems.Settings.SettingsActivity;
import io.github.nishian3695.bujit.R;

public class TutorialManager {

    public static final String PREFS_NAME  = "bujit_tutorial_prefs";
    public static final String KEY_SEEN    = "tutorial_seen";
    private static final String KEY_STEP   = "tutorial_step";

    public static class StepDef {
        public final Class<?> activityClass;
        public final int viewId;
        public final String title;
        public final String message;
        public final int spotPaddingDp;
        public final Class<?> nextActivity; // non-null = auto-navigate here after this step

        public StepDef(Class<?> act, int viewId, String title, String message,
                       int spotPaddingDp, Class<?> nextActivity) {
            this.activityClass = act;
            this.viewId        = viewId;
            this.title         = title;
            this.message       = message;
            this.spotPaddingDp = spotPaddingDp;
            this.nextActivity  = nextActivity;
        }

        public StepDef(Class<?> act, int viewId, String title, String message, int spotPaddingDp) {
            this(act, viewId, title, message, spotPaddingDp, null);
        }
    }

    public static final StepDef[] STEPS = {
        // ExpenseActivity: steps 0–4
        new StepDef(ExpenseActivity.class, R.id.check_bar_card,
            "Navigate pay periods",
            "◀ and ▶ step through past and future paychecks. Tap ▶ to project your balance forward through upcoming checks, and 🏠︎ to return to the main screen.\nLong-press to customize the projection time period.",
            12),
        new StepDef(ExpenseActivity.class, R.id.balance_card,
            "Balance at a glance",
            "Left: your current bank balance (long-press to update it).\nRight: what you'll have left after every expense due this check is paid.",
            12),
        new StepDef(ExpenseActivity.class, R.id.expense_table,
            "Expense list",
            "Recurring expenses appear here with their due date, frequency, and the amount allocated this check. Tap any row to edit or delete it, and drag to reorder.",
            8),
        new StepDef(ExpenseActivity.class, R.id.add_button,
            "Add an expense",
            "Tap + to add a recurring expense — rent, subscriptions, utilities. Set the amount, frequency, and start date.",
            20),
        // Step 4: show the navigation drawer
        new StepDef(ExpenseActivity.class, R.id.main_navigation_view,
            "Navigation menu",
            "Tap ☰ (top-left) to reach all of Bujit's features. Let's start with Income Streams.",
            0, IncomeStreamsActivity.class),
        // IncomeStreamsActivity: steps 5–6
        new StepDef(IncomeStreamsActivity.class, R.id.income_streams_list,
            "Income Streams",
            "Add your income sources here. The active stream sets your pay period and drives the balance projection on the home screen.\nTap a stream to make it active, or long-press to edit or delete it.",
            8),
        new StepDef(IncomeStreamsActivity.class, R.id.income_streams_fab,
            "Add an income source",
            "Tap + to add a paycheck — your job, a side hustle, or any recurring income. Each stream has its own frequency and start date.",
            20, CreditUtilActivity.class),
        // CreditUtilActivity: step 7
        new StepDef(CreditUtilActivity.class, R.id.credit_recyclerview,
            "Credit Utilization",
            "Track your credit card balances against their limits. Bujit highlights utilization:\n\
            ✅ 0-30%: Good utilization\n\
            ⚠️ 31-50%: Moderate utilization\n\
            ❌ 51%+: High utilization",
            8, BankingActivity.class),
        // BankingActivity: step 8
        new StepDef(BankingActivity.class, R.id.btn_connect_bank,
            "Link your bank or credit card",
            "Securely connect your bank via Teller to auto-sync your balance and credit card amounts.\nYour login credentials never leave Teller's secure system.",
            16, SettingsActivity.class),
        // SettingsActivity: step 9 (final)
        new StepDef(SettingsActivity.class, R.id.row_tutorial,
            "You're all set!",
            "Explore settings to change your theme, connect Google Calendar, or manage integrations. You can replay this tutorial here at any time.",
            8)
    };

    // SharedPreferences helpers

    public static boolean isActive(Context context) {
        return !context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                       .getBoolean(KEY_SEEN, false);
    }

    public static int getCurrentStep(Context context) {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                      .getInt(KEY_STEP, 0);
    }

    public static boolean hasStepsForActivity(Context context, Class<?> activityClass) {
        if (!isActive(context)) return false;
        int step = getCurrentStep(context);
        return step < STEPS.length && STEPS[step].activityClass == activityClass;
    }

    public static void advance(Context context) {
        int next = getCurrentStep(context) + 1;
        SharedPreferences.Editor ed =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit();
        ed.putInt(KEY_STEP, next);
        if (next >= STEPS.length) ed.putBoolean(KEY_SEEN, true);
        ed.apply();
    }

    public static void markDone(Context context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
               .edit().putBoolean(KEY_SEEN, true).apply();
    }

    public static void reset(Context context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
               .edit()
               .putInt(KEY_STEP, 0)
               .putBoolean(KEY_SEEN, false)
               .apply();
    }
}
