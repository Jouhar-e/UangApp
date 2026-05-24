import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/app_messenger.dart';
import 'package:uangapp/services/budget_service.dart';
import 'package:uangapp/services/profile_service.dart';
import 'package:uangapp/core/utils/transaction_filters.dart';
import 'package:uangapp/features/home/presentation/widgets/budget_card.dart';
import 'package:uangapp/features/home/presentation/widgets/expense_chart_card.dart';
import 'package:uangapp/features/home/presentation/widgets/profile_gradient_card.dart';
import 'package:uangapp/features/home/presentation/widgets/saldo_card.dart';
import 'package:uangapp/features/home/presentation/widgets/sync_status_banner.dart';
import 'package:uangapp/features/transactions/bloc/transaction_bloc.dart';
import 'package:uangapp/features/transactions/presentation/transaction_detail_dialog.dart';
import 'package:uangapp/features/transactions/presentation/widgets/transaction_filter_sheet.dart';
import 'package:uangapp/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:uangapp/models/transaction.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({
    super.key,
    required this.onSeeAllTransactions,
    this.onOpenAccountTab,
  });

  final VoidCallback onSeeAllTransactions;
  final VoidCallback? onOpenAccountTab;

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  TransactionFilterCriteria _filter = TransactionFilterCriteria.empty;
  double? _monthlyBudget;
  final _budgetService = BudgetService();

  static const _recentLimit = 6;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final budget = await _budgetService.loadMonthlyBudget();
    if (mounted) setState(() => _monthlyBudget = budget);
  }

  double _sumIncome(List<Transaction> list) =>
      list.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

  double _sumExpense(List<Transaction> list) =>
      list.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

  void _openFilters(List<Transaction> all) {
    showTransactionFilterSheet(
      context: context,
      initial: _filter,
      allTransactions: all,
      onApply: (criteria) => setState(() => _filter = criteria),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionBloc, TransactionState>(
      listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage || p.infoMessage != c.infoMessage,
      listener: (context, state) {
        if (state.errorMessage != null &&
            state.loadStatus != TransactionLoadStatus.loading) {
          showAppSnackBar(context, state.errorMessage!);
        }
        if (state.infoMessage != null) {
          showAppSnackBar(context, state.infoMessage!);
        }
      },
      builder: (context, state) {
        if (state.loadStatus == TransactionLoadStatus.loading &&
            state.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final sortedAll = sortTransactionsNewest(state.transactions);
        final recentFiltered = filterAndSortTransactions(sortedAll, _filter);
        final recent = recentFiltered.take(_recentLimit).toList();

        return RefreshIndicator(
          color: context.palette.forest,
          onRefresh: () async {
            context.read<TransactionBloc>().add(
                  const TransactionsLoadRequested(syncWithGoogle: true),
                );
            await context.read<ProfileService>().refresh();
            await _loadBudget();
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SyncStatusBanner(
                  isOnline: state.isOnline,
                  pendingSyncCount: state.pendingSyncCount,
                  lastSyncAt: state.lastSyncAt,
                  infoMessage: state.infoMessage,
                  conflictsResolved: state.conflictsResolvedLastSync,
                ),
              ),
              const SliverToBoxAdapter(child: ProfileGradientCard()),
              SliverToBoxAdapter(
                child: SaldoCard(
                  totalIncome: _sumIncome(sortedAll),
                  totalExpense: _sumExpense(sortedAll),
                  pendingSyncCount: state.pendingSyncCount,
                ),
              ),
              SliverToBoxAdapter(
                child: BudgetCard(
                  transactions: sortedAll,
                  monthlyBudget: _monthlyBudget,
                  onEditBudget: widget.onOpenAccountTab,
                ),
              ),
              SliverToBoxAdapter(
                child: ExpenseChartCard(transactions: sortedAll),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Transaksi Terbaru',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.palette.charcoal,
                            ),
                      ),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: _filter.activeFilterCount > 0,
                          label: Text('${_filter.activeFilterCount}'),
                          child: const Icon(Icons.tune_rounded, size: 22),
                        ),
                        tooltip: 'Filter',
                        onPressed: () => _openFilters(sortedAll),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onSeeAllTransactions,
                        child: const Text('Lihat semua >'),
                      ),
                    ],
                  ),
                ),
              ),
              if (sortedAll.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Belum ada transaksi.\nTap + untuk menambah.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (recent.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_alt_off, size: 48),
                        const SizedBox(height: 12),
                        const Text('Tidak ada transaksi sesuai filter'),
                        TextButton(
                          onPressed: () => setState(
                            () => _filter = TransactionFilterCriteria.empty,
                          ),
                          child: const Text('Reset filter'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = recent[index];
                      return TransactionTile(
                        transaction: tx,
                        compact: true,
                        onTap: () =>
                            showTransactionDetailDialog(context, tx),
                      );
                    },
                    childCount: recent.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          ),
        );
      },
    );
  }
}
