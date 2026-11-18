import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../finance_store.dart';
import '../models.dart';

/// 現金・電子決済・銀行口座・クレジットカード等のウォレットを追加・編集するシート
Future<void> showAddWalletSheet(BuildContext context, {Wallet? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AddWalletSheet(existing: existing),
  );
}

class _AddWalletSheet extends StatefulWidget {
  final Wallet? existing;
  const _AddWalletSheet({this.existing});

  @override
  State<_AddWalletSheet> createState() => _AddWalletSheetState();
}

class _AddWalletSheetState extends State<_AddWalletSheet> {
  static const List<int> _palette = [
    0xFF2E7D32,
    0xFFE53935,
    0xFF00897B,
    0xFF1565C0,
    0xFF5E35B1,
    0xFFEF6C00,
    0xFFD81B60,
    0xFF37474F,
  ];

  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  late WalletType _type;
  late int _colorValue;
  late bool _includeInSimulation;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _balanceCtrl = TextEditingController(
      text: ex != null ? ex.initialBalance.toString() : '0',
    );
    _type = ex?.type ?? WalletType.qrPay;
    _colorValue = ex?.colorValue ?? _palette[1];
    _includeInSimulation = ex?.includeInSimulation ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('決済手段・口座の名前を入力してください')),
      );
      return;
    }
    final initBal = int.tryParse(_balanceCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final store = context.read<FinanceStore>();
    final id = widget.existing?.id ??
        'wallet_${DateTime.now().microsecondsSinceEpoch}';

    await store.addOrUpdateWallet(
      Wallet(
        id: id,
        name: name,
        type: _type,
        initialBalance: initBal,
        colorValue: _colorValue,
        includeInSimulation: _includeInSimulation,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                      ? '決済手段・口座の編集'
                      : '決済手段・電子マネーを追加',
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
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '名称（例: PayPay、楽天ペイ、Suica、財布、銀行等）',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '種類',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WalletType.values.map((t) {
                return ChoiceChip(
                  avatar: Icon(t.icon, size: 16),
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _balanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: '初期残高（開始時点の金額・円）',
                prefixText: '¥ ',
                helperText: '以降の収入・支出・チャージ履歴が自動で加減算されます',
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'テーマカラー',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _palette.map((c) {
                final selected = _colorValue == c;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(c),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '生活目安シミュレーションの対象に含める',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                '「1日いくらまで使えるか」の基準残高にこの決済手段を含めます',
                style: TextStyle(fontSize: 12),
              ),
              value: _includeInSimulation,
              onChanged: (v) => setState(() => _includeInSimulation = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  '保存する',
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
