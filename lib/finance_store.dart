import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// アプリ全体の収支・ウォレット・固定収支・生活目安設定を管理するストア。
class FinanceStore extends ChangeNotifier {
  static const String _kWalletsKey = 'okozukai_wallets_v1';
  static const String _kTransactionsKey = 'okozukai_transactions_v1';
  static const String _kRecurringKey = 'okozukai_recurring_v1';
  static const String _kTemplatesKey = 'okozukai_templates_v1';
  static const String _kSimConfigKey = 'okozukai_sim_config_v1';

  List<Wallet> _wallets = [];
  List<TransactionItem> _transactions = [];
  List<RecurringRule> _recurringRules = [];
  List<QuickTemplate> _quickTemplates = [];

  // シミュレーターの保持設定
  int _simDays = 30; // デフォルト 1ヶ月 (30日)
  int? _customSimBaseAmount; // null なら現在の残高合計を使用
  bool _simIncludeFixedIncome = false; // 「この金額だけで◯ヶ月生活する」を直感的に見せるため初期はfalse、ワンタップで切替可
  bool _simDeductFixedExpense = true; // 固定引き落としは差し引く
  int _simReserveGoal = 0; // 残したい予備費・目標貯金額
  bool _isDarkMode = false;

  List<Wallet> get wallets => List.unmodifiable(_wallets);
  List<TransactionItem> get transactions => List.unmodifiable(_transactions);
  List<RecurringRule> get recurringRules => List.unmodifiable(_recurringRules);
  List<QuickTemplate> get quickTemplates => List.unmodifiable(_quickTemplates);

  int get simDays => _simDays;
  int? get customSimBaseAmount => _customSimBaseAmount;
  bool get simIncludeFixedIncome => _simIncludeFixedIncome;
  bool get simDeductFixedExpense => _simDeductFixedExpense;
  int get simReserveGoal => _simReserveGoal;
  bool get isDarkMode => _isDarkMode;

