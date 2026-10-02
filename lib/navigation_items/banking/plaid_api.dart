// Opens Plaid Link (the Java app launched the Plaid Link SDK from BankingActivity)
// and returns the public token it produces, or null if the user exits.
import 'dart:async';
import 'package:plaid_flutter/plaid_flutter.dart';

abstract class PlaidLinkLauncher {
    Future<String?> open(String linkToken);
}

class PlaidFlutterLauncher implements PlaidLinkLauncher {
    @override
    Future<String?> open(String linkToken) async {
        final Completer<String?> done = Completer();
        final StreamSubscription<LinkSuccess> success =
            PlaidLink.onSuccess.listen((event) { if (!done.isCompleted) done.complete(event.publicToken); });
        final StreamSubscription<LinkExit> exit =
            PlaidLink.onExit.listen((event) { if (!done.isCompleted) done.complete(null); });
        try {
            await PlaidLink.create(configuration: LinkTokenConfiguration(token: linkToken));
            await PlaidLink.open();
            return await done.future;
        } finally {
            await success.cancel();
            await exit.cancel();
        }
    }
}
