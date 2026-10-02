import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'app_state.dart';
import 'config/firebase_config.dart';
import 'navigation_items/banking/banking_prefs.dart';
import 'navigation_items/banking/banking_provider_config.dart';
import 'navigation_items/banking/plaid_api.dart';
import 'navigation_items/banking/plaid_backend_client.dart';
import 'navigation_items/expense_activity/balance_model.dart';
import 'navigation_items/expense_activity/expense_activity.dart';
import 'navigation_items/settings/google_tasks_account.dart';
import 'navigation_items/settings/google_tasks_helper.dart';
import 'navigation_items/settings/tip_jar.dart';
import 'prefs/app_lock_prefs.dart';
import 'storage_management/app_data_store.dart';
import 'storage_management/java_migration.dart';
import 'storage_management/storage_manager.dart';
import 'utils/sample_data.dart';

final Logger _logger = Logger("BujitMain");

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Log records go to the console (Logcat on Android, as "flutter").
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) => debugPrint([
        "${record.level.name} ${record.loggerName}: ${record.message}",
        if (record.error != null) "  ${record.error}",
        if (record.stackTrace != null) "${record.stackTrace}",
      ].join("\n")));
  runApp(const BujitApp());
}

// Opens the encrypted database and loads the app's data (see AppState.open).
// If storage can't be opened, falls back to the sample data without saving,
// so the app still runs; the home screen warns that changes won't be kept.
Future<AppState> openAppState() async {
  final DeviceAuth deviceAuth = LocalDeviceAuth();
  try {
    final storage = await StorageManager.create(await getApplicationDocumentsDirectory());
    final AppState state = await AppState.open(
      storage.store,
      tasks: GoogleTasksSync(GoogleTasksApi(GoogleTasksAccount())),
      banking: BankingService(
        PlaidBackendClient(host: bankingBackendHost, auth: FirebaseBankingAuth()),
        PlaidFlutterLauncher(),
      ),
      javaData: AndroidJavaDataSource(),
    );
    return state
      ..deviceAuth = deviceAuth
      ..tipJar = (TipJar(InAppPurchaseTipStore())..load());
  } catch (e, stack) {
    _logger.severe("Couldn't open storage", e, stack);
    final AppData data = AppData(balance: BalanceModel(currentBalance: 0.00));
    seedSampleData(data.balance);
    return AppState(data)..deviceAuth = deviceAuth;
  }
}

// App root: shows a loading screen until the data is ready, then the home screen
// (ExpenseActivity, which mirrors the Java app's main screen). The app lock, when
// on, covers every screen (see AppLockGate).
class BujitApp extends StatefulWidget {
  const BujitApp({super.key});

  @override
  State<BujitApp> createState() => _BujitAppState();
}

class _BujitAppState extends State<BujitApp> {
  AppState? _state;

  @override
  void initState() {
    super.initState();
    openAppState().then((state) {
      if (mounted) setState(() => _state = state);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState? state = _state;
    return MaterialApp(
      title: 'Bujit',
      home: state == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : ExpenseActivity(state: state),
      builder: (context, child) => state == null
          ? child!
          : AppLockGate(state: state, auth: state.deviceAuth ?? LocalDeviceAuth(), child: child!),
    );
  }
}
