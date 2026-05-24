import 'package:flutter_test/flutter_test.dart';
import 'package:uangapp/core/utils/amount_parser.dart';
import 'package:uangapp/core/utils/transaction_filters.dart';
import 'package:uangapp/models/parsed_transaction.dart';
import 'package:uangapp/models/transaction.dart';

void main() {
  test('parseAmount handles int, double, and string', () {
    expect(parseAmount(50000), 50000.0);
    expect(parseAmount(50000.5), 50000.5);
    expect(parseAmount('50.000'), 50.0);
  });

  test('ParsedTransaction.fromJson parses Gemini-style payload', () {
    final parsed = ParsedTransaction.fromJson({
      'amount': 50000,
      'type': 'Expense',
      'category': 'Food & Drinks',
      'description': 'Kopi di Starbucks',
    });
    expect(parsed.amount, 50000);
    expect(parsed.description, 'Kopi di Starbucks');
  });

  test('filterAndSortTransactions filters by type and search', () {
    final txs = [
      Transaction(
        id: '1',
        date: DateTime(2026, 5, 10),
        amount: 100,
        category: 'Food',
        description: 'Kopi',
        type: TransactionType.expense,
        createdAt: DateTime(2026, 5, 10),
        updatedAt: DateTime(2026, 5, 10),
      ),
      Transaction(
        id: '2',
        date: DateTime(2026, 5, 12),
        amount: 5000,
        category: 'Salary',
        description: 'Gaji',
        type: TransactionType.income,
        createdAt: DateTime(2026, 5, 12),
        updatedAt: DateTime(2026, 5, 12),
      ),
    ];
    final filtered = filterAndSortTransactions(
      txs,
      const TransactionFilterCriteria(
        typeFilter: TransactionTypeFilter.income,
        sort: TransactionSortOption.newest,
      ),
    );
    expect(filtered.length, 1);
    expect(filtered.first.isIncome, true);
  });

  test('parseManualAmountInput handles Indonesian thousands', () {
    expect(parseManualAmountInput('50000'), 50000);
    expect(parseManualAmountInput('50.000'), 50000);
    expect(parseManualAmountInput('1.250.500'), 1250500);
    expect(parseManualAmountInput('Rp 10.000'), 10000);
  });
}
