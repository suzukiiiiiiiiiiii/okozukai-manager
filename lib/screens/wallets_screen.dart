import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../finance_store.dart';
import '../formatters.dart';
import '../models.dart';
import '../widgets/add_recurring_sheet.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/add_wallet_sheet.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final scheme = Theme.of(context).colorScheme;
    final fixedInc = store.monthlyFixedIncomeTotal;
    final fixedExp = store.monthlyFixedExpenseTotal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // 1. 現金・電子決済・口座・カード管理セクション
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '現金・電子決済・口座の管理',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => showAddTransactionSheet(
                    context,
                    initialKind: TransactionKind.transfer,
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('チャージ', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: () => showAddWalletSheet(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('追加', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < store.wallets.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                Builder(
                  builder: (context) {
                    final w = store.wallets[i];
                    final bal = store.walletBalance(w.id);
                    return ListTile(
                      onTap: () => showAddWalletSheet(context, existing: w),
                      leading: CircleAvatar(
                        backgroundColor: w.color.withValues(alpha: 0.15),
                        child: Icon(w.type.icon, color: w.color, size: 20),
                      ),
                      title: Text(
                        w.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${w.type.label} · '
                        '${w.includeInSimulation ? "生活目安対象" : "目安対象外"}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatYen(bal),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color:
                                  bal < 0 ? scheme.error : scheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 22),

        // 2. 固定引き落とし・固定収入（定期収支）セクション
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '固定引き落とし・固定収入',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => showAddRecurringSheet(
                    context,
                    initialIsIncome: true,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('固定収入', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: () => showAddRecurringSheet(
                    context,
                    initialIsIncome: false,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('固定引落', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 固定収支の月額サマリー
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '毎月の固定収入合計',
                        style: TextStyle(fontSize: 11),
                      ),
                      Text(
                        '+${formatYen(fixedInc)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '毎月の固定引落合計',
                        style: TextStyle(fontSize: 11),
                      ),
                      Text(
                        '-${formatYen(fixedExp)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '固定収支ベース差引',
                        style: TextStyle(fontSize: 11),
                      ),
                      Text(
                        formatYen(fixedInc - fixedExp, showPlus: true),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        if (store.recurringRules.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('固定引き落とし（サブスク・通信費・家賃等）や固定収入はまだ登録されていません'),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < store.recurringRules.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  Builder(
                    builder: (context) {
                      final rule = store.recurringRules[i];
                      final w = store.walletById(rule.walletId);
                      final cat = rule.category;
                      return ListTile(
                        onTap: () =>
                            showAddRecurringSheet(context, existing: rule),
                        leading: CircleAvatar(
                          backgroundColor: cat.color.withValues(alpha: 0.15),
                          child: Icon(cat.icon, color: cat.color, size: 20),
                        ),
                        title: Text(
                          rule.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: rule.enabled
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          '${rule.dayLabel} · ${w?.name ?? ""} · '
                          '${rule.autoRecord ? "到来日自動計上" : "手動/目安反映のみ"}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  rule.isIncome
                                      ? '+${formatYen(rule.amount)}'
                                      : '-${formatYen(rule.amount)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: rule.isIncome
                                        ? const Color(0xFF2E7D32)
                                        : scheme.onSurface,
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    await store.recordRecurringRuleNow(rule);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '「${rule.title}」を履歴に計上しました',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    '今すぐ計上',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              onPressed: () =>
                                  store.deleteRecurringRule(rule.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 22),

        // 3. ワンタップ記録テンプレートの整理 & データリセット
        const Text(
          'データ管理・初期設定',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.restore_rounded),
                title: const Text(
                  'サンプルデータを復元する',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  '現金・PayPay・Suica・銀行口座と固定収支のサンプル状態に戻します',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  await store.resetAllData(withSampleData: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('サンプルデータを復元しました')),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.delete_sweep_outlined, color: scheme.error),
                title: Text(
                  '全履歴をクリアして残高0から始める',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.error,
                  ),
                ),
                subtitle: const Text(
                  'すべての取引履歴を消去し、残高0円から新しく記録を始めます',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  await store.resetAllData(withSampleData: false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('データを初期化しました')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
