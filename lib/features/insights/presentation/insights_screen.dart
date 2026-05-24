import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/app_messenger.dart';
import 'package:uangapp/core/utils/date_utils.dart';
import 'package:uangapp/core/utils/month_summary.dart';
import 'package:uangapp/features/home/presentation/widgets/month_comparison_strip.dart';
import 'package:uangapp/features/insights/bloc/insights_bloc.dart';
import 'package:uangapp/features/transactions/bloc/transaction_bloc.dart';
import 'package:uangapp/models/transaction.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  List<Transaction> _monthTransactions(List<Transaction> all) {
    return all.where((t) => isSameMonth(t.date, _selectedMonth)).toList();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih bulan laporan',
    );
    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  void _generateReport() {
    final txState = context.read<TransactionBloc>().state;
    final monthTx = _monthTransactions(txState.transactions);
    context.read<InsightsBloc>().add(
          InsightsReportRequested(
            monthTransactions: monthTx,
            month: _selectedMonth,
            allTransactions: txState.transactions,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);
    final scheme = Theme.of(context).colorScheme;
    final palette = context.palette;

    final content = BlocListener<InsightsBloc, InsightsState>(
        listenWhen: (p, c) =>
            p.savedSheetTitle != c.savedSheetTitle ||
            (p.status != c.status && c.status == InsightsStatus.success),
        listener: (context, state) {
          if (state.savedSheetTitle != null) {
            showAppSnackBar(
              context,
              'Laporan disimpan ke tab "${state.savedSheetTitle}" di Google Sheets',
            );
          }
        },
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, txState) {
            final monthTx = _monthTransactions(txState.transactions);
            final currency = NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            );
            final income = monthTx
                .where((t) => t.isIncome)
                .fold(0.0, (s, t) => s + t.amount);
            final expense = monthTx
                .where((t) => !t.isIncome)
                .fold(0.0, (s, t) => s + t.amount);

            final currentSummary = MonthFinancialSummary.fromTransactions(
              txState.transactions,
              _selectedMonth,
            );
            final previousSummary = MonthFinancialSummary.fromTransactions(
              txState.transactions,
              previousMonth(_selectedMonth),
            );

            return BlocBuilder<InsightsBloc, InsightsState>(
              builder: (context, insightsState) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    widget.embedded ? 8 : 16,
                    16,
                    widget.embedded ? 96 : 16,
                  ),
                  children: [
                    if (widget.embedded) ...[
                      Row(
                        children: [
                          Text(
                            'Laporan AI',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.calendar_month),
                            tooltip: 'Ganti bulan',
                            onPressed: _pickMonth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Card(
                      color: scheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.eco,
                                  color: scheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    monthLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: scheme.onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${monthTx.length} transaksi',
                              style: TextStyle(color: scheme.onPrimaryContainer),
                            ),
                            Text(
                              'Pemasukan: ${currency.format(income)}',
                              style: TextStyle(color: scheme.onPrimaryContainer),
                            ),
                            Text(
                              'Pengeluaran: ${currency.format(expense)}',
                              style: TextStyle(color: scheme.onPrimaryContainer),
                            ),
                            Text(
                              'Saldo: ${currency.format(income - expense)}',
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: MonthComparisonStrip(
                          current: currentSummary,
                          previous: previousSummary.expense > 0 ||
                                  previousSummary.income > 0
                              ? previousSummary
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: insightsState.status == InsightsStatus.loading
                          ? null
                          : _generateReport,
                      icon: insightsState.status == InsightsStatus.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.psychology),
                      label: Text(
                        insightsState.status == InsightsStatus.loading
                            ? 'Membuat laporan & menyimpan ke Sheets...'
                            : 'Buat Laporan AI + Simpan ke Sheet',
                      ),
                    ),
                    if (insightsState.savedSheetTitle != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.table_chart,
                            size: 18,
                            color: palette.forest,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tab: ${insightsState.savedSheetTitle}',
                              style: TextStyle(
                                color: palette.charcoal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (insightsState.errorMessage != null &&
                        insightsState.status != InsightsStatus.loading) ...[
                      const SizedBox(height: 16),
                      Text(
                        insightsState.errorMessage!,
                        style: TextStyle(
                          color: insightsState.status == InsightsStatus.failure
                              ? scheme.error
                              : Colors.orange.shade800,
                        ),
                      ),
                    ],
                    if (insightsState.report != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Laporan',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: palette.charcoal,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(insightsState.report!),
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Ganti bulan',
            onPressed: _pickMonth,
          ),
        ],
      ),
      body: content,
    );
  }
}
