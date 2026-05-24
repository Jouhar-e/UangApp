import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/date_utils.dart';
import 'package:uangapp/models/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.compact = false,
  });

  final Transaction transaction;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isIncome = transaction.isIncome;

    final title = transaction.description.isNotEmpty
        ? transaction.description
        : transaction.category;
    final subtitle = formatTransactionDateTime(
      transaction.date,
      transaction.createdAt,
    );

    final tile = ListTile(
      contentPadding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 2)
          : null,
      leading: CircleAvatar(
        radius: compact ? 22 : null,
        backgroundColor:
            isIncome ? palette.mintLight : Colors.red.shade100,
        child: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          size: compact ? 20 : 24,
          color: isIncome ? palette.charcoal : Colors.red.shade700,
        ),
      ),
      title: Text(
        title,
        style: compact
            ? const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)
            : null,
      ),
      subtitle: Text(
        '${transaction.category} · $subtitle',
        style: compact ? const TextStyle(fontSize: 12) : null,
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${currency.format(transaction.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: compact ? 13 : null,
          color: isIncome ? palette.forest : Colors.red.shade700,
        ),
      ),
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: tile,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: tile,
      ),
    );
  }
}
