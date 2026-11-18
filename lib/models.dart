import 'package:flutter/material.dart';

/// 決済手段・ウォレットの種別
enum WalletType {
  cash('現金', Icons.payments_outlined),
  qrPay('QR・バーコード決済', Icons.qr_code_2_rounded),
  emoney('電子マネー・交通系IC', Icons.contactless_outlined),
  bank('銀行口座・デビット', Icons.account_balance_outlined),
  credit('クレジットカード・後払い', Icons.credit_card_outlined);

  final String label;
  final IconData icon;
  const WalletType(this.label, this.icon);

  static WalletType fromName(String? name) {
    return WalletType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => WalletType.cash,
    );
  }
}

/// 取引の種別（支出・収入・チャージ/振替）
enum TransactionKind {
  expense('支出'),
  income('収入'),
  transfer('チャージ・振替');

  final String label;
  const TransactionKind(this.label);

  static TransactionKind fromName(String? name) {
    return TransactionKind.values.firstWhere(
      (e) => e.name == name,
      orElse: () => TransactionKind.expense,
    );
  }
}

/// カテゴリ定義（何に使ったか・何の収入か）
class CategoryDef {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const CategoryDef({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.isIncome = false,
  });
}

/// 標準カテゴリ一覧
class AppCategories {
  static const List<CategoryDef> expenseCategories = [
    CategoryDef(
      id: 'food',
      label: '食費・外食',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFE65100),
    ),
    CategoryDef(
      id: 'convenience',
      label: 'コンビニ・軽食',
      icon: Icons.storefront_rounded,
      color: Color(0xFFF57C00),
    ),
    CategoryDef(
      id: 'cafe',
      label: 'カフェ・飲料',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF6D4C41),
    ),
    CategoryDef(
      id: 'daily',
      label: '日用品・雑貨',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFF00897B),
    ),
    CategoryDef(
      id: 'transport',
      label: '交通・移動',
      icon: Icons.train_outlined,
      color: Color(0xFF1E88E5),
    ),
    CategoryDef(
      id: 'hobby',
      label: '趣味・娯楽',
      icon: Icons.sports_esports_outlined,
      color: Color(0xFF8E24AA),
    ),
    CategoryDef(
      id: 'social',
      label: '交際・イベント',
      icon: Icons.celebration_outlined,
      color: Color(0xFFD81B60),
    ),
    CategoryDef(
      id: 'clothing',
      label: '衣服・美容',
      icon: Icons.checkroom_outlined,
      color: Color(0xFF5E35B1),
    ),
    CategoryDef(
      id: 'subscription',
      label: '通信・サブスク',
      icon: Icons.subscriptions_outlined,
      color: Color(0xFF039BE5),
    ),
    CategoryDef(
      id: 'housing',
      label: '住まい・光熱費',
      icon: Icons.home_work_outlined,
      color: Color(0xFF546E7A),
    ),
    CategoryDef(
      id: 'medical',
      label: '医療・健康',
      icon: Icons.medical_services_outlined,
      color: Color(0xFF43A047),
    ),
    CategoryDef(
      id: 'other_expense',
      label: 'その他支出',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF757575),
    ),
  ];

  static const List<CategoryDef> incomeCategories = [
    CategoryDef(
      id: 'allowance',
      label: 'お小遣い・仕送り',
      icon: Icons.savings_outlined,
      color: Color(0xFF2E7D32),
      isIncome: true,
    ),
    CategoryDef(
      id: 'salary',
      label: '給料・バイト代',
      icon: Icons.work_outline_rounded,
      color: Color(0xFF1565C0),
      isIncome: true,
    ),
    CategoryDef(
      id: 'bonus',
      label: '臨時収入・賞与',
      icon: Icons.redeem_rounded,
      color: Color(0xFFEF6C00),
      isIncome: true,
    ),
    CategoryDef(
      id: 'point',
      label: 'ポイント・還元',
      icon: Icons.stars_rounded,
      color: Color(0xFFF9A825),
      isIncome: true,
    ),
    CategoryDef(
      id: 'other_income',
      label: 'その他収入',
      icon: Icons.attach_money_rounded,
      color: Color(0xFF00695C),
      isIncome: true,
    ),
  ];

  static const CategoryDef transferCategory = CategoryDef(
    id: 'transfer',
    label: 'チャージ・振替',
    icon: Icons.swap_horiz_rounded,
    color: Color(0xFF3949AB),
  );

  static CategoryDef byId(String id, {bool isIncome = false}) {
    if (id == 'transfer') return transferCategory;
    for (final c in expenseCategories) {
      if (c.id == id) return c;
    }
    for (final c in incomeCategories) {
      if (c.id == id) return c;
    }
    return isIncome ? incomeCategories.last : expenseCategories.last;
  }
}

