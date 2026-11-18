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
    final recentTx = store.transactions.take(6).toList();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // 1. 総資産・今月の収支サマリーカード
        Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '現在の総残高（現金＋電子決済＋口座）',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InkWell(
                    onTap: () => showAddTransactionSheet(
                      context,
                      initialKind: TransactionKind.transfer,
                    ),
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
              Text(
                formatYen(store.totalBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricBox(
                      label: '${now.month}月の支出合計',
                      value: formatYen(monthExp),
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricBox(
                      label: '${now.month}月の収入合計',
                      value: formatYen(monthInc),
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. 現金・電子決済ごとの残高一覧（横スクロール）
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '現金・電子決済・口座の残高',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () => onNavigateTab(3),
              child: const Text('管理・固定費 >', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: store.wallets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final w = store.wallets[index];
              final bal = store.walletBalance(w.id);
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => showAddTransactionSheet(
                  context,
                  initialWalletId: w.id,
                ),
                child: Card(
                  child: Container(
                    width: 155,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: w.color.withValues(alpha: 0.15),
                              child: Icon(w.type.icon, size: 15, color: w.color),
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
                        Text(
                          formatYen(bal),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: bal < 0 ? scheme.error : scheme.onSurface,
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

        const SizedBox(height: 18),

        // 3. 「◯ヶ月この金額で生活するには1日いくらまで」クイック目安カード
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 20,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '1日あたりの生活目安',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => onNavigateTab(2),
                      child: const Text(
                        '詳細シミュレーター >',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final preset in const [
                        (label: '1ヶ月(30日)', days: 30),
                        (label: '2ヶ月(60日)', days: 60),
                        (label: '3ヶ月(90日)', days: 90),
                        (label: '6ヶ月(180日)', days: 180),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              preset.label,
                              style: const TextStyle(fontSize: 11),
                            ),
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
                          color: scheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${sim.totalDays}日間で暮らすなら1日上限',
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatYen(sim.dailyLimit)} / 日',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: sim.dailyLimit < 0
                                    ? scheme.error
                                    : scheme.primary,
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
                              '今日あと使える金額',
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatYen(sim.todayRemaining),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: sim.todayRemaining < 0
                                    ? scheme.error
                                    : scheme.onSurface,
                              ),
                            ),
                            Text(
                              '今日の支出: ${formatYen(sim.todayVariableSpent)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurface.withValues(alpha: 0.6),
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

        // 4. ワンタップ簡単記録
        if (store.quickTemplates.isNotEmpty) ...[
          const Text(
            'ワンタップ簡単記録（よく使う支出）',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: store.quickTemplates.map((tpl) {
              final w = store.walletById(tpl.walletId);
              return ActionChip(
                avatar: Icon(
                  tpl.category.icon,
                  size: 16,
                  color: tpl.category.color,
                ),
                label: Text(
                  '${tpl.title} ${formatYen(tpl.amount)}'
                  '${w != null ? " · ${w.name}" : ""}',
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
          const SizedBox(height: 18),
        ],

        // 5. 今月何にいくら使ったか（上位カテゴリ）
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${now.month}月 何にいくら使ったか',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton(
                      onPressed: () => onNavigateTab(1),
                      child: const Text('すべて見る >', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                if (breakdowns.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '今月の支出はまだありません',
                      style: TextStyle(fontSize: 13),
                    ),
                  )
                else ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 10,
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
                            size: 18,
                            color: b.category.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b.category.label,
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

        // 6. 直近の履歴
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '直近の入出金・チャージ履歴',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () => onNavigateTab(1),
              child: const Text('履歴一覧 >', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        if (recentTx.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('まだ記録がありません。右下の「＋記録」から追加できます。')),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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
        amountColor = const Color(0xFF2E7D32);
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
        child: Icon(cat.icon, color: cat.color, size: 20),
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
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: amountColor,
        ),
      ),
    );
  }
}
