part of 'transaction_bloc.dart';

sealed class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

final class TransactionsLoadRequested extends TransactionEvent {
  const TransactionsLoadRequested({
    this.syncWithGoogle = false,
    this.silent = false,
  });

  /// Ambil data dari Google Sheets (butuh koneksi Google).
  final bool syncWithGoogle;

  /// Tanpa spinner penuh jika sudah ada cache.
  final bool silent;

  @override
  List<Object?> get props => [syncWithGoogle, silent];
}

final class TransactionAddRequested extends TransactionEvent {
  const TransactionAddRequested(this.transaction);

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

final class TransactionUpdateRequested extends TransactionEvent {
  const TransactionUpdateRequested(this.transaction);

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

final class TransactionDeleteRequested extends TransactionEvent {
  const TransactionDeleteRequested(this.transactionId);

  final String transactionId;

  @override
  List<Object?> get props => [transactionId];
}

final class TransactionDraftCleared extends TransactionEvent {
  const TransactionDraftCleared();
}

final class TransactionParseAiRequested extends TransactionEvent {
  const TransactionParseAiRequested(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

final class TransactionSyncQueueRequested extends TransactionEvent {
  const TransactionSyncQueueRequested();
}

final class TransactionsConnectivityChanged extends TransactionEvent {
  const TransactionsConnectivityChanged(this.isOnline);

  final bool isOnline;

  @override
  List<Object?> get props => [isOnline];
}
