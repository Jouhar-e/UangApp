import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/transaction_filters.dart';
import 'package:uangapp/features/transactions/bloc/transaction_bloc.dart';
import 'package:uangapp/features/transactions/presentation/transaction_detail_dialog.dart';
import 'package:uangapp/features/transactions/presentation/widgets/transaction_filter_sheet.dart';
import 'package:uangapp/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:uangapp/models/transaction.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  TransactionFilterCriteria _filter = TransactionFilterCriteria.empty;

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
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state.loadStatus == TransactionLoadStatus.loading &&
            state.transactions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final sortedAll = sortTransactionsNewest(state.transactions);
        final visible = filterAndSortTransactions(sortedAll, _filter);

        return RefreshIndicator(
          color: context.palette.forest,
          onRefresh: () async {
            context.read<TransactionBloc>().add(
                  const TransactionsLoadRequested(syncWithGoogle: true),
                );
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  child: Row(
                    children: [
                      Text(
                        'Semua Transaksi',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Badge(
                          isLabelVisible: _filter.activeFilterCount > 0,
                          label: Text('${_filter.activeFilterCount}'),
                          child: const Icon(Icons.tune_rounded),
                        ),
                        tooltip: 'Filter',
                        onPressed: () => _openFilters(sortedAll),
                      ),
                    ],
                  ),
                ),
              ),
              if (_filter.activeFilterCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${visible.length} dari ${sortedAll.length} transaksi',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.palette.forest,
                          ),
                    ),
                  ),
                ),
              if (sortedAll.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Belum ada transaksi')),
                )
              else if (visible.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: TextButton(
                      onPressed: () => setState(
                        () => _filter = TransactionFilterCriteria.empty,
                      ),
                      child: const Text('Reset filter'),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = visible[index];
                      return TransactionTile(
                        transaction: tx,
                        onTap: () =>
                            showTransactionDetailDialog(context, tx),
                      );
                    },
                    childCount: visible.length,
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
