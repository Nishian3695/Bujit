package io.github.nishian3695.bujit

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
