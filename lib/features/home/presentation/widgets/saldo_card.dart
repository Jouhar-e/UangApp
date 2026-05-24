import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uangapp/core/theme/app_palette.dart';

class SaldoCard extends StatelessWidget {
  const SaldoCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.pendingSyncCount,
  });

  final double totalIncome;
  final double totalExpense;
  final int pendingSyncCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final balance = totalIncome - totalExpense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Saldo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: palette.charcoal,
                        ),
                  ),
                  const Spacer(),
                  Icon(Icons.account_balance_wallet_outlined,
                      color: palette.sage, size: 22),
                  if (pendingSyncCount > 0) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: '$pendingSyncCount menunggu sinkron',
                      child: const Icon(Icons.sync, size: 18, color: Colors.orange),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                currency.format(balance),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: palette.charcoal,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _IncomeExpenseBox(
                      label: 'Pemasukan',
                      amount: currency.format(totalIncome),
                      isIncome: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _IncomeExpenseBox(
                      label: 'Pengeluaran',
                      amount: currency.format(totalExpense),
                      isIncome: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomeExpenseBox extends StatelessWidget {
  const _IncomeExpenseBox({
    required this.label,
    required this.amount,
    required this.isIncome,
  });

  final String label;
  final String amount;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bg = isIncome
        ? palette.mintLight
        : const Color(0xFFFFEBEE);
    final iconColor = isIncome ? palette.forest : const Color(0xFFC62828);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: palette.charcoal.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                ),
          ),
        ],
      ),
    );
  }
}