  /// 初期化と保存データの読み込み
  Future<void> load({DateTime? nowOverride}) async {
    final prefs = await SharedPreferences.getInstance();

    final walletsRaw = prefs.getString(_kWalletsKey);
    if (walletsRaw != null) {
      final list = jsonDecode(walletsRaw) as List<dynamic>;
      _wallets = list
          .map((e) => Wallet.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _wallets = _defaultWallets();
    }

    final txRaw = prefs.getString(_kTransactionsKey);
    if (txRaw != null) {
      final list = jsonDecode(txRaw) as List<dynamic>;
      _transactions = list
          .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
          .toList();
      _sortTransactions();
    } else {
      _transactions = _defaultSampleTransactions(nowOverride ?? DateTime.now());
      _sortTransactions();
    }

    final recRaw = prefs.getString(_kRecurringKey);
    if (recRaw != null) {
      final list = jsonDecode(recRaw) as List<dynamic>;
      _recurringRules = list
          .map((e) => RecurringRule.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _recurringRules = _defaultRecurringRules();
    }

    final tplRaw = prefs.getString(_kTemplatesKey);
    if (tplRaw != null) {
      final list = jsonDecode(tplRaw) as List<dynamic>;
      _quickTemplates = list
          .map((e) => QuickTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _quickTemplates = _defaultTemplates();
    }

    final simRaw = prefs.getString(_kSimConfigKey);
    if (simRaw != null) {
      final map = jsonDecode(simRaw) as Map<String, dynamic>;
      _simDays = ((map['simDays'] as num?)?.toInt() ?? 30).clamp(1, 3650);
      _customSimBaseAmount = (map['customSimBaseAmount'] as num?)?.toInt();
      _simIncludeFixedIncome = map['simIncludeFixedIncome'] as bool? ?? false;
      _simDeductFixedExpense = map['simDeductFixedExpense'] as bool? ?? true;
      _simReserveGoal = (map['simReserveGoal'] as num?)?.toInt() ?? 0;
      _isDarkMode = map['isDarkMode'] as bool? ?? false;
    }

    await applyDueRecurringRules(nowOverride: nowOverride);
    notifyListeners();
  }

  /// テスト用または即時初期化用のシードメソッド
  void seedForTest({
    List<Wallet>? wallets,
    List<TransactionItem>? transactions,
    List<RecurringRule>? recurringRules,
    List<QuickTemplate>? quickTemplates,
  }) {
    _wallets = wallets ?? _defaultWallets();
    _transactions = transactions ?? [];
    _sortTransactions();
    _recurringRules = recurringRules ?? [];
    _quickTemplates = quickTemplates ?? _defaultTemplates();
    notifyListeners();
  }

  void _sortTransactions() {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kWalletsKey,
      jsonEncode(_wallets.map((w) => w.toJson()).toList()),
    );
    await prefs.setString(
      _kTransactionsKey,
      jsonEncode(_transactions.map((t) => t.toJson()).toList()),
    );
    await prefs.setString(
      _kRecurringKey,
      jsonEncode(_recurringRules.map((r) => r.toJson()).toList()),
    );
    await prefs.setString(
      _kTemplatesKey,
      jsonEncode(_quickTemplates.map((t) => t.toJson()).toList()),
    );
    await prefs.setString(
      _kSimConfigKey,
      jsonEncode({
        'simDays': _simDays,
        'customSimBaseAmount': _customSimBaseAmount,
        'simIncludeFixedIncome': _simIncludeFixedIncome,
        'simDeductFixedExpense': _simDeductFixedExpense,
        'simReserveGoal': _simReserveGoal,
        'isDarkMode': _isDarkMode,
      }),
    );
  }

  /// ダークモード切替
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _saveAll();
    notifyListeners();
  }

  // ===========================================================================
  // ウォレット・決済手段の計算と操作
  // ===========================================================================

  Wallet? walletById(String id) {
    for (final w in _wallets) {
      if (w.id == id) return w;
    }
    return _wallets.isNotEmpty ? _wallets.first : null;
  }

  /// 指定した決済手段（ウォレット）の現在残高を計算する。
  /// 初期残高 + 収入 - 支出 - チャージ送金元 + チャージ入金先
  int walletBalance(String walletId) {
    final wallet = walletById(walletId);
    if (wallet == null) return 0;
    var balance = wallet.initialBalance;
    for (final tx in _transactions) {
      if (tx.kind == TransactionKind.income && tx.walletId == walletId) {
        balance += tx.amount;
      } else if (tx.kind == TransactionKind.expense &&
          tx.walletId == walletId) {
        balance -= tx.amount;
      } else if (tx.kind == TransactionKind.transfer) {
        if (tx.walletId == walletId) {
          balance -= tx.amount;
        }
        if (tx.toWalletId == walletId) {
          balance += tx.amount;
        }
      }
    }
    return balance;
  }

  /// 全ウォレットの総資産残高
  int get totalBalance {
    var total = 0;
    for (final w in _wallets) {
      total += walletBalance(w.id);
    }
    return total;
  }

  /// 生活目安計算の対象に含めるウォレットの合計残高
  int get simulationTargetBalance {
    var total = 0;
    for (final w in _wallets) {
      if (w.includeInSimulation) {
        total += walletBalance(w.id);
      }
    }
    return total;
  }

  Future<void> addOrUpdateWallet(Wallet wallet) async {
    final index = _wallets.indexWhere((w) => w.id == wallet.id);
    if (index >= 0) {
      _wallets[index] = wallet;
    } else {
      _wallets.add(wallet);
    }
    await _saveAll();
    notifyListeners();
  }

  Future<void> deleteWallet(String walletId) async {
    if (_wallets.length <= 1) return; // 最低1つは残す
    _wallets.removeWhere((w) => w.id == walletId);
    await _saveAll();
    notifyListeners();
  }

  // ===========================================================================
  // 入出金・チャージ履歴の操作と集計
  // ===========================================================================

  Future<void> addTransaction(TransactionItem item) async {
    _transactions.add(item);
    _sortTransactions();
    await _saveAll();
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionItem item) async {
    final idx = _transactions.indexWhere((t) => t.id == item.id);
    if (idx >= 0) {
      _transactions[idx] = item;
      _sortTransactions();
      await _saveAll();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _saveAll();
    notifyListeners();
  }

  /// クイックテンプレートの追加・削除
  Future<void> addQuickTemplate(QuickTemplate tpl) async {
    _quickTemplates.add(tpl);
    await _saveAll();
    notifyListeners();
  }

  Future<void> deleteQuickTemplate(String id) async {
    _quickTemplates.removeWhere((t) => t.id == id);
    await _saveAll();
    notifyListeners();
  }

  /// 指定した年月の取引一覧を返す
  List<TransactionItem> transactionsForMonth(int year, int month) {
    return _transactions
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  /// 指定した年月の支出合計
  int monthlyExpense(int year, int month) {
    var sum = 0;
    for (final t in _transactions) {
      if (t.date.year == year &&
          t.date.month == month &&
          t.kind == TransactionKind.expense) {
        sum += t.amount;
      }
    }
    return sum;
  }

  /// 指定した年月の収入合計
  int monthlyIncome(int year, int month) {
    var sum = 0;
    for (final t in _transactions) {
      if (t.date.year == year &&
          t.date.month == month &&
          t.kind == TransactionKind.income) {
        sum += t.amount;
      }
    }
    return sum;
  }

  /// 指定した年月の「何にいくら使ったか」（カテゴリ別支出ランキング）
  List<CategoryBreakdown> categoryBreakdownsForMonth(int year, int month) {
    final Map<String, int> amounts = {};
    final Map<String, int> counts = {};
    var totalExp = 0;

    for (final t in _transactions) {
      if (t.date.year == year &&
          t.date.month == month &&
          t.kind == TransactionKind.expense) {
        amounts[t.categoryId] = (amounts[t.categoryId] ?? 0) + t.amount;
        counts[t.categoryId] = (counts[t.categoryId] ?? 0) + 1;
        totalExp += t.amount;
      }
    }

    final result = <CategoryBreakdown>[];
    amounts.forEach((catId, amt) {
      if (amt > 0) {
        result.add(
          CategoryBreakdown(
            category: AppCategories.byId(catId),
            amount: amt,
            count: counts[catId] ?? 1,
            ratio: totalExp > 0 ? amt / totalExp : 0.0,
          ),
        );
      }
    });

    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  /// 指定した年月の「どの決済手段でいくら使ったか」（ウォレット別内訳）
  List<WalletBreakdown> walletBreakdownsForMonth(int year, int month) {
    var totalExp = 0;
    final Map<String, int> expByWallet = {};
    final Map<String, int> incByWallet = {};

    for (final t in _transactions) {
      if (t.date.year == year && t.date.month == month) {
        if (t.kind == TransactionKind.expense) {
          expByWallet[t.walletId] = (expByWallet[t.walletId] ?? 0) + t.amount;
          totalExp += t.amount;
        } else if (t.kind == TransactionKind.income) {
          incByWallet[t.walletId] = (incByWallet[t.walletId] ?? 0) + t.amount;
        }
      }
    }

    final list = _wallets.map((w) {
      final exp = expByWallet[w.id] ?? 0;
      final inc = incByWallet[w.id] ?? 0;
      return WalletBreakdown(
        wallet: w,
        expenseAmount: exp,
        incomeAmount: inc,
        currentBalance: walletBalance(w.id),
        expenseRatio: totalExp > 0 ? exp / totalExp : 0.0,
      );
    }).toList();

    list.sort((a, b) => b.expenseAmount.compareTo(a.expenseAmount));
    return list;
  }

  // ===========================================================================
  // 固定収支（定期的な収入・自動引き落とし）の管理
  // ===========================================================================

  /// 有効な毎月の固定収入合計
  int get monthlyFixedIncomeTotal {
    var sum = 0;
    for (final r in _recurringRules) {
      if (r.enabled && r.isIncome) sum += r.amount;
    }
    return sum;
  }

  /// 有効な毎月の固定引き落とし（固定支出）合計
  int get monthlyFixedExpenseTotal {
    var sum = 0;
    for (final r in _recurringRules) {
      if (r.enabled && !r.isIncome) sum += r.amount;
    }
    return sum;
  }

  Future<void> addOrUpdateRecurringRule(RecurringRule rule) async {
    final idx = _recurringRules.indexWhere((r) => r.id == rule.id);
    if (idx >= 0) {
      _recurringRules[idx] = rule;
    } else {
      _recurringRules.add(rule);
    }
    await _saveAll();
    notifyListeners();
  }

  Future<void> deleteRecurringRule(String id) async {
    _recurringRules.removeWhere((r) => r.id == id);
    await _saveAll();
    notifyListeners();
  }

  /// 指定した固定収支ルールを今すぐ履歴に1件計上する
  Future<void> recordRecurringRuleNow(
    RecurringRule rule, {
    DateTime? dateOverride,
  }) async {
    final now = dateOverride ?? DateTime.now();
    final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final tx = TransactionItem(
      id: 'rec_${rule.id}_${now.microsecondsSinceEpoch}',
      kind: rule.isIncome ? TransactionKind.income : TransactionKind.expense,
      amount: rule.amount,
      categoryId: rule.categoryId,
      walletId: rule.walletId,
      note: '[固定] ${rule.title}',
      date: now,
      isFixed: true,
      recurringRuleId: rule.id,
    );
    _transactions.add(tx);
    _sortTransactions();

    final idx = _recurringRules.indexWhere((r) => r.id == rule.id);
    if (idx >= 0) {
      _recurringRules[idx] = rule.copyWith(lastRecordedYearMonth: ym);
    }

    await _saveAll();
    notifyListeners();
  }

  /// 当月の到来済み固定収支（autoRecord == true）が未計上なら自動計上する
  Future<int> applyDueRecurringRules({DateTime? nowOverride}) async {
    final now = nowOverride ?? DateTime.now();
    final ym = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final lastDayOfThisMonth = DateTime(now.year, now.month + 1, 0).day;
    var appliedCount = 0;

    for (var i = 0; i < _recurringRules.length; i++) {
      final rule = _recurringRules[i];
      if (!rule.enabled || !rule.autoRecord) continue;
      if (rule.lastRecordedYearMonth == ym) continue;

      final targetDay = rule.dayOfMonth >= 29
          ? lastDayOfThisMonth
          : rule.dayOfMonth.clamp(1, lastDayOfThisMonth);

      if (now.day >= targetDay) {
        final txDate = DateTime(now.year, now.month, targetDay, 9, 0);
        _transactions.add(
          TransactionItem(
            id: 'auto_${rule.id}_$ym',
            kind: rule.isIncome
                ? TransactionKind.income
                : TransactionKind.expense,
            amount: rule.amount,
            categoryId: rule.categoryId,
            walletId: rule.walletId,
            note: '[固定自動計上] ${rule.title}',
            date: txDate,
            isFixed: true,
            recurringRuleId: rule.id,
          ),
        );
        _recurringRules[i] = rule.copyWith(lastRecordedYearMonth: ym);
        appliedCount++;
      }
    }

    if (appliedCount > 0) {
      _sortTransactions();
      await _saveAll();
    }
    return appliedCount;
  }

  // ===========================================================================
  // 「◯ヶ月この金額で生活するには一日いくらまで」生活目安シミュレーター
  // ===========================================================================

  Future<void> updateSimulationConfig({
    int? simDays,
    int? customBaseAmount,
    bool clearCustomBaseAmount = false,
    bool? includeFixedIncome,
    bool? deductFixedExpense,
    int? reserveGoal,
  }) async {
    if (simDays != null) _simDays = simDays.clamp(1, 3650);
    if (clearCustomBaseAmount) {
      _customSimBaseAmount = null;
    } else if (customBaseAmount != null) {
      _customSimBaseAmount = customBaseAmount;
    }
    if (includeFixedIncome != null) {
      _simIncludeFixedIncome = includeFixedIncome;
    }
    if (deductFixedExpense != null) {
      _simDeductFixedExpense = deductFixedExpense;
    }
    if (reserveGoal != null) {
      _simReserveGoal = reserveGoal.clamp(0, 100000000);
    }
    await _saveAll();
    notifyListeners();
  }

  /// 現在の設定（または引数で上書きした条件）で生活目安を計算する
  SurvivalSimulation calculateSimulation({
    int? daysOverride,
    int? baseFundsOverride,
    bool? includeFixedIncomeOverride,
    bool? deductFixedExpenseOverride,
    int? reserveGoalOverride,
    DateTime? nowOverride,
  }) {
    final now = nowOverride ?? DateTime.now();
    final days = (daysOverride ?? _simDays).clamp(1, 3650);
    final baseFunds =
        baseFundsOverride ?? _customSimBaseAmount ?? simulationTargetBalance;
    final incFixed = includeFixedIncomeOverride ?? _simIncludeFixedIncome;
    final dedFixed = deductFixedExpenseOverride ?? _simDeductFixedExpense;
    final reserve = reserveGoalOverride ?? _simReserveGoal;

    final monthsEq = days / 30.0;
    final projectedInc =
        incFixed ? (monthlyFixedIncomeTotal * monthsEq).round() : 0;
    final projectedExp =
        dedFixed ? (monthlyFixedExpenseTotal * monthsEq).round() : 0;

    final spendablePool = baseFunds + projectedInc - projectedExp - reserve;
    final dailyLimit = (spendablePool / days).floor();
    final weeklyLimit = dailyLimit * 7;
    final monthlyLimit = dailyLimit * 30;

    // 今日すでに使った変動費（固定費以外）
    var todaySpent = 0;
    for (final t in _transactions) {
      if (t.kind == TransactionKind.expense &&
          !t.isFixed &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day) {
        todaySpent += t.amount;
      }
    }

    // 直近14日間の変動費平均（1日あたり）
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 13));
    var recentSum = 0;
    for (final t in _transactions) {
      if (t.kind == TransactionKind.expense &&
          !t.isFixed &&
          !t.date.isBefore(cutoff)) {
        recentSum += t.amount;
      }
    }
    final recentDailyAvg = (recentSum / 14.0).round();

    int? survivableDays;
    if (recentDailyAvg > 0 && spendablePool > 0) {
      survivableDays = (spendablePool / recentDailyAvg).floor();
    }

    return SurvivalSimulation(
      baseFunds: baseFunds,
      totalDays: days,
      monthsEquivalent: monthsEq,
      includeFixedIncome: incFixed,
      deductFixedExpense: dedFixed,
      projectedFixedIncome: projectedInc,
      projectedFixedExpense: projectedExp,
      reserveGoal: reserve,
      spendablePool: spendablePool,
      dailyLimit: dailyLimit,
      weeklyLimit: weeklyLimit,
      monthlyLimit: monthlyLimit,
      todayVariableSpent: todaySpent,
      todayRemaining: dailyLimit - todaySpent,
      recentDailyAverage: recentDailyAvg,
      survivableDaysAtCurrentPace: survivableDays,
    );
  }

  /// サンプルデータにリセットする（または全履歴をクリアして初期状態に戻す）
  Future<void> resetAllData({
    required bool withSampleData,
    DateTime? nowOverride,
  }) async {
    final now = nowOverride ?? DateTime.now();
    _wallets = _defaultWallets(zeroBalance: !withSampleData);
    _recurringRules = withSampleData ? _defaultRecurringRules() : [];
    _quickTemplates = _defaultTemplates();
    _transactions = withSampleData ? _defaultSampleTransactions(now) : [];
    _sortTransactions();
    _simDays = 30;
    _customSimBaseAmount = null;
    _simIncludeFixedIncome = false;
    _simDeductFixedExpense = true;
    _simReserveGoal = 0;
    await _saveAll();
    notifyListeners();
  }

  // ===========================================================================
  // 初期データ定義
  // ===========================================================================

  static List<Wallet> _defaultWallets({bool zeroBalance = false}) => [
        Wallet(
          id: 'cash',
          name: '現金（財布）',
          type: WalletType.cash,
          initialBalance: zeroBalance ? 0 : 18000,
          colorValue: 0xFF2E7D32,
          includeInSimulation: true,
        ),
        Wallet(
          id: 'qr_paypay',
          name: 'PayPay',
          type: WalletType.qrPay,
          initialBalance: zeroBalance ? 0 : 12500,
          colorValue: 0xFFE53935,
          includeInSimulation: true,
        ),
        Wallet(
          id: 'emoney_suica',
          name: '交通系IC (Suica)',
          type: WalletType.emoney,
          initialBalance: zeroBalance ? 0 : 4200,
          colorValue: 0xFF00897B,
          includeInSimulation: true,
        ),
        Wallet(
          id: 'bank_main',
          name: 'メイン銀行口座',
          type: WalletType.bank,
          initialBalance: zeroBalance ? 0 : 95000,
          colorValue: 0xFF1565C0,
          includeInSimulation: true,
        ),
        Wallet(
          id: 'credit_main',
          name: 'クレジットカード',
          type: WalletType.credit,
          initialBalance: 0,
          colorValue: 0xFF5E35B1,
          includeInSimulation: true,
        ),
      ];

  static List<RecurringRule> _defaultRecurringRules() => const [
        RecurringRule(
          id: 'rec_income_allowance',
          title: '毎月のお小遣い・給料入金',
          isIncome: true,
          amount: 50000,
          categoryId: 'allowance',
          walletId: 'bank_main',
          dayOfMonth: 25,
          enabled: true,
          autoRecord: false,
        ),
        RecurringRule(
          id: 'rec_exp_mobile',
          title: 'スマホ・通信費引き落とし',
          isIncome: false,
          amount: 3280,
          categoryId: 'subscription',
          walletId: 'credit_main',
          dayOfMonth: 27,
          enabled: true,
          autoRecord: false,
        ),
        RecurringRule(
          id: 'rec_exp_sub',
          title: '動画・音楽サブスク',
          isIncome: false,
          amount: 1480,
          categoryId: 'subscription',
          walletId: 'credit_main',
          dayOfMonth: 15,
          enabled: true,
          autoRecord: false,
        ),
      ];

  static List<QuickTemplate> _defaultTemplates() => const [
        QuickTemplate(
          id: 'tpl_conv',
          title: 'コンビニ軽食',
          amount: 580,
          categoryId: 'convenience',
          walletId: 'qr_paypay',
        ),
        QuickTemplate(
          id: 'tpl_lunch',
          title: 'ランチ・定食',
          amount: 950,
          categoryId: 'food',
          walletId: 'qr_paypay',
        ),
        QuickTemplate(
          id: 'tpl_cafe',
          title: 'カフェ・コーヒー',
          amount: 450,
          categoryId: 'cafe',
          walletId: 'emoney_suica',
        ),
        QuickTemplate(
          id: 'tpl_train',
          title: '電車・バス運賃',
          amount: 420,
          categoryId: 'transport',
          walletId: 'emoney_suica',
        ),
        QuickTemplate(
          id: 'tpl_drink',
          title: '自販機ドリンク',
          amount: 160,
          categoryId: 'cafe',
          walletId: 'cash',
        ),
      ];

  static List<TransactionItem> _defaultSampleTransactions(DateTime now) {
    final today = DateTime(now.year, now.month, now.day, 12, 30);
    return [
      TransactionItem(
        id: 'sample_1',
        kind: TransactionKind.expense,
        amount: 620,
        categoryId: 'convenience',
        walletId: 'qr_paypay',
        note: 'お弁当とお茶',
        date: today,
      ),
      TransactionItem(
        id: 'sample_2',
        kind: TransactionKind.expense,
        amount: 440,
        categoryId: 'transport',
        walletId: 'emoney_suica',
        note: '往復電車代',
        date: today.subtract(const Duration(days: 1, hours: 3)),
      ),
      TransactionItem(
        id: 'sample_3',
        kind: TransactionKind.expense,
        amount: 1380,
        categoryId: 'daily',
        walletId: 'cash',
        note: 'ドラッグストア 日用品',
        date: today.subtract(const Duration(days: 2)),
      ),
      TransactionItem(
        id: 'sample_4',
        kind: TransactionKind.expense,
        amount: 2400,
        categoryId: 'hobby',
        walletId: 'credit_main',
        note: '書籍・ゲーム購入',
        date: today.subtract(const Duration(days: 3)),
      ),
      TransactionItem(
        id: 'sample_5',
        kind: TransactionKind.transfer,
        amount: 5000,
        categoryId: 'transfer',
        walletId: 'bank_main',
        toWalletId: 'qr_paypay',
        note: '銀行口座からPayPayへチャージ',
        date: today.subtract(const Duration(days: 4)),
      ),
    ];
  }
}
