import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../finance_store.dart';
import '../formatters.dart';
import '../models.dart';

/// 支出・収入・チャージ（振替）を素早く入力・編集するボトムシート
Future<void> showAddTransactionSheet(
  BuildContext context, {
  TransactionItem? existing,
  TransactionKind initialKind = TransactionKind.expense,
  String? initialWalletId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddTransactionSheet(
      existing: existing,
      initialKind: initialKind,
      initialWalletId: initialWalletId,
    ),
  );
}

class _AddTransactionSheet extends StatefulWidget {
  final TransactionItem? existing;
  final TransactionKind initialKind;
  final String? initialWalletId;

  const _AddTransactionSheet({
    this.existing,
    required this.initialKind,
    this.initialWalletId,
  });

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  late TransactionKind _kind;
  late TextEditingController _amountCtrl;
  late TextEditingController _noteCtrl;
  late String _categoryId;
  late String _walletId;
  String? _toWalletId;
  late DateTime _selectedDate;
  bool _saveAsTemplate = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<FinanceStore>();
    final ex = widget.existing;
    _kind = ex?.kind ?? widget.initialKind;
    _amountCtrl = TextEditingController(
      text: ex != null ? ex.amount.toString() : '',
    );
    _noteCtrl = TextEditingController(text: ex?.note ?? '');

