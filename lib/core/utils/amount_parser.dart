/// Defensive parsing for AI JSON amount fields (int, double, or string).
double? parseAmount(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.,\-]'), '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
  return double.tryParse(value.toString());
}

/// Parses manual IDR input: `50000`, `50.000`, `1.250.000`, `12,5` (decimal comma).
double? parseManualAmountInput(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'\s'), '');
  s = s.replaceAll(RegExp('rp', caseSensitive: false), '').replaceAll('IDR', '');
  s = s.trim();
  if (s.isEmpty) return null;

  // Decimal comma at end: "12.345,67" or "12345,5"
  final commaDec = RegExp(r'^([\d\.]+),(\d{1,2})$');
  final mComma = commaDec.firstMatch(s);
  if (mComma != null) {
    final intPart = mComma.group(1)!.replaceAll('.', '');
    return double.tryParse('$intPart.${mComma.group(2)}');
  }

  // Plain Indonesian thousands: 50.000 or 1.250.500 (every dot is thousands)
  if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
    return double.tryParse(s.replaceAll('.', ''));
  }

  // Decimal dot at end segment: "...12.55" (< 3 fractional digits — treat as decimal)
  final dotDec = RegExp(r'^([\d,]+)\.(\d{1,2})$');
  final mDot = dotDec.firstMatch(s);
  if (mDot != null && mDot.group(2)!.length <= 2) {
    final intPart = mDot.group(1)!.replaceAll(',', '');
    return double.tryParse('$intPart.${mDot.group(2)}');
  }

  // Digits only after stripping lone separators mistaken for decimals
  if (RegExp(r'^\d+$').hasMatch(s)) {
    return double.tryParse(s);
  }

  // Fallback: commas as decimals
  final normalized = s.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized);
}
