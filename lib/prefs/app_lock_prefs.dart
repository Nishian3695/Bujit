// The app lock (the Java app's AppLockPrefs + BujitApp.maybeShowLockPrompt): when
// it's on, Bujit asks for the fingerprint/face/device PIN on opening and every
// time it comes back from the background. The setting itself is
// AppData.appLockEnabled; DeviceAuth does the asking, so tests can fake it.
// While it's on, the app switcher shows a cover instead of the budget.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../app_state.dart';

abstract class DeviceAuth {
    // Whether the device has a screen lock (biometrics or PIN/pattern/password) to use.
    Future<bool> isAvailable();
    // Asks for it; true once the user is confirmed.
    Future<bool> authenticate(String reason);
}

class LocalDeviceAuth implements DeviceAuth {
    final LocalAuthentication _auth = LocalAuthentication();

    @override
    Future<bool> isAvailable() async {
        try {
            return await _auth.isDeviceSupported();
        } catch (_) {
            return false;
        }
    }

    @override
    Future<bool> authenticate(String reason) async {
        try {
            // Biometrics or the device credential, as in the Java app.
            return await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
        } on LocalAuthException {
            return false;
        }
    }
}

// Covers the whole app (every screen and dialog) while it's locked.
class AppLockGate extends StatefulWidget {
    final AppState state;
    final DeviceAuth auth;
    final Widget child;

    const AppLockGate({super.key, required this.state, required this.auth, required this.child});

    @override
    State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
    static const MethodChannel _privacy = MethodChannel("bujit/privacy");

    late bool _locked = widget.state.data.appLockEnabled;
    bool _asking = false;
    // Covered (not locked) while leaving the foreground, so the app switcher's
    // snapshot shows the cover rather than balances.
    bool _covered = false;
    bool? _hiddenInRecents;

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addObserver(this);
        if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
        _syncRecents();
    }

    @override
    void didUpdateWidget(AppLockGate oldWidget) {
        super.didUpdateWidget(oldWidget);
        _syncRecents(); // The setting may have just changed in Settings
    }

    // On Android, keeps the system from taking a recents snapshot while the lock is on.
    void _syncRecents() {
        final bool hide = widget.state.data.appLockEnabled;
        if (hide == _hiddenInRecents || defaultTargetPlatform != TargetPlatform.android) return;
        _hiddenInRecents = hide;
        _privacy.invokeMethod<void>("setHiddenInRecents", hide).catchError((Object _) {});
    }

    @override
    void dispose() {
        WidgetsBinding.instance.removeObserver(this);
        super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
        // Going to the background locks; coming back asks. "Inactive" only covers the
        // app (for the app switcher), since the unlock prompt itself can cause it.
        final bool lockOn = widget.state.data.appLockEnabled;
        if (lifecycle == AppLifecycleState.paused && lockOn && !_asking) {
            setState(() => _locked = true);
        } else if ((lifecycle == AppLifecycleState.inactive || lifecycle == AppLifecycleState.hidden) &&
                lockOn && !_asking && !_covered) {
            setState(() => _covered = true);
        } else if (lifecycle == AppLifecycleState.resumed) {
            if (_covered) setState(() => _covered = false);
            if (_locked) _unlock();
        }
    }

    Future<void> _unlock() async {
        if (_asking) return;
        _asking = true;
        final bool ok = await widget.auth.authenticate("Authenticate to access your budget");
        _asking = false;
        if (ok && mounted) setState(() => _locked = false);
    }

    @override
    Widget build(BuildContext context) {
        return Stack(
            children: [
                widget.child,
                if (_covered && !_locked)
                    Positioned.fill(
                        child: Material(child: Center(child: Icon(Icons.lock, size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant))),
                    ),
                if (_locked)
                    Positioned.fill(
                        child: Material(
                            child: SafeArea(
                                child: Center(
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            const Icon(Icons.lock, size: 48),
                                            const SizedBox(height: 12),
                                            const Text("Bujit is locked"),
                                            const SizedBox(height: 12),
                                            FilledButton(onPressed: _unlock, child: const Text("Unlock")),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    ),
            ],
        );
    }
}
