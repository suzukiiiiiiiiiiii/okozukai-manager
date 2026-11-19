import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../finance_store.dart';
import '../widgets/add_transaction_sheet.dart';
import 'dashboard_screen.dart';
import 'simulator_screen.dart';
import 'transactions_screen.dart';
import 'wallets_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'お小遣い管理',
    '内訳・履歴',
    '1日の生活目安',
    '決済・固定費・設定',
  ];

  void _setTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final scheme = Theme.of(context).colorScheme;

    final screens = [
      DashboardScreen(onNavigateTab: _setTab),
      const TransactionsScreen(),
      const SimulatorScreen(),
      const WalletsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<AppThemeMode>(
            tooltip: 'テーマを変更',
            initialValue: store.themeMode,
            onSelected: store.setThemeMode,
            itemBuilder: (context) => [
              for (final mode in AppThemeMode.values)
                PopupMenuItem(
                  value: mode,
                  child: Row(
                    children: [
                      Icon(
                        mode.icon,
                        size: 18,
                        color: store.themeMode == mode
                            ? scheme.primary
                            : scheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        mode.label,
                        style: TextStyle(
                          fontWeight: store.themeMode == mode
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      if (store.themeMode == mode) ...[
                        const Spacer(),
                        Icon(Icons.check_rounded,
                            size: 16, color: scheme.primary),
                      ],
                    ],
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(store.themeMode.icon, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    store.themeMode.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // チュートリアル体験モード中のみ表示されるバナー
          if (store.isTutorialDemoMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: scheme.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'チュートリアル体験中（使用例を表示しています）',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: store.exitTutorialDemoMode,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '終了して本番へ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
      floatingActionButton: (store.isSimpleTheme && _currentIndex == 0)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddTransactionSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                '記録する',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _setTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: '内訳・履歴',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate_rounded),
            label: '生活目安',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: '決済・設定',
          ),
        ],
      ),
    );
  }
}
