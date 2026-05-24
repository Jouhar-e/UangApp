import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:uangapp/core/constants/transaction_categories.dart';
import 'package:uangapp/core/utils/transaction_filters.dart';
import 'package:uangapp/core/utils/transaction_merge.dart';
import 'package:uangapp/models/parsed_transaction.dart';
import 'package:uangapp/models/pending_sync_operation.dart';
import 'package:uangapp/models/transaction.dart';
import 'package:uangapp/services/cache_service.dart';
import 'package:uangapp/services/connectivity_service.dart';
import 'package:uangapp/services/ai_service.dart';
import 'package:uangapp/services/google_sheets_service.dart';
import 'package:uangapp/services/sqlite_service.dart';
import 'package:uangapp/services/sync_queue_service.dart';

part 'transaction_event.dart';
part 'transaction_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc({
    required GoogleSheetsService sheetsService,
    required CacheService cacheService,
    required SyncQueueService syncQueueService,
    required ConnectivityService connectivityService,
    required AiService aiService,
  })  : _sheetsService = sheetsService,
        _cacheService = cacheService,
        _syncQueueService = syncQueueService,
        _connectivityService = connectivityService,
        _aiService = aiService,
        super(const TransactionState()) {
    on<TransactionsLoadRequested>(_onLoad);
    on<TransactionAddRequested>(_onAdd);
    on<TransactionUpdateRequested>(_onUpdate);
    on<TransactionDeleteRequested>(_onDelete);
    on<TransactionDraftCleared>(_onDraftCleared);
    on<TransactionParseAiRequested>(_onParseAi);
    on<TransactionSyncQueueRequested>(_onSyncQueue);
    on<TransactionsConnectivityChanged>(_onConnectivity);
  }

  final GoogleSheetsService _sheetsService;
  final CacheService _cacheService;
  final SyncQueueService _syncQueueService;
  final ConnectivityService _connectivityService;
  final AiService _aiService;
  final _uuid = const Uuid();

  Future<void> _persistLocal(
    List<Transaction> transactions, {
    DateTime? lastSyncAt,
  }) async {
    await _cacheService.saveTransactions(transactions);
    if (lastSyncAt != null) {
      await _cacheService.saveLastSyncAt(lastSyncAt);
    }
  }

  Future<void> _emitPendingCount(Emitter<TransactionState> emit) async {
    final pending = await _syncQueueService.loadPending();
    emit(state.copyWith(pendingSyncCount: pending.length));
  }

  Transaction _normalize(Transaction tx) {
    return tx.copyWith(
      category: TransactionCategories.normalize(tx.category, tx.type),
    );
  }

  Future<void> _onLoad(
    TransactionsLoadRequested event,
    Emitter<TransactionState> emit,
  ) async {
    final lastSync = await _cacheService.loadLastSyncAt();
    final cached = sortTransactionsNewest(await _cacheService.loadTransactions());
    final pending = await _syncQueueService.loadPending();
    final pendingIds = _syncQueueService.pendingIds(pending);

    if (!event.silent) {
      if (cached.isNotEmpty) {
        emit(state.copyWith(
          loadStatus: TransactionLoadStatus.success,
          transactions: cached,
          lastSyncAt: lastSync,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          loadStatus: TransactionLoadStatus.loading,
          clearError: true,
        ));
      }
    }

    final online = await _connectivityService.isOnline;
    emit(state.copyWith(
      isOnline: online,
      pendingSyncCount: pending.length,
    ));

    if (!online || !event.syncWithGoogle) {
      emit(state.copyWith(
        loadStatus: TransactionLoadStatus.success,
        transactions: cached,
        lastSyncAt: lastSync,
        errorMessage: !online
            ? (cached.isEmpty
                ? 'Offline — belum ada data tersimpan'
                : null)
            : (cached.isEmpty
                ? 'Ketuk menu ⋮ → Sinkronkan untuk memuat dari Google Sheets'
                : null),
        clearError: !online && cached.isNotEmpty,
      ));
      return;
    }

    try {
      final cachedId = await _cacheService.loadSpreadsheetId();
      final sheetId = await _sheetsService.ensureSpreadsheet(
        cachedId: cachedId,
        forSync: event.syncWithGoogle,
      );
      await _cacheService.saveSpreadsheetId(sheetId);

      // Load ALL local including soft-deleted ones for correct merge:
      final allLocal = await SqliteService.instance.loadTransactions(includeDeleted: true);

      final remote =
          sortTransactionsNewest(await _sheetsService.fetchTransactions());
      final merge = mergeTransactions(
        local: allLocal,
        remote: remote,
        pendingMutationIds: pendingIds,
      );

      var merged = merge.transactions;
      // We apply pending deletes in memory so they are immediately hidden
      for (final op in pending) {
        if (op.type == SyncOpType.delete) {
          merged = merged.map((t) => t.id == op.transaction.id ? t.copyWith(isDeleted: true) : t).toList();
        }
      }

      final now = DateTime.now();
      await _persistLocal(merged, lastSyncAt: now);

      final activeMerged = sortTransactionsNewest(merged.where((t) => !t.isDeleted).toList());

      String? info;
      if (merge.conflictsResolved > 0) {
        info =
            'Sinkron: ${merge.conflictsResolved} perbedaan diselesaikan (versi terbaru dipakai)';
      }

      emit(state.copyWith(
        loadStatus: TransactionLoadStatus.success,
        transactions: activeMerged,
        lastSyncAt: now,
        conflictsResolvedLastSync: merge.conflictsResolved,
        infoMessage: info,
        clearError: true,
      ));

      add(const TransactionSyncQueueRequested());
    } catch (e) {
      final fallback =
          sortTransactionsNewest(await _cacheService.loadTransactions());
      emit(state.copyWith(
        loadStatus: TransactionLoadStatus.failure,
        transactions: fallback.isNotEmpty ? fallback : state.transactions,
        errorMessage: 'Sinkron gagal: $e',
      ));
    }
  }

  Future<void> _onDraftCleared(
    TransactionDraftCleared event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(clearParsed: true));
  }

  /// Helper: perbarui list lokal di SQLite + emit state baru.
  /// Dipakai oleh _onAdd, _onUpdate, _onDelete saat offline atau API gagal.
  Future<void> _applyLocalList(
    List<Transaction> list,
    Emitter<TransactionState> emit,
  ) async {
    final sorted = sortTransactionsNewest(list);
    await SqliteService.instance.saveTransactions(sorted);
    await _emitPendingCount(emit);
    emit(state.copyWith(transactions: sorted));
  }

  Future<void> _onAdd(
    TransactionAddRequested event,
    Emitter<TransactionState> emit,
  ) async {
    var tx = _normalize(event.transaction);
    if (tx.id.isEmpty) {
      final now = DateTime.now();
      tx = tx.copyWith(id: _uuid.v4(), createdAt: now, updatedAt: now);
    } else {
      tx = tx.touchUpdated();
    }

    final online = await _connectivityService.isOnline;

    // --- Offline: simpan lokal & antri ---
    if (!online) {
      await _syncQueueService.enqueueAdd(tx);
      await _applyLocalList([tx, ...state.transactions], emit);
      emit(state.copyWith(clearParsed: true, clearError: true));
      return;
    }

    // --- Online: langsung kirim ke Sheets, fallback ke antrean jika gagal ---
    try {
      final cachedId = await _cacheService.loadSpreadsheetId();
      await _sheetsService.ensureSpreadsheet(cachedId: cachedId);
      final sid = _sheetsService.spreadsheetId;
      if (sid != null && sid.isNotEmpty) {
        await _cacheService.saveSpreadsheetId(sid);
      }

      final saved = await _sheetsService.appendTransaction(tx);
      await SqliteService.instance.saveTransaction(saved);
      await _applyLocalList([saved, ...state.transactions], emit);
      emit(state.copyWith(
        loadStatus: TransactionLoadStatus.success,
        clearParsed: true,
        clearError: true,
      ));
    } catch (e) {
      // API gagal — simpan ke antrean & tampilkan lokal
      await _syncQueueService.enqueueAdd(tx);
      await _applyLocalList([tx, ...state.transactions], emit);
      emit(state.copyWith(
        clearParsed: true,
        infoMessage: 'Disimpan lokal — akan disinkronkan saat online',
      ));
    }
  }

  Future<void> _onUpdate(
    TransactionUpdateRequested event,
    Emitter<TransactionState> emit,
  ) async {
    final tx = _normalize(event.transaction).touchUpdated();
    final online = await _connectivityService.isOnline;

    Future<void> updateLocal() async {
      final list = state.transactions
          .map((t) => t.id == tx.id ? tx : t)
          .toList();
      await _applyLocalList(list, emit);
    }

    if (!online) {
      await _syncQueueService.enqueueUpdate(tx);
      await updateLocal();
      emit(state.copyWith(
        infoMessage: 'Perubahan disimpan lokal — menunggu sinkron',
        clearError: true,
      ));
      return;
    }

    try {
      final cachedId = await _cacheService.loadSpreadsheetId();
      await _sheetsService.ensureSpreadsheet(cachedId: cachedId);
      final saved = await _sheetsService.updateTransaction(tx);
      await SqliteService.instance.saveTransaction(saved);
      final list = state.transactions.map((t) => t.id == saved.id ? saved : t).toList();
      await _applyLocalList(list, emit);
      emit(state.copyWith(clearError: true, clearInfo: true));
    } catch (e) {
      await _syncQueueService.enqueueUpdate(tx);
      await updateLocal();
      emit(state.copyWith(
        infoMessage: 'Perubahan disimpan lokal — akan disinkronkan',
      ));
    }
  }

  Future<void> _onDelete(
    TransactionDeleteRequested event,
    Emitter<TransactionState> emit,
  ) async {
    final id = event.transactionId;
    final existing = state.transactions.firstWhere((t) => t.id == id);
    final online = await _connectivityService.isOnline;

    // Tandai soft-delete di SQLite lokal terlebih dahulu
    final softDeleted = existing.copyWith(isDeleted: true);
    await SqliteService.instance.saveTransaction(softDeleted);

    Future<void> removeLocal() async {
      await _applyLocalList(
        state.transactions.where((t) => t.id != id).toList(),
        emit,
      );
    }

    if (!online) {
      await _syncQueueService.enqueueDelete(softDeleted);
      await removeLocal();
      emit(state.copyWith(
        infoMessage: 'Dihapus lokal — menunggu sinkron',
        clearError: true,
      ));
      return;
    }

    try {
      final cachedId = await _cacheService.loadSpreadsheetId();
      await _sheetsService.ensureSpreadsheet(cachedId: cachedId);
      // Soft delete di Sheets (kolom is_deleted = TRUE)
      await _sheetsService.deleteTransaction(id);
      await _syncQueueService.removeById(id);
      await removeLocal();
      emit(state.copyWith(clearError: true, clearInfo: true));
    } catch (e) {
      await _syncQueueService.enqueueDelete(softDeleted);
      await removeLocal();
      emit(state.copyWith(
        infoMessage: 'Dihapus lokal — akan disinkronkan ke Sheet',
      ));
    }
  }

  Future<void> _onParseAi(
    TransactionParseAiRequested event,
    Emitter<TransactionState> emit,
  ) async {
    emit(state.copyWith(isParsingAi: true, errorMessage: null, clearParsed: true));
    try {
      final parsed = await _aiService.parseTransactionText(event.text);
      emit(state.copyWith(
        isParsingAi: false,
        parsedTransaction: parsed,
      ));
    } catch (e) {
      final String text;
      if (e is StateError) {
        text = e.message;
      } else {
        text =
            'AI gagal memparse: ${AiService.userFacingMessage(e)} Silakan input manual.';
      }
      emit(state.copyWith(
        isParsingAi: false,
        errorMessage: text,
      ));
    }
  }

  Future<void> _onSyncQueue(
    TransactionSyncQueueRequested event,
    Emitter<TransactionState> emit,
  ) async {
    final online = await _connectivityService.isOnline;
    emit(state.copyWith(isOnline: online));
    if (!online) return;

    final pending = await _syncQueueService.loadPending();
    if (pending.isEmpty) return;

    final cachedId = await _cacheService.loadSpreadsheetId();
    try {
      await _sheetsService.ensureSpreadsheet(cachedId: cachedId);
      final sid = _sheetsService.spreadsheetId;
      if (sid != null && sid.isNotEmpty) {
        await _cacheService.saveSpreadsheetId(sid);
      }
    } catch (_) {
      return;
    }

    for (final op in pending) {
      try {
        switch (op.type) {
          case SyncOpType.add:
            final saved = await _sheetsService.appendTransaction(op.transaction);
            await SqliteService.instance.saveTransaction(saved);
            break;
          case SyncOpType.update:
            final saved = await _sheetsService.updateTransaction(op.transaction);
            await SqliteService.instance.saveTransaction(saved);
            break;
          case SyncOpType.delete:
            await _sheetsService.deleteTransaction(op.transaction.id);
            await SqliteService.instance.saveTransaction(op.transaction.copyWith(isDeleted: true));
            break;
        }
        await _syncQueueService.removeById(op.transaction.id);
      } catch (_) {
        break;
      }
    }

    // Ambil list transaksi aktif terupdate dari SQLite
    final activeList = await SqliteService.instance.loadTransactions();
    final remaining = await _syncQueueService.loadPending();
    emit(state.copyWith(
      transactions: sortTransactionsNewest(activeList),
      pendingSyncCount: remaining.length,
      lastSyncAt: DateTime.now(),
    ));
  }

  void _onConnectivity(
    TransactionsConnectivityChanged event,
    Emitter<TransactionState> emit,
  ) {
    emit(state.copyWith(isOnline: event.isOnline));
    if (event.isOnline) {
      add(const TransactionsLoadRequested(silent: true));
      add(const TransactionSyncQueueRequested());
    }
  }
}
