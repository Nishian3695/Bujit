// The app lock (the Java app's AppLockPrefs + BujitApp.maybeShowLockPrompt): when
// it's on, Bujit asks for the fingerprint/face/device PIN on opening and every
// time it comes back from the background. The setting itself is
// AppData.appLockEnabled; DeviceAuth does the asking, so tests can fake it.
import 'package:flutter/material.dart';
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
    late bool _locked = widget.state.data.appLockEnabled;
    bool _asking = false;

    @override
    void initState() {
        super.initState();
        WidgetsBinding.instance.addObserver(this);
        if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }

    @override
    void dispose() {
        WidgetsBinding.instance.removeObserver(this);
        super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
        // Going to the background locks; coming back asks. (Not "inactive", which the
        // unlock prompt itself can cause.)
        if (lifecycle == AppLifecycleState.paused && widget.state.data.appLockEnabled && !_asking) {
            setState(() => _locked = true);
        } else if (lifecycle == AppLifecycleState.resumed && _locked) {
            _unlock();
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
