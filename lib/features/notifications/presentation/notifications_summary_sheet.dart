import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/expense_summary.dart';
import 'package:uangapp/services/notification_service.dart';

void showNotificationsSummarySheet(
  BuildContext context,
  ExpenseSummary summary,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _NotificationsSummarySheet(summary: summary),
  );
}

class _NotificationsSummarySheet extends StatelessWidget {
  const _NotificationsSummarySheet({required this.summary});

  final ExpenseSummary summary;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateLabel =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(summary.referenceDate);
    final monthLabel =
        DateFormat('MMMM yyyy', 'id_ID').format(summary.referenceDate);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: palette.forest),
              const SizedBox(width: 10),
              Text(
                'Ringkasan Pengeluaran',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          _SummaryBlock(
            title: 'Hari ini',
            count: summary.todayExpenseCount,
            total: currency.format(summary.todayExpenseTotal),
            icon: Icons.today_outlined,
            accent: palette.forest,
          ),
          const SizedBox(height: 12),
          _SummaryBlock(
            title: 'Bulan ini ($monthLabel)',
            count: summary.monthExpenseCount,
            total: currency.format(summary.monthExpenseTotal),
            icon: Icons.calendar_month_outlined,
            accent: palette.charcoal,
          ),
          const SizedBox(height: 20),
          Text(
            'Notifikasi harian dikirim setiap pukul 20:00 dengan ringkasan yang sama.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.sage,
                ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await NotificationService.instance.showSummaryNow(summary);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Kirim notifikasi sekarang'),
          ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.title,
    required this.count,
    required this.total,
    required this.icon,
    required this.accent,
  });

  final String title;
  final int count;
  final String total;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.mintLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accent.withValues(alpha: 0.15),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count transaksi · $total',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
