// The app's live data, shared by every screen. Screens change data through it
// and call changed(), which rebuilds listeners (e.g. the home screen) and saves.
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'navigation_items/expense_activity/balance_model.dart';
import 'storage_management/app_data_store.dart';
import 'utils/sample_data.dart';

class AppState extends ChangeNotifier {
    static final Logger _logger = Logger("BujitAppState");

    final AppData data;
    final AppDataStore? _store; // null = nothing is saved (tests, or storage failed to open)

    AppState(this.data, [this._store]);

    BalanceModel get balance => data.balance;

    // False when changes can't be saved (storage failed to open).
    bool get isSaving => _store != null;

    // Loads saved data and brings it up to [today] (default: now), paying what came
    // due and crediting paychecks that arrived, then saves the result. On the very
    // first launch there's nothing saved, so the tutorial's sample data is loaded
    // instead, as the Java app does.
    static Future<AppState> open(AppDataStore store, {DateTime? today}) async {
        AppData? data = await store.load();
        if (data == null) {
            data = AppData(balance: BalanceModel(currentBalance: 0.00));
            seedSampleData(data.balance, today: today);
        } else {
            data.balance.makeRecent(today: today);
        }
        final AppState state = AppState(data, store);
        await state.save();
        return state;
    }

    // Saves everything. Failures are logged rather than thrown, so a storage
    // problem never crashes a screen mid-edit.
    Future<void> save() async {
        final AppDataStore? store = _store;
        if (store == null) return;
        try {
            await store.save(data);
        } catch (e, stack) {
            _logger.severe("Saving failed", e, stack);
        }
    }

    // Call after changing anything in [data]: rebuilds listening screens and saves.
    Future<void> changed() {
        notifyListeners();
        return save();
    }

    // Replaces everything with the tutorial's sample data (Settings).
    Future<void> resetToSampleData({DateTime? today}) {
        seedSampleData(data.balance, today: today);
        return changed();
    }
}
