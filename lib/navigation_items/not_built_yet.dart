// Placeholder for menu screens that haven't been ported from the Java app yet,
// so every menu item already navigates somewhere.
import 'package:flutter/material.dart';

class NotBuiltYet extends StatelessWidget {
    final String title;
    const NotBuiltYet({super.key, required this.title});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Center(child: Text("$title isn't built yet.")),
        );
    }
}
