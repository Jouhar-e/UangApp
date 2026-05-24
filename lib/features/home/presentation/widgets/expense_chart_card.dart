import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/month_summary.dart';
import 'package:uangapp/features/home/presentation/widgets/month_comparison_strip.dart';
import 'package:uangapp/models/transaction.dart';

class ExpenseChartCard extends StatelessWidget {
  const ExpenseChartCard({
    super.key,
    required this.transactions,
  });

  final List<Transaction> transactions;

  static const _chartColors = [
    Color(0xFF5B8266),
    Color(0xFF99B898),
    Color(0xFFF06292),
    Color(0xFF880E4F),
    Color(0xFF334D5C),
    Color(0xFFFFB74D),
    Color(0xFF64B5F6),
    Color(0xFF8D6E63),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final current = MonthFinancialSummary.fromTransactions(
      transactions,
      currentMonth,
    );
    final previous = MonthFinancialSummary.fromTransactions(
      transactions,
      previousMonth(currentMonth),
    );

    final byCategory = current.expenseByCategory;

    if (byCategory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Belum ada pengeluaran bulan ini untuk grafik kategori.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final total = top.fold(0.0, (s, e) => s + e.value);
    final currency =
        NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengeluaran per kategori',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.charcoal,
                    ),
              ),
              Text(
                monthLabelId(currentMonth),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              MonthComparisonStrip(current: current, previous: previous),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),
              SizedBox(
                height: 168,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 148,
                      height: 148,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 34,
                          sections: [
                            for (var i = 0; i < top.length; i++)
                              PieChartSectionData(
                                color: _chartColors[i % _chartColors.length],
                                value: top[i].value,
                                title: total > 0
                                    ? '${(top[i].value / total * 100).toStringAsFixed(0)}%'
                                    : '',
                                radius: 48,
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < top.length; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: _LegendRow(
                                color: _chartColors[i % _chartColors.length],
                                label: top[i].key,
                                amount: currency.format(top[i].value),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.amount,
  });

  final Color color;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.25),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
