import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'app_state.dart';
import 'navigation_items/expense_activity/balance_model.dart';
import 'navigation_items/expense_activity/expense_activity.dart';
import 'storage_management/app_data_store.dart';
import 'storage_management/storage_manager.dart';
import 'utils/sample_data.dart';

final Logger _logger = Logger("BujitMain");

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BujitApp());
}

// Opens the encrypted database and loads the app's data (see AppState.open).
// If storage can't be opened, falls back to the sample data without saving,
// so the app still runs; the home screen warns that changes won't be kept.
Future<AppState> openAppState() async {
  try {
    final storage = await StorageManager.create(await getApplicationDocumentsDirectory());
    return await AppState.open(storage.store);
  } catch (e, stack) {
    _logger.severe("Couldn't open storage", e, stack);
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.00));
    seedSampleData(data.balance);
    return AppState(data);
  }
}

// App root: shows a loading screen until the data is ready, then the home screen
// (ExpenseActivity, which mirrors the Java app's main screen).
class BujitApp extends StatefulWidget {
  const BujitApp({super.key});

  @override
  State<BujitApp> createState() => _BujitAppState();
}

class _BujitAppState extends State<BujitApp> {
  late final Future<AppState> _state = openAppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bujit',
      home: FutureBuilder<AppState>(
        future: _state,
        builder: (context, snapshot) {
          final AppState? state = snapshot.data;
          if (state == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return ExpenseActivity(state: state);
        },
      ),
    );
  }
}
