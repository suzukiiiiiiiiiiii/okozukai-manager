import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../finance_store.dart';
import '../models.dart';

/// 固定引き落とし（家賃・通信費・サブスク等）や固定収入（給料・お小遣い等）を追加・編集するシート
Future<void> showAddRecurringSheet(
  BuildContext context, {
  RecurringRule? existing,
  bool initialIsIncome = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddRecurringSheet(
      existing: existing,
      initialIsIncome: initialIsIncome,
    ),
  );
}

class _AddRecurringSheet extends StatefulWidget {
  final RecurringRule? existing;
  final bool initialIsIncome;

  const _AddRecurringSheet({
    this.existing,
    required this.initialIsIncome,
  });

  @override
  State<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<_AddRecurringSheet> {
  late bool _isIncome;
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late String _categoryId;
  late String _walletId;
  late int _dayOfMonth;
  late bool _autoRecord;

  @override
  void initState() {
    super.initState();
    final store = context.read<FinanceStore>();
    final ex = widget.existing;
    _isIncome = ex?.isIncome ?? widget.initialIsIncome;
    _titleCtrl = TextEditingController(text: ex?.title ?? '');
    _amountCtrl = TextEditingController(
      text: ex != null ? ex.amount.toString() : '',
    );
    _categoryId = ex?.categoryId ?? (_isIncome ? 'allowance' : 'subscription');
    _walletId = ex?.walletId ??
        (store.wallets.isNotEmpty ? store.wallets.first.id : 'cash');
    _dayOfMonth = ex?.dayOfMonth ?? 25;
    _autoRecord = ex?.autoRecord ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final amt = int.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('項目名（例: スマホ代、家賃、毎月のお小遣い等）を入力してください')),
      );
      return;
    }
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('1円以上の金額を入力してください')),
      );
      return;
    }

    final store = context.read<FinanceStore>();
    final id = widget.existing?.id ??
        'rec_${DateTime.now().microsecondsSinceEpoch}';

    await store.addOrUpdateRecurringRule(
      RecurringRule(
        id: id,
        title: title,
        isIncome: _isIncome,
        amount: amt,
        categoryId: _categoryId,
        walletId: _walletId,
        dayOfMonth: _dayOfMonth,
        enabled: widget.existing?.enabled ?? true,
        autoRecord: _autoRecord,
        lastRecordedYearMonth: widget.existing?.lastRecordedYearMonth,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final categories = _isIncome
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
                  widget.existing != null
                      ? '固定収支ルールの編集'
                      : '固定引き落とし・固定収入の登録',
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('固定引き落とし・固定支出'),
                    icon: Icon(Icons.event_repeat_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('固定収入（給料・お小遣い）'),
                    icon: Icon(Icons.savings_outlined, size: 18),
                  ),
                ],
                selected: {_isIncome},
                onSelectionChanged: (s) {
                  final next = s.first;
                  setState(() {
                    _isIncome = next;
                    _categoryId = next ? 'allowance' : 'subscription';
                  });
                },
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: _isIncome
                    ? '名称（例: 毎月のお小遣い、バイト代、給与等）'
                    : '名称（例: スマホ通信費、家賃、Netflix等）',
                prefixIcon: const Icon(Icons.label_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '毎月の金額 (円)',
                      prefixText: '¥ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _dayOfMonth,
                    decoration: const InputDecoration(labelText: '毎月の発生日'),
                    items: [
                      for (var d = 1; d <= 28; d++)
                        DropdownMenuItem(value: d, child: Text('毎月$d日')),
                      const DropdownMenuItem(value: 99, child: Text('毎月月末')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _dayOfMonth = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _isIncome ? '入金先の決済手段・口座' : '引き落とし元の決済手段・口座',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: store.wallets.map((w) {
                return ChoiceChip(
                  avatar: Icon(w.type.icon, size: 16, color: w.color),
                  label: Text(w.name),
                  selected: _walletId == w.id,
                  onSelected: (_) => setState(() => _walletId = w.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text(
              'カテゴリ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                return ChoiceChip(
                  avatar: Icon(cat.icon, size: 16, color: cat.color),
                  label: Text(cat.label),
                  selected: _categoryId == cat.id,
                  onSelected: (_) => setState(() => _categoryId = cat.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '到来日に自動で入出金履歴へ計上する',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'OFFの場合でも「生活目安シミュレーター」の固定収支計算には反映されます',
                style: TextStyle(fontSize: 12),
              ),
              value: _autoRecord,
              onChanged: (v) => setState(() => _autoRecord = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  '固定収支を保存する',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
