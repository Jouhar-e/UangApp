import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/month_summary.dart';

/// Ringkasan perbandingan bulan ini vs bulan sebelumnya.
class MonthComparisonStrip extends StatelessWidget {
  const MonthComparisonStrip({
    super.key,
    required this.current,
    required this.previous,
  });

  final MonthFinancialSummary current;
  final MonthFinancialSummary? previous;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final currency =
        NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ');

    if (previous == null) {
      return Text(
        'Belum ada data bulan sebelumnya untuk perbandingan.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.sage,
            ),
      );
    }

    final expenseDelta = percentChange(current.expense, previous!.expense);
    final incomeDelta = percentChange(current.income, previous!.income);
    final prevLabel = monthLabelId(previous!.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dibanding $prevLabel',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.charcoal,
              ),
        ),
        const SizedBox(height: 8),
        _CompareRow(
          label: 'Pengeluaran',
          currentText: currency.format(current.expense),
          previousText: currency.format(previous!.expense),
          change: expenseDelta,
          upIsBad: true,
          palette: palette,
        ),
        const SizedBox(height: 6),
        _CompareRow(
          label: 'Pemasukan',
          currentText: currency.format(current.income),
          previousText: currency.format(previous!.income),
          change: incomeDelta,
          upIsBad: false,
          palette: palette,
        ),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.currentText,
    required this.previousText,
    required this.change,
    required this.upIsBad,
    required this.palette,
  });

  final String label;
  final String currentText;
  final String previousText;
  final double? change;
  final bool upIsBad;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    Color? badgeColor;
    IconData? icon;
    if (change != null) {
      final up = change! > 0;
      final bad = upIsBad ? up : !up;
      badgeColor = bad ? const Color(0xFFC62828) : palette.forest;
      icon = up ? Icons.trending_up : Icons.trending_down;
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            '$previousText → $currentText',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (change != null && icon != null) ...[
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 2),
          Text(
            formatPercentChange(change),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ],
    );
  }
}
