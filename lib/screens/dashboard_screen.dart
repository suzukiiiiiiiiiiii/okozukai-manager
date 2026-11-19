import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../finance_store.dart';
import '../formatters.dart';
import '../models.dart';
import '../widgets/add_transaction_sheet.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final now = DateTime.now();
    final sim = store.calculateSimulation(nowOverride: now);
    final monthExp = store.monthlyExpense(now.year, now.month);
    final monthInc = store.monthlyIncome(now.year, now.month);
    final breakdowns = store.categoryBreakdownsForMonth(now.year, now.month);
    final recentTx = store.transactions.take(5).toList();
    final scheme = Theme.of(context).colorScheme;
    final simple = store.isSimpleTheme;

    if (simple) {
      return _SimpleDashboardBody(
        store: store,
        now: now,
        sim: sim,
        monthExp: monthExp,
        monthInc: monthInc,
        recentTx: store.transactions.take(4).toList(),
        onNavigateTab: onNavigateTab,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // 1. 総資産・今月の収支サマリーカード
        _BalanceSummaryCard(
          totalBalance: store.totalBalance,
          month: now.month,
          monthExpense: monthExp,
          monthIncome: monthInc,
          simple: false,
          onTapTransfer: () => showAddTransactionSheet(
            context,
            initialKind: TransactionKind.transfer,
          ),
        ),

        const SizedBox(height: 16),

        // 2. 1日あたりの生活目安（コンパクト表示）
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        '1日の生活目安',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onNavigateTab(2),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('詳細 >', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final preset in const [
                        (label: '1ヶ月', days: 30),
                        (label: '2ヶ月', days: 60),
                        (label: '3ヶ月', days: 90),
                        (label: '6ヶ月', days: 180),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              preset.label,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            selected: store.simDays == preset.days,
                            onSelected: (_) => store.updateSimulationConfig(
                              simDays: preset.days,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: simple
                              ? const Color(0xFFF3F4F6)
                              : scheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${sim.totalDays}日間・1日上限',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${formatYen(sim.dailyLimit)} / 日',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: sim.dailyLimit < 0
                                      ? scheme.error
                                      : scheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '今日あと使える額',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatYen(sim.todayRemaining),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: sim.todayRemaining < 0
                                      ? scheme.error
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // 3. 決済手段ごとの残高一覧
        Row(
          children: [
            const Expanded(
              child: Text(
                '決済手段の残高',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => onNavigateTab(3),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('管理・固定費 >', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: store.wallets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final w = store.wallets[index];
              final bal = store.walletBalance(w.id);
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => showAddTransactionSheet(
                  context,
                  initialWalletId: w.id,
                ),
                child: Card(
                  child: Container(
                    width: 148,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              w.type.icon,
                              size: 16,
                              color: simple ? scheme.primary : w.color,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                w.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatYen(bal),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: bal < 0 ? scheme.error : scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // スタンダード／ダーク時のみワンタップ記録を表示（シンプルモードはスッキリ維持）
        if (!simple && store.quickTemplates.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text(
            'ワンタップ記録',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: store.quickTemplates.map((tpl) {
              return ActionChip(
                avatar: Icon(
                  tpl.category.icon,
                  size: 15,
                  color: tpl.category.color,
                ),
                label: Text(
                  '${tpl.title} ${formatYen(tpl.amount)}',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  await store.addTransaction(
                    TransactionItem(
                      id: 'tx_${now.microsecondsSinceEpoch}',
                      kind: TransactionKind.expense,
                      amount: tpl.amount,
                      categoryId: tpl.categoryId,
                      walletId: tpl.walletId,
                      note: tpl.title,
                      date: now,
                    ),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '「${tpl.title} (${formatYen(tpl.amount)})」を記録しました',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 18),

        // 4. 今月の支出内訳（上位カテゴリ）
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${now.month}月の支出内訳',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onNavigateTab(1),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('すべて見る >', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                if (breakdowns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '今月の支出はまだありません',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: breakdowns.map((b) {
                          final flex = (b.ratio * 1000).round().clamp(1, 1000);
                          return Expanded(
                            flex: flex,
                            child: Container(color: b.category.color),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final b in breakdowns.take(4))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            b.category.icon,
                            size: 16,
                            color: b.category.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b.category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${(b.ratio * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            formatYen(b.amount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // 5. 直近の履歴
        Row(
          children: [
            const Expanded(
              child: Text(
                '直近の履歴',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => onNavigateTab(1),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('履歴一覧 >', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (recentTx.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'まだ記録がありません。右下の「＋ 記録する」から追加できます。',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < recentTx.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _TransactionRow(item: recentTx[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  final int totalBalance;
  final int month;
  final int monthExpense;
  final int monthIncome;
  final bool simple;
  final VoidCallback onTapTransfer;

  const _BalanceSummaryCard({
    required this.totalBalance,
    required this.month,
    required this.monthExpense,
    required this.monthIncome,
    required this.simple,
    required this.onTapTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (simple) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '総残高',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onTapTransfer,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 15),
                    label: const Text(
                      'チャージ・振替',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatYen(totalBalance),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$month月の支出',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatYen(monthExpense),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$month月の収入',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatYen(monthIncome),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.25)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '現在の総残高',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onTapTransfer,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'チャージ・振替',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatYen(totalBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniMetricBox(
                  label: '$month月の支出',
                  value: formatYen(monthExpense),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetricBox(
                  label: '$month月の収入',
                  value: formatYen(monthIncome),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniMetricBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionItem item;

  const _TransactionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final wallet = store.walletById(item.walletId);
    final toWallet = item.toWalletId != null
        ? store.walletById(item.toWalletId!)
        : null;
    final cat = item.category;
    final scheme = Theme.of(context).colorScheme;

    final String titleText;
    if (item.kind == TransactionKind.transfer) {
      titleText = item.note.isNotEmpty
          ? item.note
          : '${wallet?.name ?? ""} → ${toWallet?.name ?? ""} チャージ';
    } else {
      titleText = item.note.isNotEmpty ? item.note : cat.label;
    }

    final String subtitleText;
    if (item.kind == TransactionKind.transfer) {
      subtitleText =
          '${formatDateShort(item.date)} · ${wallet?.name ?? ""} → ${toWallet?.name ?? ""}';
    } else {
      subtitleText =
          '${formatDateShort(item.date)} · ${cat.label} · ${wallet?.name ?? ""}';
    }

    final Color amountColor;
    final String amountText;
    switch (item.kind) {
      case TransactionKind.expense:
        amountColor = scheme.onSurface;
        amountText = '-${formatYen(item.amount)}';
        break;
      case TransactionKind.income:
        amountColor = const Color(0xFF15803D);
        amountText = '+${formatYen(item.amount)}';
        break;
      case TransactionKind.transfer:
        amountColor = scheme.primary;
        amountText = formatYen(item.amount);
        break;
    }

    return ListTile(
      onTap: () => showAddTransactionSheet(context, existing: item),
      leading: CircleAvatar(
        backgroundColor: cat.color.withValues(alpha: 0.14),
        child: Icon(cat.icon, color: cat.color, size: 19),
      ),
      title: Text(
        titleText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitleText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Text(
        amountText,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: amountColor,
        ),
      ),
    );
  }
}

/// シンプルテーマ専用の超スッキリ・ミニマルホーム画面。
/// 情報量を「総残高・今日の目安・2つの記録ボタン・直近履歴」だけに絞り、
/// 迷わず直感的に使える構成にしている。
class _SimpleDashboardBody extends StatelessWidget {
  final FinanceStore store;
  final DateTime now;
  final SurvivalSimulation sim;
  final int monthExp;
  final int monthInc;
  final List<TransactionItem> recentTx;
  final ValueChanged<int> onNavigateTab;

  const _SimpleDashboardBody({
    required this.store,
    required this.now,
    required this.sim,
    required this.monthExp,
    required this.monthInc,
    required this.recentTx,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.55);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: [
        // 1. 残高と今日の目安（余白を活かした1つのクリーンブロック）
        const SizedBox(height: 4),
        Text(
          '総残高',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatYen(store.totalBalance),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 1日の目安（タップで生活目安タブへ）
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onNavigateTab(2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '今日あと使える目安（${sim.totalDays}日割）',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: muted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatYen(sim.todayRemaining),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: sim.todayRemaining < 0
                        ? scheme.error
                        : scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 18, color: muted),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 2. 迷わない2つの大きなアクションボタン
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => showAddTransactionSheet(
                  context,
                  initialKind: TransactionKind.expense,
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.remove_rounded, size: 18),
                label: const Text(
                  '支出を記録',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showAddTransactionSheet(
                  context,
                  initialKind: TransactionKind.income,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  '収入・チャージ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // 3. 今月の収支（1行だけの簡潔サマリー）
        Row(
          children: [
            Expanded(
              child: Text(
                '${now.month}月の支出  ${formatYen(monthExp)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ),
            Text(
              '収入  ${formatYen(monthInc)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 20),

        // 4. 最近の記録（最新4件のみ）
        Row(
          children: [
            const Expanded(
              child: Text(
                '最近の記録',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => onNavigateTab(1),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('すべて見る >', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentTx.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'まだ記録がありません',
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < recentTx.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _TransactionRow(item: recentTx[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
