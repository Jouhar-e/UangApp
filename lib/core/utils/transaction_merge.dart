import 'package:uangapp/models/transaction.dart';

class TransactionMergeResult {
  const TransactionMergeResult({
    required this.transactions,
    required this.conflictsResolved,
  });

  final List<Transaction> transactions;
  final int conflictsResolved;
}

/// Gabungkan cache lokal dengan data Google Sheets (versi [updatedAt] lebih baru menang).
TransactionMergeResult mergeTransactions({
  required List<Transaction> local,
  required List<Transaction> remote,
  required Set<String> pendingMutationIds,
}) {
  final byId = <String, Transaction>{};
  var conflicts = 0;

  for (final r in remote) {
    if (r.id.isEmpty) continue;
    byId[r.id] = r;
  }

  for (final l in local) {
    if (l.id.isEmpty) continue;
    final existing = byId[l.id];
    if (existing == null) {
      byId[l.id] = l;
      continue;
    }

    final localWins = pendingMutationIds.contains(l.id) ||
        l.updatedAt.isAfter(existing.updatedAt);
    if (localWins) {
      if (!l.updatedAt.isAtSameMomentAs(existing.updatedAt) &&
          !pendingMutationIds.contains(l.id)) {
        conflicts++;
      }
      byId[l.id] = l;
    } else if (l.updatedAt.isBefore(existing.updatedAt)) {
      conflicts++;
    }
  }

  final merged = byId.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  return TransactionMergeResult(
    transactions: merged,
    conflictsResolved: conflicts,
  );
}
