part of 'insights_bloc.dart';

sealed class InsightsEvent extends Equatable {
  const InsightsEvent();

  @override
  List<Object?> get props => [];
}

final class InsightsReportRequested extends InsightsEvent {
  const InsightsReportRequested({
    required this.monthTransactions,
    required this.month,
    required this.allTransactions,
  });

  final List<Transaction> monthTransactions;
  final DateTime month;
  final List<Transaction> allTransactions;

  @override
  List<Object?> get props => [monthTransactions, month, allTransactions];
}
