import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangapp/core/constants/app_constants.dart';
import 'package:uangapp/models/transaction.dart';

class BudgetService {
  Future<double?> loadMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(AppConstants.monthlyBudgetKey);
  }

  Future<void> saveMonthlyBudget(double? amount) async {
    final prefs = await SharedPreferences.getInstance();
    if (amount == null || amount <= 0) {
      await prefs.remove(AppConstants.monthlyBudgetKey);
    } else {
      await prefs.setDouble(AppConstants.monthlyBudgetKey, amount);
    }
  }

  double monthExpense(List<Transaction> transactions, DateTime month) {
    return transactions
        .where((t) =>
            !t.isIncome &&
            t.date.year == month.year &&
            t.date.month == month.month)
        .fold(0.0, (s, t) => s + t.amount);
  }
}
