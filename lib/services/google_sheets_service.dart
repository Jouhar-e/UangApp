import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:uangapp/core/constants/app_constants.dart';
import 'package:uangapp/core/utils/date_utils.dart';
import 'package:uangapp/models/transaction.dart';
import 'package:uangapp/services/google_auth_service.dart';

class GoogleSheetsService {
  GoogleSheetsService(this._apiRunner);

  final AuthenticatedApiRunner _apiRunner;
  final _uuid = const Uuid();

  String? _spreadsheetId;

  String? get spreadsheetId => _spreadsheetId;

  void setSpreadsheetId(String? id) => _spreadsheetId = id;

  /// Warna tab sheet — Forest (#5B8266).
  static sheets.Color get _forestTabColor => sheets.Color()
    ..red = 91 / 255
    ..green = 130 / 255
    ..blue = 102 / 255;

  Future<String> ensureSpreadsheet({
    String? cachedId,
    bool forSync = false,
  }) async {
    if (cachedId != null && cachedId.isNotEmpty) {
      _spreadsheetId = cachedId;
      try {
        await _getTransactionsRange();
        return cachedId;
      } catch (_) {
        _spreadsheetId = null;
      }
    }

    final id = await _apiRunner.run(
      (client) async {
      final driveApi = drive.DriveApi(client);
      final query =
          "mimeType='application/vnd.google-apps.spreadsheet' and name='${AppConstants.spreadsheetName}' and trashed=false";
      final list = await driveApi.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (list.files != null && list.files!.isNotEmpty) {
        return list.files!.first.id!;
      }

      return _createSpreadsheet(client);
    },
      forSync: forSync,
    );

    _spreadsheetId = id;
    return id;
  }

  Future<String> _createSpreadsheet(http.Client client) async {
    final sheetsApi = sheets.SheetsApi(client);

    final spreadsheet = await sheetsApi.spreadsheets.create(
      sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(
          title: AppConstants.spreadsheetName,
        ),
        sheets: [
          sheets.Sheet(
            properties: sheets.SheetProperties(
              title: AppConstants.transactionsSheetName,
            ),
          ),
        ],
      ),
    );

    final id = spreadsheet.spreadsheetId!;
    await sheetsApi.spreadsheets.values.update(
      sheets.ValueRange(values: [AppConstants.transactionHeaders]),
      id,
      '${AppConstants.transactionsSheetName}!A1',
      valueInputOption: 'RAW',
    );

