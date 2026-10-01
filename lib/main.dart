import 'package:flutter/material.dart';

void main() {
  runApp(const BujitApp());
}

/// Bare-bones entry point so the project runs out of the box. Replace
/// this with your own translation of the original app's screens/navigation
/// as you build out lib/ExpenseActivity, lib/NavigationItems, etc.
class BujitApp extends StatelessWidget {
  const BujitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bujit',
      home: Scaffold(
        appBar: AppBar(title: const Text('Bujit')),
        body: const Center(child: Text('Bare-bones scaffold - start translating here.')),
      ),
    );
  }
}
