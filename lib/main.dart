import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/budget_store.dart';
import 'src/overview_screen.dart';
import 'src/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final store = await BudgetStore.load(PrefsBudgetStorage());
  runApp(BudgetApp(store: store));
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key, required this.store});

  final BudgetStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: OverviewScreen(store: store),
    );
  }
}
