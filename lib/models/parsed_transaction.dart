import 'package:equatable/equatable.dart';
import 'package:uangapp/core/constants/transaction_categories.dart';
import 'package:uangapp/core/utils/amount_parser.dart';
import 'package:uangapp/models/transaction.dart';

/// Result from AI parsing (Groq, before user confirmation).
class ParsedTransaction extends Equatable {
  const ParsedTransaction({
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
  });

  final double amount;
  final TransactionType type;
  final String category;
  final String description;

  /// Buka dialog input manual (bukan dari respons AI).
  static const emptyForm = ParsedTransaction(
    amount: 0,
    type: TransactionType.expense,
    category: '',
    description: '',
  );

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {    final amount = parseAmount(json['amount']);
    if (amount == null || amount <= 0) {
      throw const FormatException('Invalid or missing amount from AI response');
    }

    final type = Transaction.parseType(json['type'] as String?);
    final rawCategory = (json['category'] as String?)?.trim() ?? '';
    return ParsedTransaction(
      amount: amount,
      type: type,
      category: TransactionCategories.normalize(rawCategory, type),
      description: (json['description'] as String?)?.trim() ?? '',
    );
  }

  Transaction toTransaction({DateTime? date}) {
    final now = DateTime.now();
    return Transaction(
      id: '',
      date: date ?? now,
      amount: amount,
      category: category,
      description: description,
      type: type,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [amount, type, category, description];
}
