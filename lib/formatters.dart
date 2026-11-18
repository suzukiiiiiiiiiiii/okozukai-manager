/// 金額や日付の表示フォーマットを揃えるユーティリティ。
library;

const List<String> _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

/// 整数金額をカンマ区切りの円表記（例: ¥12,800）に変換する。
String formatYen(int amount, {bool showPlus = false}) {
  final isNegative = amount < 0;
  final absVal = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < absVal.length; i++) {
    if (i > 0 && (absVal.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(absVal[i]);
  }
  if (isNegative) {
    return '-¥${buffer.toString()}';
  }
  if (showPlus && amount > 0) {
    return '+¥${buffer.toString()}';
  }
  return '¥${buffer.toString()}';
}

/// 短い日付表記（例: 11/17 (火)）
String formatDateShort(DateTime date) {
  final wd = _weekdays[(date.weekday - 1).clamp(0, 6)];
  return '${date.month}/${date.day} ($wd)';
}

/// 年月日表記（例: 2026/11/17 (火)）
String formatDateFull(DateTime date) {
  final wd = _weekdays[(date.weekday - 1).clamp(0, 6)];
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}/$m/$d ($wd)';
}

/// 年月表記（例: 2026年11月）
String formatYearMonth(int year, int month) {
  return '$year年$month月';
}

/// 指定した年月の日数を返す。
int daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}
