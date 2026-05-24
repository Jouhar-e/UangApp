import 'package:uangapp/models/pending_sync_operation.dart';
import 'package:uangapp/models/transaction.dart';
import 'package:uangapp/services/sqlite_service.dart';

/// Antrian operasi sync (tambah / ubah / hapus) saat offline atau gagal API.
class SyncQueueService {
  Future<List<PendingSyncOperation>> loadPending() async {
    return await SqliteService.instance.loadPendingSyncOperations();
  }

  Set<String> pendingIds(List<PendingSyncOperation> ops) =>
      ops.map((o) => o.transaction.id).toSet();

  Future<void> enqueue(PendingSyncOperation operation) async {
    await SqliteService.instance.enqueueSyncOperation(operation);
  }

  Future<void> enqueueAdd(Transaction transaction) => enqueue(
        PendingSyncOperation(
          type: SyncOpType.add,
          transaction: transaction,
          enqueuedAt: DateTime.now(),
        ),
      );

  Future<void> enqueueUpdate(Transaction transaction) => enqueue(
        PendingSyncOperation(
          type: SyncOpType.update,
          transaction: transaction,
          enqueuedAt: DateTime.now(),
        ),
      );

  Future<void> enqueueDelete(Transaction transaction) => enqueue(
        PendingSyncOperation(
          type: SyncOpType.delete,
          transaction: transaction,
          enqueuedAt: DateTime.now(),
        ),
      );

  Future<void> removeById(String id) async {
    await SqliteService.instance.removeSyncOperation(id);
  }

  Future<void> clear() async {
    await SqliteService.instance.clearSyncQueue();
  }
}
