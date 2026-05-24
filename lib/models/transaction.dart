import 'package:equatable/equatable.dart';
import 'package:uangapp/core/utils/amount_parser.dart';
import 'package:uangapp/core/utils/date_utils.dart';

enum TransactionType { income, expense }

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  final String id;
  final DateTime date;
  final double amount;
  final String category;
  final String description;
  final TransactionType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  bool get isIncome => type == TransactionType.income;

  String get typeLabel => isIncome ? 'Income' : 'Expense';

  static TransactionType parseType(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized == 'income' || normalized == 'pemasukan') {
      return TransactionType.income;
    }
    return TransactionType.expense;
  }

  List<Object> toSheetRow() {
    return [
      id,
      formatSheetDate(date),
      amount.toString(),
      category,
      description,
      typeLabel,
      formatSheetDateTime(createdAt),
      formatSheetDateTime(updatedAt),
      isDeleted.toString().toUpperCase(),
    ];
  }

  factory Transaction.fromSheetRow(List<dynamic> row) {
    final created = parseSheetDateTime(row.length > 6 ? row[6].toString() : null) ??
        DateTime.now();
    final updated = parseSheetDateTime(row.length > 7 ? row[7].toString() : null) ??
        created;
    final deletedRaw = row.length > 8 ? row[8].toString().trim().toUpperCase() : 'FALSE';
    final isDeleted = deletedRaw == 'TRUE';
    return Transaction(
      id: row.isNotEmpty ? row[0].toString() : '',
      date: parseSheetDate(row.length > 1 ? row[1].toString() : null) ?? DateTime.now(),
      amount: parseAmount(row.length > 2 ? row[2] : null) ?? 0,
      category: row.length > 3 ? row[3].toString() : '',
      description: row.length > 4 ? row[4].toString() : '',
      type: parseType(row.length > 5 ? row[5].toString() : null),
      createdAt: created,
      updatedAt: updated,
      isDeleted: isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': formatSheetDate(date),
        'amount': amount,
        'category': category,
        'description': description,
        'type': typeLabel,
        'created_at': formatSheetDateTime(createdAt),
        'updated_at': formatSheetDateTime(updatedAt),
        'is_deleted': isDeleted,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final created =
        parseSheetDateTime(json['created_at'] as String?) ?? DateTime.now();
    final updated =
        parseSheetDateTime(json['updated_at'] as String?) ?? created;
    return Transaction(
      id: json['id'] as String? ?? '',
      date: parseSheetDate(json['date'] as String?) ?? DateTime.now(),
      amount: parseAmount(json['amount']) ?? 0,
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: parseType(json['type'] as String?),
      createdAt: created,
      updatedAt: updated,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Transaction copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? category,
    String? description,
    TransactionType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Transaction touchUpdated() => copyWith(updatedAt: DateTime.now());

  @override
  List<Object?> get props => [
        id,
        date,
        amount,
        category,
        description,
        type,
        createdAt,
        updatedAt,
        isDeleted,
      ];
}
