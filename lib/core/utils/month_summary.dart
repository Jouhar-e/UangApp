import 'package:intl/intl.dart';
import 'package:uangapp/models/transaction.dart';

class MonthFinancialSummary {
  const MonthFinancialSummary({
    required this.month,
    required this.income,
    required this.expense,
    required this.transactionCount,
    required this.expenseByCategory,
  });

  final DateTime month;
  final double income;
  final double expense;
  final int transactionCount;
  final Map<String, double> expenseByCategory;

  double get balance => income - expense;

  static MonthFinancialSummary fromTransactions(
    List<Transaction> all,
    DateTime month,
  ) {
    final target = DateTime(month.year, month.month);
    final inMonth = all.where(
      (t) => t.date.year == target.year && t.date.month == target.month,
    );

    var income = 0.0;
    var expense = 0.0;
    final byCategory = <String, double>{};

    for (final t in inMonth) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
        byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      }
    }

    return MonthFinancialSummary(
      month: target,
      income: income,
      expense: expense,
      transactionCount: inMonth.length,
      expenseByCategory: byCategory,
    );
  }
}

DateTime previousMonth(DateTime month) {
  final m = DateTime(month.year, month.month);
  return DateTime(m.year, m.month - 1);
}

/// Perubahan persen: positif = naik, negif = turun.
double? percentChange(double current, double previous) {
  if (previous <= 0) return null;
  return ((current - previous) / previous) * 100;
}

String monthLabelId(DateTime month) =>
    DateFormat('MMMM yyyy', 'id_ID').format(DateTime(month.year, month.month));

String formatPercentChange(double? change) {
  if (change == null) return '—';
  final sign = change > 0 ? '+' : '';
  return '$sign${change.toStringAsFixed(0)}%';
}
