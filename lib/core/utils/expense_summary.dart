import 'package:intl/intl.dart';
import 'package:uangapp/core/utils/date_utils.dart';
import 'package:uangapp/models/transaction.dart';

class ExpenseSummary {
  const ExpenseSummary({
    required this.todayExpenseCount,
    required this.todayExpenseTotal,
    required this.monthExpenseCount,
    required this.monthExpenseTotal,
    required this.referenceDate,
  });

  final int todayExpenseCount;
  final double todayExpenseTotal;
  final int monthExpenseCount;
  final double monthExpenseTotal;
  final DateTime referenceDate;

  String get notificationTitle => 'Ringkasan Pengeluaran UangApp';

  String get notificationBody {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return 'Hari ini: $todayExpenseCount transaksi · ${currency.format(todayExpenseTotal)}\n'
        'Bulan ini: $monthExpenseCount transaksi · ${currency.format(monthExpenseTotal)}';
  }
}

ExpenseSummary computeExpenseSummary(
  List<Transaction> transactions, {
  DateTime? reference,
}) {
  final now = reference ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  var todayCount = 0;
  var todayTotal = 0.0;
  var monthCount = 0;
  var monthTotal = 0.0;

  for (final tx in transactions) {
    if (tx.isIncome) continue;
    final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
    if (day == today) {
      todayCount++;
      todayTotal += tx.amount;
    }
    if (isSameMonth(tx.date, now)) {
      monthCount++;
      monthTotal += tx.amount;
    }
  }

  return ExpenseSummary(
    todayExpenseCount: todayCount,
    todayExpenseTotal: todayTotal,
    monthExpenseCount: monthCount,
    monthExpenseTotal: monthTotal,
    referenceDate: now,
  );
}
