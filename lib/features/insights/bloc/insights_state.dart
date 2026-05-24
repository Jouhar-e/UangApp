part of 'insights_bloc.dart';

enum InsightsStatus { initial, loading, success, failure }

class InsightsState extends Equatable {
  const InsightsState({
    this.status = InsightsStatus.initial,
    this.report,
    this.errorMessage,
    this.savedSheetTitle,
  });

  final InsightsStatus status;
  final String? report;
  final String? errorMessage;
  /// Nama tab Google Sheet setelah laporan tersimpan, mis. Laporan_2026-05
  final String? savedSheetTitle;

  InsightsState copyWith({
    InsightsStatus? status,
    String? report,
    String? errorMessage,
    String? savedSheetTitle,
    bool clearSavedSheet = false,
  }) {
    return InsightsState(
      status: status ?? this.status,
      report: report ?? this.report,
      errorMessage: errorMessage,
      savedSheetTitle:
          clearSavedSheet ? null : (savedSheetTitle ?? this.savedSheetTitle),
    );
  }

  @override
  List<Object?> get props => [status, report, errorMessage, savedSheetTitle];
}
