import 'package:flutter/material.dart';
import 'navigation_items/expense_activity/expense_activity.dart';

void main() {
  runApp(const BujitApp());
}

// App root. The home screen (ExpenseActivity) mirrors the Java app's main
// screen; other screens get added as routes as they're ported.
class BujitApp extends StatelessWidget {
  const BujitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bujit',
      home: ExpenseActivity(),
    );
  }
}
