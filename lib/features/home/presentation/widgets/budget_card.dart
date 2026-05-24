import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/models/transaction.dart';
import 'package:uangapp/services/budget_service.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.transactions,
    required this.monthlyBudget,
    this.onEditBudget,
  });

  final List<Transaction> transactions;
  final double? monthlyBudget;
  final VoidCallback? onEditBudget;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final budgetService = BudgetService();
    final now = DateTime.now();
    final spent = budgetService.monthExpense(transactions, now);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (monthlyBudget == null || monthlyBudget! <= 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Card(
          child: ListTile(
            leading: Icon(Icons.savings_outlined, color: palette.forest),
            title: const Text('Anggaran bulanan'),
            subtitle: const Text('Atur di tab Akun untuk melacak limit'),
            trailing: onEditBudget != null
                ? TextButton(onPressed: onEditBudget, child: const Text('Atur'))
                : null,
          ),
        ),
      );
    }

    final limit = monthlyBudget!;
    final progress = (spent / limit).clamp(0.0, 1.2);
    final over = spent > limit;
    final barColor = over ? const Color(0xFFC62828) : palette.forest;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Anggaran bulan ini',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (onEditBudget != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEditBudget,
                      tooltip: 'Ubah anggaran',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress > 1 ? 1 : progress,
                  minHeight: 10,
                  backgroundColor: palette.mintLight,
                  color: barColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Terpakai ${currency.format(spent)} dari ${currency.format(limit)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (over)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Melebihi anggaran ${currency.format(spent - limit)}',
                    style: TextStyle(
                      color: barColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Sisa ${currency.format(limit - spent)}',
                    style: TextStyle(color: palette.forest, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
