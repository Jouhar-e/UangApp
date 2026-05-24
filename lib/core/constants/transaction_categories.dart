import 'package:uangapp/models/transaction.dart';

/// Kategori standar untuk konsistensi filter, grafik, dan AI.
class TransactionCategories {
  TransactionCategories._();

  static const expense = [
    'Makanan & Minuman',
    'Transportasi',
    'Belanja',
    'Tagihan & Utilitas',
    'Kesehatan',
    'Hiburan',
    'Pendidikan',
    'Rumah & Perawatan',
    'Hadiah & Donasi',
    'Lainnya',
  ];

  static const income = [
    'Gaji',
    'Freelance',
    'Investasi',
    'Hadiah',
    'Refund',
    'Lainnya',
  ];

  static List<String> forType(TransactionType type) =>
      type == TransactionType.income ? income : expense;

  /// Memetakan teks bebas (termasuk dari AI) ke kategori standar terdekat.
  static String normalize(String raw, TransactionType type) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return forType(type).last;

    final options = forType(type);
    final lower = trimmed.toLowerCase();

    for (final option in options) {
      if (option.toLowerCase() == lower) return option;
    }

    const aliases = <String, String>{
      'food': 'Makanan & Minuman',
      'food & drinks': 'Makanan & Minuman',
      'makanan': 'Makanan & Minuman',
      'minuman': 'Makanan & Minuman',
      'transport': 'Transportasi',
      'ojek': 'Transportasi',
      'bensin': 'Transportasi',
      'shopping': 'Belanja',
      'utilities': 'Tagihan & Utilitas',
      'listrik': 'Tagihan & Utilitas',
      'salary': 'Gaji',
      'gaji': 'Gaji',
      'other': 'Lainnya',
    };

    for (final entry in aliases.entries) {
      if (lower.contains(entry.key)) {
        if (options.contains(entry.value)) return entry.value;
      }
    }

    for (final option in options) {
      final optLower = option.toLowerCase();
      if (lower.contains(optLower) || optLower.contains(lower)) {
        return option;
      }
    }

    return options.last;
  }
}
