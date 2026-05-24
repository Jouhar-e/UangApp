import 'package:uangapp/models/transaction.dart';

enum SyncOpType { add, update, delete }

class PendingSyncOperation {
  const PendingSyncOperation({
    required this.type,
    required this.transaction,
    required this.enqueuedAt,
  });

  final SyncOpType type;
  final Transaction transaction;
  final DateTime enqueuedAt;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'transaction': transaction.toJson(),
        'enqueued_at': enqueuedAt.toIso8601String(),
      };

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    final txJson = json['transaction'] as Map<String, dynamic>;
    return PendingSyncOperation(
      type: SyncOpType.values.byName(json['type'] as String),
      transaction: Transaction.fromJson(txJson),
      enqueuedAt: DateTime.tryParse(json['enqueued_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
