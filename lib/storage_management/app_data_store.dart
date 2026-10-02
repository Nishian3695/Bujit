// Loads and saves everything the app persists, against the encrypted database.
// Kept free of platform code (no secure storage, no file paths) so it can be
// tested with an in-memory database; StorageManager does the platform setup.
import 'package:drift/drift.dart';
import '../navigation_items/expense_activity/balance_model.dart';
import '../navigation_items/income_streams/income_stream_model.dart';
import '../utils/category_manager.dart';
import 'database/app_database.dart';
import 'database/mappers/expense_mapper.dart';
import 'database/mappers/income_stream_mapper.dart';
import 'database/mappers/single_event_mapper.dart';
import '../navigation_items/single_events/single_event_model.dart';
import '../navigation_items/single_events/single_events_ledger.dart';

// Everything the app persists, in domain form.
class AppData {
    final BalanceModel balance;
    final List<String> categories; // User categories (getCategories() adds "Other")
    final List<SingleEventModel> singleEvents; // Newest-changed first
    bool includeNextCheck; // Settings: show "Next Check" instead of "After This Check"
    int singleEventExpiryDays; // Settings: days after its last change a single event is cleared

    AppData({
        required this.balance,
        List<String>? categories,
        List<SingleEventModel>? singleEvents,
        this.includeNextCheck = false,
        this.singleEventExpiryDays = 30,
    }) : categories = categories ?? defaultCategories(),
         singleEvents = singleEvents ?? [];

    // Single events applied against this data's balance and cards.
    SingleEventsLedger get singleEventsLedger => SingleEventsLedger(balance, singleEvents);
}

class AppDataStore {
    final AppDatabase db;
    AppDataStore(this.db);

    // Reads everything, or returns null if nothing was ever saved (first launch).
    // Doesn't catch up to today: callers run BalanceModel.makeRecent() after.
    Future<AppData?> load() async {
        final AppMetaRow? meta = await (db.select(db.appMetaRows)
              ..where((t) => t.id.equals(0)))
            .getSingleOrNull();
        if (meta == null) return null;

        final BalanceModel balance = BalanceModel(
            currentBalance: meta.currentBalance,
            lastUpdated: meta.lastUpdated,
        );
        final expenseRows = await (db.select(db.expenseItemRows)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
        balance.expenses.addAll(expenseRows.map((row) => row.toDomain()));
        final streamRows = await (db.select(db.incomeStreamModelRows)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
        balance.incomeStreams.addAll(streamRows.map((row) => row.toDomain()));
        balance.activeIncome = _activeStream(balance.incomeStreams);

        final categoryRows = await (db.select(db.categoryRows)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
        final eventRows = await (db.select(db.singleEventRows)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
        return AppData(
            balance: balance,
            categories: categoryRows.map((row) => row.name).toList(),
            singleEvents: eventRows.map((row) => row.toDomain()).toList(),
            includeNextCheck: meta.includeNextCheck,
            singleEventExpiryDays: meta.singleEventExpiryDays,
        );
    }

    // Replaces everything stored with [data], in one transaction (all or nothing).
    // Sets each saved item's id to its new row id.
    Future<void> save(AppData data) {
        final BalanceModel balance = data.balance;
        return db.transaction(() async {
            await db.delete(db.expenseItemRows).go();
            for (final expense in balance.expenses) {
                expense.id = await db.into(db.expenseItemRows).insert(expense.toInsertCompanion());
            }
            await db.delete(db.incomeStreamModelRows).go();
            for (final IncomeStreamModel stream in balance.incomeStreams) {
                stream.isActive = identical(stream, balance.activeIncome);
                stream.id = await db.into(db.incomeStreamModelRows).insert(stream.toInsertCompanion());
            }
            await db.delete(db.categoryRows).go();
            for (final String name in data.categories.toSet()) {
                if (name == otherCategory || name == newCategory) continue;
                await db.into(db.categoryRows).insert(CategoryRowsCompanion.insert(name: name));
            }
            await db.delete(db.singleEventRows).go();
            for (final SingleEventModel event in data.singleEvents) {
                event.id = await db.into(db.singleEventRows).insert(event.toInsertCompanion());
            }
            await db.into(db.appMetaRows).insertOnConflictUpdate(AppMetaRowsCompanion.insert(
                id: const Value(0),
                currentBalance: Value(balance.currentBalance),
                lastUpdated: balance.lastUpdated,
                includeNextCheck: Value(data.includeNextCheck),
                singleEventExpiryDays: Value(data.singleEventExpiryDays),
            ));
        });
    }

    // The stream marked active, or the first one if none is (there should always
    // be one while any stream exists, as in the Java app).
    static IncomeStreamModel? _activeStream(List<IncomeStreamModel> streams) {
        for (final IncomeStreamModel stream in streams) {
            if (stream.isActive) return stream;
        }
        return streams.isEmpty ? null : streams.first;
    }
}
