import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'finance_store.dart';
import 'screens/main_shell.dart';
import 'screens/tutorial_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = FinanceStore();
  await store.load();
  runApp(OkozukaiApp(store: store));
}

class OkozukaiApp extends StatelessWidget {
  final FinanceStore store;

  const OkozukaiApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: Consumer<FinanceStore>(
        builder: (context, finance, _) {
          return MaterialApp(
            title: 'お小遣い管理',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(mode: finance.themeMode),
            home: finance.hasCompletedTutorial
                ? const MainShell()
                : const TutorialScreen(),
          );
        },
      ),
    );
  }
}
