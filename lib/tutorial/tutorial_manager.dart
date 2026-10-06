// Mirrors Tutorial/TutorialManager.java in the original Java app: the guided
// tutorial's steps, in order. Each step spotlights one element (a
// TutorialTarget with that id) on one screen; some open the next screen when
// dismissed. Progress (AppData.tutorialStep/tutorialSeen) is saved, so the
// tutorial resumes where it left off and can be replayed from Settings.
//
// Texts are adapted to what this app does so far.
import 'package:flutter/widgets.dart';

// Screens the tutorial visits (each wraps its Scaffold in a TutorialOverlay).
enum TutorialScreen { home, incomeStreams, creditUtil, linkedAccounts, singleEvents, visuals, settings }

class TutorialStep {
    final TutorialScreen screen;
    final String targetId; // TutorialTarget id to spotlight
    final String title;
    final String message;
    final TutorialScreen? nextScreen; // Opened when this step is dismissed with Next

    const TutorialStep(this.screen, this.targetId, this.title, this.message, [this.nextScreen]);
}

class TutorialManager {
    static const List<TutorialStep> steps = [
        TutorialStep(TutorialScreen.home, "check_nav", "Navigate pay periods",
            "◀ and ▶ step through your paychecks. Tap ▶ to project your balance forward through "
            "upcoming checks; the + button becomes 🏠 to bring you back to this one."),
        TutorialStep(TutorialScreen.home, "balance_card", "Balance at a glance",
            "Left: your current balance. Tap it to update it, choose which of your accounts make "
            "it up, or add funds you track elsewhere.\nRight: what you'll have left after every "
            "expense due this check is paid -- including anything due on payday itself."),
        TutorialStep(TutorialScreen.home, "expense_list", "Expense list",
            "Recurring expenses and credit cards appear here with their due date and the amount "
            "due this check. Tap any row to edit or delete it; hold and drag to reorder. Swipe "
            "to page between checks."),
        TutorialStep(TutorialScreen.home, "add_button", "Add an expense",
            "Tap + to add a recurring expense (rent, subscriptions, utilities) -- with its amount, "
            "frequency, dates, category and what pays for it -- or a one-off single event."),
        TutorialStep(TutorialScreen.home, "menu_button", "Navigation menu",
            "Tap ☰ (top-left) to reach all of Bujit's features. Let's start with Income Streams.",
            TutorialScreen.incomeStreams),
        TutorialStep(TutorialScreen.incomeStreams, "income_list", "Income Streams",
            "Add your income sources here. The active stream (the selected circle) sets your pay "
            "periods on the home screen. Tap a stream to edit or delete it."),
        TutorialStep(TutorialScreen.incomeStreams, "income_add", "Add an income source",
            "Tap + to add a paycheck: your job, a side hustle, or any recurring income. Each "
            "stream has its own amount, frequency and starting date.",
            TutorialScreen.creditUtil),
        TutorialStep(TutorialScreen.creditUtil, "credit_list", "Credit Utilization",
            "Track your credit card balances against their limits:\n✅ under 30%: good\n"
            "⚠️ 30-70%: moderate\n❌ 70% and up: high",
            TutorialScreen.linkedAccounts),
        TutorialStep(TutorialScreen.linkedAccounts, "connect_bank", "Link your bank or credit card",
            "Securely connect your bank through Plaid to sync your balance and credit card amounts "
            "automatically. Bujit never sees your login."),
        TutorialStep(TutorialScreen.linkedAccounts, "manual_accounts", "My Accounts",
            "Track savings, cash or any account by hand here. Choose which ones make up your "
            "balance with \"From Accounts\" when you update it, and pay expenses from them.",
            TutorialScreen.singleEvents),
        TutorialStep(TutorialScreen.singleEvents, "single_events_list", "Single Events",
            "One-off expenses or income: a surprise bill, splitting dinner, a friend paying you "
            "back. They change your balance (or a card) immediately and clear from this list after "
            "30 days (adjustable in Settings). Until then you can edit or remove them.",
            TutorialScreen.visuals),
        TutorialStep(TutorialScreen.visuals, "visuals_tabs", "Visuals",
            "Three views of the bigger picture. Cash Flow tracks income and expenses by pay period "
            "across the year. Categories breaks your spending per check down by type. Net Balance "
            "charts your accounts' total, as it was and as it's projected to be."),
        TutorialStep(TutorialScreen.visuals, "cash_flow_chart", "Cash Flow chart",
            "Green = income, red = expenses. GROSS shows both; NET collapses them into one +/- bar. "
            "Each period's numbers are listed below, and ‹ › browse other years.",
            TutorialScreen.settings),
        TutorialStep(TutorialScreen.settings, "import_csv", "Import from CSV",
            "Have your expenses in a spreadsheet? Import a CSV here instead of typing them one by "
            "one. Save the template to see the format."),
        TutorialStep(TutorialScreen.settings, "replay_tutorial", "You're all set!",
            "Settings also has the Next Check option and how long single events stay listed. You "
            "can replay this tutorial here at any time."),
    ];

    // Keys for the elements steps spotlight, by TutorialTarget id.
    static final Map<String, GlobalKey> _targets = {};
    static GlobalKey targetKey(String id) => _targets.putIfAbsent(id, () => GlobalKey(debugLabel: "tutorial:$id"));
}

// Marks [child] as the element tutorial step [id] spotlights.
class TutorialTarget extends StatelessWidget {
    final String id;
    final Widget child;
    const TutorialTarget({super.key, required this.id, required this.child});

    @override
    Widget build(BuildContext context) => KeyedSubtree(key: TutorialManager.targetKey(id), child: child);
}
