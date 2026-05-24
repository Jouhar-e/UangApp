import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangapp/core/constants/app_constants.dart';
import 'package:uangapp/models/transaction.dart';
import 'package:uangapp/services/sqlite_service.dart';

class CacheService {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> saveTransactions(List<Transaction> transactions) async {
    await SqliteService.instance.saveTransactions(transactions);
  }

  Future<List<Transaction>> loadTransactions() async {
    return await SqliteService.instance.loadTransactions();
  }

  Future<void> saveSpreadsheetId(String id) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.cacheSpreadsheetIdKey, id);
  }

  Future<String?> loadSpreadsheetId() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.cacheSpreadsheetIdKey);
  }

  Future<void> saveLastSyncAt(DateTime time) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.lastSyncAtKey, time.toIso8601String());
  }

  Future<DateTime?> loadLastSyncAt() async {
    final prefs = await _prefs;
    final raw = prefs.getString(AppConstants.lastSyncAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}
