import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../finance_store.dart';

/// 初回起動時（および設定から再表示時）に表示するチュートリアル画面。
/// 使用例はこのチュートリアル内（または一時的な体験モード中）にのみ表示され、
/// 終了後はサンプルデータが残らないクリーンな状態でアプリを始められます。
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const int _totalPages = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<FinanceStore>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 上部ヘッダー（スキップ）
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '使い方ガイド (${_page + 1}/$_totalPages)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: store.completeTutorial,
                    child: const Text('スキップ'),
                  ),
                ],
              ),
            ),

            // ページ本体
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _page = index),
                children: const [
                  _TutorialPage(
                    icon: Icons.account_balance_wallet_outlined,
                    title: '現金も電子決済もまとめて管理',
                    description:
                        '財布の現金だけでなく、PayPay・Suica・銀行口座・クレカの残高をひと目で確認できます。チャージや振替にも対応しています。',
                    exampleTitle: '使用例（チュートリアル限定表示）',
                    exampleRows: [
                      _ExampleRow('現金（財布）', '¥18,000'),
                      _ExampleRow('PayPay', '¥12,500'),
                      _ExampleRow('交通系IC (Suica)', '¥4,200'),
                    ],
                  ),
                  _TutorialPage(
                    icon: Icons.autorenew_rounded,
                    title: '固定収入・固定引き落としに対応',
                    description:
                        '毎月のお小遣いや給料、スマホ代やサブスクの引き落としを登録しておくと、生活目安の計算に自動で反映されます。',
                    exampleTitle: '使用例（チュートリアル限定表示）',
                    exampleRows: [
                      _ExampleRow('毎月25日 · お小遣い入金', '+¥50,000'),
                      _ExampleRow('毎月27日 · スマホ通信費', '-¥3,280'),
                      _ExampleRow('毎月15日 · 動画サブスク', '-¥1,480'),
                    ],
                  ),
                  _TutorialPage(
                    icon: Icons.pie_chart_outline_rounded,
                    title: '何にいくら使ったかをすぐ把握',
                    description:
                        '金額とカテゴリを選ぶだけで数秒で記録完了。月ごとの支出内訳がグラフで分かりやすく表示されます。',
                    exampleTitle: '使用例（チュートリアル限定表示）',
                    exampleRows: [
                      _ExampleRow('食費・外食（42%）', '¥12,400'),
                      _ExampleRow('コンビニ・軽食（28%）', '¥8,200'),
                      _ExampleRow('交通費（18%）', '¥5,300'),
                    ],
                  ),
                  _TutorialPage(
                    icon: Icons.calculate_outlined,
                    title: '「1日いくらまで？」を自動計算',
                    description:
                        '「今の残高で◯ヶ月生活するには1日いくらまで使えるか」を固定費も差し引いてリアルタイムに表示します。',
                    exampleTitle: '使用例（チュートリアル限定表示）',
                    exampleRows: [
                      _ExampleRow('1ヶ月（30日）で暮らす場合', '¥1,500 / 日'),
                      _ExampleRow('今日あと使える金額', '¥880'),
                    ],
                  ),
                ],
              ),
            ),

            // インジケーター
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (index) {
                  final active = index == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: active ? 22 : 6,
                    decoration: BoxDecoration(
                      color: active
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // 下部アクションボタン
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_page < _totalPages - 1) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          '次へ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: store.completeTutorial,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'データ空の状態から始める',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => store.enterTutorialDemoMode(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text(
                          '使用例（デモ）で少し触ってみる',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '※デモのデータは終了すると自動で消去されます',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExampleRow {
  final String label;
  final String value;

  const _ExampleRow(this.label, this.value);
}

class _TutorialPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String exampleTitle;
  final List<_ExampleRow> exampleRows;

  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.exampleTitle,
    required this.exampleRows,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: scheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exampleTitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < exampleRows.length; i++) ...[
                    if (i > 0) const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exampleRows[i].label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          exampleRows[i].value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
