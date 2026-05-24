import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uangapp/core/constants/app_constants.dart';
import 'package:uangapp/features/transactions/bloc/transaction_bloc.dart';
import 'package:uangapp/services/cache_service.dart';
import 'package:uangapp/services/google_sheets_service.dart';
import 'package:uangapp/core/utils/app_messenger.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openGoogleSpreadsheet(BuildContext context) async {
  final cache = context.read<CacheService>();
  final sheets = context.read<GoogleSheetsService>();

  var sheetId = sheets.spreadsheetId ?? await cache.loadSpreadsheetId();
  if (sheetId == null || sheetId.isEmpty) {
    if (context.mounted) {
      context.read<TransactionBloc>().add(
            const TransactionsLoadRequested(syncWithGoogle: true),
          );
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
    sheetId = sheets.spreadsheetId ?? await cache.loadSpreadsheetId();
  }

  if (sheetId == null || sheetId.isEmpty) {
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      'Spreadsheet belum tersedia. Refresh atau tambah transaksi dulu.',
    );
    return;
  }

  final url = Uri.parse(AppConstants.spreadsheetEditUrl(sheetId));
  final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    showAppSnackBar(context, 'Tidak dapat membuka: $url');
  }
}
