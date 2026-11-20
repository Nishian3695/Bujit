package io.github.nishian3695.bujit

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// A FragmentActivity so the app lock's biometric prompt (local_auth) can show.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Release builds' App Check (Play Integrity exchanged at the backend); see ReleaseAppCheck.
        MethodChannel(messenger, "bujit/app_check").setMethodCallHandler { call, result ->
            when (call.method) {
                "installReleaseProvider" -> try {
                    result.success(ReleaseAppCheck.install())
                } catch (e: Exception) {
                    result.error("app_check", e.message, null)
                }
                else -> result.notImplemented()
            }
        }

        // While the app lock is on, the recents screen shows no snapshot of the budget
        // (Android 13+); older versions get FLAG_SECURE, which also blocks screenshots.
        // See AppLockGate.
        MethodChannel(messenger, "bujit/privacy").setMethodCallHandler { call, result ->
            when (call.method) {
                "setHiddenInRecents" -> {
                    val hide = call.arguments as? Boolean ?: false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        setRecentsScreenshotEnabled(!hide)
                    } else if (hide) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Importing the Java app's data after an update from it; see JavaMigration.
        MethodChannel(messenger, "bujit/java_migration").setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> Thread {
                    try {
                        val data = JavaMigration.read(applicationContext)
                        runOnUiThread { result.success(data) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("java_migration", e.message, null) }
                    }
                }.start()
                "markMigrated" -> result.success(JavaMigration.markMigrated(applicationContext))
                else -> result.notImplemented()
            }
        }
    }
}
