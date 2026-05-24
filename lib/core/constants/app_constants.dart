class AppConstants {
  AppConstants._();

  static const spreadsheetName = 'Flutter_Finance_Tracker';
  static const transactionsSheetName = 'Transactions';

  /// Tab laporan AI per bulan, contoh: Laporan_2026-05
  static String monthlyReportSheetTitle(DateTime month) {
    final y = month.year;
    final m = month.month.toString().padLeft(2, '0');
    return 'Laporan_$y-$m';
  }

  static const transactionHeaders = [
    'id',
    'date',
    'amount',
    'category',
    'description',
    'type',
    'created_at',
    'updated_at',
    'is_deleted',
  ];

  static const googleScopes = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive.file',
  ];

  static const cacheTransactionsKey = 'cached_transactions';
  static const cacheSpreadsheetIdKey = 'spreadsheet_id';
  static const cacheProfileKey = 'user_profile';
  static const pendingSyncQueueKey = 'pending_sync_queue_v2';
  static const lastSyncAtKey = 'last_sync_at';
  static const monthlyBudgetKey = 'monthly_budget_idr';
  static const notificationHourKey = 'notification_hour';
  static const notificationMinuteKey = 'notification_minute';
  static const notificationsEnabledKey = 'notifications_enabled';

  static String spreadsheetEditUrl(String spreadsheetId) =>
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/edit';
}
