import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../finance_store.dart';
import '../formatters.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  late TextEditingController _customAmountCtrl;

  @override
  void initState() {
    super.initState();
    final store = context.read<FinanceStore>();
    _customAmountCtrl = TextEditingController(
      text: store.customSimBaseAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _customAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FinanceStore>();
    final sim = store.calculateSimulation();
    final scheme = Theme.of(context).colorScheme;
    final usingCustom = store.customSimBaseAmount != null;
    final simple = store.isSimpleTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        // 1. 試算結果ヒーローカード
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: simple ? Colors.white : null,
            border: simple
                ? Border.all(
                    color: sim.dailyLimit < 0
                        ? scheme.error.withValues(alpha: 0.4)
                        : const Color(0xFFE5E7EB),
                  )
                : null,
            gradient: simple
                ? null
                : LinearGradient(
                    colors: sim.dailyLimit >= 0
                        ? [
                            scheme.primary,
                            Color.lerp(scheme.primary, Colors.black, 0.28)!,
                          ]
                        : [
                            const Color(0xFFC62828),
                            const Color(0xFF8E0000),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(simple ? 14 : 20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatYen(sim.baseFunds)} で '
                '${sim.totalDays}日間（約${sim.monthsEquivalent.toStringAsFixed(1)}ヶ月）生活する場合',
                style: TextStyle(
                  color: simple
                      ? scheme.onSurface.withValues(alpha: 0.6)
                      : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1日あたり使える目安金額',
                style: TextStyle(
                  color: simple ? scheme.onSurface : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatYen(sim.dailyLimit),
                      style: TextStyle(
                        color: simple
                            ? (sim.dailyLimit < 0
                                ? scheme.error
                                : scheme.onSurface)
                            : Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ 日',
                      style: TextStyle(
                        color: simple
                            ? scheme.onSurface.withValues(alpha: 0.6)
                            : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SimStatTile(
                      label: '今日あと使える額',
                      value: formatYen(sim.todayRemaining),
                      sub: '今日の支出: ${formatYen(sim.todayVariableSpent)}',
                      lightMode: simple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SimStatTile(
                      label: '1週間(7日)換算',
                      value: formatYen(sim.weeklyLimit),
                      sub: '30日換算: ${formatYen(sim.monthlyLimit)}',
                      lightMode: simple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: simple
                      ? const Color(0xFFF3F4F6)
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '内訳: 基準額 ${formatYen(sim.baseFunds)}'
                  '${sim.includeFixedIncome ? " + 固定収入 ${formatYen(sim.projectedFixedIncome)}" : ""}'
                  '${sim.deductFixedExpense ? " - 固定引落 ${formatYen(sim.projectedFixedExpense)}" : ""}'
                  '${sim.reserveGoal > 0 ? " - 予備費 ${formatYen(sim.reserveGoal)}" : ""}'
                  ' = 自由枠 ${formatYen(sim.spendablePool)}',
                  style: TextStyle(
                    color: simple ? scheme.onSurface : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. 期間設定（「◯ヶ月・◯日間」の選択）
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
                        '① 生活する期間',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${sim.totalDays}日 (約${sim.monthsEquivalent.toStringAsFixed(1)}ヶ月)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in const [
                      (label: '半月', days: 15),
                      (label: '1ヶ月', days: 30),
                      (label: '2ヶ月', days: 60),
                      (label: '3ヶ月', days: 90),
                      (label: '4ヶ月', days: 120),
                      (label: '6ヶ月', days: 180),
                      (label: '1年', days: 365),
                    ])
                      ChoiceChip(
                        label: Text(
                          p.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: store.simDays == p.days,
                        onSelected: (_) =>
                            store.updateSimulationConfig(simDays: p.days),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: store.simDays.clamp(1, 365).toDouble(),
                  min: 1,
                  max: 365,
                  divisions: 364,
                  label: '${store.simDays}日間',
                  onChanged: (v) =>
                      store.updateSimulationConfig(simDays: v.round()),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 3. 基準金額の設定（現在の残高 or 仮の金額で試算）
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '② 基準にする金額',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text(
                          '現在の残高',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(
                          '金額を指定',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    selected: {usingCustom},
                    onSelectionChanged: (s) {
                      final custom = s.first;
                      if (!custom) {
                        _customAmountCtrl.clear();
                        store.updateSimulationConfig(
                          clearCustomBaseAmount: true,
                        );
                      } else {
                        final fallback = store.simulationTargetBalance > 0
                            ? store.simulationTargetBalance
                            : 100000;
                        _customAmountCtrl.text = fallback.toString();
                        store.updateSimulationConfig(
                          customBaseAmount: fallback,
                        );
                      }
                    },
                  ),
                ),
                if (usingCustom) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '試算したい金額 (円)',
                      prefixText: '¥ ',
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v.replaceAll(',', '').trim());
                      if (parsed != null && parsed >= 0) {
                        store.updateSimulationConfig(customBaseAmount: parsed);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final amt in [
                        30000,
                        50000,
                        100000,
                        150000,
                        200000,
                        300000,
                      ])
                        ActionChip(
                          label: Text(
                            formatYen(amt),
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            _customAmountCtrl.text = amt.toString();
                            store.updateSimulationConfig(customBaseAmount: amt);
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 4. 固定引き落とし・固定収入・予備費の反映オプション
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '③ 固定引き落とし・固定収入・予備費の考慮',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '期間中の固定引き落としを差し引く',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '月額固定費 ${formatYen(store.monthlyFixedExpenseTotal)} '
                    '(期間計 -${formatYen(sim.projectedFixedExpense)})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: store.simDeductFixedExpense,
                  onChanged: (v) =>
                      store.updateSimulationConfig(deductFixedExpense: v),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '期間中の固定収入を加算する',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '月額固定収入 ${formatYen(store.monthlyFixedIncomeTotal)} '
                    '(期間計 +${formatYen(sim.projectedFixedIncome)})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: store.simIncludeFixedIncome,
                  onChanged: (v) =>
                      store.updateSimulationConfig(includeFixedIncome: v),
                ),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '手元に残したい予備費・目標貯金額',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatYen(store.simReserveGoal),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    for (final r in [0, 5000, 10000, 30000, 50000, 100000])
                      ChoiceChip(
                        label: Text(
                          r == 0 ? '¥0 (全額使い切り)' : formatYen(r),
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: store.simReserveGoal == r,
                        onSelected: (_) =>
                            store.updateSimulationConfig(reserveGoal: r),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // 5. 期間別比較早見表（1ヶ月〜12ヶ月）
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '期間別の「1日いくらまで」比較早見表',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '同じ条件で期間を変えた場合の1日・1週間の目安一覧',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 10),
                for (final days in const [30, 60, 90, 180, 365]) ...[
                  Builder(
                    builder: (context) {
                      final rowSim =
                          store.calculateSimulation(daysOverride: days);
                      final monthsLabel = days == 365
                          ? '1年 (365日)'
                          : '${(days / 30).round()}ヶ月 ($days日)';
                      final isCurrent = store.simDays == days;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? scheme.primary.withValues(alpha: 0.1)
                              : scheme.onSurface.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              monthsLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '1日 ${formatYen(rowSim.dailyLimit)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: rowSim.dailyLimit < 0
                                        ? scheme.error
                                        : scheme.primary,
                                  ),
                                ),
                                Text(
                                  '週 ${formatYen(rowSim.weeklyLimit)} / 自由枠 ${formatYen(rowSim.spendablePool)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
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
        ),

        const SizedBox(height: 14),

        // 6. 現在の支出ペース診断
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '直近の支出ペース診断',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('直近14日間の1日平均支出（変動費）'),
                    Text(
                      '${formatYen(sim.recentDailyAverage)} / 日',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (sim.survivableDaysAtCurrentPace != null)
                  Text(
                    sim.recentDailyAverage <= sim.dailyLimit
                        ? '現在のペースなら目標の${sim.totalDays}日間を問題なくクリアできます（計算上は約${sim.survivableDaysAtCurrentPace}日持ちます）。'
                        : '現在のペースだと約${sim.survivableDaysAtCurrentPace}日で自由枠を使い切ります。'
                            '${sim.totalDays}日間持たせるには1日あたりあと ${formatYen(sim.recentDailyAverage - sim.dailyLimit)} 抑えると安心です。',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sim.recentDailyAverage <= sim.dailyLimit
                          ? const Color(0xFF2E7D32)
                          : scheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SimStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool lightMode;

  const _SimStatTile({
    required this.label,
    required this.value,
    required this.sub,
    this.lightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightMode
            ? const Color(0xFFF3F4F6)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: lightMode
                  ? scheme.onSurface.withValues(alpha: 0.65)
                  : Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: lightMode ? scheme.onSurface : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: lightMode
                  ? scheme.onSurface.withValues(alpha: 0.55)
                  : Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