    if (ex != null) {
      _categoryId = ex.categoryId;
      _walletId = ex.walletId;
      _toWalletId = ex.toWalletId;
      _selectedDate = ex.date;
    } else {
      _categoryId = _kind == TransactionKind.income ? 'allowance' : 'food';
      _walletId = widget.initialWalletId ??
          (store.wallets.isNotEmpty ? store.wallets.first.id : 'cash');
      _toWalletId = store.wallets.length > 1 ? store.wallets[1].id : _walletId;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _addAmount(int delta) {
    final current = int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final next = (current + delta).clamp(0, 99999999);
    setState(() {
      _amountCtrl.text = next == 0 ? '' : next.toString();
    });
  }

  Future<void> _submit() async {
    final rawAmt = int.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    if (rawAmt == null || rawAmt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('1円以上の金額を入力してください')),
      );
      return;
    }
    if (_kind == TransactionKind.transfer && _walletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('出金元とチャージ先は別の決済手段を選んでください')),
      );
      return;
    }

    final store = context.read<FinanceStore>();
    final note = _noteCtrl.text.trim();
    final id = widget.existing?.id ??
        'tx_${DateTime.now().microsecondsSinceEpoch}';

    final tx = TransactionItem(
      id: id,
      kind: _kind,
      amount: rawAmt,
      categoryId: _kind == TransactionKind.transfer ? 'transfer' : _categoryId,
      walletId: _walletId,
      toWalletId: _kind == TransactionKind.transfer ? _toWalletId : null,
      note: note,
      date: _selectedDate,
      isFixed: widget.existing?.isFixed ?? false,
      recurringRuleId: widget.existing?.recurringRuleId,
    );

    if (widget.existing != null) {
      await store.updateTransaction(tx);
    } else {
      await store.addTransaction(tx);
      if (_saveAsTemplate && _kind == TransactionKind.expense) {
        final cat = AppCategories.byId(_categoryId);
        await store.addQuickTemplate(
          QuickTemplate(
            id: 'tpl_${DateTime.now().microsecondsSinceEpoch}',
            title: note.isNotEmpty ? note : cat.label,
            amount: rawAmt,
            categoryId: _categoryId,
            walletId: _walletId,
          ),
        );
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _applyQuickTemplate(QuickTemplate tpl) async {
    final store = context.read<FinanceStore>();
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
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${tpl.title} (${formatYen(tpl.amount)})」を記録しました'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final categories = _kind == TransactionKind.income
        ? AppCategories.incomeCategories
        : AppCategories.expenseCategories;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existing != null ? '記録の編集' : 'かんたん収支・チャージ記録',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 種別切り替え（支出 / 収入 / チャージ・振替）
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TransactionKind>(
                segments: const [
                  ButtonSegment(
                    value: TransactionKind.expense,
                    label: Text('支出'),
                    icon: Icon(Icons.remove_circle_outline, size: 18),
                  ),
                  ButtonSegment(
                    value: TransactionKind.income,
                    label: Text('収入'),
                    icon: Icon(Icons.add_circle_outline, size: 18),
                  ),
                  ButtonSegment(
                    value: TransactionKind.transfer,
                    label: Text('チャージ・振替'),
                    icon: Icon(Icons.swap_horiz_rounded, size: 18),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) {
                  final next = selection.first;
                  setState(() {
                    _kind = next;
                    if (next == TransactionKind.income) {
                      _categoryId = 'allowance';
                    } else if (next == TransactionKind.expense) {
                      _categoryId = 'food';
                    }
                  });
                },
              ),
            ),

            // ワンタップ記録テンプレート（新規支出時のみ表示）
            if (widget.existing == null &&
                _kind == TransactionKind.expense &&
                store.quickTemplates.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'ワンタップ即時記録（タップでそのまま登録）',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: store.quickTemplates.map((tpl) {
                    final wallet = store.walletById(tpl.walletId);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(
                          tpl.category.icon,
                          size: 16,
                          color: tpl.category.color,
                        ),
                        label: Text(
                          '${tpl.title} ${formatYen(tpl.amount)}'
                          '${wallet != null ? " (${wallet.name})" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => _applyQuickTemplate(tpl),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 金額入力 + クイック加算ボタン
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                labelText: '金額 (円)',
                prefixText: '¥ ',
                suffixIcon: _amountCtrl.text.isNotEmpty
                    ? IconButton(
                        onPressed: () => setState(() => _amountCtrl.clear()),
                        icon: const Icon(Icons.backspace_outlined),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final amt in [100, 500, 1000, 3000, 5000, 10000])
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _addAmount(amt),
                    child: Text(
                      '+${formatYen(amt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // 決済手段（現金・電子マネー・QR決済・銀行口座等）の選択
            Text(
              _kind == TransactionKind.transfer
                  ? '出金元（チャージ元）の決済手段・口座'
                  : (_kind == TransactionKind.income
                      ? '入金先の決済手段・口座'
                      : '支払った決済手段（現金・電子決済・カード）'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: store.wallets.map((w) {
                final selected = _walletId == w.id;
                final bal = store.walletBalance(w.id);
                return ChoiceChip(
                  avatar: Icon(w.type.icon, size: 16, color: w.color),
                  label: Text('${w.name} (${formatYen(bal)})'),
                  selected: selected,
                  onSelected: (_) => setState(() => _walletId = w.id),
                );
              }).toList(),
            ),

            if (_kind == TransactionKind.transfer) ...[
              const SizedBox(height: 14),
              const Text(
                'チャージ先・振替先の決済手段',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: store.wallets.map((w) {
                  final selected = _toWalletId == w.id;
                  final bal = store.walletBalance(w.id);
                  return ChoiceChip(
                    avatar: Icon(w.type.icon, size: 16, color: w.color),
                    label: Text('${w.name} (${formatYen(bal)})'),
                    selected: selected,
                    onSelected: (_) => setState(() => _toWalletId = w.id),
                  );
                }).toList(),
              ),
            ],

            // カテゴリ選択（支出・収入時）
            if (_kind != TransactionKind.transfer) ...[
              const SizedBox(height: 16),
              Text(
                _kind == TransactionKind.expense ? '何に使ったか（カテゴリ）' : '収入の種類',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final selected = _categoryId == cat.id;
                  return ChoiceChip(
                    avatar: Icon(cat.icon, size: 16, color: cat.color),
                    label: Text(cat.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _categoryId = cat.id),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 14),

            // メモと日付
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'メモ（例: コンビニ弁当、カフェ等）',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _selectedDate.hour,
                          _selectedDate.minute,
                        );
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(formatDateShort(_selectedDate)),
                ),
              ],
            ),

            if (widget.existing == null &&
                _kind == TransactionKind.expense) ...[
              const SizedBox(height: 6),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'この内容を「ワンタップ即時記録」にも登録する',
                  style: TextStyle(fontSize: 12),
                ),
                value: _saveAsTemplate,
                onChanged: (v) => setState(() => _saveAsTemplate = v ?? false),
              ),
            ],

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  widget.existing != null ? '変更を保存する' : '記録する',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
