part of 'transaction_bloc.dart';

enum TransactionLoadStatus { initial, loading, success, failure }

class TransactionState extends Equatable {
  const TransactionState({
    this.loadStatus = TransactionLoadStatus.initial,
    this.transactions = const [],
    this.isOnline = true,
    this.isParsingAi = false,
    this.parsedTransaction,
    this.errorMessage,
    this.infoMessage,
    this.pendingSyncCount = 0,
    this.lastSyncAt,
    this.conflictsResolvedLastSync = 0,
  });

  final TransactionLoadStatus loadStatus;
  final List<Transaction> transactions;
  final bool isOnline;
  final bool isParsingAi;
  final ParsedTransaction? parsedTransaction;
  final String? errorMessage;
  final String? infoMessage;
  final int pendingSyncCount;
  final DateTime? lastSyncAt;
  final int conflictsResolvedLastSync;

  double get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  TransactionState copyWith({
    TransactionLoadStatus? loadStatus,
    List<Transaction>? transactions,
    bool? isOnline,
    bool? isParsingAi,
    ParsedTransaction? parsedTransaction,
    bool clearParsed = false,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
    int? pendingSyncCount,
    DateTime? lastSyncAt,
    int? conflictsResolvedLastSync,
  }) {
    return TransactionState(
      loadStatus: loadStatus ?? this.loadStatus,
      transactions: transactions ?? this.transactions,
      isOnline: isOnline ?? this.isOnline,
      isParsingAi: isParsingAi ?? this.isParsingAi,
      parsedTransaction:
          clearParsed ? null : (parsedTransaction ?? this.parsedTransaction),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      conflictsResolvedLastSync:
          conflictsResolvedLastSync ?? this.conflictsResolvedLastSync,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        transactions,
        isOnline,
        isParsingAi,
        parsedTransaction,
        errorMessage,
        infoMessage,
        pendingSyncCount,
        lastSyncAt,
        conflictsResolvedLastSync,
      ];
}