    return id;
  }



  Future<int?> _findRowNumberForId(
    sheets.SheetsApi sheetsApi,
    String spreadsheetId,
    String transactionId,
  ) async {
    final range = '${AppConstants.transactionsSheetName}!A:A';
    final response =
        await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
    final rows = response.values ?? [];
    for (var i = 1; i < rows.length; i++) {
      if (rows[i].isNotEmpty && rows[i][0].toString() == transactionId) {
        return i + 1;
      }
    }
    return null;
  }

  Future<void> _validateAndMigrateHeaders(sheets.SheetsApi sheetsApi, String id) async {
    final headerResponse = await sheetsApi.spreadsheets.values.get(
      id,
      '${AppConstants.transactionsSheetName}!A1:I1',
    );
    final row = headerResponse.values?.firstOrNull ?? [];
    
    if (row.isEmpty) {
      await sheetsApi.spreadsheets.values.update(
        sheets.ValueRange(values: [AppConstants.transactionHeaders]),
        id,
        '${AppConstants.transactionsSheetName}!A1',
        valueInputOption: 'RAW',
      );
      return;
    }

    for (var i = 0; i < row.length; i++) {
      if (i < AppConstants.transactionHeaders.length) {
        final expected = AppConstants.transactionHeaders[i];
        final actual = row[i].toString().trim().toLowerCase();
        if (actual != expected.toLowerCase()) {
          throw FormatException(
            'Kolom Google Sheet tidak cocok di index $i. Ditemukan "$actual", '
            'diharapkan "$expected". Harap jangan mengubah nama atau urutan kolom.',
          );
        }
      }
    }

    if (row.length < 9) {
      await sheetsApi.spreadsheets.values.update(
        sheets.ValueRange(values: [['is_deleted']]),
        id,
        '${AppConstants.transactionsSheetName}!I1',
        valueInputOption: 'RAW',
      );
    }
  }

  Future<List<Transaction>> fetchTransactions() async {
    final id = _spreadsheetId;
    if (id == null || id.isEmpty) {
      throw StateError('Spreadsheet belum diinisialisasi');
    }

    return _apiRunner.run((client) async {
      final sheetsApi = sheets.SheetsApi(client);
      await _validateAndMigrateHeaders(sheetsApi, id);
      final range = await _getTransactionsRangeWithClient(sheetsApi, id);
      final response = await sheetsApi.spreadsheets.values.get(id, range);

      final rows = response.values ?? [];
      if (rows.length <= 1) return <Transaction>[];

      return rows.skip(1).map((row) {
        return Transaction.fromSheetRow(row);
      }).where((t) => t.id.isNotEmpty).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  Future<Transaction> updateTransaction(Transaction transaction) async {
    final id = _spreadsheetId;
    if (id == null || id.isEmpty) {
      throw StateError('Spreadsheet belum diinisialisasi');
    }

    final tx = transaction.touchUpdated();

    await _apiRunner.run((client) async {
      final sheetsApi = sheets.SheetsApi(client);
      await _validateAndMigrateHeaders(sheetsApi, id);
      final row = await _findRowNumberForId(sheetsApi, id, tx.id);
      if (row == null) {
        throw StateError('Transaksi tidak ditemukan di Sheet');
      }
      await sheetsApi.spreadsheets.values.update(
        sheets.ValueRange(values: [tx.toSheetRow()]),
        id,
        '${AppConstants.transactionsSheetName}!A$row:I$row',
        valueInputOption: 'RAW',
      );
    });

    return tx;
  }

  Future<void> deleteTransaction(String transactionId) async {
    final id = _spreadsheetId;
    if (id == null || id.isEmpty) {
      throw StateError('Spreadsheet belum diinisialisasi');
    }

    await _apiRunner.run((client) async {
      final sheetsApi = sheets.SheetsApi(client);
      final row = await _findRowNumberForId(sheetsApi, id, transactionId);
      if (row == null) return;

      // Soft delete: update Column I to 'TRUE'
      await sheetsApi.spreadsheets.values.update(
        sheets.ValueRange(values: [['TRUE']]),
        id,
        '${AppConstants.transactionsSheetName}!I$row',
        valueInputOption: 'RAW',
      );
    });
  }

  Future<Transaction> appendTransaction(Transaction transaction) async {
    final id = _spreadsheetId;
    if (id == null || id.isEmpty) {
      throw StateError('Spreadsheet belum diinisialisasi');
    }

    final now = DateTime.now();
    final toSave = transaction.id.isEmpty
        ? transaction.copyWith(
            id: _uuid.v4(),
            createdAt: now,
            updatedAt: now,
          )
        : transaction.touchUpdated();

    await _apiRunner.run((client) async {
      final sheetsApi = sheets.SheetsApi(client);
      await _validateAndMigrateHeaders(sheetsApi, id);
      await sheetsApi.spreadsheets.values.append(
        sheets.ValueRange(values: [toSave.toSheetRow()]),
        id,
        '${AppConstants.transactionsSheetName}!A:I',
        valueInputOption: 'RAW',
        insertDataOption: 'INSERT_ROWS',
      );
    });

    return toSave;
  }

  /// Membuat tab laporan bulanan (jika belum ada) dan menulis ringkasan + teks AI.
  Future<String> saveMonthlyReport({
    required DateTime month,
    required String reportText,
    required double totalIncome,
    required double totalExpense,
    required int transactionCount,
  }) async {
    final id = _spreadsheetId;
    if (id == null || id.isEmpty) {
      throw StateError('Spreadsheet belum diinisialisasi');
    }

    final sheetTitle = AppConstants.monthlyReportSheetTitle(month);
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(month);
    final balance = totalIncome - totalExpense;
    final createdAt = formatSheetDateTime(DateTime.now());

    final rows = <List<Object>>[
      ['Laporan Bulanan UangApp', ''],
      ['Bulan', monthLabel],
      ['Periode', '${month.year}-${month.month.toString().padLeft(2, '0')}'],
      ['Dibuat', createdAt],
      ['Pemasukan (IDR)', totalIncome.toStringAsFixed(0)],
      ['Pengeluaran (IDR)', totalExpense.toStringAsFixed(0)],
      ['Saldo (IDR)', balance.toStringAsFixed(0)],
      ['Jumlah Transaksi', transactionCount.toString()],
      ['', ''],
      ['Laporan AI', ''],
      [reportText, ''],
    ];

    await _apiRunner.run((client) async {
      final sheetsApi = sheets.SheetsApi(client);
      await _ensureSheetTab(sheetsApi, id, sheetTitle);

      await sheetsApi.spreadsheets.values.clear(
        sheets.ClearValuesRequest(),
        id,
        '$sheetTitle!A:Z',
      );

      await sheetsApi.spreadsheets.values.update(
        sheets.ValueRange(values: rows),
        id,
        '$sheetTitle!A1',
        valueInputOption: 'RAW',
      );

      final sheetId = await _sheetIdByTitle(sheetsApi, id, sheetTitle);
      if (sheetId != null) {
        await _styleReportHeader(sheetsApi, id, sheetId);
      }
    });

    return sheetTitle;
  }

  Future<void> _ensureSheetTab(
    sheets.SheetsApi sheetsApi,
    String spreadsheetId,
    String title,
  ) async {
    final existing = await _sheetIdByTitle(sheetsApi, spreadsheetId, title);
    if (existing != null) return;

    await sheetsApi.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(
            addSheet: sheets.AddSheetRequest(
              properties: sheets.SheetProperties(
                title: title,
                tabColor: _forestTabColor,
              ),
            ),
          ),
        ],
      ),
      spreadsheetId,
    );
  }

  Future<int?> _sheetIdByTitle(
    sheets.SheetsApi sheetsApi,
    String spreadsheetId,
    String title,
  ) async {
    final meta = await sheetsApi.spreadsheets.get(
      spreadsheetId,
      includeGridData: false,
    );
    for (final sheet in meta.sheets ?? []) {
      if (sheet.properties?.title == title) {
        return sheet.properties?.sheetId;
      }
    }
    return null;
  }

  Future<void> _styleReportHeader(
    sheets.SheetsApi sheetsApi,
    String spreadsheetId,
    int sheetId,
  ) async {
    final headerStyle = sheets.CellFormat(
      backgroundColor: _forestTabColor,
      textFormat: sheets.TextFormat(
        bold: true,
        foregroundColor: sheets.Color()
          ..red = 1
          ..green = 1
          ..blue = 1,
      ),
    );

    await sheetsApi.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(
            repeatCell: sheets.RepeatCellRequest(
              range: sheets.GridRange(
                sheetId: sheetId,
                startRowIndex: 0,
                endRowIndex: 1,
                startColumnIndex: 0,
                endColumnIndex: 2,
              ),
              cell: sheets.CellData(userEnteredFormat: headerStyle),
              fields: 'userEnteredFormat(backgroundColor,textFormat)',
            ),
          ),
        ],
      ),
      spreadsheetId,
    );
  }

  Future<String> _getTransactionsRange() async {
    final id = _spreadsheetId!;
    return _apiRunner.run((client) async {
      final sheetsApi = sheets.SheetsApi(client);
      return _getTransactionsRangeWithClient(sheetsApi, id);
    });
  }

  Future<String> _getTransactionsRangeWithClient(
    sheets.SheetsApi sheetsApi,
    String spreadsheetId,
  ) async {
    return '${AppConstants.transactionsSheetName}!A:I';
  }
}
