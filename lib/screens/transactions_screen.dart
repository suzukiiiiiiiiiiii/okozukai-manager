import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../finance_store.dart';
import '../formatters.dart';
import '../models.dart';
import '../widgets/add_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late int _year;
  late int _month;
  String? _selectedCategoryId;
  String? _selectedWalletId;
  TransactionKind? _selectedKind;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_year, _month + delta, 1);
    setState(() {
      _year = next.year;
      _month = next.month;
      _selectedCategoryId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final scheme = Theme.of(context).colorScheme;

    final monthTx = store.transactionsForMonth(_year, _month);
    final monthExp = store.monthlyExpense(_year, _month);
    final monthInc = store.monthlyIncome(_year, _month);
    final catBreakdowns = store.categoryBreakdownsForMonth(_year, _month);
    final walletBreakdowns = store.walletBreakdownsForMonth(_year, _month);

    final filteredTx = monthTx.where((t) {
      if (_selectedKind != null && t.kind != _selectedKind) return false;
      if (_selectedCategoryId != null && t.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_selectedWalletId != null &&
          t.walletId != _selectedWalletId &&
          t.toWalletId != _selectedWalletId) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchNote = t.note.toLowerCase().contains(q);
        final matchCat = t.category.label.toLowerCase().contains(q);
        final wName = store.walletById(t.walletId)?.name.toLowerCase() ?? '';
        if (!matchNote && !matchCat && !wName.contains(q)) return false;
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // 1. 月切り替えバー
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        formatYearMonth(_year, _month),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '支出 ${formatYen(monthExp)}  /  収入 ${formatYen(monthInc)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 2. 「何にいくら使ったか」カテゴリ別支出内訳カード
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'カテゴリ別内訳',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_selectedCategoryId != null)
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedCategoryId = null),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('解除', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (catBreakdowns.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('この月の支出データはありません'),
                  )
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: catBreakdowns.map((b) {
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
                  for (final b in catBreakdowns)
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          _selectedCategoryId =
                              _selectedCategoryId == b.category.id
                                  ? null
                                  : b.category.id;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedCategoryId == b.category.id
                              ? b.category.color.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  b.category.color.withValues(alpha: 0.15),
                              child: Icon(
                                b.category.icon,
                                size: 16,
                                color: b.category.color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${b.category.label} (${b.count}件)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  LinearProgressIndicator(
                                    value: b.ratio,
                                    minHeight: 5,
                                    borderRadius: BorderRadius.circular(4),
                                    color: b.category.color,
                                    backgroundColor:
                                        b.category.color.withValues(alpha: 0.12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatYen(b.amount),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${(b.ratio * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        scheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 3. 決済手段別（現金・PayPay・Suica・クレカ等）の利用額内訳
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '決済手段別の支出額（現金・電子決済・カード）',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (_selectedWalletId != null)
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedWalletId = null),
                        child: const Text('解除', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: walletBreakdowns.map((wb) {
                    final selected = _selectedWalletId == wb.wallet.id;
                    return FilterChip(
                      avatar: Icon(
                        wb.wallet.type.icon,
                        size: 16,
                        color: wb.wallet.color,
                      ),
                      label: Text(
                        '${wb.wallet.name}: ${formatYen(wb.expenseAmount)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedWalletId = selected ? null : wb.wallet.id;
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 4. 検索＆種別フィルタ＋履歴一覧
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'メモやカテゴリ名で検索...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<TransactionKind?>(
              initialValue: _selectedKind,
              tooltip: '種別で絞り込み',
              onSelected: (k) => setState(() => _selectedKind = k),
              itemBuilder: (_) => const [
                PopupMenuItem(value: null, child: Text('すべて表示')),
                PopupMenuItem(
                  value: TransactionKind.expense,
                  child: Text('支出のみ'),
                ),
                PopupMenuItem(
                  value: TransactionKind.income,
                  child: Text('収入のみ'),
                ),
                PopupMenuItem(
                  value: TransactionKind.transfer,
                  child: Text('チャージ・振替のみ'),
                ),
              ],
              child: Chip(
                avatar: const Icon(Icons.filter_list_rounded, size: 16),
                label: Text(_selectedKind?.label ?? 'すべて'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (filteredTx.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('条件に一致する履歴はありません'),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < filteredTx.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _HistoryTile(item: filteredTx[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TransactionItem item;

  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final wallet = store.walletById(item.walletId);
    final toWallet = item.toWalletId != null
        ? store.walletById(item.toWalletId!)
        : null;
    final cat = item.category;
    final scheme = Theme.of(context).colorScheme;

    final title = item.kind == TransactionKind.transfer
        ? (item.note.isNotEmpty
            ? item.note
            : '${wallet?.name ?? ""} → ${toWallet?.name ?? ""} チャージ')
        : (item.note.isNotEmpty ? item.note : cat.label);

    final subtitle = item.kind == TransactionKind.transfer
        ? '${formatDateFull(item.date)} · ${wallet?.name ?? ""} → ${toWallet?.name ?? ""}'
        : '${formatDateFull(item.date)} · ${cat.label} · ${wallet?.name ?? ""}';

    final String amtStr;
    final Color amtColor;
    switch (item.kind) {
      case TransactionKind.expense:
        amtStr = '-${formatYen(item.amount)}';
        amtColor = scheme.onSurface;
        break;
      case TransactionKind.income:
        amtStr = '+${formatYen(item.amount)}';
        amtColor = const Color(0xFF2E7D32);
        break;
      case TransactionKind.transfer:
        amtStr = formatYen(item.amount);
        amtColor = scheme.primary;
        break;
    }

    return ListTile(
      onTap: () => showAddTransactionSheet(context, existing: item),
      leading: CircleAvatar(
        backgroundColor: cat.color.withValues(alpha: 0.15),
        child: Icon(cat.icon, color: cat.color, size: 20),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amtStr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: amtColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            tooltip: '削除',
            onPressed: () => store.deleteTransaction(item.id),
          ),
        ],
      ),
    );
  }
}
