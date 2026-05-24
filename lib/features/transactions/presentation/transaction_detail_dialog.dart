import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/app_messenger.dart';
import 'package:uangapp/features/transactions/bloc/transaction_bloc.dart';
import 'package:uangapp/features/transactions/presentation/transaction_confirm_dialog.dart';
import 'package:uangapp/models/transaction.dart';

void showTransactionDetailDialog(BuildContext context, Transaction transaction) {
  showAppDialog<void>(
    context: context,
    child: TransactionDetailDialog(transaction: transaction),
  );
}

class TransactionDetailDialog extends StatelessWidget {
  const TransactionDetailDialog({super.key, required this.transaction});

  final Transaction transaction;

  Future<void> _edit(BuildContext context) async {
    final updated = await showDialog<Transaction>(
      context: context,
      builder: (_) => TransactionConfirmDialog.edit(initial: transaction),
    );
    if (updated == null || !context.mounted) return;
    context.read<TransactionBloc>().add(TransactionUpdateRequested(updated));
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Tindakan ini juga menghapus baris di Google Sheet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    context
        .read<TransactionBloc>()
        .add(TransactionDeleteRequested(transaction.id));
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isIncome = transaction.isIncome;
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(transaction.date);
    final createdStr =
        DateFormat("d MMM yyyy · HH:mm", 'id_ID').format(transaction.createdAt);
    final updatedStr =
        DateFormat("d MMM yyyy · HH:mm", 'id_ID').format(transaction.updatedAt);

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                isIncome ? palette.mintLight : Colors.red.shade100,
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? palette.forest : Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isIncome ? 'Pemasukan' : 'Pengeluaran',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${currency.format(transaction.amount)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? palette.forest : Colors.red.shade700,
                  ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.description_outlined,
              label: 'Deskripsi',
              value: transaction.description.isNotEmpty
                  ? transaction.description
                  : '—',
            ),
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Kategori',
              value: transaction.category,
            ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal',
              value: dateStr,
            ),
            _DetailRow(
              icon: Icons.schedule_outlined,
              label: 'Dicatat',
              value: createdStr,
            ),
            if (!transaction.updatedAt.isAtSameMomentAs(transaction.createdAt))
              _DetailRow(
                icon: Icons.edit_outlined,
                label: 'Diubah',
                value: updatedStr,
              ),
            _DetailRow(
              icon: Icons.tag_outlined,
              label: 'ID',
              value: transaction.id,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _delete(context),
          child: Text(
            'Hapus',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        TextButton(
          onPressed: () => _edit(context),
          child: const Text('Ubah'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: palette.sage),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.sage,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.charcoal,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