/// 決済手段・お財布（現金・PayPay・Suica・銀行口座・クレジットカードなど）
class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final int initialBalance;
  final int colorValue;
  final bool includeInSimulation;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.colorValue,
    this.includeInSimulation = true,
  });

  Color get color => Color(colorValue);

  Wallet copyWith({
    String? name,
    WalletType? type,
    int? initialBalance,
    int? colorValue,
    bool? includeInSimulation,
  }) {
    return Wallet(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      colorValue: colorValue ?? this.colorValue,
      includeInSimulation: includeInSimulation ?? this.includeInSimulation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'initialBalance': initialBalance,
        'colorValue': colorValue,
        'includeInSimulation': includeInSimulation,
      };

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String? ?? 'cash',
      name: json['name'] as String? ?? '現金',
      type: WalletType.fromName(json['type'] as String?),
      initialBalance: (json['initialBalance'] as num?)?.toInt() ?? 0,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF2E7D32,
      includeInSimulation: json['includeInSimulation'] as bool? ?? true,
    );
  }
}

/// 1件の入出金またはチャージ履歴
class TransactionItem {
  final String id;
  final TransactionKind kind;
  final int amount;
  final String categoryId;
  final String walletId;
  final String? toWalletId;
  final String note;
  final DateTime date;
  final bool isFixed;
  final String? recurringRuleId;

  const TransactionItem({
    required this.id,
    required this.kind,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    this.toWalletId,
    required this.note,
    required this.date,
    this.isFixed = false,
    this.recurringRuleId,
  });

