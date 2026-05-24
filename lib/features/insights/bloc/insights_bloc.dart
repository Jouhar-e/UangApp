import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uangapp/core/utils/month_summary.dart';
import 'package:uangapp/models/transaction.dart';
import 'package:uangapp/services/ai_service.dart';
import 'package:uangapp/services/cache_service.dart';
import 'package:uangapp/services/google_sheets_service.dart';

part 'insights_event.dart';
part 'insights_state.dart';

class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  InsightsBloc({
    required AiService aiService,
    required GoogleSheetsService sheetsService,
    required CacheService cacheService,
  })  : _aiService = aiService,
        _sheetsService = sheetsService,
        _cacheService = cacheService,
        super(const InsightsState()) {
    on<InsightsReportRequested>(_onReport);
  }

  final AiService _aiService;
  final GoogleSheetsService _sheetsService;
  final CacheService _cacheService;

  Future<void> _onReport(
    InsightsReportRequested event,
    Emitter<InsightsState> emit,
  ) async {
    emit(state.copyWith(
      status: InsightsStatus.loading,
      errorMessage: null,
      clearSavedSheet: true,
    ));

    try {
      if (!_aiService.isConfigured) {
        throw StateError('GROQ_API_KEY belum dikonfigurasi di .env');
      }

      final monthTx = event.monthTransactions;
      final totalIncome = monthTx
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);
      final totalExpense = monthTx
          .where((t) => !t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);

      final prevSummary = MonthFinancialSummary.fromTransactions(
        event.allTransactions,
        previousMonth(event.month),
      );

      final report = await _aiService.generateMonthlyReport(
        monthTransactions: monthTx,
        month: event.month,
        previousMonthSummary:
            prevSummary.transactionCount > 0 ? prevSummary : null,
      );

      String? sheetTitle;
      try {
        final cachedId = await _cacheService.loadSpreadsheetId();
        await _sheetsService.ensureSpreadsheet(cachedId: cachedId);
        final sid = _sheetsService.spreadsheetId;
        if (sid != null && sid.isNotEmpty) {
          await _cacheService.saveSpreadsheetId(sid);
        }

        sheetTitle = await _sheetsService.saveMonthlyReport(
          month: event.month,
          reportText: report,
          totalIncome: totalIncome,
          totalExpense: totalExpense,
          transactionCount: monthTx.length,
        );
      } catch (sheetError) {
        emit(state.copyWith(
          status: InsightsStatus.success,
          report: report,
          errorMessage:
              'Laporan AI berhasil, tetapi gagal disimpan ke Google Sheets: $sheetError',
        ));
        return;
      }

      emit(state.copyWith(
        status: InsightsStatus.success,
        report: report,
        savedSheetTitle: sheetTitle,
        errorMessage: null,
      ));
    } catch (e) {
      final String text;
      if (e is StateError) {
        text = e.message;
      } else {
        text = AiService.userFacingMessage(e);
      }
      emit(state.copyWith(
        status: InsightsStatus.failure,
        errorMessage: text,
      ));
    }
  }
}
