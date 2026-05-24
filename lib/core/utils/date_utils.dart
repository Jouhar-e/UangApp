import 'package:intl/intl.dart';

/// Consistent YYYY-MM-DD for Google Sheets (avoids regional formatting glitches).
String formatSheetDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

String formatSheetDateTime(DateTime date) {
  return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(date);
}

DateTime? parseSheetDate(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final trimmed = value.trim();
  try {
    if (trimmed.length >= 10) {
      return DateTime.parse(trimmed.substring(0, 10));
    }
    return DateTime.parse(trimmed);
  } catch (_) {
    return null;
  }
}

DateTime? parseSheetDateTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  try {
    return DateTime.parse(value.trim());
  } catch (_) {
    return parseSheetDate(value);
  }
}

/// Tampilan daftar: "20 Mei 2026 · 14:30"
String formatTransactionDateTime(DateTime date, DateTime createdAt) {
  final d = DateFormat('d MMM yyyy', 'id_ID').format(date);
  final t = DateFormat('HH:mm', 'id_ID').format(createdAt);
  return '$d · $t';
}

bool isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}