  CategoryDef get category {
    if (kind == TransactionKind.transfer) return AppCategories.transferCategory;
    return AppCategories.byId(
      categoryId,
      isIncome: kind == TransactionKind.income,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'amount': amount,
        'categoryId': categoryId,
        'walletId': walletId,
        'toWalletId': toWalletId,
        'note': note,
        'date': date.toIso8601String(),
        'isFixed': isFixed,
        'recurringRuleId': recurringRuleId,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final kind = TransactionKind.fromName(json['kind'] as String?);
    return TransactionItem(
      id: json['id'] as String? ?? '',
      kind: kind,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      categoryId: json['categoryId'] as String? ??
          (kind == TransactionKind.income ? 'allowance' : 'food'),
      walletId: json['walletId'] as String? ?? 'cash',
      toWalletId: json['toWalletId'] as String?,
      note: json['note'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      isFixed: json['isFixed'] as bool? ?? false,
      recurringRuleId: json['recurringRuleId'] as String?,
    );
  }
}

/// 固定引き落とし・固定収入ルール（毎月の家賃、サブスク、給料、定期お小遣いなど）
class RecurringRule {
  final String id;
  final String title;
  final bool isIncome;
  final int amount;
  final String categoryId;
  final String walletId;

  /// 毎月の発生日（1〜28、または 99 = 月末）
  final int dayOfMonth;
  final bool enabled;
  final bool autoRecord;
  final String? lastRecordedYearMonth;

  const RecurringRule({
    required this.id,
    required this.title,
    required this.isIncome,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    required this.dayOfMonth,
    this.enabled = true,
    this.autoRecord = true,
    this.lastRecordedYearMonth,
  });

  CategoryDef get category =>
      AppCategories.byId(categoryId, isIncome: isIncome);

  String get dayLabel => dayOfMonth >= 29 ? '毎月月末' : '毎月$dayOfMonth日';

  RecurringRule copyWith({
    String? title,
    bool? isIncome,
    int? amount,
    String? categoryId,
    String? walletId,
    int? dayOfMonth,
    bool? enabled,
    bool? autoRecord,
    String? lastRecordedYearMonth,
  }) {
    return RecurringRule(
      id: id,
      title: title ?? this.title,
      isIncome: isIncome ?? this.isIncome,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      walletId: walletId ?? this.walletId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      enabled: enabled ?? this.enabled,
      autoRecord: autoRecord ?? this.autoRecord,
      lastRecordedYearMonth:
          lastRecordedYearMonth ?? this.lastRecordedYearMonth,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isIncome': isIncome,
        'amount': amount,
        'categoryId': categoryId,
        'walletId': walletId,
        'dayOfMonth': dayOfMonth,
        'enabled': enabled,
        'autoRecord': autoRecord,
        'lastRecordedYearMonth': lastRecordedYearMonth,
      };

  factory RecurringRule.fromJson(Map<String, dynamic> json) {
    final isInc = json['isIncome'] as bool? ?? false;
    return RecurringRule(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isIncome: isInc,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      categoryId: json['categoryId'] as String? ??
          (isInc ? 'allowance' : 'subscription'),
      walletId: json['walletId'] as String? ?? 'cash',
      dayOfMonth: (json['dayOfMonth'] as num?)?.toInt() ?? 25,
      enabled: json['enabled'] as bool? ?? true,
      autoRecord: json['autoRecord'] as bool? ?? true,
      lastRecordedYearMonth: json['lastRecordedYearMonth'] as String?,
    );
  }
}

/// よく使う支出のワンタップ記録用テンプレート
class QuickTemplate {
  final String id;
  final String title;
  final int amount;
  final String categoryId;
  final String walletId;

  const QuickTemplate({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.walletId,
  });

  CategoryDef get category => AppCategories.byId(categoryId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'categoryId': categoryId,
        'walletId': walletId,
      };

  factory QuickTemplate.fromJson(Map<String, dynamic> json) {
    return QuickTemplate(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      categoryId: json['categoryId'] as String? ?? 'convenience',
      walletId: json['walletId'] as String? ?? 'qr_paypay',
    );
  }
}

/// カテゴリ別集計（「何にいくら使ったか」）
class CategoryBreakdown {
  final CategoryDef category;
  final int amount;
  final int count;
  final double ratio;

  const CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.count,
    required this.ratio,
  });
}

/// 決済手段別集計（「現金・電子決済のどれでいくら使ったか」）
class WalletBreakdown {
  final Wallet wallet;
  final int expenseAmount;
  final int incomeAmount;
  final int currentBalance;
  final double expenseRatio;

  const WalletBreakdown({
    required this.wallet,
    required this.expenseAmount,
    required this.incomeAmount,
    required this.currentBalance,
    required this.expenseRatio,
  });
}

/// 「◯ヶ月（または◯日間）この金額で生活するには1日いくらまで」試算結果
class SurvivalSimulation {
  final int baseFunds;
  final int totalDays;
  final double monthsEquivalent;
  final bool includeFixedIncome;
  final bool deductFixedExpense;
  final int projectedFixedIncome;
  final int projectedFixedExpense;
  final int reserveGoal;
  final int spendablePool;
  final int dailyLimit;
  final int weeklyLimit;
  final int monthlyLimit;
  final int todayVariableSpent;
  final int todayRemaining;
  final int recentDailyAverage;
  final int? survivableDaysAtCurrentPace;

  const SurvivalSimulation({
    required this.baseFunds,
    required this.totalDays,
    required this.monthsEquivalent,
    required this.includeFixedIncome,
    required this.deductFixedExpense,
    required this.projectedFixedIncome,
    required this.projectedFixedExpense,
    required this.reserveGoal,
    required this.spendablePool,
    required this.dailyLimit,
    required this.weeklyLimit,
    required this.monthlyLimit,
    required this.todayVariableSpent,
    required this.todayRemaining,
    required this.recentDailyAverage,
    required this.survivableDaysAtCurrentPace,
  });
}
