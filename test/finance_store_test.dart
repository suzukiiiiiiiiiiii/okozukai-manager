import 'package:flutter_test/flutter_test.dart';
import 'package:okozukai_manager/finance_store.dart';
import 'package:okozukai_manager/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('現金・電子決済の残高とチャージ計算', () {
    test('支出・収入・電子マネーチャージが各決済手段の残高に正しく反映される', () async {
      final store = FinanceStore()
        ..seedForTest(
          wallets: const [
            Wallet(
              id: 'cash',
              name: '現金',
              type: WalletType.cash,
              initialBalance: 10000,
              colorValue: 0xFF2E7D32,
            ),
            Wallet(
              id: 'paypay',
              name: 'PayPay',
              type: WalletType.qrPay,
              initialBalance: 2000,
              colorValue: 0xFFE53935,
            ),
          ],
        );

      expect(store.totalBalance, 12000);

      // 現金からPayPayへ3,000円チャージ（総残高は12,000円のまま変わらない）
      await store.addTransaction(
        TransactionItem(
          id: 't1',
          kind: TransactionKind.transfer,
          amount: 3000,
          categoryId: 'transfer',
          walletId: 'cash',
          toWalletId: 'paypay',
          note: 'セブン銀行ATMチャージ',
          date: DateTime(2026, 11, 17),
        ),
      );

      expect(store.walletBalance('cash'), 7000);
      expect(store.walletBalance('paypay'), 5000);
      expect(store.totalBalance, 12000);

      // PayPayで800円のランチ支出
      await store.addTransaction(
        TransactionItem(
          id: 't2',
          kind: TransactionKind.expense,
          amount: 800,
          categoryId: 'food',
          walletId: 'paypay',
          note: 'ランチ',
          date: DateTime(2026, 11, 17),
        ),
      );

      expect(store.walletBalance('paypay'), 4200);
      expect(store.totalBalance, 11200);
    });
  });

  group('何にいくら使ったか（カテゴリ別・決済別集計）', () {
    test('カテゴリ別支出額の高い順に並び、割合が計算される', () async {
      final store = FinanceStore()..seedForTest(transactions: []);

      await store.addTransaction(
        TransactionItem(
          id: 'e1',
          kind: TransactionKind.expense,
          amount: 600,
          categoryId: 'convenience',
          walletId: 'qr_paypay',
          note: 'コンビニ',
          date: DateTime(2026, 11, 10),
        ),
      );
      await store.addTransaction(
        TransactionItem(
          id: 'e2',
          kind: TransactionKind.expense,
          amount: 2400,
          categoryId: 'food',
          walletId: 'cash',
          note: '外食',
          date: DateTime(2026, 11, 12),
        ),
      );

      final list = store.categoryBreakdownsForMonth(2026, 11);
      expect(list.length, 2);
      expect(list.first.category.id, 'food');
      expect(list.first.amount, 2400);
      expect(list.first.ratio, closeTo(0.8, 0.001));
      expect(list.last.category.id, 'convenience');
      expect(list.last.amount, 600);
    });
  });

  group('固定引き落とし・固定収入と生活目安シミュレーター', () {
    test('◯ヶ月この金額で生活する場合の1日あたり上限と今日の残り額が正しく計算される', () {
      final now = DateTime(2026, 11, 17, 15, 0);
      final store = FinanceStore()
        ..seedForTest(
          wallets: const [
            Wallet(
              id: 'bank',
              name: '銀行口座',
              type: WalletType.bank,
              initialBalance: 100000,
              colorValue: 0xFF1565C0,
            ),
          ],
          recurringRules: const [
            RecurringRule(
              id: 'r_sub',
              title: '通信費・サブスク固定引落',
              isIncome: false,
              amount: 5000,
              categoryId: 'subscription',
              walletId: 'bank',
              dayOfMonth: 25,
              enabled: true,
              autoRecord: false,
            ),
            RecurringRule(
              id: 'r_inc',
              title: '毎月のお小遣い',
              isIncome: true,
              amount: 30000,
              categoryId: 'allowance',
              walletId: 'bank',
              dayOfMonth: 25,
              enabled: true,
              autoRecord: false,
            ),
          ],
          transactions: [
            TransactionItem(
              id: 'today_1',
              kind: TransactionKind.expense,
              amount: 500,
              categoryId: 'food',
              walletId: 'bank',
              note: '今日の昼食',
              date: now,
            ),
          ],
        );

      // 現在残高 = 99,500円
      // 3ヶ月 (90日) 生活、固定引落(5,000×3 = 15,000円)を差し引き、予備費 14,500円を残す場合:
      // 自由枠 = 99,500 - 15,000 - 14,500 = 70,000円
      // 1日あたり = floor(70,000 / 90) = 777円
      final sim = store.calculateSimulation(
        daysOverride: 90,
        includeFixedIncomeOverride: false,
        deductFixedExpenseOverride: true,
        reserveGoalOverride: 14500,
        nowOverride: now,
      );

      expect(sim.baseFunds, 99500);
      expect(sim.projectedFixedExpense, 15000);
      expect(sim.spendablePool, 70000);
      expect(sim.dailyLimit, 777);
      expect(sim.todayVariableSpent, 500);
      expect(sim.todayRemaining, 277);
    });
  });
}
